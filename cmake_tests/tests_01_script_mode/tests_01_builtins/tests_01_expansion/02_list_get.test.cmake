# NOTE:
#   Read the doc/01_general_expansion_rules_and_reverse_to_expansion_construction_rules.txt`
#   for expansion and construction details represented here.
#

set(a 123)
set(in_str "1;2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\")

list(GET in_str 0 arg0)
list(GET in_str 1 arg1)

tkl_escape_string_after_list_get(arg0 "${arg0}")
tkl_escape_string_after_list_get(arg1 "${arg1}")

tkl_escape_test_assert_string(test_assert_outter_arg0 "${arg0}")
tkl_escape_test_assert_string(test_assert_outter_arg1 "${arg1}")

# CAUTION: first argument must be escaped by the same rules as implemented in the `tkl_escape_test_assert_string`
tkl_test_assert_true("arg0 STREQUAL \"1\"" "1 arg0=${arg0}")

tkl_test_assert_true("arg0 STREQUAL \"${test_assert_outter_arg0}\"" "2 arg0=${arg0} test_assert_outter_arg0=${test_assert_outter_arg0}")

if (arg0 STREQUAL "1")
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "2 arg0=${arg0}")
endif()

# CAUTION: first argument must be escaped by the same rules as implemented in the `tkl_escape_test_assert_string`
tkl_test_assert_true("arg1 STREQUAL \"2\;3\\\;4\\\\\;5\\\\\\\;6\\\\\\\\\;7\\\\\\\\\\\;\\\${a}\\\\\"" "1 arg1=${arg1}")

tkl_test_assert_true("arg1 STREQUAL \"${test_assert_outter_arg1}\"" "2 arg1=${arg1} test_assert_outter_arg1=${test_assert_outter_arg1}")

# CAUTION: second argument must be the same as declared in the `in_str`!
if (arg1 STREQUAL "2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\")
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "2 arg1=${arg1}")
endif()
