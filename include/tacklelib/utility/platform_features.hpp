#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_PLATFORM_FEATURES_HPP
#define UTILITY_PLATFORM_FEATURES_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>


// COMPILER FEATURES AND WORKAROUNDS

// common implementation based on: https://stackoverflow.com/questions/26089319/is-there-a-standard-definition-for-cplusplus-in-c14
// msvc implementation based on:
//  https://stackoverflow.com/questions/37503029/cplusplus-is-equal-to-199711-in-msvc-does-it-support-c11
//  and Microsoft `C++ 14 Core Language Features` for the `Visual Studio 2015` workaround
//
#ifdef UTILITY_COMPILER_CXX_MSC

// MSVC specific workarounds, tested on Visual Studio 2015 Update 3
//
// details: https://en.wikipedia.org/wiki/Microsoft_Visual_C%2B%2B
//
#if 0
+----------------------------------------+----------+------+----------+---------------+-------------+
| product name                           | Version  | year | _MSC_VER | _MSC_FULL_VER | RTL version |
+----------------------------------------+----------+------+----------+---------------+-------------+
| Microsoft C 1.0                        |          |      | 100      |               |             |
| Microsoft C 2.0                        |          |      | 200      |               |             |
| Microsoft C 3.0                        |          |      | 300      |               |             |
| Microsoft C 4.0                        |          |      | 400      |               |             |
| Microsoft C 5.0                        |          |      | 500      |               |             |
| Microsoft C 6.0                        |          |      | 600      |               |             |
| Microsoft C/C++ 7.0                    |          |      | 700      |               |             |
| Visual C++ 1.0                         | 1.0      |      | 800      |               | 1           |
| Visual C++ 2.0                         | 2.0      |      | 900      |               | 2           |
| Visual C++ 4.0 (Developer Studio)      | 4.0      |      | 1000     |               | 4           |
| Visual C++ 4.1 (Developer Studio)      | 4.1      |      | 1010     |               | 4.1         |
| Visual C++ 4.2 (Developer Studio)      | 4.2      |      | 1020     |               | 4.2         |
| Visual Studio 97 [5.0]                 | 5.0      | 97   | 1100     |               | 5           |
| Visual Studio 6.0 SP5                  | 6.0      |      | 1200     | 12008804      | 6           |
| Visual Studio 6.0 SP6                  | 6.0      |      | 1200     | 12008804      | 6           |
| Visual Studio .NET 2002 [7.0]          | 7.0      | 2002 | 1300     | 13009466      | 7           |
| Visual Studio .NET 2003 Beta [7.1]     | 7.1      | 2003 | 1310     | 13102292      | 7.1         |
| Visual Studio Toolkit 2003 [7.1]       | 7.1      | 2003 | 1310     | 13103052      | 7.1         |
| Visual Studio .NET 2003 [7.1]          | 7.1      | 2003 | 1310     | 13103077      | 7.1         |
| Visual Studio .NET 2003 SP1 [7.1]      | 7.1      | 2003 | 1310     | 13106030      | 7.1         |
| Visual Studio 2005 Beta 1 [8.0]        | 8.0      | 2005 | 1400     | 140040607     | 8           |
| Visual Studio 2005 Beta 2 [8.0]        | 8.0      | 2005 | 1400     | 140050215     | 8           |
| Visual Studio 2005 [8.0]               | 8.0      | 2005 | 1400     | 140050320     | 8           |
| Visual Studio 2005 SP1 [8.0]           | 8.0      | 2005 | 1400     | 140050727     | 8           |
| Visual Studio 2008 Beta 2 [9.0]        | 8.0      | 2008 | 1500     | 150020706     | 9           |
| Visual Studio 2008 [9.0]               | 9.0      | 2010 | 1500     | 150021022     | 9           |
| Visual Studio 2008 SP1 [9.0]           | 9.0      | 2010 | 1500     | 150030729     | 9           |
| Visual Studio 2010 Beta 1 [10.0]       | 10.0     | 2010 | 1600     | 160020506     | 10          |
| Visual Studio 2010 Beta 2 [10.0]       | 10.0     | 2010 | 1600     | 160021003     | 10          |
| Visual Studio 2010 [10.0]              | 10.0     | 2010 | 1600     | 160030319     | 10          |
| Visual Studio 2010 SP1 [10.0]          | 10.0     | 2010 | 1600     | 160040219     | 10          |
| Visual Studio 2012 [11.0]              | 11.0     | 2012 | 1700     | 170050727     | 11          |
| Visual Studio 2012 Update 1 [11.0]     | 11.0     | 2012 | 1700     | 170051106     | 11          |
| Visual Studio 2012 Update 2 [11.0]     | 11.0     | 2012 | 1700     | 170060315     | 11          |
| Visual Studio 2012 Update 3 [11.0]     | 11.0     | 2012 | 1700     | 170060610     | 11          |
| Visual Studio 2012 Update 4 [11.0]     | 11.0     | 2012 | 1700     | 170061030     | 11          |
| Visual Studio 2012 November CTP [11.0] | 11.0     | 2012 | 1700     | 170051025     | 11          |
| Visual Studio 2013 Preview [12.0]      | 12.0     | 2013 | 1800     | 180020617     | 12          |
| Visual Studio 2013 RC [12.0]           | 12.0     | 2013 | 1800     | 180020827     | 12          |
| Visual Studio 2013 [12.0]              | 12.0     | 2013 | 1800     | 180021005     | 12          |
| Visual Studio 2013 Update 1 [12.0]     | 12.0     | 2013 | 1800     | 180021005     | 12          |
| Visual Studio 2013 Update2 RC [12.0]   | 12.0     | 2013 | 1800     | 180030324     | 12          |
| Visual Studio 2013 Update 2 [12.0]     | 12.0     | 2013 | 1800     | 180030501     | 12          |
| Visual Studio 2013 Update 3 [12.0]     | 12.0     | 2013 | 1800     | 180030723     | 12          |
| Visual Studio 2013 Update 4 [12.0]     | 12.0     | 2013 | 1800     | 180031101     | 12          |
| Visual Studio 2013 Update 5 [12.0]     | 12.0     | 2013 | 1800     | 180040629     | 12          |
| Visual Studio 2013 November CTP [12.0] | 12.0     | 2013 | 1800     | 180021114     | 12          |
| Visual Studio 2015 [14.0]              | 14.0     | 2015 | 1900     | 190023026     | 14          |
| Visual Studio 2015 Update 1 [14.0]     | 14.0     | 2015 | 1900     | 190023506     | 14          |
| Visual Studio 2015 Update 2 [14.0]     | 14.0     | 2015 | 1900     | 190023918     | 14          |
| Visual Studio 2015 Update 3 [14.0]     | 14.0     | 2015 | 1900     | 190024210     | 14          |
| Visual Studio 2017 version 15.0        | 15.0     | 2017 | 1910     | 191025017     | 14.1        |
| Visual Studio 2017 version 15.1        | 15.1     | 2017 | 1910     | 191025017     | 14.1        |
| Visual Studio 2017 version 15.2        | 15.2     | 2017 | 1910     | 191025017     | 14.1        |
| Visual Studio 2017 version 15.3.3      | 15.3.3   | 2017 | 1911     | 191125507     | 14.11       |
| Visual Studio 2017 version 15.4.4      | 15.4.4   | 2017 | 1911     | 191125542     | 14.11       |
| Visual Studio 2017 version 15.4.5      | 15.4.5   | 2017 | 1911     | 191125547     | 14.11       |
| Visual Studio 2017 version 15.5.2      | 15.5.2   | 2017 | 1912     | 191225831     | 14.12       |
| Visual Studio 2017 version 15.5.3      | 15.5.3   | 2017 | 1912     | 191225834     | 14.12       |
| Visual Studio 2017 version 15.5.4      | 15.5.4   | 2017 | 1912     | 191225834     | 14.12       |
| Visual Studio 2017 version 15.5.6      | 15.5.6   | 2017 | 1912     | 191225835     | 14.12       |
| Visual Studio 2017 version 15.5.7      | 15.5.7   | 2017 | 1912     | 191225835     | 14.12       |
| Visual Studio 2017 version 15.6.0      | 15.6.0   | 2017 | 1913     | 191326128     | 14.13       |
| Visual Studio 2017 version 15.6.1      | 15.6.1   | 2017 | 1913     | 191326128     | 14.13       |
| Visual Studio 2017 version 15.6.2      | 15.6.2   | 2017 | 1913     | 191326128     | 14.13       |
| Visual Studio 2017 version 15.6.3      | 15.6.3   | 2017 | 1913     | 191326129     | 14.13       |
| Visual Studio 2017 version 15.6.4      | 15.6.4   | 2017 | 1913     | 191326129     | 14.13       |
| Visual Studio 2017 version 15.6.6      | 15.6.6   | 2017 | 1913     | 191326131     | 14.13       |
| Visual Studio 2017 version 15.6.7      | 15.6.7   | 2017 | 1913     | 191326132     | 14.13       |
| Visual Studio 2017 version 15.7.1      | 15.7.1   | 2017 | 1914     | 191426428     | 14.14       |
| Visual Studio 2017 version 15.7.2      | 15.7.2   | 2017 | 1914     | 191426429     | 14.14       |
| Visual Studio 2017 version 15.7.3      | 15.7.3   | 2017 | 1914     | 191426430     | 14.14       |
| Visual Studio 2017 version 15.7.5      | 15.7.5   | 2017 | 1914     | 191426433     | 14.14       |
| Visual Studio 2017 version 15.9.1      | 15.9.1   | 2017 | 1916     | 191627023     | 14.16       |
| Visual Studio 2017 version 15.9.4      | 15.9.4   | 2017 | 1916     | 191627025     | 14.16       |
| Visual Studio 2017 version 15.9.5      | 15.9.5   | 2017 | 1916     | 191627026     | 14.16       |
| Visual Studio 2017 version 15.9.7      | 15.9.7   | 2017 | 1916     | 191627027     | 14.16       |
| Visual Studio 2017 version 15.9.11     | 15.9.11  | 2017 | 1916     | 191627030     | 14.16       |
| Visual Studio 2019 version 16.0.0      | 16.0.0   | 2019 | 1920     | 192027508     | 14.20       |
| Visual Studio 2019 version 16.1.2      | 16.1.2   | 2019 | 1921     | 192127702     | 14.21       |
| Visual Studio 2019 version 16.2.3      | 16.2.3   | 2019 | 1922     | 192227905     | 14.21       |
| Visual Studio 2019 version 16.3.2      | 16.3.2   | 2019 | 1923     | 192328105     | 14.21       |
| Visual Studio 2019 version 16.4.0      | 16.4.0   | 2019 | 1924     | 192428314     | 14.24       |
| Visual Studio 2019 version 16.5.1      | 16.5.1   | 2019 | 1925     | 192528611     | 14.25       |
| Visual Studio 2019 version 16.6.2      | 16.6.2   | 2019 | 1926     | 192628806     | 14.26       |
| Visual Studio 2019 version 16.7        | 16.7     | 2019 | 1927     | 192729112     | 14.27       |
| Visual Studio 2019 version 16.8.1      | 16.8.1   | 2019 | 1928     | 192829333     | 14.28       |
| Visual Studio 2019 version 16.8.2      | 16.8.2   | 2019 | 1928     | 192829334     | 14.28       |
| Visual Studio 2019 version 16.9.0      | 16.9.0   | 2019 | 1928     | 192829910     | 14.28       |
| Visual Studio 2019 version 16.9.2      | 16.9.2   | 2019 | 1928     | 192829913     | 14.28       |
| Visual Studio 2019 version 16.9.17     | 16.9.17  | 2019 | 1928     | 192829921     | 14.28       |
| Visual Studio 2019 version 16.9.18     | 16.9.18  | 2019 | 1928     | 192829921     | 14.28       |
| Visual Studio 2019 version 16.9.19     | 16.9.19  | 2019 | 1928     | 192829923     | 14.28       |
| Visual Studio 2019 version 16.11.2     | 16.11.2  | 2019 | 1929     | 192930133     | 14.29       |
| Visual Studio 2019 version 16.11.8     | 16.11.8  | 2019 | 1929     | 192930138     | 14.29       |
| Visual Studio 2019 version 16.11.9     | 16.11.9  | 2019 | 1929     | 192930139     | 14.29       |
| Visual Studio 2019 version 16.11.10    | 16.11.10 | 2019 | 1929     | 192930140     | 14.29       |
| Visual Studio 2019 version 16.11.11    | 16.11.11 | 2019 | 1929     | 192930141     | 14.29       |
| Visual Studio 2019 version 16.11.12    | 16.11.12 | 2019 | 1929     | 192930142     | 14.29       |
| Visual Studio 2019 version 16.11.16    | 16.11.16 | 2019 | 1929     | 192930145     | 14.29       |
| Visual Studio 2019 version 16.11.24    | 16.11.24 | 2019 | 1929     | 192930148     | 14.29       |
| Visual Studio 2019 version 16.11.27    | 16.11.27 | 2019 | 1929     | 192930151     | 14.29       |
| Visual Studio 2019 version 16.11.35    | 16.11.35 | 2019 | 1929     | 192930154     | 14.29       |
| Visual Studio 2022 version 17.0.1      | 17.0.1   | 2022 | 1930     | 193030705     | 14.30       |
| Visual Studio 2022 version 17.0.2      | 17.0.2   | 2022 | 1930     | 193030706     | 14.31       |
| Visual Studio 2022 version 17.1.3      | 17.1.3   | 2022 | 1931     | 193131105     | 14.31       |
| Visual Studio 2022 version 17.2.2      | 17.2.2   | 2022 | 1932     | 193231329     | 14.32       |
| Visual Studio 2022 version 17.3.4      | 17.3.4   | 2022 | 1933     | 193331630     | 14.33       |
| Visual Studio 2022 version 17.4.0      | 17.4.0   | 2022 | 1934     | 193431933     | 14.34       |
| Visual Studio 2022 version 17.5.0      | 17.5.0   | 2022 | 1935     | 193532215     | 14.35       |
| Visual Studio 2022 version 17.6.0      | 17.6.0   | 2022 | 1936     | 193632532     | 14.36       |
| Visual Studio 2022 version 17.6.2      | 17.6.2   | 2022 | 1936     | 193632532     | 14.36.32532 |
| Visual Studio 2022 version 17.6.4      | 17.6.4   | 2022 | 1936     | 193632535     | 14.36.32532 |
| Visual Studio 2022 version 17.7.0      | 17.7.0   | 2022 | 1937     | 193732822     | 14.36.32543 |
| Visual Studio 2022 version 17.8.0      | 17.8.0   | 2022 | 1938     | 193833130     | 14.38.33135 |
| Visual Studio 2022 version 17.9.1      | 17.9.1   | 2022 | 1939     | 193933520     | 14.39.33520 |
| Visual Studio 2022 version 17.9.6      | 17.9.6   | 2022 | 1939     | 193933523     | 14.39.33523 |
+----------------------------------------+----------+------+----------+---------------+-------------+
#endif

