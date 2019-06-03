include(tacklelib/Std)
include(tacklelib/ForwardVariables)
include(tacklelib/Handlers)

macro(return_pre_handler)
  tkl_testmodule_update_status()
endmacro()

unset(all_vars_list1)
unset(all_vars_list2)

tkl_copy_vars(all_vars_list1)
tkl_enable_handlers(PRE_ONLY macro return)
tkl_copy_vars(all_vars_list2)

list(REMOVE_ITEM all_vars_list2 all_vars_list1)

set(vars_before ${all_vars_list1})
list(REMOVE_ITEM vars_before ${all_vars_list2})

set(vars_after ${all_vars_list2})
list(REMOVE_ITEM vars_after ${all_vars_list1})

tkl_test_assert_true("vars_before STREQUAL \"\"" "vars_before=${vars_before}")
tkl_test_assert_true("vars_after STREQUAL \"\"" "vars_after=${vars_after}")

unset(all_vars_list1)
unset(all_vars_list2)

tkl_copy_vars(all_vars_list1)
tkl_add_handler(PRE return return_pre_handler)
tkl_copy_vars(all_vars_list2)

list(REMOVE_ITEM all_vars_list2 all_vars_list1)

set(vars_before ${all_vars_list1})
list(REMOVE_ITEM vars_before ${all_vars_list2})

set(vars_after ${all_vars_list2})
list(REMOVE_ITEM vars_after ${all_vars_list1})

tkl_test_assert_true("vars_before STREQUAL \"\"" "vars_before=${vars_before}")
tkl_test_assert_true("vars_after STREQUAL \"\"" "vars_after=${vars_after}")

return()
