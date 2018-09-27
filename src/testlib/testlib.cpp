#if defined(TACKLE_TESTLIB) || defined(UNIT_TESTS) || defined(BENCH_TESTS)

#include "testlib.hpp"

#if defined(UTILITY_PLATFORM_WINDOWS)
#include <windows.h>
#endif

#include <boost/format.hpp>

#include <cstdarg>


#define TEST_IMPL_DEFINE_ENV_VAR(class_name, var_name) \
    tackle::path_string class_name::UTILITY_PP_CONCAT(s_, var_name); \
    bool class_name::UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _exists) = false; \
    bool class_name::UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _disabled) = false

#if defined(UTILITY_PLATFORM_WINDOWS)

#define TEST_BASE_INIT_ENV_VAR(class_name, var_name) \
    if_break(1) { \
        if (!class_name::UTILITY_PP_CONCAT(s_, var_name).empty()) { \
            if(utility::is_path_exists(class_name::UTILITY_PP_CONCAT(s_, var_name))) { \
                class_name::UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _exists) = true; \
            } \
            break; \
        } \
        size_t var_size = 0; \
        char buf[4096] = {0}; \
        if (!getenv_s(&var_size, buf, utility::static_size(buf), UTILITY_PP_STRINGIZE(var_name))) { \
            class_name::UTILITY_PP_CONCAT(s_, var_name) = buf; \
            if (!class_name::UTILITY_PP_CONCAT(s_, var_name).empty() && utility::is_path_exists(class_name::UTILITY_PP_CONCAT(s_, var_name))) \
                class_name::UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _exists) = true; \
        } \
    } (void)0

#elif defined(UTILITY_PLATFORM_POSIX)

#define TEST_BASE_INIT_ENV_VAR(class_name, var_name) \
    if_break(1) { \
        if (!class_name::UTILITY_PP_CONCAT(s_, var_name).empty()) { \
            if(utility::is_path_exists(class_name::UTILITY_PP_CONCAT(s_, var_name))) { \
                class_name::UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _exists) = true; \
            } \
            break; \
        } \
        const char * var_str = getenv(UTILITY_PP_STRINGIZE(var_name)); \
        if (var_str) { \
            class_name::UTILITY_PP_CONCAT(s_, var_name) = var_str; \
            if (!class_name::UTILITY_PP_CONCAT(s_, var_name).empty() && utility::is_path_exists(class_name::UTILITY_PP_CONCAT(s_, var_name))) \
                class_name::UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _exists) = true; \
        } \
    } (void)0

#else
#error platform is not implemented
#endif

#define TEST_INIT_ENV_VAR(base_name, class_name, var_name, base_var_name, suffix_path) \
    if (class_name::UTILITY_PP_CONCAT(s_, var_name).empty()) { \
        class_name::UTILITY_PP_CONCAT(s_, var_name) = base_name::UTILITY_PP_CONCAT(s_, base_var_name) + suffix_path; \
        if (!utility::is_path_exists(class_name::UTILITY_PP_CONCAT(s_, var_name))) { \
            utility::create_directory(class_name::UTILITY_PP_CONCAT(s_, var_name)); \
            class_name::UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _exists) = true; \
        } \
        else { \
            class_name::UTILITY_PP_CONCAT(UTILITY_PP_CONCAT(s_is_, var_name), _exists) = utility::is_directory_path(class_name::UTILITY_PP_CONCAT(s_, var_name)); \
        } \
    } else (void)0


extern std::vector<test::TestCase> g_test_cases;

TEST_IMPL_DEFINE_ENV_VAR(TestCaseStaticBase, TESTS_DATA_IN_ROOT);
TEST_IMPL_DEFINE_ENV_VAR(TestCaseStaticBase, TESTS_DATA_OUT_ROOT);
TEST_IMPL_DEFINE_ENV_VAR(TestCaseWithDataReference, TESTS_REF_DIR);
TEST_IMPL_DEFINE_ENV_VAR(TestCaseWithDataGenerator, TESTS_GEN_DIR);
TEST_IMPL_DEFINE_ENV_VAR(TestCaseWithDataOutput, TESTS_OUT_DIR);

