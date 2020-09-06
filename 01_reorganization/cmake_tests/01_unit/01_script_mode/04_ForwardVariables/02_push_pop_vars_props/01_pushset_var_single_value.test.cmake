include(tacklelib/ForwardVariables)

tkl_copy_vars(. filtered_vars_list1)

set(a 111)
unset(b)

tkl_pushset_var_to_stack(global a "444")
tkl_pushset_var_to_stack(global b "555")

tkl_test_assert_true("a STREQUAL \"444\"" "1 a=${a}")
tkl_test_assert_true("b STREQUAL \"555\"" "2 b=${b}")

tkl_pop_var_from_stack(global a)
tkl_pop_var_from_stack(global b)

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
