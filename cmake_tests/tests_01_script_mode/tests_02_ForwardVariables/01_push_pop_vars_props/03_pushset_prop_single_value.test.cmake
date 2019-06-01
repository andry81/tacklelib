include(tacklelib/ForwardVariables)

tkl_copy_vars(. filtered_vars_list1)

set_property(GLOBAL PROPERTY "x" 111)
set_property(GLOBAL PROPERTY "y") # unset property

tkl_pushset_prop_to_stack(a GLOBAL "x" "444")
tkl_pushset_prop_to_stack(b GLOBAL "y" "555")

tkl_test_assert_true("a STREQUAL \"444\"" "1 a=${a}")
tkl_test_assert_true("b STREQUAL \"555\"" "2 b=${b}")

get_property(a GLOBAL PROPERTY "x")
get_property(b GLOBAL PROPERTY "y")

tkl_test_assert_true("a STREQUAL \"444\"" "1 a=${a}")
tkl_test_assert_true("b STREQUAL \"555\"" "2 b=${b}")

tkl_pop_prop_from_stack(a GLOBAL "x")
tkl_pop_prop_from_stack(b GLOBAL "y")

tkl_test_assert_true("a STREQUAL \"111\"" "3 a=${a}")

tkl_test_assert_true("NOT DEFINED b" "4 b=${b}")
if (NOT DEFINED b) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "5 b=${b}")
endif()

get_property(a GLOBAL PROPERTY "x")
get_property(b GLOBAL PROPERTY "y")

tkl_test_assert_true("a STREQUAL \"111\"" "3 a=${a}")

tkl_test_assert_true("NOT DEFINED b" "4 b=${b}")
if (NOT DEFINED b) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "5 b=${b}")
endif()

tkl_copy_vars(. filtered_vars_list2)

list(REMOVE_ITEM filtered_vars_list2 filtered_vars_list1;a)

tkl_test_assert_true("filtered_vars_list1 STREQUAL filtered_vars_list2" "filtered_vars_list1=${filtered_vars_list1}\nfiltered_vars_list2=${filtered_vars_list2}")
