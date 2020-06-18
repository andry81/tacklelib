#include <tacklelib/utility/time.hpp>

#ifndef UTILITY_PLATFORM_FEATURE_STD_HAS_GET_TIME
#include <boost/date_time/posix_time/posix_time.hpp>
#endif

#include <inttypes.h>


namespace utility {
namespace time {

    // WORKAROUND:
    //  1. Boost uses `strftime` time string format instead of the `std::get_time` time string format plus biased time base which has to be workarounded:
    //      `from_time_t(t1 + t2) gains incorrect and different results on Windows and Linux`:
    //      https://github.com/boostorg/date_time/issues/157
    //  2. Use base year extraction to renormalize std::tm to the std representation.
    //

    std::time_t convert_time_string_to_std_time(const std::string & time_str_format, const std::string & time_value_str,
                                                convert_time_string_to_std_time_error_func_t error_func)
    {
        std::time_t epoch_time_sec = 0;

#if defined(UTILITY_PLATFORM_FEATURE_STD_HAS_GET_TIME) && !defined(UTILITY_PLATFORM_FEATURE_USE_BOOST_POSIX_TIME_INSTEAD_STD_GET_TIME)
        try
        {
            std::tm t;
            if (utility::time::get_time(t, std::string{}, time_str_format, time_value_str)) {
                if (time_str_format.find("%Y") == std::string::npos) {
                    if (time_str_format.find("%y") == std::string::npos) {
                        // from 1900 year
                        t.tm_year += 70;
                    }
                    else {
                        // [00-68] -> 2000-2068
                        // [69-99] -> 1969-1999
                        if (t.tm_year < 69) {
                            t.tm_year += 100;
                        }
                    }
                }
                if (!t.tm_mday) t.tm_mday = 1;

#if defined(UTILITY_COMPILER_CXX_MSC) && UTILITY_COMPILER_CXX_VERSION < 1910
                time_t epoch_time_correction_sec = 0;
                int epoch_time_correction_from_year = 70;
                if (t.tm_year < 70) {
                    // CAUTION:
                    //   utility::time::timegm will fail if the year component is less than 70, so fix the year and add delta directly to the time_t
                    //
                    epoch_time_correction_from_year = t.tm_year;
                    t.tm_year = 70;
                }
#endif

                errno = 0; // must be to ensure the state change
                epoch_time_sec = utility::time::timegm(t);
                if (epoch_time_sec == -1 && errno != 0) { // error handle
                    epoch_time_sec = 0;
                }
                else {
#if defined(UTILITY_COMPILER_CXX_MSC) && UTILITY_COMPILER_CXX_VERSION < 1910
                    for (int i = epoch_time_correction_from_year; i < 70; i++) {
                        epoch_time_sec -= 365 * 24 * 60 * 60;
                    }
                    epoch_time_sec -= (get_leap_days(1970) - get_leap_days(1900 + epoch_time_correction_from_year)) * 24 * 60 * 60;
#endif
                }
            }
            else {
                if (error_func) {
                    error_func(time_str_format, time_value_str, nullptr);
                }
            }
        }
#else
        try
        {
            namespace boost_ptime = boost::posix_time;

            struct base_time_extractor
            {
                base_time_extractor() {
                    std::istringstream iss{ "%Y-%m-%d" };
                    iss.imbue(std::locale(std::locale::classic(), new boost_ptime::time_input_facet("1970-01-01")));
                    boost_ptime::ptime base_ptime_value;
                    iss >> base_ptime_value;
                    base_time = boost_ptime::to_tm(base_ptime_value);
                    //printf("base tm_year (boost) 1: %i\n", base_time.tm_year);
                }

                std::tm base_time;
            } static s_base_time_extractor;

            std::istringstream iss{ time_value_str };
            iss.imbue(std::locale(std::locale::classic(), new boost_ptime::time_input_facet(time_str_format.c_str())));
            boost_ptime::ptime ptime_value;
            iss >> ptime_value;

            if (!ptime_value.is_not_a_date_time()) {
                std::tm t = boost_ptime::to_tm(ptime_value);

                if (time_str_format.find("%Y") == std::string::npos) {
                    if (time_str_format.find("%y") == std::string::npos) {
                        // biased base, normalize
                        t.tm_year -= s_base_time_extractor.base_time.tm_year;
                        // from 1900 year
                        t.tm_year += 70;
                    }
                    else {
                        // CAUTION:
                        //  Here is a specific boost incompatability versus the std::get_time because the boost has used the
                        //  strftime format which is quite different:
                        //  [00-99] -> 2000-2099

                        // std::get_time format, just in case:
                        //  [00-68] -> 2000-2068
                        //  [69-99] -> 1969-1999
                        if (t.tm_year < 69) {
                            t.tm_year += 100;
                        }
                    }
                }
                if (!t.tm_mday) t.tm_mday = 1; // just in case

                epoch_time_sec = utility::time::timegm(t);
            }
            else {
                if (error_func) {
                    error_func(time_str_format, time_value_str, nullptr);
                }
            }
        }
        catch (const boost::bad_lexical_cast & ex)
        {
            if (error_func) {
                error_func(time_str_format, time_value_str, &ex);
            }
        }
#endif
        catch (const std::out_of_range & ex)
        {
            if (error_func) {
                error_func(time_str_format, time_value_str, &ex);
            }
        }

        return epoch_time_sec;
    }