#   if UTILITY_COMPILER_CXX_VERSION >= 1915
#       define TEMPLATE_SCOPE template
#   else
#       define TEMPLATE_SCOPE
#   endif

#   if UTILITY_COMPILER_CXX_VERSION >= 1600
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CPP11
#   endif

#   if UTILITY_COMPILER_CXX_VERSION >= 1900
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CPP14
#   endif

#   if UTILITY_COMPILER_CXX_VERSION >= 1900
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CONSTEXPR
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CONSTEXPR_FUNC
#   endif

#   if UTILITY_COMPILER_CXX_VERSION >= 1310
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_LLONG
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_ULLONG
#   endif

#   if UTILITY_COMPILER_CXX_VERSION >= 1900
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_INTEGER_SEQUENCE
#   endif

#   if UTILITY_COMPILER_CXX_VERSION >= 1900
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_MAKE_UNIQUE
#   endif

#else

#   define TEMPLATE_SCOPE template

#   if __cplusplus >= 201103L
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CPP11
#       ifdef UTILITY_COMPILER_CXX_GCC // specific case for GCC 4.7.x and lower
#           if UTILITY_COMPILER_CXX_VERSION >= 5 || \
               UTILITY_COMPILER_CXX_VERSION == 4 && UTILITY_COMPILER_CXX_VERSION_MINOR >= 8
