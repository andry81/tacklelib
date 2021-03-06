function(test_empty_in_begin_01)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_make_var_from_ARGV_end(argv)

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"\"" "1 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"2\"" "1 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 2" "1 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \";2\"" "1 argv=${argv}")
endfunction()

function(test_empty_in_begin_02)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_make_var_from_ARGV_end(argv)

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"2\"" "2 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"\"" "2 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 1" "2 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"2\"" "2 argv=${argv}")
endfunction()

function(test_empty_in_mid_01)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_make_var_from_ARGV_end(argv)

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "3 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"\"" "3 ARGV1=${ARGV1}")
  tkl_test_assert_true("\"${ARGV2}\" STREQUAL \"3\"" "3 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 3" "3 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1;;3\"" "3 argv=${argv}")
endfunction()

function(test_empty_in_mid_02)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_make_var_from_ARGV_end(argv)

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "4 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"3\"" "4 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 2" "4 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1;3\"" "4 argv=${argv}")
endfunction()

function(test_empty_in_end_01)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_make_var_from_ARGV_end(argv)

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "5 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"\"" "5 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 2" "5 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1;\"" "5 argv=${argv}")
endfunction()

function(test_empty_in_end_02)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_make_var_from_ARGV_end(argv)

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "6 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"\"" "6 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 1" "6 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1\"" "6 argv=${argv}")
endfunction()

test_empty_in_begin_01("" 2)
test_empty_in_begin_02(;2)

test_empty_in_mid_01(1 "" 3)
test_empty_in_mid_02(1;;3)

test_empty_in_end_01(1 "")
test_empty_in_end_02(1;)
