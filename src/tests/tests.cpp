#include "test_common.hpp"

// include all tests headers from here
//...
//

#include <boost/preprocessor/stringize.hpp>
#include <boost/preprocessor/cat.hpp>
#include <boost/filesystem.hpp>

#include <thread>
#include <chrono>

#include <stdio.h>
#include <stdlib.h>


#define TEST_DEFINE_ENV_VAR(class_name, var_name) \
    std::string class_name::BOOST_PP_CAT(s_, var_name); \
    bool class_name::BOOST_PP_CAT(BOOST_PP_CAT(s_is_, var_name), _exists) = false; \
    bool class_name::BOOST_PP_CAT(BOOST_PP_CAT(s_is_, var_name), _disabled) = false

#if defined(UTILITY_PLATFORM_WINDOWS)

#define TEST_BASE_INIT_ENV_VAR(class_name, var_name) \
    if_break(1) { \
        if (!class_name::BOOST_PP_CAT(s_, var_name).empty()) { \
            if(boost::fs::is_directory(class_name::BOOST_PP_CAT(s_, var_name)) && boost::fs::exists(class_name::BOOST_PP_CAT(s_, var_name))) { \
                class_name::BOOST_PP_CAT(BOOST_PP_CAT(s_is_, var_name), _exists) = true; \
            } \
            break; \
        } \
        size_t var_size = 0; \
        char buf[4096] = {0}; \
        if (!getenv_s(&var_size, buf, utility::static_size(buf), BOOST_PP_STRINGIZE(var_name))) { \
            class_name::BOOST_PP_CAT(s_, var_name) = buf; \
            if (!class_name::BOOST_PP_CAT(s_, var_name).empty() && boost::fs::is_directory(class_name::BOOST_PP_CAT(s_, var_name)) && boost::fs::exists(class_name::BOOST_PP_CAT(s_, var_name))) \
                class_name::BOOST_PP_CAT(BOOST_PP_CAT(s_is_, var_name), _exists) = true; \
        } \
    } (void)0

#elif defined(UTILITY_PLATFORM_POSIX)

#define TEST_BASE_INIT_ENV_VAR(class_name, var_name) \
    if_break(1) { \
        if (!class_name::BOOST_PP_CAT(s_, var_name).empty()) { \
            if(boost::fs::is_directory(class_name::BOOST_PP_CAT(s_, var_name)) && boost::fs::exists(class_name::BOOST_PP_CAT(s_, var_name))) { \
                class_name::BOOST_PP_CAT(BOOST_PP_CAT(s_is_, var_name), _exists) = true; \
            } \
            break; \
        } \
        const char * var_str = getenv(BOOST_PP_STRINGIZE(var_name)); \
        if (var_str) { \
            class_name::BOOST_PP_CAT(s_, var_name) = var_str; \
            if (!class_name::BOOST_PP_CAT(s_, var_name).empty() && boost::fs::is_directory(class_name::BOOST_PP_CAT(s_, var_name)) && boost::fs::exists(class_name::BOOST_PP_CAT(s_, var_name))) \
                class_name::BOOST_PP_CAT(BOOST_PP_CAT(s_is_, var_name), _exists) = true; \
        } \
    } (void)0

#else
#error platform is not implemented
#endif

#define TEST_INIT_ENV_VAR(base_name, class_name, var_name, base_var_name, suffix_path) \
    if (class_name::BOOST_PP_CAT(s_, var_name).empty()) { \
        class_name::BOOST_PP_CAT(s_, var_name) = base_name::BOOST_PP_CAT(s_, base_var_name) + suffix_path; \
        if (!boost::fs::exists(class_name::BOOST_PP_CAT(s_, var_name))) { \
            boost::fs::create_directory(class_name::BOOST_PP_CAT(s_, var_name)); \
            class_name::BOOST_PP_CAT(BOOST_PP_CAT(s_is_, var_name), _exists) = true; \
        } \
        else { \
            class_name::BOOST_PP_CAT(BOOST_PP_CAT(s_is_, var_name), _exists) = boost::fs::is_directory(class_name::BOOST_PP_CAT(s_, var_name)); \
        } \
    } else (void)0

#define DECLARE_TEST_CASE_FUNC(scope_token, func_token, init_func, data_in_subdir, flags) \
    { "", BOOST_PP_STRINGIZE(scope_token), BOOST_PP_STRINGIZE(func_token), init_func, data_in_subdir, flags }