#               define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CONSTEXPR
#               define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CONSTEXPR_FUNC
#           endif
#       else
#           define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CONSTEXPR
#           define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CONSTEXPR_FUNC
#       endif
#   endif

#   if __cplusplus >= 201402L
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CPP14
#   endif

#   ifdef LLONG_MAX
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_LLONG
#   endif
#   ifdef ULLONG_MAX
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_ULLONG
#   endif

#   ifdef UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CPP14
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_INTEGER_SEQUENCE
#       define UTILITY_PLATFORM_FEATURE_CXX_STANDARD_MAKE_UNIQUE
#   endif

#endif

#ifdef UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CONSTEXPR_FUNC
#   define CONSTEXPR_FUNC constexpr
#else
#   define CONSTEXPR_FUNC
#endif

#ifdef UTILITY_PLATFORM_FEATURE_CXX_STANDARD_CONSTEXPR
#   define CONSTEXPR constexpr
#else
#   define CONSTEXPR
#endif

#ifdef UTILITY_COMPILER_CXX_CLANG
#   define UTILITY_COMPILER_CXX_CLANG_CONSTEXPR_FUNC       CONSTEXPR_FUNC
#   define UTILITY_COMPILER_CXX_NOT_CLANG_CONSTEXPR_FUNC
#else
#   define UTILITY_COMPILER_CXX_CLANG_CONSTEXPR_FUNC
#   define UTILITY_COMPILER_CXX_NOT_CLANG_CONSTEXPR_FUNC   CONSTEXPR_FUNC
#endif

