include(tacklelib/testlib/TestModule)
include(tacklelib/Std)
include(tacklelib/Handlers)

tkl_testmodule_init()

macro(return_pre_handler)
  tkl_testmodule_update_status()
endmacro()

tkl_copy_vars(parent_all_vars_list1 parent_vars_list1 parent_var_values_list1 "")
tkl_enable_handlers(PRE_ONLY macro return)
tkl_copy_vars(parent_all_vars_list2 parent_vars_list2 parent_var_values_list2 "")

tkl_test_assert_true("parent_all_vars_list1 STREQUAL parent_all_vars_list2" "parent_all_vars_list1 not equal to parent_all_vars_list2")

tkl_copy_vars(parent_all_vars_list1 parent_vars_list1 parent_var_values_list1 "")
tkl_add_handler(PRE return return_pre_handler)
tkl_copy_vars(parent_all_vars_list2 parent_vars_list2 parent_var_values_list2 "")

tkl_test_assert_true("parent_all_vars_list1 STREQUAL parent_all_vars_list2" "parent_all_vars_list1 not equal to parent_all_vars_list2")

return()
