include(tacklelib/Handlers)

set(return_handlers_call_counter 0)

macro(return_pre_handler_1)
  math(EXPR return_handlers_call_counter ${return_handlers_call_counter}+1)
endmacro()

macro(return_pre_handler_2)
  math(EXPR return_handlers_call_counter ${return_handlers_call_counter}+1)
  if (return_handlers_call_counter EQUAL 2)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "not all handlers called")
  endif()

  tkl_testmodule_update_status()
endmacro()

tkl_enable_handlers(PRE_ONLY macro return)
tkl_add_handler(PRE return return_pre_handler_1)
tkl_add_handler(PRE return return_pre_handler_2)

return()
