include(TestModule)

function(TestCase_01)
  TestAssertTrue(0 "dummy test 1")
endfunction()

function(TestCase_02)
  TestAssertTrue(1 "dummy test 2")
endfunction()

TestModule_RunTestCases(
  TestCase_01
  TestCase_02
)
