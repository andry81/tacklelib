include(tacklelib/ForwardVariables)
include(tacklelib/Eval)

tkl_copy_vars(parent_all_vars_list1)
tkl_eval("set(a 123)")
tkl_copy_vars(parent_all_vars_list2)

list(REMOVE_ITEM parent_all_vars_list2 parent_all_vars_list1)

tkl_test_assert_true("parent_all_vars_list1 STREQUAL parent_all_vars_list2" "parent_all_vars_list1 not equal to parent_all_vars_list2")
