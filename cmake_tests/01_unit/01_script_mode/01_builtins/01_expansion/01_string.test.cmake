# NOTE:
#   Read the doc/01_general_expansion_rules_and_reverse_to_expansion_construction_rules.txt`
#   for expansion and construction details represented here.
#

set(a 123)
set(in_str "1;2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\")

# CAUTION: first argument must be escaped by the same rules as implemented in the `tkl_escape_test_assert_string`
tkl_test_assert_true("in_str STREQUAL \"1;2\;3\\\;4\\\\\;5\\\\\\\;6\\\\\\\\\;7\\\\\\\\\\\;\\\${a}\\\\\"" "1 in_str=${in_str}")

tkl_escape_test_assert_string(test_assert_outter_arg "${in_str}")

tkl_test_assert_true("in_str STREQUAL \"${test_assert_outter_arg}\"" "2 in_str=${in_str} test_assert_outter_arg=${test_assert_outter_arg}")

# CAUTION: second argument must be the same as declared in the `in_str`!
if (in_str STREQUAL "1;2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\")
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "3 in_str=${in_str}")
endif()
