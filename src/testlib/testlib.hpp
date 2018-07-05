#pragma once

#if !defined(TACKLE_TESTLIB) && !defined(UNIT_TESTS) && !defined(BENCH_TESTS)
#error This header must be used explicitly in a test declared environment. Use respective definitions to declare a test environment.
#endif

#include <tacklelib_private.hpp>

#if defined(UTILITY_PLATFORM_WINDOWS)
#include <windows.h>
#endif

#include <utility/assert_private.hpp>   // must uses private `assert.hpp` implementation!

#include <utility/utility.hpp>
#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/type_traits.hpp>
#include <utility/math.hpp>
#include <utility/algorithm.hpp>

#include <tackle/path_string.hpp>

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
#define DECLARE_TEST_CASE_FUNC(scope_token, func_token, init_func, data_in_subdir, data_out_subdir, flags) \
    { "", UTILITY_PP_STRINGIZE(scope_token), UTILITY_PP_STRINGIZE(func_token), init_func, data_in_subdir, data_out_subdir, flags }

// Declares gtest a class test case.
//
#define DECLARE_TEST_CASE_CLASS(prefix_str, scope_token, func_token, init_func, data_in_subdir, data_out_subdir, flags) \
    { UTILITY_PP_STRINGIZE(prefix_str), UTILITY_PP_STRINGIZE(scope_token), UTILITY_PP_STRINGIZE(func_token), init_func, data_in_subdir, data_out_subdir, flags }

// builtin test case info class
//
#define TEST_CASE_GET_INFO() \
    ::testing::UnitTest::GetInstance()->current_test_info()

// returns current test case instance token contained test name
//
#define TEST_CASE_INSTANCE_TOKEN() \
    [](auto * test_case_info_ptr_) -> tackle::path_string { \
        auto * name_ptr_ = test_case_info_ptr_->name(); \
        return name_ptr_; \
    }(TEST_CASE_GET_INFO())

// returns current test case class token contained class name prefix and name
//
#define TEST_CASE_CLASS_TOKEN() \
    [](auto * test_case_info_ptr_) -> tackle::path_string { \
        auto * name_ptr_ = test_case_info_ptr_->test_case_name(); \
        return name_ptr_; \
    }(TEST_CASE_GET_INFO())

// returns current test case class name
//
#define TEST_CASE_CLASS_NAME() \
    [](auto * test_case_info_ptr_) -> tackle::path_string { \
        auto * name_ptr_ = test_case_info_ptr_->test_case_name(); \
        /* split name by / */ \
        auto * name_suffix_ptr_ = strrchr(name_ptr_, '/'); \
        if (name_suffix_ptr_) return name_suffix_ptr_ + 1; \
        return name_ptr_; \
    }(TEST_CASE_GET_INFO())

// returns current test case class token prefix
//
#define TEST_CASE_CLASS_TOKEN_PREFIX() \
    [](auto * test_case_info_ptr_) -> tackle::path_string { \
        auto * name_ptr_ = test_case_info_ptr_->test_case_name(); \
        /* split name by / */ \
        auto * name_suffix_ptr_ = strrchr(name_ptr_, '/'); \
        if (name_suffix_ptr_) return tackle::path_string(name_ptr_, name_suffix_ptr_); \
        return name_ptr_; \
    }(TEST_CASE_GET_INFO())

// Macro builder of a test directory used a builtin ROOT-variable for a root path.
//  ref_name    - name of builtin ROOT-variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
// Returns:
//  <ROOT-variable> + <test-case-<ref_name>_subdir>
//
#define TEST_CASE_GET_ROOT(ref_name) \
    ::TestCaseStaticBase:: UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _root)(UTILITY_PP_FUNC, TEST_CASE_CLASS_NAME(), UTILITY_PP_STRINGIZE(*))

// Macro builder of a test directory used a builtin ROOT-variable for a root path.
//  func        - name of gtest case test function or `func_token` parameter.
//   Available variants:
//   - <name>   - search in particular test case
//   - `*`      - search in all test cases
//  ref_name    - name of builtin ROOT-variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
// Returns:
//  <ROOT-variable> + <test-case-<ref_name>_subdir>
//
#define TEST_CASE_GET_ROOT2(func, ref_name) \
    ::TestCaseStaticBase:: UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _root)(UTILITY_PP_FUNC, TEST_CASE_CLASS_NAME(), UTILITY_PP_STRINGIZE(func))

