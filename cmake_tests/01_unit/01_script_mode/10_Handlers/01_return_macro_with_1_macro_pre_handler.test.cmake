include(tacklelib/Handlers)

macro(return_pre_handler)
  tkl_test_assert_true("a STREQUAL \"111\"" "call context variables is not visible: a=${a}")
endmacro()

tkl_enable_handlers(PRE_ONLY macro return)

tkl_add_last_handler(PRE return return_pre_handler)

set(a 111)

return()

tkl_test_assert_true(0 "unreachable code")
