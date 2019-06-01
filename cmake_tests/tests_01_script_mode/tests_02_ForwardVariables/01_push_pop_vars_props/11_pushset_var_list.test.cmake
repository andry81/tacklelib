include(tacklelib/ForwardVariables)

set(x ";\\\\\\\\;\\\\;\\\;\\;\;;\\a;\$;\\\$;")

tkl_copy_vars(. filtered_vars_list1)

set(a 111)
unset(b)

tkl_pushset_var_to_stack(global a "${x}")
tkl_pushset_var_to_stack(global b "${x}")

tkl_test_assert_true("a STREQUAL \"\${x}\"" "1 a=${a} x=${x}")
if (a STREQUAL "${x}") # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "2 a=${a} x=${x}")
endif()

tkl_test_assert_true("b STREQUAL \"\${x}\"" "1 b=${b} x=${x}")
if (b STREQUAL "${x}") # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "2 b=${b} x=${x}")
endif()

tkl_pop_var_from_stack(global a)
tkl_pop_var_from_stack(global b)

tkl_test_assert_true("a STREQUAL \"111\"" "3 a=${a} x=${x}")
if (a STREQUAL "111") # double check
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

tkl_copy_vars(. filtered_vars_list2)

list(REMOVE_ITEM filtered_vars_list2 filtered_vars_list1;a)

tkl_test_assert_true("filtered_vars_list1 STREQUAL filtered_vars_list2" "filtered_vars_list1=${filtered_vars_list1}\nfiltered_vars_list2=${filtered_vars_list2}")
