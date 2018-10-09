#include "test_common.hpp"

// include all tests headers from here
//...
//

// must define appropriate tests here to skip them in case of absence respective conditions
DECLARE_TEST_CASES
{
#ifdef UNIT_TESTS
    DECLARE_TEST_CASE_FUNC(FunctionsTest, *, "", nullptr, 0),

    DECLARE_TEST_CASE_FUNC(TackleDequeTest, *, "", nullptr, 0),

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
    DECLARE_TEST_CASE_FUNC(FunctionsTest, *, nullptr, "test_funcs_duration", "test_funcs_duration", 0),

// examples here...
//
//    DECLARE_TEST_CASE_CLASS(TestParseFromRefFile, test_duration, parse_from_ref_file, "_common", nullptr,
//        test::TCF_IS_PARAMETERIZED | test::TCF_HAS_DATA_REF),
#endif
};