// Macro builder of a test directory used a builtin ROOT-variable for a root path.
//  scope       - name of gtest case scope or `scope_token` parameter.
//  func        - name of gtest case test function or `func_token` parameter.
//   Available variants:
//   - <name>   - search in particular test case
//   - `*`      - search in all test cases
//  ref_name    - name of builtin ROOT-variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
// Returns:
//  <ROOT-variable> + <test-case-<ref_name>_subdir>
//
#define TEST_CASE_GET_ROOT3(scope, func, ref_name) \
    ::TestCaseStaticBase:: UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _root)(UTILITY_PP_FUNC, UTILITY_PP_STRINGIZE(scope), UTILITY_PP_STRINGIZE(func))

// Macro builder of a test directory used a builtin DIR-variable for a root path.
//  ref_name    - name of builtin DIR-variable name to request:
//   Available variants:
//   - `ref`
//   - `gen`
//   - `out`
// Returns:
//  <DIR-variable>
//
#define TEST_CASE_GET_DIR(ref_name) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir)(UTILITY_PP_FUNC, nullptr, nullptr)

// Macro builder of a test directory used a builtin DIR-variable for a root path.
//  ref_name    - name of builtin DIR-variable name to request:
//   Available variants:
//   - `ref`
//   - `gen`
//   - `out`
//  prefix_dir  - prefix directory path.
// Returns:
//  <DIR-variable> + [prefix_dir + "/<ref_name>"]
//
#define TEST_CASE_GET_DIR2(ref_name, prefix_dir) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir)(UTILITY_PP_FUNC, prefix_dir, nullptr)

// Macro builder of a test directory used a builtin DIR-variable for a root path.
//  ref_name    - name of builtin DIR-variable name to request:
//   Available variants:
//   - `ref`
//   - `gen`
//   - `out`
//  prefix_dir  - prefix directory path.
//  suffix_dir  - suffix directory path.
// Returns:
//  <DIR-variable> + [prefix_dir + "/<ref_name>"] + suffix_dir
//
#define TEST_CASE_GET_DIR3(ref_name, prefix_dir, suffix_dir) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir)(UTILITY_PP_FUNC, prefix_dir, suffix_dir)

// Macro builder of a test directory used a builtin variable for a root path.
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//   - `ref`
//   - `gen`
//   - `out`
// Returns:
//  <variable>
//
#define TEST_CASE_DIR_PATH(ref_name) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir_path)(UTILITY_PP_FUNC)

// Macro builder of a test directory used a builtin variable for a root path.
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//   - `ref`
//   - `gen`
//   - `out`
//  path1       - suffix path.
// Returns:
//  <variable> + path1
//
#define TEST_CASE_DIR_PATH2(ref_name, path1) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir_path)(UTILITY_PP_FUNC, tackle::path_string(path1))

// Macro builder of a test directory used a builtin variable for a root path.
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//   - `ref`
//   - `gen`
//   - `out`
//  path1, path2 - suffix path.
// Returns:
//  <variable> + path1 + path2
//
#define TEST_CASE_DIR_PATH3(ref_name, path1, path2) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir_path)(UTILITY_PP_FUNC, tackle::path_string(path1) + tackle::path_string(path2))

// Macro builder of a test directory used a builtin variable for a root path.
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//   - `ref`
//   - `gen`
//   - `out`
//  path1, path2, path3 - suffix path.
// Returns:
//  <variable> + path1 + path2 + path3
//
#define TEST_CASE_DIR_PATH4(ref_name, path1, path2, path3) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir_path)(UTILITY_PP_FUNC, \
        tackle::path_string(path1) + tackle::path_string(path2) + tackle::path_string(path3))

// Macro builder of a test directory used a builtin variable for a root path.
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//   - `ref`
//   - `gen`
//   - `out`
//  path1, path2, path3, path4 - suffix path.
// Returns:
//  <variable> + path1 + path2 + path3 + path4
//
#define TEST_CASE_DIR_PATH5(ref_name, path1, path2, path3, path4) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir_path)(UTILITY_PP_FUNC, \
        tackle::path_string(path1) + tackle::path_string(path2) + tackle::path_string(path3) + tackle::path_string(path4))

// Macro builder of a test file path used a builtin variable for a root path.
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//   - `ref`
//   - `gen`
//   - `out`
// Returns:
//  <variable>
//
#define TEST_CASE_FILE_PATH(ref_name) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _file_path)(UTILITY_PP_FUNC)

