#include "XenomaiLock.h"

#include <pthread.h>
#include <error.h>
#include <string.h>
#include <cobalt/sys/cobalt.h>
#ifndef _GNU_SOURCE
#    define _GNU_SOURCE
#endif
#include <unistd.h>
#include <sys/syscall.h>

#ifndef __COBALT__
#    error This should be compiled with __COBALT__ and the appropriate Xenomai headers in the #include path
#endif // __COBALT__
// All __wrap_* calls below are Xenomai libcobalt calls

//#define PRINT_XENO_LOCK

#ifdef PRINT_XENO_LOCK
#    define xprintf printf
#    define xfprintf fprintf
#else // PRINT_XENO_LOCK
#    define xprintf(...)
#    define xfprintf(...)
#endif // PRINT_XENO_LOCK

extern "C" {
void xenomai_init(int* argcp, char* const** argvp);
}

static inline pid_t get_tid() {
    pid_t tid = syscall(SYS_gettid);
    return tid;
}

// throughout, we use heuristics to check whether Xenomai needs to be
// initialised and whether the current thread is a Xenomai thread.
// See https://www.xenomai.org/pipermail/xenomai/2019-January/040203.html
static void initialize_xenomai() {
    xprintf("Initialize_xenomai\n");
    int argc = 2;
    char const0[] = "";
#ifdef PRINT_XENO_LOCK
    char const1[] = "--trace";
#else // PRINT_XENO_LOCK
    char const1[] = "";
#endif // PRINT_XENO_LOCK
    char const2[] = "";
    char* const arg0 = const0;
    char* const arg1 = const1;
    char* const arg2 = const2;
    char* const** argv = (char* const**)malloc(sizeof(char**) * argc + 1);
    argv[0] = &arg0;
    argv[1] = &arg1;
    argv[argc] = &arg2;
    xenomai_init(&argc, argv);
}

static int turn_into_cobalt_thread(bool recurred = false) {
    int current_mode = cobalt_thread_mode();
    struct sched_param param;
    memset(&param, 0, sizeof(param));
    int policy;
    int ret = pthread_getschedparam(pthread_self(), &policy, &param);
    pid_t tid = get_tid();

    if (int ret = __wrap_sched_setscheduler(tid, policy, &param)) {
        fprintf(stderr, "Warning: unable to turn current thread into a Xenomai thread : (%d) %s\n", -ret,
                strerror(-ret));
        initialize_xenomai();
        if (!recurred)
            return turn_into_cobalt_thread(1);
        else
            return -1;
    }
    xprintf("Turned thread %d into a Cobalt thread %s\n", tid, recurred ? "with recursion" : "");
    return 0;
}

XenomaiInitializer::XenomaiInitializer() { initialize_xenomai(); }

XenomaiMutex::XenomaiMutex() {
    xprintf("Construct mutex\n");
    if (int ret = __wrap_pthread_mutex_init(&mutex, NULL)) {
        if (EPERM == ret) {
            xprintf("mutex init returned EPERM\n");
            initialize_xenomai();
            if (int ret = __wrap_pthread_mutex_init(&mutex, NULL)) {
                fprintf(stderr, "Error: unable to initialize mutex : (%d) %s\n", ret, strerror(-ret));
                return;
            }
        }
    }
    enabled = true;
}

XenomaiMutex::~XenomaiMutex() {
    xprintf("Destroy mutex %p\n", &mutex);
    if (enabled)
        __wrap_pthread_mutex_destroy(&mutex);
}

