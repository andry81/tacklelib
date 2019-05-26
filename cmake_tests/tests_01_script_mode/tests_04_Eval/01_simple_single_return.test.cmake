include(tacklelib/Eval)

tkl_eval("return()") # `return` will execute in the scope of the `tkl_eval` function

tkl_test_assert_true(1)
