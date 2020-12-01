#include <mutex> //unique_lock
// Xenomai enforces the requirement to hold the lock so that optimizing
// the wake up process is possible - under the assumption that the caller
// owns the lock. There is no hack around this.
// See: https://www.xenomai.org/pipermail/xenomai/2017-October/037759.html
#define SC_CONDITION_VARIABLE_ANY_SHOULD_LOCK_BEFORE_NOTIFY

// to make sure Xenomai gets initialised on time, create one object of this
// class before any XenomaiMutex or XenomaiConditionVariable constructors
class XenomaiInitializer {
public:
    XenomaiInitializer();
};

class XenomaiMutex {
    friend class XenomaiConditionVariable;

public:
    XenomaiMutex();
    XenomaiMutex(std::unique_lock<XenomaiMutex>&);
    ~XenomaiMutex();
    bool try_lock(bool recurred = false);
    void lock(bool recurred = false);
    void unlock(bool recurred = false);

private:
    pthread_mutex_t mutex;
    bool enabled = false;
};

class XenomaiConditionVariable {
public:
    XenomaiConditionVariable();
    ~XenomaiConditionVariable();
    void wait(std::unique_lock<XenomaiMutex>& lck, bool recurred = false);
    void notify_one(bool recurred = false) noexcept;
    void notify_all(bool recurred = false) noexcept;

private:
    pthread_cond_t cond;
    bool enabled = false;
};
