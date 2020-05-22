include(tacklelib/Eval)

function(test_return)
  tkl_macro_fast_eval("return()") # `return` should execute in the scope of the `tkl_macro_fast_eval` function

  tkl_test_assert_true(1)
endfunction()

test_return()
