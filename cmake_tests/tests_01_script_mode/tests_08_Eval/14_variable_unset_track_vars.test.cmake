include(tacklelib/ForwardVariables)
include(tacklelib/Eval)

set(a 123)

tkl_copy_vars(all_vars_list1)
tkl_eval("unset(a)")
tkl_copy_vars(all_vars_list2)

list(REMOVE_ITEM all_vars_list2 all_vars_list1)

set(vars_before ${all_vars_list1})
list(REMOVE_ITEM vars_before ${all_vars_list2})

set(vars_after ${all_vars_list2})
list(REMOVE_ITEM vars_after ${all_vars_list1})

tkl_test_assert_true("vars_before STREQUAL \"a\"" "vars_before=${vars_before}")
tkl_test_assert_true("vars_after STREQUAL \"\"" "vars_after=${vars_after}")
