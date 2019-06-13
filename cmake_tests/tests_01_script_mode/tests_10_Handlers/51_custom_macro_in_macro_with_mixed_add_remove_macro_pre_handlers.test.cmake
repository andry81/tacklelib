include(tacklelib/Handlers)
include(tacklelib/Props)

macro(custom_pre_handler_1)
  tkl_test_assert_true("a STREQUAL \"111\"" "1 call context variables is not visible: a=${a}")

  tkl_append_global_prop(. call_sequence -3)
endmacro()

macro(custom_pre_handler_2)
  tkl_test_assert_true("a STREQUAL \"111\"" "2 call context variables is not visible: a=${a}")

  tkl_append_global_prop(. call_sequence -2)
endmacro()

macro(custom_pre_handler_3)
  tkl_test_assert_true("a STREQUAL \"111\"" "2 call context variables is not visible: a=${a}")

  tkl_append_global_prop(. call_sequence -1)
endmacro()

macro(custom_macro)
  tkl_append_global_prop(. call_sequence 0)
endmacro()

tkl_enable_handlers(PRE_POST macro custom_macro)

tkl_add_last_handler(PRE custom_macro custom_pre_handler_1)
tkl_add_last_handler(PRE custom_macro custom_pre_handler_2)
tkl_add_last_handler(PRE custom_macro custom_pre_handler_3)
tkl_remove_first_handler(PRE custom_macro)
tkl_remove_last_handler(PRE custom_macro)
tkl_add_first_handler(PRE custom_macro custom_pre_handler_3)
tkl_add_last_handler(PRE custom_macro custom_pre_handler_1)
tkl_remove_last_handler(PRE custom_macro)

set(a 111)

custom_macro()

tkl_get_global_prop(call_sequence call_sequence 0)
tkl_test_assert_true("call_sequence STREQUAL \"-1;-2;0\"" "call sequence is invalid: call_sequence=${call_sequence}")

return()

tkl_test_assert_true(0 "unreachable code")
