include(tacklelib/ForwardVariables)
include(tacklelib/Eval)

tkl_copy_vars(all_vars_list1)
tkl_macro_fast_eval("tkl_test_assert_true(1)")
tkl_copy_vars(all_vars_list2)

list(REMOVE_ITEM all_vars_list2 all_vars_list1;${all_vars_list1})

tkl_test_assert_true("all_vars_list2 STREQUAL \"\"" "all_vars_list2=${all_vars_list2}")
