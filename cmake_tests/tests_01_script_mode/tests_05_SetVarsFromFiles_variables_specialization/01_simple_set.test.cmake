function(HellowTestWorld)
  message("hello testworld!")
  tkl_test_assert_true(1 "success hello")
endfunction()

tkl_testmodule_run_test_cases(
  HellowTestWorld
)
