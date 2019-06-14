include(tacklelib/Eval)

function(TestCase_direct_message_01)
  foreach(i RANGE 1000)
    message(1)
  endforeach()
  tkl_test_assert_true(1)
endfunction()

function(TestCase_eval_message_01)
  foreach(i RANGE 1000)
    tkl_eval("message(1)")
  endforeach()
  tkl_test_assert_true(1)
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_direct_message_01
  TestCase_eval_message_01
)
