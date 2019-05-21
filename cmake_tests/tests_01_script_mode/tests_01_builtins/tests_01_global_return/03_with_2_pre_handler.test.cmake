include(tacklelib/testlib/TestModule)
include(tacklelib/Handlers)

tkl_testmodule_init()

set(return_handlers_call_counter 0)

macro(return_pre_handler_1)
  math(EXPR return_handlers_call_counter ${return_handlers_call_counter}+1)
endmacro()

macro(return_pre_handler_2)
  math(EXPR return_handlers_call_counter ${return_handlers_call_counter}+1)
  if (return_handlers_call_counter EQUAL 2)
    tkl_test_assert_true(1 "all handlers called")
  endif()
endmacro()

tkl_enable_handlers_for(PRE_ONLY macro return)
tkl_add_handler_for_return(PRE return_pre_handler_1)
tkl_add_handler_for_return(PRE return_pre_handler_2)

tkl_testmodule_update_status()

return()
