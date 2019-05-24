include(tacklelib/testlib/TestModule)

tkl_testmodule_init()

# INFO:
#   In a function to intercept the `return` call w/o reimplementation of the `return`
#   function and call the test module state update before the module exit.
#
function(TestModuleEntry)
  include("${TACKLELIB_TESTLIB_TESTMODULE_FILE}")
endfunction()

TestModuleEntry()

tkl_testmodule_update_status()
