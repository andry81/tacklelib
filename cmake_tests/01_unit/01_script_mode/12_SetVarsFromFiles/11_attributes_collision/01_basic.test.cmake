#tkl_enable_test_dbg_msg()

function(HellowTestWorld)
  tkl_test_dbg_msg("TODO!")
  tkl_test_assert_true(1)
endfunction()

tkl_testmodule_run_test_cases(
  HellowTestWorld
)
