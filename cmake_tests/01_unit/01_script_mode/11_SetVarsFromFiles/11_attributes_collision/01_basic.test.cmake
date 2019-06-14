#tkl_enable_test_dbg_message()

function(HellowTestWorld)
  tkl_test_dbg_message("TODO!")
  tkl_test_assert_true(1)
endfunction()

tkl_testmodule_run_test_cases(
  HellowTestWorld
)