// Macro builder of a test file path used a builtin variable for a root path.
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//   - `ref`
//   - `gen`
//   - `out`
//  path1       - suffix path.
// Returns:
//  <variable> + path1
//
#define TEST_CASE_FILE_PATH2(ref_name, path1) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir_path)(UTILITY_PP_FUNC, \
        tackle::path_string(path1))

// Macro builder of a test file path used a builtin variable for a root path.
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//   - `ref`
//   - `gen`
//   - `out`
//  path1, path2 - suffix path.
// Returns:
//  <variable> + path1 + path2
//
#define TEST_CASE_FILE_PATH3(ref_name, path1, path2) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir_path)(UTILITY_PP_FUNC, \
        tackle::path_string(path1) + tackle::path_string(path2))

// Macro builder of a test file path used a builtin variable for a root path.
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//   - `ref`
//   - `gen`
//   - `out`
//  path1, path2, path3 - suffix path.
// Returns:
//  <variable> + path1 + path2 + path3
//
#define TEST_CASE_FILE_PATH4(ref_name, path1, path2, path3) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir_path)(UTILITY_PP_FUNC, \
        tackle::path_string(path1) + tackle::path_string(path2) + tackle::path_string(path3))

// Macro builder of a test file path used a builtin variable for a root path.
//  ref_name    - name of builtin variable name to request:
//   Available variants:
//   - `data_in`
//   - `data_out`
//   - `ref`
//   - `gen`
//   - `out`
//  path1, path2, path3, path4 - suffix path.
// Returns:
//  <variable> + path1 + path2 + path3 + path4
//
#define TEST_CASE_FILE_PATH5(ref_name, path1, path2, path3, path4) \
    UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir_path)(UTILITY_PP_FUNC, \
        tackle::path_string(path1) + tackle::path_string(path2) + tackle::path_string(path3) + tackle::path_string(path4))

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
    static tackle::path_string UTILITY_PP_CONCAT(s_, var_name); \
    static bool UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _exists); \
    static bool UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _disabled)

#define TEST_IMPL_DECLARE_ENV_VAR_BASE_CLASS(class_name, var_name, ref_name) \
    class class_name : public ::TestCaseStaticBase \
    { \
    public: \
        TEST_IMPL_DECLARE_ENV_VAR(var_name); \
        static const tackle::path_string & UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _var)(const char * error_msg_prefix); \
        static tackle::path_string UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir)(const char * error_msg_prefix, const char * prefix_dir, const char * suffix_dir); \
        static tackle::path_string UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir)(const char * error_msg_prefix, const tackle::path_string & prefix_dir, const tackle::path_string & suffix_dir); \
        static tackle::path_string UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _dir_path)(const char * error_msg_prefix, const tackle::path_string & path_suffix); \
        static tackle::path_string UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(get_, ref_name), _file_path)(const char * error_msg_prefix, const tackle::path_string & path_suffix); \
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
        bool (*init_func)();
        const char * data_in_subdir;
        const char * data_out_subdir;
        int flags;
    };

    void global_preinit(std::string & gtest_exclude_filter); // calls BEFORE
    void global_postinit(std::string & gtest_exclude_filter); 
    tackle::path_string get_data_in_subdir(tackle::path_string & scope_str, const tackle::path_string & func_str);
    tackle::path_string get_data_out_subdir(tackle::path_string & scope_str, const tackle::path_string & func_str);
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

    static const tackle::path_string & get_data_in_var(const char * error_msg_prefix);
    static const tackle::path_string & get_data_out_var(const char * error_msg_prefix);

    static tackle::path_string get_data_in_root(const char * error_msg_prefix, const tackle::path_string & scope_str, const tackle::path_string & func_str);
    static tackle::path_string get_data_out_root(const char * error_msg_prefix, const tackle::path_string & scope_str, const tackle::path_string & func_str);

    static tackle::path_string get_data_in_dir_path(const char * error_msg_prefix, const tackle::path_string & path_suffix);
    static tackle::path_string get_data_out_dir_path(const char * error_msg_prefix, const tackle::path_string & path_suffix);

    static tackle::path_string get_data_in_file_path(const char * error_msg_prefix, const tackle::path_string & path_suffix);
    static tackle::path_string get_data_out_file_path(const char * error_msg_prefix, const tackle::path_string & path_suffix);
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
