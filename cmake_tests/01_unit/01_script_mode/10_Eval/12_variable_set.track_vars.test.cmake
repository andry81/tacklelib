include(tacklelib/ForwardVariables)
include(tacklelib/Eval)

function(TestCase_01)
  tkl_copy_vars(all_vars_list1)
  tkl_eval("set(a 123)")
  tkl_copy_vars(all_vars_list2)

  list(REMOVE_ITEM all_vars_list2 all_vars_list1)

  set(vars_before ${all_vars_list1})
  list(REMOVE_ITEM vars_before ${all_vars_list2})

  set(vars_after ${all_vars_list2})
  list(REMOVE_ITEM vars_after ${all_vars_list1})

  tkl_test_assert_true("vars_before STREQUAL \"\"" "vars_before=${vars_before}")
  tkl_test_assert_true("vars_after STREQUAL \"a\"" "vars_after=${vars_after}")
endfunction()

function(TestCase_02)
  tkl_copy_vars(all_vars_list1)
  tkl_macro_eval("set(a 123)")
  tkl_copy_vars(all_vars_list2)

  list(REMOVE_ITEM all_vars_list2 all_vars_list1)

  set(vars_before ${all_vars_list1})
  list(REMOVE_ITEM vars_before ${all_vars_list2})

  set(vars_after ${all_vars_list2})
  list(REMOVE_ITEM vars_after ${all_vars_list1})

  tkl_test_assert_true("vars_before STREQUAL \"\"" "vars_before=${vars_before}")
  tkl_test_assert_true("vars_after STREQUAL \"a\"" "vars_after=${vars_after}")
endfunction()

function(TestCase_03)
  tkl_copy_vars(all_vars_list1)
  tkl_macro_fast_eval("set(a 123)")
  tkl_copy_vars(all_vars_list2)

  list(REMOVE_ITEM all_vars_list2 all_vars_list1)

  set(vars_before ${all_vars_list1})
  list(REMOVE_ITEM vars_before ${all_vars_list2})

  set(vars_after ${all_vars_list2})
  list(REMOVE_ITEM vars_after ${all_vars_list1})

  tkl_test_assert_true("vars_before STREQUAL \"\"" "vars_before=${vars_before}")
  tkl_test_assert_true("vars_after STREQUAL \"a\"" "vars_after=${vars_after}")
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_01
  TestCase_02
  TestCase_03
)