bool TestCaseStaticBase::s_enable_all_tests = false;
bool TestCaseStaticBase::s_enable_interactive_tests = false;
bool TestCaseStaticBase::s_enable_only_interactive_tests = false; // overrides all enable_*_tests flags
bool TestCaseStaticBase::s_enable_combinator_tests = false;


namespace test
{
    namespace
    {
        inline const char * _get_test_case_msg_prefix_str(size_t index)
        {
            static const char * test_case_msg_prefix_str[] = {
                "[     SKIP ] ", "[    DEBUG ] ", "[  CAUTION ] ", "[  WARNING ] ", "[     INFO ] "
            };

            return test_case_msg_prefix_str[index];
        }

        inline const char * _get_global_init_msg_prefix_str(size_t index)
        {
            static const char * global_init_msg_prefix_str[] = {
                "skip: ", "debug: ", "caution: ", "warning: ", "info: "
            };

            return global_init_msg_prefix_str[index];
        }

        inline WORD _get_log_out_console_attrs(size_t index)
        {
            static const WORD console_attrs[] = { \
                FOREGROUND_INTENSITY | FOREGROUND_RED | FOREGROUND_GREEN, \
                FOREGROUND_INTENSITY | FOREGROUND_RED | FOREGROUND_BLUE, \
                FOREGROUND_INTENSITY | FOREGROUND_RED, \
                FOREGROUND_INTENSITY | FOREGROUND_RED | FOREGROUND_GREEN, \
                FOREGROUND_INTENSITY | FOREGROUND_GREEN | FOREGROUND_BLUE \
            };

            return console_attrs[index];
        }

#ifdef UTILITY_PLATFORM_POSIX
        inline const char * _get_console_color_ansi_sequence(size_t index)
        {
            static const char * console_color_ansi_sequence[] = {
                "\033[1;33m",
                "\033[1;35m",
                "\033[1;31m",
                "\033[1;33m",
                "\033[1;36m",
            }; \

            return console_color_ansi_sequence[index];
        }
#endif
    }