// long <=> int64_t <=> long long
//    `long long int vs. long int vs. int64_t in C++`:
//    https://stackoverflow.com/questions/4160945/long-long-int-vs-long-int-vs-int64-t-in-c
//

#if !defined(UTILITY_COMPILER_CXX_GCC) || __WORDSIZE < 64
#   define UTILITY_PLATFORM_FEATURE_INT64_IS_LLONG
#else
#   define UTILITY_PLATFORM_FEATURE_INT64_IS_LONG
#endif

//  For the `std::get_time` function enable at least GCC 5.x is required:
//    `TODO extended iomanip manipulators std::get_time and std::put_time (C++11, section 27.7.5)`:
//    https://gcc.gnu.org/bugzilla/show_bug.cgi?id=54354#c9
//

#if defined(UTILITY_COMPILER_CXX_MSC) && UTILITY_COMPILER_CXX_VERSION >= 1600 || \
    defined(UTILITY_COMPILER_CXX_GCC) && UTILITY_COMPILER_CXX_VERSION >= 5 || \
    defined(UTILITY_COMPILER_CXX_CLANG) && (UTILITY_COMPILER_CXX_VERSION > 3 || UTILITY_COMPILER_CXX_VERSION == 3 && UTILITY_COMPILER_CXX_VERSION_MINOR >= 3)
