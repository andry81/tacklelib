#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_TIME_HPP
#define UTILITY_TIME_HPP

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/assert.hpp>

#include <cstdint>
#include <atomic>
#include <chrono>
#include <limits>

#ifdef UTILITY_PLATFORM_WINDOWS
#include <winnt.h>
#include <winbase.h>
#elif UTILITY_PLATFORM_POSIX
#include <time.h>
#else
#error platform is not implemented
#endif


namespace utility
{
#ifdef UTILITY_PLATFORM_WINDOWS
    using clockid_t = int;

    const clockid_t CLOCK_REALTIME              = 0;    // Identifier for system-wide realtime clock.
    const clockid_t CLOCK_MONOTONIC             = 1;    // Monotonic system-wide clock.
    const clockid_t CLOCK_PROCESS_CPUTIME_ID    = 2;    // High-resolution timer from the CPU.
    const clockid_t CLOCK_THREAD_CPUTIME_ID     = 3;    // Thread-specific CPU-time clock.
    const clockid_t CLOCK_MONOTONIC_RAW         = 4;    // Monotonic system-wide clock, not adjusted for frequency scaling.
    const clockid_t CLOCK_REALTIME_COARSE       = 5;    // Identifier for system-wide realtime clock, updated only on ticks.
    const clockid_t CLOCK_MONOTONIC_COARSE      = 6;    // Monotonic system-wide clock, updated only on ticks.
    const clockid_t CLOCK_BOOTTIME              = 7;    // Monotonic system-wide clock that includes time spent in suspension.
    const clockid_t CLOCK_REALTIME_ALARM        = 8;    // Like CLOCK_REALTIME but also wakes suspended system.
    const clockid_t CLOCK_BOOTTIME_ALARM        = 9;    // Like CLOCK_BOOTTIME but also wakes suspended system.
    const clockid_t CLOCK_TAI                   = 11;   // Like CLOCK_REALTIME but in International Atomic Time.

    void unix_time(struct timespec *spec)
    {
        constexpr const int64_t w2ux = 116444736000000000i64; //1.jan1601 to 1.jan1970

        int64_t wintime;
        GetSystemTimeAsFileTime((FILETIME *)&wintime);
        wintime -= w2ux;
        spec->tv_sec = wintime / 10000000i64;
        spec->tv_nsec = wintime % 10000000i64 * 100;
    }

    int clock_gettime(clockid_t clk_id, struct timespec * ct)
    {
        UTILITY_UNUSED_STATEMENT(clk_id);

        // context call saved per thread basis instead of per entire application
        thread_local std::atomic<bool> s_has_queried_frequency = false;
        thread_local LARGE_INTEGER s_counts_per_sec;
        timespec unix_startspec;
        LARGE_INTEGER count;

        if (!s_has_queried_frequency.exchange(true)) {
            if (QueryPerformanceFrequency(&s_counts_per_sec)) {
                unix_time(&unix_startspec);
            }
            else {
                s_counts_per_sec.QuadPart = 0;
            }
        }

        if (!ct || s_counts_per_sec.QuadPart <= 0 || !QueryPerformanceCounter(&count)) {
            return -1;
        }

        ct->tv_sec = unix_startspec.tv_sec + count.QuadPart / s_counts_per_sec.QuadPart;
        int64_t tv_nsec = unix_startspec.tv_nsec + ((count.QuadPart % s_counts_per_sec.QuadPart) * 1000000000i64) / s_counts_per_sec.QuadPart;

        if (!(tv_nsec < 1000000000)) {
            ct->tv_sec++;
            tv_nsec -= 1000000000;
        }

        DEBUG_ASSERT_GE(int64_t((std::numeric_limits<long>::max)()), tv_nsec);
        ct->tv_nsec = long(tv_nsec);

        return 0;
    }
#endif
}

#endif