    void global_preinit(std::string & gtest_exclude_filter)
    {
        TEST_BASE_INIT_ENV_VAR(TestCaseStaticBase, TESTS_DATA_IN_ROOT);
        TEST_BASE_INIT_ENV_VAR(TestCaseStaticBase, TESTS_DATA_OUT_ROOT);

        // defaults
        if (TestCaseStaticBase::s_TESTS_DATA_IN_ROOT.empty()) {
            TestCaseStaticBase::s_TESTS_DATA_IN_ROOT = "./tests_data";
            TestCaseStaticBase::s_is_TESTS_DATA_IN_ROOT_exists = true;
        }

        if (TestCaseStaticBase::s_TESTS_DATA_OUT_ROOT.empty()) {
            TestCaseStaticBase::s_TESTS_DATA_OUT_ROOT = "./tests_data_out";
            TestCaseStaticBase::s_is_TESTS_DATA_OUT_ROOT_exists = true;
        }

        TEST_BASE_INIT_ENV_VAR(TestCaseWithDataReference, TESTS_REF_DIR);
        TEST_BASE_INIT_ENV_VAR(TestCaseWithDataGenerator, TESTS_GEN_DIR);
        TEST_BASE_INIT_ENV_VAR(TestCaseWithDataOutput, TESTS_OUT_DIR);

        TEST_INIT_ENV_VAR(TestCaseStaticBase, TestCaseWithDataReference, TESTS_REF_DIR, TESTS_DATA_IN_ROOT, "");
        TEST_INIT_ENV_VAR(TestCaseStaticBase, TestCaseWithDataGenerator, TESTS_GEN_DIR, TESTS_DATA_OUT_ROOT, "");
        TEST_INIT_ENV_VAR(TestCaseStaticBase, TestCaseWithDataOutput, TESTS_OUT_DIR, TESTS_DATA_OUT_ROOT, "");

        // skip tests if conditions has met
        bool has_TESTS_REF_DIR_exclude_warning = false;
        bool has_TESTS_GEN_DIR_exclude_warning = false;
        bool has_TESTS_OUT_DIR_exclude_warning = false;
        bool has_interactive_exclude_warning = false;
        bool has_only_interactive_tests_warning = false;
        bool has_combinator_exclude_warning = false;

        std::string gtest_inner_exclude_filter;

        // hierarchy: `/test_case/<ref|gen|out>`
        for(const auto & v : g_test_cases) {
            bool do_exclude = false;

            if (v.flags & test::TCF_HAS_DATA_REF) {
                if (TestCaseWithDataReference::s_is_TESTS_REF_DIR_disabled || !TestCaseWithDataReference::s_is_TESTS_REF_DIR_exists) {
                    if (!has_TESTS_REF_DIR_exclude_warning) {
                        has_TESTS_REF_DIR_exclude_warning = true;
                        TEST_LOG_OUT(FROM_GLOBAL_INIT | WARNING,
                            "tests which required TESTS_REF_DIR (--data_ref_dir) or TESTS_DATA_IN_ROOT (--data_in_root) directory path will be %s.",
                            TestCaseWithDataReference::s_is_TESTS_REF_DIR_disabled ? "disabled" : "skipped");
                    }
                    do_exclude = true;
                }
                else if (v.data_in_subdir && !std::string(v.data_in_subdir).empty()) { // filter by subdir
                    // test on existance, disable test case if not found
                    const tackle::path_string data_in_subdir = TestCaseWithDataReference::s_TESTS_REF_DIR + v.data_in_subdir;
                    if (!utility::is_path_exists(data_in_subdir) || !utility::is_directory_path(data_in_subdir)) {
                        TEST_LOG_OUT(FROM_GLOBAL_INIT | WARNING,
                            "tests input data subdirectory is not found: \"%s\".\n", data_in_subdir.c_str());
                        do_exclude = true;
                    }
                }
            } else if ((TestCaseWithDataGenerator::s_is_TESTS_GEN_DIR_disabled || !TestCaseWithDataGenerator::s_is_TESTS_GEN_DIR_exists) && (v.flags & test::TCF_HAS_DATA_GEN)) {
                if (!has_TESTS_GEN_DIR_exclude_warning) {
                    has_TESTS_GEN_DIR_exclude_warning = true;
                    TEST_LOG_OUT(FROM_GLOBAL_INIT | WARNING,
                        "tests which required TESTS_GEN_DIR (--data_gen_dir) or TESTS_DATA_IN_ROOT (--data_in_root) directory path will be %s.",
                        TestCaseWithDataGenerator::s_is_TESTS_GEN_DIR_disabled ? "disabled" : "skipped");
                }
                do_exclude = true;
            } else if ((TestCaseWithDataOutput::s_is_TESTS_OUT_DIR_disabled || !TestCaseWithDataOutput::s_is_TESTS_OUT_DIR_exists) && (v.flags & test::TCF_HAS_DATA_OUT)) {
                if (!has_TESTS_OUT_DIR_exclude_warning) {
                    has_TESTS_OUT_DIR_exclude_warning = true;
                    TEST_LOG_OUT(FROM_GLOBAL_INIT | WARNING,
                        "tests which required TESTS_OUT_DIR (--data_out_dir) or TESTS_DATA_IN_ROOT (--data_in_root) directory path will be %s.",
                        TestCaseWithDataOutput::s_is_TESTS_OUT_DIR_disabled ? "disabled" : "skipped");
                }
                do_exclude = true;
            }

            if (!do_exclude) {
                if (TestCaseStaticBase::s_enable_only_interactive_tests && !(v.flags & test::TCF_IS_INTERACTIVE)) {
                    if (!has_only_interactive_tests_warning) {
                        has_only_interactive_tests_warning = true;
                        TEST_LOG_OUT(FROM_GLOBAL_INIT | WARNING,
                            "only interactive tests are enabled, all other tests will be skipped.");
                    }
                    do_exclude = true;
                }
                else if (!TestCaseStaticBase::s_enable_interactive_tests && (v.flags & test::TCF_IS_INTERACTIVE)) {
                    if (!has_interactive_exclude_warning) {
                        has_interactive_exclude_warning = true;
                        TEST_LOG_OUT(FROM_GLOBAL_INIT | WARNING,
                            "interactive tests are disabled by default (use `--enable_interactive_tests` to enable interactive tests).");
                    }
                    do_exclude = true;
                }
                else if (!TestCaseStaticBase::s_enable_combinator_tests && (v.flags & test::TCF_IS_COMBINATOR)) {
                    if (!has_combinator_exclude_warning) {
                        has_combinator_exclude_warning = true;
                        TEST_LOG_OUT(FROM_GLOBAL_INIT | WARNING,
                            "long and heavy combinator tests are disabled by default (use `--enable_combinator_tests` to enable combinator tests).");
                    }
                    do_exclude = true;
                }
            }

#ifndef UNIT_TESTS_ENABLE_INTERACTIVE_TESTS
            if (!do_exclude) {
                if (TestCaseStaticBase::s_enable_interactive_tests && (v.flags & test::TCF_IS_INTERACTIVE)) {
                    if (!has_interactive_exclude_warning) {
                        has_interactive_exclude_warning = true;
                        TEST_LOG_OUT(FROM_GLOBAL_INIT | WARNING,
                            "UNIT_TESTS_ENABLE_INTERACTIVE_TESTS macro is not defined, interactive tests will be skipped.");
                    }
                    do_exclude = true;
                }
            }
#endif

            if (!do_exclude) {
                // test static initialize
                if (v.init_func) {
                    if (!v.init_func()) {
                        do_exclude = true;
                    }
                }
            }

            if (do_exclude) {
                if (!gtest_inner_exclude_filter.empty())
                    gtest_inner_exclude_filter += ":";
                const std::string prefix_str = (v.prefix_str ? v.prefix_str : "");
                const std::string scope_token_str = (v.scope_str ? v.scope_str : "");
                const std::string func_str = (v.func_str ? v.func_str : "");
                if (v.flags & test::TCF_IS_PARAMETERIZED) {
                    gtest_inner_exclude_filter += prefix_str + (!prefix_str.empty() && !scope_token_str.empty() ? "/" : "") + scope_token_str +
                        (!scope_token_str.empty() && !func_str.empty() ? "/" : "") + (!func_str.empty() ? func_str : "*") + "/*";
                }
                else {
                    gtest_inner_exclude_filter += prefix_str + (!prefix_str.empty() && !scope_token_str.empty() ? "/" : "") + scope_token_str +
                        (!scope_token_str.empty() && !func_str.empty() ? "/" : "") + (!func_str.empty() ? func_str : "*");
                }
            }
        }

        if (!gtest_exclude_filter.empty())
            gtest_exclude_filter += ":";
        if (!gtest_inner_exclude_filter.empty() &&
            std::string::npos == gtest_exclude_filter.find("-", 0))
            gtest_exclude_filter += "-";
        gtest_exclude_filter += gtest_inner_exclude_filter;
    }

