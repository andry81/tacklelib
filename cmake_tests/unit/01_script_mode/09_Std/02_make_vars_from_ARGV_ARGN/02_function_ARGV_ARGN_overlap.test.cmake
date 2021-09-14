#tkl_enable_test_dbg_msg()

function(test_inner_func)
  tkl_test_dbg_msg("ARGV=${ARGV} ARGC=${ARGC} ARGV0=${ARGV0} ARGV1=${ARGV1}")
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"y\"" "ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 1" "ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1\"" "argv=${argv}")
  tkl_test_assert_true("argn STREQUAL \"1\"" "argn=${argn}")
endfunction()

function(test_outter_func)
  test_inner_func(1)
endfunction()

test_outter_func(x y)
