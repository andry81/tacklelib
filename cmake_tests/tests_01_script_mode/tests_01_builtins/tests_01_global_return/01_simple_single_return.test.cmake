include(tacklelib/testlib/TestModule)

tkl_testmodule_init()

tkl_test_assert_true(1 "always true")

tkl_testmodule_update_status()

return()

tkl_test_assert_true(0 "always false") # must be always unreachable

tkl_testmodule_update_status()
