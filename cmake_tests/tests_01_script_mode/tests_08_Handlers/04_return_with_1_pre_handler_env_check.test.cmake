include(tacklelib/Std)
include(tacklelib/ForwardVariables)
include(tacklelib/Handlers)

macro(return_pre_handler)
  tkl_testmodule_update_status()
endmacro()

unset(parent_all_vars_list1)
unset(parent_all_vars_list2)

tkl_copy_vars(parent_all_vars_list1)
tkl_enable_handlers(PRE_ONLY macro return)
tkl_copy_vars(parent_all_vars_list2)

list(REMOVE_ITEM parent_all_vars_list2 parent_all_vars_list1)

tkl_test_assert_true("parent_all_vars_list1 STREQUAL parent_all_vars_list2" "1: parent_all_vars_list1 not equal to parent_all_vars_list2")

unset(parent_all_vars_list1)
unset(parent_all_vars_list2)

tkl_copy_vars(parent_all_vars_list1)
tkl_add_handler(PRE return return_pre_handler)
tkl_copy_vars(parent_all_vars_list2)

list(REMOVE_ITEM parent_all_vars_list2 parent_all_vars_list1)

tkl_test_assert_true("parent_all_vars_list1 STREQUAL parent_all_vars_list2" "2: parent_all_vars_list1 not equal to parent_all_vars_list2")

return()
