function(dbg_message msg)
  #message("${msg}")
endfunction()

function(test_inner_func)
  dbg_message("ARGV=${ARGV} ARGC=${ARGC} ARGV0=${ARGV0} ARGV1=${ARGV1}")
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_make_var_from_ARGV_end(argv)

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"y\"" "ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 1" "ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1\"" "argv=${argv}")
endfunction()

function(test_outter_func)
  test_inner_func(1)
endfunction()

test_outter_func(x y)
