include(tacklelib/Utility)

# NOTE:
#   Read the doc/01_general_expansion_rules_and_reverse_to_expansion_construction_rules.txt`
#   for expansion and construction details represented here.
#

set(a 123)
set(in_str "1;2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\")
set(in_str2 "")

set(index 0)
foreach(arg IN LISTS in_str)
  tkl_escape_string_after_list_get(arg "${arg}")

  list(APPEND in_str2 "${arg}")

  math(EXPR index ${index}+1)
endforeach()

# CAUTION: first argument must be escaped by the same rules as implemented in the `tkl_escape_test_assert_string`
tkl_test_assert_true("in_str2 STREQUAL \"1;2\;3\\\;4\\\\\;5\\\\\\\;6\\\\\\\\\;7\\\\\\\\\\\;\\\${a}\\\\\"" "1 in_str2=${in_str2}")

tkl_escape_test_assert_string(test_assert_outter_arg "${in_str2}")

tkl_test_assert_true("in_str2 STREQUAL \"${test_assert_outter_arg}\"" "2 in_str2=${in_str2} test_assert_outter_arg=${test_assert_outter_arg}")

# CAUTION: second argument must be the same as declared in the `in_str`!
if (in_str2 STREQUAL "1;2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\")
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "3 in_str2=${in_str2}")
endif()
