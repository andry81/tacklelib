#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_TIME_HPP
#define UTILITY_TIME_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_traits.hpp>
#include <tacklelib/utility/assert.hpp>
#include <tacklelib/utility/string.hpp>

#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_INSTEAD_STD_STRINGSTREAMS)
#include <fmt/format.h>
#include <fmt/chrono.h>
#endif

#include <string>
#include <vector>
#include <ctime>
#include <cmath>
#include <cstdint>
#include <atomic>
#include <chrono>
#include <limits>
#include <sstream>
#include <iomanip>
#include <utility>
#include <exception>
#include <functional>

#ifdef UTILITY_PLATFORM_WINDOWS
// windows includes must be ordered here!
#   include <windef.h>
#   include <winbase.h>
#   include <winnt.h>
#elif defined(UTILITY_PLATFORM_POSIX)
#   include <sys/types.h>
#   include <sys/time.h>
#   ifdef UTILITY_PLATFORM_MINGW
#       include <cygwin/time.h>
#       include <sysinfoapi.h>
//#   else
//#       include <pthread_time.h> # does not exist on some Linuxes
#   endif
#else
#   error platform is not implemented
#endif

#undef LIBRARY_API_NAMESPACE
#define LIBRARY_API_NAMESPACE TACKLELIB
#include <tacklelib/utility/library_api_define.hpp>


namespace utility {
namespace time {

    using convert_time_string_to_std_time_error_func_t      = std::function<void(const std::string &, const std::string &, const std::exception *)>;
    using convert_time_string_from_std_time_error_func_t    = std::function<void(const std::string &, const std::time_t &, const std::exception *)>;

    static CONSTEXPR const uint64_t unix_epoch_mcsecs                       =  62135596800000000ULL;
    static CONSTEXPR const uint64_t from_1_jan1601_to_1_jan1970_100nsecs    = 116444736000000000ULL;   //1.jan1601 to 1.jan1970

#ifdef UTILITY_PLATFORM_WINDOWS
    using clockid_t = int;

    const clockid_t CLOCK_REALTIME              = 0;    // Identifier for system-wide realtime clock.
    const clockid_t CLOCK_MONOTONIC             = 1;    // Monotonic system-wide clock.
    const clockid_t CLOCK_PROCESS_CPUTIME_ID    = 2;    // High-resolution timer from the CPU.
    const clockid_t CLOCK_THREAD_CPUTIME_ID     = 3;    // Thread-specific CPU-time clock.
#else
#   ifndef CLOCK_MONOTONIC_RAW
    const clockid_t CLOCK_MONOTONIC_RAW         = 4;    // Monotonic system-wide clock, not adjusted for frequency scaling.
#   endif
#   ifndef CLOCK_REALTIME_COARSE
    const clockid_t CLOCK_REALTIME_COARSE       = 5;    // Identifier for system-wide realtime clock, updated only on ticks.
#   endif
#   ifndef CLOCK_MONOTONIC_COARSE
    const clockid_t CLOCK_MONOTONIC_COARSE      = 6;    // Monotonic system-wide clock, updated only on ticks.
#   endif
#   ifndef CLOCK_BOOTTIME
    const clockid_t CLOCK_BOOTTIME              = 7;    // Monotonic system-wide clock that includes time spent in suspension.
#   endif
#   ifndef CLOCK_REALTIME_ALARM
    const clockid_t CLOCK_REALTIME_ALARM        = 8;    // Like CLOCK_REALTIME but also wakes suspended system.
#   endif
#   ifndef CLOCK_BOOTTIME_ALARM
    const clockid_t CLOCK_BOOTTIME_ALARM        = 9;    // Like CLOCK_BOOTTIME but also wakes suspended system.
#   endif
#   ifndef CLOCK_TAI
    const clockid_t CLOCK_TAI                   = 11;   // Like CLOCK_REALTIME but in International Atomic Time.
#   endif
#endif

    FORCE_INLINE void unix_time(struct timespec *spec)
    {
#ifdef UTILITY_PLATFORM_WINDOWS
        int64_t wintime;
        GetSystemTimeAsFileTime((FILETIME *)&wintime);
        wintime -= from_1_jan1601_to_1_jan1970_100nsecs;
        spec->tv_sec = wintime / 10000000;
        spec->tv_nsec = wintime % 10000000 * 100;
#elif defined(UTILITY_PLATFORM_POSIX) || defined(UTILITY_PLATFORM_MINGW)
        struct timeval tv; 
        gettimeofday(&tv, NULL);
        spec->tv_sec = tv.tv_sec;
        spec->tv_nsec = tv.tv_usec * 1000;
#else
        ::timespec_get(spec, TIME_UTC);
#endif
    }

    FORCE_INLINE int clock_gettime(clockid_t clk_id, struct timespec * ct)
    {
#ifdef UTILITY_PLATFORM_WINDOWS
        UTILITY_UNUSED_STATEMENT(clk_id);

        // context call saved per thread basis instead of per entire application
        thread_local std::atomic<bool> s_has_queried_frequency{ false };
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
        int64_t tv_nsec = unix_startspec.tv_nsec + ((count.QuadPart % s_counts_per_sec.QuadPart) * 1000000000) / s_counts_per_sec.QuadPart;

        if (!(tv_nsec < 1000000000)) {
            ct->tv_sec++;
            tv_nsec -= 1000000000;
        }

        DEBUG_ASSERT_GE(int64_t((std::numeric_limits<long>::max)()), tv_nsec);
        ct->tv_nsec = long(tv_nsec);

        return 0;
#else
        return ::clock_gettime(clk_id, ct);
#endif
    }

    FORCE_INLINE bool is_leap_year(size_t year)
    {
        return !(year % 4) && (year % 100) || !(year % 400);
    }

