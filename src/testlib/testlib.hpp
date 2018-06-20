#pragma once

#if !defined(TACKLE_TESTLIB) && !defined(UNIT_TESTS) && !defined(BENCH_TESTS)
#error This header must be used explicitly in a test declared environment. Use respective definitions to declare a test environment.
#endif

#include <tacklelib.hpp>

#if defined(UTILITY_PLATFORM_WINDOWS)
#include <windows.h>
#endif

#include <utility/utility.hpp>
#include <utility/platform.hpp>
#include <utility/assert.hpp>
#include <utility/static_assert.hpp>
#include <utility/type_traits.hpp>
#include <utility/math.hpp>
#include <utility/algorithm.hpp>

#include <iostream>
#include <sstream>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <tuple>
#include <vector>
#include <limits>


// Declares main list of tests for execution.
//
#define DECLARE_TEST_CASES std::vector<test::TestCase> g_test_cases =

// Declares gtest a function test case.
//
#define DECLARE_TEST_CASE_FUNC(scope_token, func_token, init_func, data_in_subdir, flags) \
    { "", UTILITY_PP_STRINGIZE(scope_token), UTILITY_PP_STRINGIZE(func_token), init_func, data_in_subdir, flags }

// Declares gtest a class test case.
//
#define DECLARE_TEST_CASE_CLASS(prefix_str, scope_token, func_token, init_func, data_in_subdir, flags) \
    { UTILITY_PP_STRINGIZE(prefix_str), UTILITY_PP_STRINGIZE(scope_token), UTILITY_PP_STRINGIZE(func_token), init_func, data_in_subdir, flags }

// Macro extractor for a root builtin variable value.
//  scope       - name of gtest case scope or `scope_token` parameter.
//  func        - name of gtest case test function or `func_token` parameter.
//   Available variants:
//   - <name>   - search in particular test case
//   - `*`      - search in all test cases
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//
#define TEST_CASE_GET_ROOT(scope, func, ref_name) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _root)(UTILITY_PP_STRINGIZE(scope), UTILITY_PP_STRINGIZE(func))

// Macro extractor for a directory builtin variable value.
//  scope       - name of gtest case scope or `scope_token` parameter.
//  func        - name of gtest case test function or `func_token` parameter.
//   Available variants:
//   - <name>   - search in particular test case
//   - `*`      - search in all test cases
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `ref`
//   - `gen`
//   - `out`
//
#define TEST_CASE_GET_DIR(scope, func, ref_name) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir)(UTILITY_PP_STRINGIZE(scope), UTILITY_PP_STRINGIZE(func))

#define TEST_INTERRUPT() \
    { ::test::interrupt_test(); return; } (void)0

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


// internal definitions, must be undefined at the of this header!
#define TEST_IMPL_DECLARE_ENV_VAR(var_name) \
    static std::string UTILITY_PP_CONCAT(s_, var_name); \
    static bool UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _exists); \
    static bool UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _disabled)

#define TEST_IMPL_DECLARE_ENV_VAR_BASE_CLASS(class_name, var_name, ref_name) \
    class class_name : public ::TestCaseStaticBase \
    { \
    public: \
        TEST_IMPL_DECLARE_ENV_VAR(var_name); \
        static std::string UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir)(const char * scope_str, const char * func_str); \
    protected: \
        class_name(); \
    }


namespace test
{
    enum TestCaseFlags
    {
        TCF_HAS_DATA_REF        = 0x00000001,   // test case has data reference
        TCF_HAS_DATA_GEN        = 0x00000002,   // test case has data generator
        TCF_HAS_DATA_OUT        = 0x00000004,   // test case has data output
        TCF_IS_INTERACTIVE      = 0x80000000,   // interactive test case, the user input is mandatory
        TCF_IS_PARAMETERIZED    = 0x40000000,   // parameterized test case, has combinations
        TCF_IS_COMBINATOR       = 0x20000000,   // parameterized test case with heavy combinations
    };

    struct TestCase
    {
        const char * prefix_str;
        const char * scope_str;
        const char * func_str;
        const char * data_in_subdir;
        bool(*init_func)();
        int flags;
    };

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

    TEST_IMPL_DECLARE_ENV_VAR(TESTS_DATA_IN_ROOT);
    TEST_IMPL_DECLARE_ENV_VAR(TESTS_DATA_OUT_ROOT);

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

TEST_IMPL_DECLARE_ENV_VAR_BASE_CLASS(TestCaseWithDataReference, TESTS_REF_DIR, ref);
TEST_IMPL_DECLARE_ENV_VAR_BASE_CLASS(TestCaseWithDataGenerator, TESTS_GEN_DIR, gen);
TEST_IMPL_DECLARE_ENV_VAR_BASE_CLASS(TestCaseWithDataOutput, TESTS_OUT_DIR, out);


#undef TEST_IMPL_DECLARE_ENV_VAR
#undef TEST_IMPL_DECLARE_ENV_VAR_BASE_CLASS
