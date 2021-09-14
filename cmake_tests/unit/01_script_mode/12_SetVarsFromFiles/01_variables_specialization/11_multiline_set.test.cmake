include(tacklelib/SetVarsFromFiles)

#tkl_enable_test_dbg_msg()

tkl_load_vars_from_files("${TACKLELIB_TESTLIB_TESTMODULE_DIR}/refs/${TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_PREFIX}.vars")

tkl_test_assert_true("s1 STREQUAL \"1234 5 6\n7 8 9\"" "s1=`${s1}`")
tkl_test_assert_true("s2 STREQUAL \"1234;5;67;8;9\"" "s2=`${s2}`")
tkl_test_assert_true("s3 STREQUAL \"1234 5 6\n7 8 9\"" "s3=`${s3}`")

tkl_test_assert_true("l1 STREQUAL \"123;4 5 6;7;8;9\"" "l1=`${l1}`")
tkl_test_assert_true("l2 STREQUAL \"123;4 5 6;7;8;9\"" "l2=`${l2}`")
tkl_test_assert_true("l3 STREQUAL \"123;4 5 6;7;8;9\"" "l3=`${l3}`")
tkl_test_assert_true("l4 STREQUAL \"1234 5 67;8;9\"" "l4=`${l4}`")
tkl_test_assert_true("l5 STREQUAL \"1 2;3;4;5;6;7\"" "l5=`${l5}`")
tkl_test_assert_true("l6 STREQUAL \"1 2;3;4;5;6;7\"" "l6=`${l6}`")
tkl_test_assert_true("l7 STREQUAL \"1 23;45;67\"" "l7=`${l7}`")
