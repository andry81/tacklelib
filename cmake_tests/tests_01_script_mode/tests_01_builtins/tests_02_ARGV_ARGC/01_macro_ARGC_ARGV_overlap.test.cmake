macro(test_inner_macro)
  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"\"" "ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 1" "ARGC=${ARGC}")
endmacro()

macro(test_outter_macro)
  test_inner_macro(1)
endmacro()

test_outter_macro(x y)
