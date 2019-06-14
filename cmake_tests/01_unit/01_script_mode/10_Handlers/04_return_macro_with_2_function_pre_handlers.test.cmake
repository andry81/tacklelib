include(tacklelib/Handlers)
include(tacklelib/Props)

function(return_pre_handler_1)
  tkl_test_assert_true("a STREQUAL \"111\"" "1 call context variables is not visible: a=${a}")

  tkl_append_global_prop(. call_sequence -2)

  return()

  tkl_test_assert_true(0 "1 unreachable code")
endfunction()

function(return_pre_handler_2)
  tkl_test_assert_true("a STREQUAL \"111\"" "2 call context variables is not visible: a=${a}")

  tkl_append_global_prop(. call_sequence -1)

  return()

  tkl_test_assert_true(0 "2 unreachable code")
endfunction()

tkl_enable_handlers(PRE_ONLY macro return)

tkl_add_last_handler(PRE return return_pre_handler_1)
tkl_add_last_handler(PRE return return_pre_handler_2)

function(func_with_return)
  return()

  tkl_test_assert_true(0 "3 unreachable code")
endfunction()

set(a 111)

func_with_return()

tkl_get_global_prop(call_sequence call_sequence 0)
tkl_test_assert_true("call_sequence STREQUAL \"-2;-1\"" "call sequence is invalid: call_sequence=${call_sequence}")
