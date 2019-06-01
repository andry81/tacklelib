function(dbg_message msg)
  message("${msg}")
endfunction()

function(HellowTestWorld)
  dbg_message("TODO!")
  tkl_test_assert_true(1)
endfunction()

tkl_testmodule_run_test_cases(
  HellowTestWorld
)