    void global_postinit(std::string & gtest_exclude_filter)
    {
        bool negated_filter = false;

        // reread the filter
        std::string gtest_external_filter = ::testing::GTEST_FLAG(filter);
        if (!gtest_external_filter.empty() &&
            std::string::npos != gtest_external_filter.find("-", 0)) {
            negated_filter = true;
        }

        if (!gtest_exclude_filter.empty() &&
            std::string::npos != gtest_exclude_filter.find("-", 0)) {
            negated_filter = true;
        }

        // generate disabled tests filter string for not declared tests
        int test_case_index = 0;
        const auto * test_case = ::testing::UnitTest::GetInstance()->GetTestCase(test_case_index);
        while (test_case) {
            bool is_declared = false;
            const auto built_test_case_name = test_case->name();
            for (const auto & v : g_test_cases) {
                const std::string prefix_str = (v.prefix_str ? v.prefix_str : "");
                const std::string scope_token_str = (v.scope_str ? v.scope_str : "");
                const auto declared_test_case_name = prefix_str + (!prefix_str.empty() && !scope_token_str.empty() ? "/" : "") + scope_token_str;
                if (built_test_case_name == declared_test_case_name) {
                    is_declared = true;
                    break;
                }
            }

            if (!is_declared) {
                // generate test case disable filter
                if (!gtest_exclude_filter.empty())
                    gtest_exclude_filter += ":";
                if (!negated_filter) {
                    gtest_exclude_filter += "-";
                    negated_filter = true;
                }
                gtest_exclude_filter += std::string(built_test_case_name) + ".*";
                TEST_LOG_OUT(FROM_GLOBAL_INIT | SKIP,
                    "Test case \"%s\" built but not declared for execution, will be skipped.", built_test_case_name);
            }

            test_case = ::testing::UnitTest::GetInstance()->GetTestCase(++test_case_index);
        }

        if (!gtest_exclude_filter.empty()) {
            // update the filter
            if (!::testing::GTEST_FLAG(filter).empty())
                ::testing::GTEST_FLAG(filter) += ":";
            ::testing::GTEST_FLAG(filter) += gtest_exclude_filter;
        }
    }