#define try_or_retry(retry, func, id, name, testRetry, succ, fail)                                                     \
    xprintf("BBBtid: %d ", get_tid());                                                                                 \
    int ret;                                                                                                           \
    if (enabled) {                                                                                                     \
        xprintf("%s %p\n", name, id);                                                                                  \
        if (0 == (ret = func)) {                                                                                       \
            return succ;                                                                                               \
        }                                                                                                              \
        if (recurred) {                                                                                                \
            xfprintf(stderr, "%s %d  failed after recursion: %d\n", name, id, ret);                                    \
            return fail;                                                                                               \
        }                                                                                                              \
        if (testRetry == ret) {                                                                                        \
            if (turn_into_cobalt_thread()) {                                                                           \
                xfprintf(stderr, "%s %d could not turn into cobalt\n", name, id);                                      \
                return fail;                                                                                           \
            }                                                                                                          \
            return retry;                                                                                              \
        }                                                                                                              \
        return fail;                                                                                                   \
    } else {                                                                                                           \
        xfprintf(stderr, "%s %d disabled %p\n", name, id);                                                             \
        return fail;                                                                                                   \
    }

// condition resource_deadlock_would_occur instead of deadlocking. https://en.cppreference.com/w/cpp/thread/mutex/lock
bool XenomaiMutex::try_lock(bool recurred) {
    const char name[] = "try_lock";
    int testRetry = EPERM;
    bool succ = true;
    bool fail = false;
    try_or_retry(try_lock(true), __wrap_pthread_mutex_trylock(&mutex), &mutex, name, testRetry, succ, fail)
    // TODO: An implementation that can detect the invalid usage is encouraged to throw a std::system_error with error
    // condition resource_deadlock_would_occur instead of deadlocking.
}

void XenomaiMutex::lock(bool recurred) {
    const char name[] = "lock";
    int testRetry = EPERM;
    try_or_retry(lock(true), __wrap_pthread_mutex_lock(&mutex), &mutex, name, testRetry, , )
}

void XenomaiMutex::unlock(bool recurred) {
    const char name[] = "unlock";
    int testRetry = EPERM;
    try_or_retry(unlock(true), __wrap_pthread_mutex_unlock(&mutex), &mutex, name, testRetry, , )
}

XenomaiConditionVariable::XenomaiConditionVariable() {
    xprintf("Construct CondictionVariable\n");
    if (int ret = __wrap_pthread_cond_init(&cond, NULL)) {
        if (EPERM == ret) {
            xprintf("mutex init returned EPERM\n");
            initialize_xenomai();
            if (int ret = __wrap_pthread_cond_init(&cond, NULL)) {
                fprintf(stderr, "Error: unable to create condition variable : (%d) %s\n", ret, strerror(ret));
                return;
            }
        }
        return;
    }
    enabled = true;
}

XenomaiConditionVariable::~XenomaiConditionVariable() {
    if (enabled) {
        notify_all();
        __wrap_pthread_cond_destroy(&cond);
    }
}

void XenomaiConditionVariable::wait(std::unique_lock<XenomaiMutex>& lck, bool recurred) {
    // If any parameter has a value that is not valid for this function (such as if lck's mutex object is not locked by
    // the calling thread), it causes undefined behavior.

    // Otherwise, if an exception is thrown, both the condition_variable_any object and the arguments are in a valid
    // state (basic guarantee). Additionally, on exception, the state of lck is attempted to be restored before exiting
    // the function scope (by calling lck.lock()).

    // It may throw system_error in case of failure (transmitting any error condition from the respective call to lock
    // or unlock). The predicate version (2) may also throw exceptions thrown by pred.
    const char name[] = "wait";
    int testRetry = EPERM;
    try_or_retry(wait(lck, true), __wrap_pthread_cond_wait(&cond, &lck.mutex()->mutex), &cond, name, testRetry, , )
}

void XenomaiConditionVariable::notify_one(bool recurred) noexcept {
    const char name[] = "notify_one";
    int testRetry = EPERM;
    try_or_retry(notify_one(true), __wrap_pthread_cond_signal(&cond), &cond, name, testRetry, , )
}

void XenomaiConditionVariable::notify_all(bool recurred) noexcept {
    const char name[] = "notify_all";
    int testRetry = EPERM;
    try_or_retry(notify_all(true), __wrap_pthread_cond_broadcast(&cond), &cond, name, testRetry, , )
}
