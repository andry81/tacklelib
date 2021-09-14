include(tacklelib/SetVarsFromFiles)

#tkl_enable_test_dbg_msg()

tkl_load_vars_from_files("${TACKLELIB_TESTLIB_TESTMODULE_DIR}/refs/${TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_PREFIX}.vars")

tkl_test_assert_true("n EQUAL 1" "n=${n}")

tkl_test_assert_true("s1 STREQUAL \"123\"" "s1=${s1}")
tkl_test_assert_true("s2 STREQUAL \"1\\\\2\\\\\\\\3\"" "s2=${s2}")

tkl_test_assert_true("l STREQUAL \"1;2 3;456\"" "l=${l}")

tkl_test_assert_true("b1" "b1=${b1}")
tkl_test_assert_true("NOT b2" "b2=${b2}")

tkl_test_assert_true("p1 STREQUAL \"c:/aaa/1 2\"" "p1=${p1}")
tkl_test_assert_true("p2 STREQUAL \"c:/AAA/1 2\"" "p2=${p2}")