    FORCE_INLINE size_t get_leap_days(size_t year)
    {
        DEBUG_ASSERT_GE(year, 1800U);
        const size_t prev_year = year - 1;
        return prev_year / 4 - prev_year / 100 + prev_year / 400;
    }


    FORCE_INLINE std::tm gmtime(const std::time_t & time)
    {
        std::tm t{};

#ifdef UTILITY_PLATFORM_WINDOWS
        gmtime_s(&t, &time);
#else
        gmtime_r(&time, &t);
#endif

        return t;
    }

    // analog: `std::mktime` to convert into `std::time_t`
    FORCE_INLINE std::time_t timegm(const std::tm & time)
    {
        std::tm c_tm = time; // must be not constant

#if defined(UTILITY_COMPILER_CXX_MSC)
        return ::_mkgmtime(&c_tm);
#elif defined(UTILITY_COMPILER_CXX_CLANG) || defined(UTILITY_COMPILER_CXX_GCC)
        return ::timegm(&c_tm);
#else
#   error platform is not implemented
#endif
    }

    FORCE_INLINE std::tm get_calendar_time_from_utc_time_sec(double utc_time_sec, double * utc_time_sec_fract = nullptr)
    {
        // convert UTC time to time_t structure
        const std::time_t track_time = std::time_t(uint64_t(utc_time_sec)); // seconds since 00:00 hours 1 Jan 1970 (unix epoch)

        if (utc_time_sec_fract) {
            double whole;
            *utc_time_sec_fract = std::modf(utc_time_sec, &whole);
        }

        return utility::time::gmtime(track_time);
    }

    FORCE_INLINE bool get_time(std::string & time_str, const std::string & fmt, const std::tm & time, std::exception * exception_ptr = nullptr)
    {
        if (exception_ptr) {
            *exception_ptr = std::exception{};
        }

#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_INSTEAD_STD_STRINGSTREAMS)
        const std::string fmt_format{ utility::string_format(256, "{:%s}", fmt.c_str()) }; // faster than fmt format
        try
        {
            time_str = fmt::format(fmt_format, time);
            return true;
        }
        catch (const fmt::format_error & ex)
        {
            if (exception_ptr) {
                *exception_ptr = ex;
            }
        }
#else
        std::stringstream buffer;
        buffer << std::put_time(&time, fmt.c_str());
        if (!buffer.fail()) {
            time_str = buffer.str();
            return true;
        }
#endif

        return false;
    }

#ifdef UTILITY_PLATFORM_FEATURE_STD_HAS_GET_TIME
    // Uses `std::get_time` to read the formatted time string into calendar time (not including milliseconds and days since 1 January).
    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool get_time(std::tm & time, const std::string & locale,
                               const std::basic_string<t_elem, t_traits, t_alloc> & fmt, const std::basic_string<t_elem, t_traits, t_alloc> & date_time_str,
                               std::exception * exception_ptr = nullptr)
    {
        if (exception_ptr) {
            *exception_ptr = std::exception{};
        }

// not implemented
//#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_INSTEAD_STD_STRINGSTREAMS)
//        const std::string fmt_format{ utility::string_format(256, "{:%s}", fmt.c_str()) }; // faster than fmt format
//        try
//        {
//            time = fmt::get_time(fmt_format, date_time_str);
//            return true;
//        }
//        catch (const fmt::format_error & ex)
//        {
//            if (exception_ptr) {
//                *exception_ptr = ex;
//            }
//        }
//
//        return false;
//#else
        time = std::tm{};

        std::basic_istringstream<t_elem, t_traits, t_alloc> ss{ date_time_str };
        if (!locale.empty()) {
            ss.imbue(std::locale(locale));
        }

        // CAUTION:
        //  t.tm_yday is not initialized here!
        //
        ss >> std::get_time(&time, fmt.c_str());

        return !ss.fail();
//#endif
    }

    // Uses `std::get_time` to read the formatted time string into calendar time (not including milliseconds and days since 1 January).
    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool get_time(std::tm & time, const std::string & locale,
                               const std::basic_string<t_elem, t_traits, t_alloc> & fmt, std::basic_string<t_elem, t_traits, t_alloc> && date_time_str,
                               std::exception * exception_ptr = nullptr)
    {
        if (exception_ptr) {
            *exception_ptr = std::exception{};
        }

// not implemented
//#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_INSTEAD_STD_STRINGSTREAMS)
//        const std::string fmt_format{ utility::string_format(256, "{:%s}", fmt.c_str()) }; // faster than fmt format
//        try
//        {
//            time = fmt::get_time(fmt_format, std::move(date_time_str));
//            return true;
//        }
//        catch (const fmt::format_error & ex)
//        {
//            if (exception_ptr) {
//                *exception_ptr = ex;
//            }
//        }
//
//        return false;
//#else
        time = std::tm{};

        std::basic_istringstream<t_elem, t_traits, t_alloc> ss{ std::move(date_time_str) };
        if (!locale.empty()) {
            ss.imbue(std::locale(locale));
        }

        // CAUTION:
        //  t.tm_yday is not initialized here!
        //
        ss >> std::get_time(&time, fmt.c_str());

        return !ss.fail();
//#endif
    }
#endif

    std::time_t LIBRARY_API_DECL convert_time_string_to_std_time(const std::string & time_str_format, const std::string & time_value_str,
                                                                 convert_time_string_to_std_time_error_func_t error_func = convert_time_string_to_std_time_error_func_t{});

    std::string LIBRARY_API_DECL convert_time_string_from_std_time(const std::string & time_str_format, const std::time_t & time_value,
                                                                   convert_time_string_from_std_time_error_func_t error_func = convert_time_string_from_std_time_error_func_t{});

}
}

#endif