    tackle::path_string get_data_in_subdir(const tackle::path_string & scope_str, const tackle::path_string & func_str)
    {
        for (const auto & v : g_test_cases) {
            if (scope_str == v.scope_str && (func_str.empty() || func_str == "*" || func_str == v.func_str)) {
                if (v.data_in_subdir && !std::string(v.data_in_subdir).empty()) {
                    return v.data_in_subdir;
                }

                return tackle::path_string{};
            }
        }

        return tackle::path_string{};
    }

    tackle::path_string get_data_out_subdir(const tackle::path_string & scope_str, const tackle::path_string & func_str)
    {
        for (const auto & v : g_test_cases) {
            if (scope_str == v.scope_str && (func_str.empty() || func_str == "*" || func_str == v.func_str)) {
                if (v.data_out_subdir && !std::string(v.data_out_subdir).empty()) {
                    return v.data_out_subdir;
                }

                return tackle::path_string{};
            }
        }

        return tackle::path_string{};
    }

    void interrupt_test()
    {
        TEST_LOG_OUT(SKIP, "User interrupted.");
    }

    void log_out_va(int lvl, const char * fmt, va_list vl)
    {
        size_t lvl_offset = (lvl) & PREFIX_OFFSET_MASK;
        if (lvl_offset < MIN_LVL || lvl_offset > MAX_LVL) lvl_offset = MIN_LVL;
        lvl_offset -= MIN_LVL;

#if defined(UTILITY_PLATFORM_WINDOWS)
        HANDLE hConsole = ::GetStdHandle(STD_OUTPUT_HANDLE);
        CONSOLE_SCREEN_BUFFER_INFO ConsoleInfo;
        GetConsoleScreenBufferInfo(hConsole, &ConsoleInfo);
        SetConsoleTextAttribute(hConsole, _get_log_out_console_attrs(lvl_offset));

        const bool is_global_init = !(lvl & FROM_GLOBAL_INIT);
        if (is_global_init) {
            fprintf(stderr, "%s", _get_test_case_msg_prefix_str(lvl_offset));
        }
        else {
            fprintf(stdout, "%s", _get_global_init_msg_prefix_str(lvl_offset));
        }

        vfprintf(stderr, fmt, vl);

        fputs("\n", stderr);

        SetConsoleTextAttribute(hConsole, ConsoleInfo.wAttributes);

#elif defined(UTILITY_PLATFORM_POSIX)

        const bool is_global_init = !(lvl & FROM_GLOBAL_INIT); \
        if (is_global_init) {
            fprintf(stderr, "%s%s", _get_console_color_ansi_sequence(lvl_offset), _get_test_case_msg_prefix_str(lvl_offset));
        }
        else {
            fprintf(stdout, "%s%s", _get_console_color_ansi_sequence(lvl_offset), _get_global_init_msg_prefix_str(lvl_offset));
        }

        vfprintf(stderr, fmt, vl);

        fputs("\033[0m\n", stderr);

#else
#error platform is not implemented
#endif
    }