#   define UTILITY_PLATFORM_FEATURE_STD_HAS_GET_TIME
#endif

// For the `std::is_trivially_copyable` function enable at least GCC 5.x is required:
//    `‘is_trivially_copyable’ is not a member of ‘std’`:
//    https://stackoverflow.com/questions/25123458/is-trivially-copyable-is-not-a-member-of-std
//

#if !defined(UTILITY_COMPILER_CXX_GCC) || UTILITY_COMPILER_CXX_VERSION >= 5
#   define UTILITY_PLATFORM_FEATURE_STD_HAS_IS_TRIVIALLY_COPYABLE
#endif

// For the `codecvt` header at least GCC 5.x is required:
//    `Is codecvt not a std header?`:
//    https://stackoverflow.com/questions/15615136/is-codecvt-not-a-std-header
//

#if !defined(UTILITY_COMPILER_CXX_GCC) || UTILITY_COMPILER_CXX_VERSION >= 5
#   define UTILITY_PLATFORM_FEATURE_STD_HAS_CODECVT_HEADER
#endif

#if !defined(UTILITY_COMPILER_CXX_GCC) || UTILITY_COMPILER_CXX_VERSION >= 5
#   define UTILITY_PLATFORM_FEATURE_COMPILER_ENABLED_TAIL_RECURSION_ELIMINATION
#endif

// switch to the boost implementation to avoid exception on negative time_t values in gmtime* functions
#if defined(UTILITY_COMPILER_CXX_MSC) && UTILITY_COMPILER_CXX_VERSION < 1910
#define UTILITY_PLATFORM_FEATURE_USE_BOOST_POSIX_TIME_INSTEAD_STD_GET_TIME
#endif

#endif
