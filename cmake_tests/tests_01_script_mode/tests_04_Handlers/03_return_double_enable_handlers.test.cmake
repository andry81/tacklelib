include(tacklelib/testlib/TestModule)
include(tacklelib/Handlers)

tkl_testmodule_init()

macro(return_pre_handler)
  tkl_test_assert_true(1 "handler called")

  tkl_testmodule_update_status()
endmacro()

tkl_enable_handlers(PRE_ONLY macro return)
tkl_enable_handlers(PRE_ONLY macro return)

tkl_add_handler(PRE return return_pre_handler)

return()
