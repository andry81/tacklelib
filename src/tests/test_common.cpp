#include "test_common.hpp"
#include "test_tacklelib.hpp"

#include <boost/preprocessor/stringize.hpp>
#include <boost/preprocessor/cat.hpp>

#include <boost/filesystem.hpp>
#include <boost/format.hpp>


bool TestCaseStaticBase::s_enable_all_tests = false;
bool TestCaseStaticBase::s_enable_interactive_tests = false;
bool TestCaseStaticBase::s_enable_only_interactive_tests = false; // overrides all enable_*_tests flags
bool TestCaseStaticBase::s_enable_combinator_tests = false;


namespace boost
{
    namespace fs = filesystem;
}

namespace test
{
    void interrupt_test()
    {
        TEST_LOG_OUT(SKIP, "User interrupted.");
    }
}

//TestCaseStaticBase
TestCaseStaticBase::TestCaseStaticBase()
{
}

std::string TestCaseStaticBase::get_data_in_root(const char * scope_str, const char * func_str)
{
    const char * data_in_subdir = test::get_data_in_subdir(scope_str, func_str);
    return s_TESTS_DATA_IN_ROOT + (data_in_subdir ? std::string("/") + data_in_subdir : "");
}

std::string TestCaseStaticBase::get_data_out_root(const char * scope_str, const char * func_str)
{
    (void)scope_str;
    (void)func_str;
    return s_TESTS_DATA_OUT_ROOT;
}

//TestCaseWithDataReference
TestCaseWithDataReference::TestCaseWithDataReference()
{
}

std::string TestCaseWithDataReference::get_ref_dir(const char * scope_str, const char * func_str)
{
    UTILITY_UNUSED_STATEMENT(func_str);

    if (s_TESTS_REF_DIR.empty())
        throw std::runtime_error((boost::format("%s: TESTS_REF_DIR does not exist") % UTILITY_PP_FUNC).str());

    return s_TESTS_REF_DIR + "/" + scope_str + "/ref";
}

//TestCaseWithDataGenerator
TestCaseWithDataGenerator::TestCaseWithDataGenerator()
{
}

std::string TestCaseWithDataGenerator::get_gen_dir(const char * scope_str, const char * func_str)
{
    UTILITY_UNUSED_STATEMENT(func_str);

    if (!s_is_TESTS_GEN_DIR_exists)
        throw std::runtime_error((boost::format("%s: TESTS_GEN_DIR does not exist") % UTILITY_PP_FUNC).str());

    const std::string gen_dir = s_TESTS_GEN_DIR + "/" + scope_str + "/gen";

    // generated direcory must already exists on first request
    if (!boost::fs::exists(gen_dir))
        boost::fs::create_directories(gen_dir);

    return gen_dir;
}

//TestCaseWithDataOutput
TestCaseWithDataOutput::TestCaseWithDataOutput()
{
}

std::string TestCaseWithDataOutput::get_out_dir(const char * scope_ptr, const char * func_str)
{
    UTILITY_UNUSED_STATEMENT(func_str);

    if (s_TESTS_OUT_DIR.empty())
        throw std::runtime_error((boost::format("%s: TESTS_OUT_DIR does not exist") % UTILITY_PP_FUNC).str());

    const std::string out_dir = s_TESTS_OUT_DIR + "/" + scope_ptr + "/out";

    // output direcory must already exists on first request
    if (!boost::fs::exists(out_dir))
        boost::fs::create_directories(out_dir);

    return out_dir;
}