    void log_out(int lvl, const char * fmt, ...)
    {
        va_list vl;
        va_start(vl, fmt);

        log_out_va(lvl, fmt, vl);

        va_end(vl);
    }

    void log_out_predicate_va(const log_out_predicate_func_t & functor, int lvl, const char * fmt, va_list vl)
    {
        log_out_va(lvl, fmt, vl);

        functor(lvl, fmt, vl);
    }

    void log_out_predicate(const log_out_predicate_func_t & functor, int lvl, const char * fmt, ...)
    {
        va_list vl;
        va_start(vl, fmt);

        log_out_predicate_va(functor, lvl, fmt, vl);

        va_end(vl);
    }
}

//TestCaseStaticBase
TestCaseStaticBase::TestCaseStaticBase()
{
}

const tackle::path_string & TestCaseStaticBase::get_data_in_var(const char * error_msg_prefix)
{
    if (s_TESTS_DATA_IN_ROOT.empty() || !utility::is_directory_path(s_TESTS_DATA_IN_ROOT)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: s_TESTS_DATA_IN_ROOT directory does not exist: \"%s\"") %
            error_msg_prefix % s_TESTS_DATA_IN_ROOT).str());
    }

    return s_TESTS_DATA_IN_ROOT;
}

const tackle::path_string & TestCaseStaticBase::get_data_out_var(const char * error_msg_prefix)
{
    if (s_TESTS_DATA_OUT_ROOT.empty() || !utility::is_directory_path(s_TESTS_DATA_OUT_ROOT)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: s_TESTS_DATA_OUT_ROOT directory does not exist: \"%s\"") %
            error_msg_prefix % s_TESTS_DATA_OUT_ROOT).str());
    }

    return s_TESTS_DATA_OUT_ROOT;
}

tackle::path_string TestCaseStaticBase::get_data_in_root(const char * error_msg_prefix, const tackle::path_string & scope_str, const tackle::path_string & func_str)
{
    const tackle::path_string & data_in_subdir = test::get_data_in_subdir(scope_str, func_str);
    return get_data_in_var(error_msg_prefix) + data_in_subdir;
}

tackle::path_string TestCaseStaticBase::get_data_out_root(const char * error_msg_prefix, const tackle::path_string & scope_str, const tackle::path_string & func_str)
{
    const tackle::path_string & data_out_subdir = test::get_data_out_subdir(scope_str, func_str);
    return get_data_out_var(error_msg_prefix) + data_out_subdir;
}

tackle::path_string TestCaseStaticBase::get_data_in_dir_path(const char * error_msg_prefix, const tackle::path_string & path_suffix)
{
    const tackle::path_string & path = get_data_in_var(error_msg_prefix) + path_suffix;
    if (!::utility::is_directory_path(path)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: directory does not exist: \"%s\"") %
            error_msg_prefix % path).str());
    }
    return path;
}

tackle::path_string TestCaseStaticBase::get_data_out_dir_path(const char * error_msg_prefix, const tackle::path_string & path_suffix)
{
    const tackle::path_string & path = get_data_out_var(error_msg_prefix) + path_suffix;
    if (!::utility::is_directory_path(path)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: directory does not exist: \"%s\"") %
            error_msg_prefix % path).str());
    }
    return path;
}

tackle::path_string TestCaseStaticBase::get_data_in_file_path(const char * error_msg_prefix, const tackle::path_string & path_suffix)
{
    const tackle::path_string & path = get_data_in_var(error_msg_prefix) + path_suffix;
    if (!::utility::is_regular_file(path)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: file path does not exist: \"%s\"") %
            error_msg_prefix % path).str());
    }
    return path;
}

