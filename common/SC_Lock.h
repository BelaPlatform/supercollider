/*
    SuperCollider real time audio synthesis system
    Copyright (c) 2002 James McCartney. All rights reserved.
    http://www.audiosynth.com

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
*/

#pragma once

#include <chrono>
#include <condition_variable>
#include <mutex>
#include <thread>

#ifdef SC_BELA
// only for server stuff
#    define SC_CONDITION_VARIABLE_ANY_SHOULD_LOCK_BEFORE_NOTIFY // See:
                                                                // https://www.xenomai.org/pipermail/xenomai/2017-October/037759.html
#    include <RtLock.h> // from Bela
using SC_Lock = RtMutex;
using condition_variable_any = RtConditionVariable;
#else
using SC_Lock = std::mutex;
using condition_variable_any = std::condition_variable_any;
#endif

using SC_Thread = std::thread;
using std::cv_status;
using std::lock_guard;
using std::timed_mutex;
using std::unique_lock;
using mutex = SC_Lock;
