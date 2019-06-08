include(tacklelib/Utility)

# NOTE:
#   Read the doc/01_general_expansion_rules_and_reverse_to_expansion_construction_rules.txt`
#   for expansion and construction details represented here.
#

set(a 123)
set(in_str "1;2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\")

set(index 0)
foreach(arg IN LISTS in_str)
  tkl_escape_string_after_list_get(arg "${arg}")

  tkl_escape_test_assert_string(test_assert_outter_arg "${arg}")

  if (index EQUAL 0)
    # CAUTION: first argument must be escaped by the same rules as implemented in the `tkl_escape_test_assert_string`
    tkl_test_assert_true("arg STREQUAL \"1\"" "1 arg=${arg}")

    tkl_test_assert_true("arg STREQUAL \"${test_assert_outter_arg}\"" "2 arg=${arg} test_assert_outter_arg=${test_assert_outter_arg}")

    # CAUTION: second argument must be the same as declared in the `in_str`!
    if (arg STREQUAL "1")
      tkl_test_assert_true(1)
    else()
      tkl_test_assert_true(0 "3 arg=${arg}")
    endif()
  elseif (index EQUAL 1)
    # CAUTION: first argument must be escaped by the same rules as implemented in the `tkl_escape_test_assert_string`
    tkl_test_assert_true("arg STREQUAL \"2\;3\\\;4\\\\\;5\\\\\\\;6\\\\\\\\\;7\\\\\\\\\\\;\\\${a}\\\\\"" "1 arg=${arg}")

    tkl_test_assert_true("arg STREQUAL \"${test_assert_outter_arg}\"" "2 arg=${arg} test_assert_outter_arg=${test_assert_outter_arg}")

    # CAUTION: second argument must be the same as declared in the `in_str`!
    if (arg STREQUAL "2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\")
      tkl_test_assert_true(1)
    else()
      tkl_test_assert_true(0 "3 arg=${arg}")
    endif()
  else()
    tkl_test_assert_true(0 "not implemented")
  endif()

  math(EXPR index ${index}+1)
endforeach()