tackle::path_string TestCaseStaticBase::get_data_out_file_path(const char * error_msg_prefix, const tackle::path_string & path_suffix)
{
    const tackle::path_string & path = get_data_out_var(error_msg_prefix) + path_suffix;
    if (!::utility::is_regular_file(path)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: file path does not exist: \"%s\"") %
            error_msg_prefix % path).str());
    }
    return path;
}

//TestCaseWithDataReference
TestCaseWithDataReference::TestCaseWithDataReference()
{
}

const tackle::path_string & TestCaseWithDataReference::get_ref_var(const char * error_msg_prefix)
{
    if (s_TESTS_REF_DIR.empty() || !utility::is_directory_path(s_TESTS_REF_DIR)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: s_TESTS_REF_DIR directory does not exist: \"%s\"") %
            error_msg_prefix % s_TESTS_REF_DIR).str());
    }

    return s_TESTS_REF_DIR;
}

tackle::path_string TestCaseWithDataReference::get_ref_dir(const char * error_msg_prefix, const char * prefix_dir, const char * suffix_dir)
{
    return get_ref_dir(error_msg_prefix,
        tackle::path_string((prefix_dir && *prefix_dir != '\0') ? prefix_dir : ""),
        tackle::path_string((suffix_dir && *suffix_dir != '\0') ? suffix_dir : ""));
}

tackle::path_string TestCaseWithDataReference::get_ref_dir(const char * error_msg_prefix, const tackle::path_string & prefix_dir, const tackle::path_string & suffix_dir)
{
    const tackle::path_string & root_dir_var = get_ref_var(error_msg_prefix);

    const bool has_prefix_dir = !prefix_dir.empty();
    const tackle::path_string ref_dir = root_dir_var + prefix_dir + (has_prefix_dir ? "ref" : "") + suffix_dir;

    // reference directory must already exist at first request
    if (!utility::is_directory_path(ref_dir)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: test reference directory does not exist: \"%s\"") %
            error_msg_prefix % ref_dir).str());
    }

    return ref_dir;
}

tackle::path_string TestCaseWithDataReference::get_ref_dir_path(const char * error_msg_prefix, const tackle::path_string & path_suffix)
{
    const tackle::path_string & path = get_ref_var(error_msg_prefix) + path_suffix;
    if (!::utility::is_directory_path(path)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: directory does not exist: \"%s\"") %
            error_msg_prefix % path).str());
    }
    return path;
}

tackle::path_string TestCaseWithDataReference::get_ref_file_path(const char * error_msg_prefix, const tackle::path_string & path_suffix)
{
    const tackle::path_string & path = get_ref_var(error_msg_prefix) + path_suffix;
    if (!::utility::is_regular_file(path)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: file path does not exist: \"%s\"") %
            error_msg_prefix % path).str());
    }
    return path;
}

//TestCaseWithDataGenerator
TestCaseWithDataGenerator::TestCaseWithDataGenerator()
{
}

const tackle::path_string & TestCaseWithDataGenerator::get_gen_var(const char * error_msg_prefix)
{
    if (s_TESTS_GEN_DIR.empty() || !utility::is_directory_path(s_TESTS_GEN_DIR)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: s_TESTS_GEN_DIR directory does not exist: \"%s\"") %
            error_msg_prefix % s_TESTS_GEN_DIR).str());
    }

    return s_TESTS_GEN_DIR;
}

tackle::path_string TestCaseWithDataGenerator::get_gen_dir(const char * error_msg_prefix, const char * prefix_dir, const char * suffix_dir)
{
    return get_gen_dir(error_msg_prefix,
        tackle::path_string((prefix_dir && *prefix_dir != '\0') ? prefix_dir : ""),
        tackle::path_string((suffix_dir && *suffix_dir != '\0') ? suffix_dir : ""));
}

