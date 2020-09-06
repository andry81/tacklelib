include(tacklelib/Handlers)
include(tacklelib/Props)

function(return_pre_handler_1)
  tkl_append_global_prop(. call_sequence -2)

  return()

  tkl_test_assert_true(0 "1 unreachable code")
endfunction()

function(return_pre_handler_2)
  tkl_append_global_prop(. call_sequence -1)

  return()

  tkl_test_assert_true(0 "2 unreachable code")
endfunction()

tkl_enable_handlers(PRE_ONLY macro return)

tkl_add_last_handler(PRE return return_pre_handler_1)

tkl_copy_vars(all_vars_list1)
tkl_add_last_handler(PRE return return_pre_handler_2)
tkl_copy_vars(all_vars_list2)

list(REMOVE_ITEM all_vars_list2 all_vars_list1)

set(vars_before ${all_vars_list1})
list(REMOVE_ITEM vars_before ${all_vars_list2})

set(vars_after ${all_vars_list2})
list(REMOVE_ITEM vars_after ${all_vars_list1})

tkl_test_assert_true("vars_before STREQUAL \"\"" "vars_before=${vars_before}")
tkl_test_assert_true("vars_after STREQUAL \"\"" "vars_after=${vars_after}")

function(func_with_return)
  return()

  tkl_test_assert_true(0 "3 unreachable code")
endfunction()

func_with_return()

tkl_get_global_prop(call_sequence call_sequence 0)
tkl_test_assert_true("call_sequence STREQUAL \"-2;-1\"" "call sequence is invalid: call_sequence=${call_sequence}")
