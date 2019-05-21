include(tacklelib/testlib/TestModule)
include(tacklelib/Handlers)

tkl_testmodule_init()

macro(return_pre_handler)
  tkl_test_assert_true(1 "handler called")
endmacro()

tkl_enable_handlers_for(PRE_ONLY macro return)
tkl_add_handler_for_return(PRE return_pre_handler)

tkl_testmodule_update_status()

return()