tackle::path_string TestCaseWithDataGenerator::get_gen_dir(const char * error_msg_prefix, const tackle::path_string & prefix_dir, const tackle::path_string & suffix_dir)
{
    const tackle::path_string & root_dir_var = get_gen_var(error_msg_prefix);

    const bool has_prefix_dir = !prefix_dir.empty();
    const tackle::path_string gen_dir = root_dir_var + prefix_dir + (has_prefix_dir ? "gen" : "") + suffix_dir;

    // generated direcory must be created if not done yet
    if (!utility::is_path_exists(gen_dir)) {
        utility::create_directories(gen_dir);
    }

    return gen_dir;
}

tackle::path_string TestCaseWithDataGenerator::get_gen_dir_path(const char * error_msg_prefix, const tackle::path_string & path_suffix)
{
    const tackle::path_string & path = get_gen_var(error_msg_prefix) + path_suffix;
    if (!::utility::is_directory_path(path)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: directory path does not exist: \"%s\"") %
            error_msg_prefix % path).str());
    }
    return path;
}

tackle::path_string TestCaseWithDataGenerator::get_gen_file_path(const char * error_msg_prefix, const tackle::path_string & path_suffix)
{
    const tackle::path_string & path = get_gen_var(error_msg_prefix) + path_suffix;
    if (!::utility::is_regular_file(path)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: file path does not exist: \"%s\"") %
            error_msg_prefix % path).str());
    }
    return path;
}

//TestCaseWithDataOutput
TestCaseWithDataOutput::TestCaseWithDataOutput()
{
}

const tackle::path_string & TestCaseWithDataOutput::get_out_var(const char * error_msg_prefix)
{
    if (s_TESTS_OUT_DIR.empty() || !utility::is_directory_path(s_TESTS_OUT_DIR)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: s_TESTS_OUT_DIR does not exist: \"%s\"") %
            error_msg_prefix % s_TESTS_OUT_DIR).str());
    }

    return s_TESTS_OUT_DIR;
}

tackle::path_string TestCaseWithDataOutput::get_out_dir(const char * error_msg_prefix, const char * prefix_dir, const char * suffix_dir)
{
    return get_out_dir(error_msg_prefix,
        tackle::path_string((prefix_dir && *prefix_dir != '\0') ? prefix_dir : ""),
        tackle::path_string((suffix_dir && *suffix_dir != '\0') ? suffix_dir : ""));
}

tackle::path_string TestCaseWithDataOutput::get_out_dir(const char * error_msg_prefix, const tackle::path_string & prefix_dir, const tackle::path_string & suffix_dir)
{
    const tackle::path_string & root_dir_var = get_out_var(error_msg_prefix);

    const bool has_prefix_dir = !prefix_dir.empty();
    const tackle::path_string out_dir = root_dir_var + prefix_dir + (has_prefix_dir ? "out" : "") + suffix_dir;

    // output direcory must be created if not done yet
    if (!utility::is_path_exists(out_dir)) {
        utility::create_directories(out_dir);
    }

    return out_dir;
}

tackle::path_string TestCaseWithDataOutput::get_out_dir_path(const char * error_msg_prefix, const tackle::path_string & path_suffix)
{
    const tackle::path_string & path = get_out_var(error_msg_prefix) + path_suffix;
    if (!::utility::is_directory_path(path)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: directory path does not exist: \"%s\"") %
            error_msg_prefix % path).str());
    }
    return path;
}

tackle::path_string TestCaseWithDataOutput::get_out_file_path(const char * error_msg_prefix, const tackle::path_string & path_suffix)
{
    const tackle::path_string & path = get_out_var(error_msg_prefix) + path_suffix;
    if (!::utility::is_regular_file(path)) {
        DEBUG_BREAK_IN_DEBUGGER(true);
        throw std::runtime_error((boost::format("%s: file path does not exist: \"%s\"") %
            error_msg_prefix % path).str());
    }
    return path;
}

#else

namespace {
    enum dummy { dummy_ = 1 }; // to suppress compiler warnings around an empty translation unit
}

#endif
