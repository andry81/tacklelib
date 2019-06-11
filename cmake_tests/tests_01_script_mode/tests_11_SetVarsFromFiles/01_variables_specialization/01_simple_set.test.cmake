include(tacklelib/SetVarsFromFiles)

function(dbg_message msg)
  message("${msg}")
endfunction()

function(TestCase_set_01)
  tkl_load_vars_from_files("${TACKLELIB_TESTLIB_TESTMODULE_DIR}/refs/TestCase_set_01.vars")

  tkl_test_assert_true("n EQUAL 1" "n=${n}")
  tkl_test_assert_true("s STREQUAL \"123\"" "s=${s}")
  tkl_test_assert_true("l STREQUAL \"1;2 3;456\"" "l=${l}")
  tkl_test_assert_true("b" "b=${b}")
  tkl_test_assert_true("p1 STREQUAL \"c:/aaa/1 2\"" "p1=${p1}")
  tkl_test_assert_true("p2 STREQUAL \"c:/AAA/1 2\"" "p2=${p2}")
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_set_01
)
