#pragma once

#include "common.hpp"

#if defined(UTILITY_PLATFORM_WINDOWS)
#include <windows.h>
#endif

#include <boost/preprocessor/cat.hpp>
#include <boost/preprocessor/stringize.hpp>
#include <boost/preprocessor/identity.hpp>
#include <boost/filesystem.hpp>
#include <boost/regex.hpp>
#include <boost/range/combine.hpp>

#include <boost/filesystem.hpp>
#include <boost/format.hpp>

#include <iostream>
#include <sstream>
#include <string>
#include <tuple>
#include <vector>
#include <limits>


#define TEST_DECLARE_ENV_VAR(var_name) \
    static std::string BOOST_PP_CAT(s_, var_name); \
    static bool BOOST_PP_CAT(BOOST_PP_CAT(s_is_, var_name), _exists); \
    static bool BOOST_PP_CAT(BOOST_PP_CAT(s_is_, var_name), _disabled)

#define TEST_DECLARE_ENV_VAR_BASE_CLASS(class_name, var_name, ref_name) \
    class class_name : public ::TestCaseStaticBase \
    { \
    public: \
        TEST_DECLARE_ENV_VAR(var_name); \
        static std::string BOOST_PP_CAT(BOOST_PP_CAT(get_, ref_name), _dir)(const char * scope_str, const char * func_str); \
    protected: \
        class_name(); \
    }

#define TEST_CASE_GET_ROOT(scope, func, ref_name) BOOST_PP_CAT(BOOST_PP_CAT(get_, ref_name), _root)(BOOST_PP_STRINGIZE(scope), BOOST_PP_STRINGIZE(func))
#define TEST_CASE_GET_DIR(scope, func, ref_name) BOOST_PP_CAT(BOOST_PP_CAT(get_, ref_name), _dir)(BOOST_PP_STRINGIZE(scope), BOOST_PP_STRINGIZE(func))

#define TEST_INTERRUPT() \
    ::test::interrupt_test(); \
    return

#if defined(UTILITY_PLATFORM_WINDOWS)

