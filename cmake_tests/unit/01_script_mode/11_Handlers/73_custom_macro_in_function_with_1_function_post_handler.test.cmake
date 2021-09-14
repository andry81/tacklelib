include(tacklelib/Handlers)
include(tacklelib/Props)

function(custom_post_handler)
  tkl_test_assert_true("a STREQUAL \"111\"" "1 call context variables is not visible: a=${a}")
  tkl_test_assert_true("b STREQUAL \"222\"" "2 call context variables is not visible: b=${b}")

  tkl_append_global_prop(. call_sequence +1)

  return()

  tkl_test_assert_true(0 "1 unreachable code")
endfunction()

macro(custom_macro)
  tkl_append_global_prop(. call_sequence 0)

  set(b 222)
endmacro()

tkl_enable_handlers(PRE_POST function custom_macro)

tkl_add_last_handler(POST custom_macro custom_post_handler)

set(a 111)

custom_macro()

get_property(call_sequence GLOBAL PROPERTY call_sequence)
tkl_test_assert_true("call_sequence STREQUAL \"0;+1\"" "call sequence is invalid: call_sequence=${call_sequence}")

return()

tkl_test_assert_true(0 "unreachable code")
