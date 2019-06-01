include(tacklelib/ForwardVariables)

set(x ";\\\\\\\\;\\\\;\\\;\\;\;;\\a;\$;\\\$;")

tkl_copy_vars(. filtered_vars_list1)

set_property(GLOBAL PROPERTY "x" 111)
set_property(GLOBAL PROPERTY "y") # unset property

tkl_pushunset_prop_to_stack(GLOBAL "x" "${x}")
tkl_pushunset_prop_to_stack(GLOBAL "y" "${x}")

get_property(a GLOBAL PROPERTY "x")
get_property(b GLOBAL PROPERTY "y")

tkl_test_assert_true("NOT DEFINED a" "3 a=${a} x=${x}")
if (NOT DEFINED a) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "4 a=${a} x=${x}")
endif()

tkl_test_assert_true("NOT DEFINED b" "3 b=${b} x=${x}")
if (NOT DEFINED b) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "4 b=${b} x=${x}")
endif()

tkl_pop_prop_from_stack(a GLOBAL "x")
tkl_pop_prop_from_stack(b GLOBAL "y")

tkl_test_assert_true("a STREQUAL \"111\"" "5 a=${a} x=${x}")
if (a STREQUAL "111") # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "6 a=${a} x=${x}")
endif()

tkl_test_assert_true("NOT DEFINED b" "5 b=${b} x=${x}")
if (NOT DEFINED b) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "6 b=${b} x=${x}")
endif()

get_property(a GLOBAL PROPERTY "x")
get_property(b GLOBAL PROPERTY "y")

tkl_test_assert_true("a STREQUAL \"111\"" "7 a=${a} x=${x}")
if (a STREQUAL "111") # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "8 a=${a} x=${x}")
endif()

tkl_test_assert_true("NOT DEFINED b" "7 b=${b} x=${x}")
if (NOT DEFINED b) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "8 b=${b} x=${x}")
endif()

tkl_copy_vars(. filtered_vars_list2)

list(REMOVE_ITEM filtered_vars_list2 filtered_vars_list1;a)

tkl_test_assert_true("filtered_vars_list1 STREQUAL filtered_vars_list2" "filtered_vars_list1=${filtered_vars_list1}\nfiltered_vars_list2=${filtered_vars_list2}")