#define DECLARE_TEST_CASE_CLASS(prefix_str, scope_token, func_token, init_func, data_in_subdir, flags) \
    { BOOST_PP_STRINGIZE(prefix_str), BOOST_PP_STRINGIZE(scope_token), BOOST_PP_STRINGIZE(func_token), init_func, data_in_subdir, flags }

TEST_DEFINE_ENV_VAR(TestCaseStaticBase, TESTS_DATA_IN_ROOT);
TEST_DEFINE_ENV_VAR(TestCaseStaticBase, TESTS_DATA_OUT_ROOT);
TEST_DEFINE_ENV_VAR(TestCaseWithDataReference, TESTS_REF_DIR);
TEST_DEFINE_ENV_VAR(TestCaseWithDataGenerator, TESTS_GEN_DIR);
TEST_DEFINE_ENV_VAR(TestCaseWithDataOutput, TESTS_OUT_DIR);


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

    struct TestCaseGtestFlags
    {
        const char * prefix_str;
        const char * scope_str;
        const char * func_str;
        const char * data_in_subdir;
        bool(*init_func)();
        int flags;
    };
}

// must define appropriate tests here to skip them in case of absence respective conditions
const test::TestCaseGtestFlags g_test_cases_gtest_flags[] = {
#ifdef UNIT_TESTS
    DECLARE_TEST_CASE_FUNC(FunctionsTest, *, "", nullptr, 0),

// examples here...
//
//    DECLARE_TEST_CASE_CLASS(TestParseFromRefFile, test_00_from_file_name_pttn, parse_from_ref_file,
//        "test_00_from_file_name_pttn/data", test_00_from_file_name_pttn::search_files,
//        test::TCF_IS_PARAMETERIZED | test::TCF_HAS_DATA_REF),
//
//    DECLARE_TEST_CASE_CLASS(TestParseFromRefFile, test_01_from_file_name_pttn2, parse_from_ref_file,
//        "test_01_from_file_name_pttn2/data", test_01_from_file_name_pttn2::search_files,
//        test::TCF_IS_PARAMETERIZED | test::TCF_HAS_DATA_REF | test::TCF_HAS_DATA_OUT),
//
//    DECLARE_TEST_CASE_CLASS(TestParseFromRefFile, test_02_from_file_name_mini, parse_from_ref_file, "_common", nullptr,
//        test::TCF_IS_PARAMETERIZED | test::TCF_HAS_DATA_REF | test::TCF_HAS_DATA_OUT),
//
//    DECLARE_TEST_CASE_CLASS(TestParseFromRefFile, test_03_from_file_name_compacted, parse_from_ref_file, "_common", nullptr,
//        test::TCF_IS_PARAMETERIZED | test::TCF_HAS_DATA_REF | test::TCF_HAS_DATA_OUT),
//
//    DECLARE_TEST_CASE_CLASS(TestParseFromRefFile, test_04_from_file_name_full, parse_from_ref_file, "_common", nullptr,
//        test::TCF_IS_PARAMETERIZED | test::TCF_HAS_DATA_REF | test::TCF_HAS_DATA_OUT),
#endif

#ifdef BENCH_TESTS
// examples here...
//
//    DECLARE_TEST_CASE_CLASS(TestParseFromRefFile, test_duration, parse_from_ref_file, "_common", nullptr,
//        test::TCF_IS_PARAMETERIZED | test::TCF_HAS_DATA_REF),
#endif
};


namespace boost
{
    namespace fs = filesystem;
}

namespace test
{
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
        for(const auto & v : g_test_cases_gtest_flags) {
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
                    const std::string data_in_subdir = TestCaseWithDataReference::s_TESTS_REF_DIR + "/" + v.data_in_subdir;
                    if (!boost::fs::exists(data_in_subdir) || !boost::fs::is_directory(data_in_subdir)) {
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
            for (const auto & v : g_test_cases_gtest_flags) {
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

    const char * get_data_in_subdir(const char * scope_str, const char * func_str)
    {
        for (const auto & v : g_test_cases_gtest_flags) {
            if (std::string(scope_str) == v.scope_str && (!func_str || std::string(func_str).empty() ||
                std::string(func_str) == "*" || std::string(func_str) == v.func_str)) {
                if (v.data_in_subdir && !std::string(v.data_in_subdir).empty()) {
                    return v.data_in_subdir;
                }

                return nullptr;
            }
        }

        return nullptr;
    }
}
