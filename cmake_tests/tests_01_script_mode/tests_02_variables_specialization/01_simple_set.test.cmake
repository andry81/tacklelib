include(TestModule)

function(HellowTestWorld)
  message("hello testworld!")
  TestAssertTrue(1 "success hello")
endfunction()

TestModule_RunTestCases(
  HellowTestWorld
)
