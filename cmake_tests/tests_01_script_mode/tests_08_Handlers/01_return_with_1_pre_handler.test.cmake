include(tacklelib/Handlers)

macro(return_pre_handler)
  tkl_test_assert_true(1)

  tkl_testmodule_update_status()
endmacro()

tkl_enable_handlers(PRE_ONLY macro return)

tkl_add_handler(PRE return return_pre_handler)

return()