#define TEST_LOG_OUT(lvl, format, ...) \
    [&]() -> void {             \
        enum TEST_LOG_LEVEL {   \
            SKIP        = 1,    \
            DEBUG       = 2,    \
            CAUTION     = 3,    \
            WARNING     = 4,    \
            INFO        = 5,    \
            MIN_LVL     = SKIP, \
            MAX_LVL     = INFO, \
            FROM_GLOBAL_INIT = 0x10000, \
            LVL_FLAGS_MASK = 0xFFFF0000, \
            PREFIX_OFFSET_MASK = 0x0000FFFF \
        };  \
        HANDLE hConsole = ::GetStdHandle(STD_OUTPUT_HANDLE); \
        CONSOLE_SCREEN_BUFFER_INFO ConsoleInfo; \
        GetConsoleScreenBufferInfo(hConsole, &ConsoleInfo); \
        static const char * test_case_msg_prefix_str[] = { \
            "[     SKIP ] ", "[    DEBUG ] ", "[  CAUTION ] ", "[  WARNING ] ", "[     INFO ] " \
        };  \
        static const char * global_init_msg_prefix_str[] = { \
            "skip: ", "debug: ", "caution: ", "warning: ", "info: " \
        };  \
        static const WORD console_attrs[] = { \
            FOREGROUND_INTENSITY | FOREGROUND_RED | FOREGROUND_GREEN, \
            FOREGROUND_INTENSITY | FOREGROUND_RED | FOREGROUND_BLUE, \
            FOREGROUND_INTENSITY | FOREGROUND_RED, \
            FOREGROUND_INTENSITY | FOREGROUND_RED | FOREGROUND_GREEN, \
            FOREGROUND_INTENSITY | FOREGROUND_GREEN | FOREGROUND_BLUE \
        }; \
        size_t lvl_offset = (lvl) & PREFIX_OFFSET_MASK; \
        if (lvl_offset < MIN_LVL || lvl_offset > MAX_LVL) lvl_offset = MIN_LVL; \
        lvl_offset -= MIN_LVL; \
        SetConsoleTextAttribute(hConsole, console_attrs[lvl_offset]); \
        const bool is_global_init = !(lvl & FROM_GLOBAL_INIT); \
        if (is_global_init) { \
            fprintf(stderr, "%s" format "\n", test_case_msg_prefix_str[lvl_offset], ## __VA_ARGS__); \
        } \
        else { \
            fprintf(stdout, "%s" format "\n", global_init_msg_prefix_str[lvl_offset], ## __VA_ARGS__); \
        } \
        SetConsoleTextAttribute(hConsole, ConsoleInfo.wAttributes); \
    }()

#elif defined(UTILITY_PLATFORM_POSIX)

#define TEST_LOG_OUT(lvl, format, ...) \
    [&]() -> void {             \
        enum TEST_LOG_LEVEL {   \
            SKIP        = 1,    \
            DEBUG       = 2,    \
            CAUTION     = 3,    \
            WARNING     = 4,    \
            INFO        = 5,    \
            MIN_LVL     = SKIP, \
            MAX_LVL     = INFO, \
            FROM_GLOBAL_INIT = 0x10000, \
            LVL_FLAGS_MASK = 0xFFFF0000, \
            PREFIX_OFFSET_MASK = 0x0000FFFF \
        };  \
        static const char * test_case_msg_prefix_str[] = { \
            "[     SKIP ] ", "[    DEBUG ] ", "[  CAUTION ] ", "[  WARNING ] ", "[     INFO ] " \
        };  \
        static const char * global_init_msg_prefix_str[] = { \
            "skip: ", "debug: ", "caution: ", "warning: ", "info: " \
        };  \
        static const char* console_color_ansi_sequence[] = { \
            "\033[1;33m", \
            "\033[1;35m", \
            "\033[1;31m", \
            "\033[1;33m", \
            "\033[1;36m", \
        }; \
        size_t lvl_offset = (lvl) & PREFIX_OFFSET_MASK; \
        if (lvl_offset < MIN_LVL || lvl_offset > MAX_LVL) lvl_offset = MIN_LVL; \
        lvl_offset -= MIN_LVL; \
        const bool is_global_init = !(lvl & FROM_GLOBAL_INIT); \
        if (is_global_init) { \
            fprintf(stderr, "%s%s" format "\033[0m\n", console_color_ansi_sequence[lvl_offset], test_case_msg_prefix_str[lvl_offset], ## __VA_ARGS__); \
        } \
        else { \
            fprintf(stdout, "%s%s" format "\033[0m\n", console_color_ansi_sequence[lvl_offset], global_init_msg_prefix_str[lvl_offset], ## __VA_ARGS__); \
        } \
    }()

#else
#error platform is not implemented
#endif

#define STD_CHRONO_MSEC(dur) ::std::chrono::duration_cast<std::chrono::milliseconds>(dur).count()


namespace test
{
    void global_preinit(std::string & gtest_exclude_filter); // calls BEFORE
    void global_postinit(std::string & gtest_exclude_filter); 
    const char * get_data_in_subdir(const char * scope_str, const char * func_str);
    void interrupt_test();
}

class TestCaseStaticBase
{
public:
    static bool s_enable_all_tests;
    static bool s_enable_interactive_tests;
    static bool s_enable_only_interactive_tests; // overrides all enable_*_tests flags
    static bool s_enable_combinator_tests;

    TEST_DECLARE_ENV_VAR(TESTS_DATA_IN_ROOT);
    TEST_DECLARE_ENV_VAR(TESTS_DATA_OUT_ROOT);

    static std::string get_data_in_root(const char * scope_str, const char * func_str);
    static std::string get_data_out_root(const char * scope_str, const char * func_str);
protected:
    TestCaseStaticBase();
};

class TestCaseWithDataInput : public ::TestCaseStaticBase
{
protected:
    TestCaseWithDataInput()
    {
    }
};

TEST_DECLARE_ENV_VAR_BASE_CLASS(TestCaseWithDataReference, TESTS_REF_DIR, ref);
TEST_DECLARE_ENV_VAR_BASE_CLASS(TestCaseWithDataGenerator, TESTS_GEN_DIR, gen);
TEST_DECLARE_ENV_VAR_BASE_CLASS(TestCaseWithDataOutput, TESTS_OUT_DIR, out);