    std::string convert_time_string_from_std_time(const std::string & time_str_format, const std::time_t & time_value,
                                                  convert_time_string_from_std_time_error_func_t error_func)
    {
#if defined(UTILITY_PLATFORM_FEATURE_STD_HAS_GET_TIME) && !defined(UTILITY_PLATFORM_FEATURE_USE_BOOST_POSIX_TIME_INSTEAD_STD_GET_TIME)
        std::string time_str;

        try
        {
#if !defined(UTILITY_COMPILER_CXX_MSC) || UTILITY_COMPILER_CXX_VERSION >= 1910
            std::tm t = utility::time::gmtime(time_value);
#else
            std::tm t = utility::time::gmtime(time_value >= 0 ? time_value : 0); // avoid exception code 0xc0000409
#endif

            if (time_str_format.find("%Y") == std::string::npos) {
                if (time_str_format.find("%y") == std::string::npos) {
                    // from 1900 year
                    t.tm_year += 70;
                }
                else {
                    // std::get_time format:
                    //  [00-68] -> 2000-2068
                    //  [69-99] -> 1969-1999
                    if (t.tm_year < 69) {
                        t.tm_year += 100;
                    }
                }
            }
            if (!t.tm_mday) t.tm_mday = 1; // just in case

            if (utility::time::get_time(time_str, time_str_format, t)) {
                return time_str;
            }
            else {
                if (error_func) {
                    error_func(time_str_format, time_value, nullptr);
                }
            }
        }
#else
        try
        {
            namespace boost_ptime = boost::posix_time;

            std::tm t = utility::time::gmtime(time_value);

            if (!t.tm_mday) t.tm_mday = 1; // just in case

            std::ostringstream oss;
            oss.imbue(std::locale(std::locale::classic(), new boost_ptime::time_facet(time_str_format.c_str())));
            boost_ptime::ptime ptime_value = boost_ptime::ptime_from_tm(t);
            oss << ptime_value;

            if (!oss.fail()) {
                return oss.str();
            }
            else {
                if (error_func) {
                    error_func(time_str_format, time_value, nullptr);
                }
            }
        }
        catch (const boost::bad_lexical_cast & ex)
        {
            if (error_func) {
                error_func(time_str_format, time_value, &ex);
            }
        }
#endif
        catch (const std::out_of_range & ex)
        {
            if (error_func) {
                error_func(time_str_format, time_value, &ex);
            }
        }

#if defined(UTILITY_PLATFORM_FEATURE_STD_HAS_GET_TIME) && !defined(UTILITY_PLATFORM_FEATURE_USE_BOOST_POSIX_TIME_INSTEAD_STD_GET_TIME)
        return time_str;
#else
        return std::string{};
#endif
    }

}
}
