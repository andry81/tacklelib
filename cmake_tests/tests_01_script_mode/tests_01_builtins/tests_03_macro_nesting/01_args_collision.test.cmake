macro(outter_macro a)
  macro(inner_macro a)
    tkl_test_assert_true("\"${a}\" STREQUAL \"111\"" "a=${a}")
  endmacro()
endmacro()

outter_macro(111)
inner_macro(222)

function(outter_func a)
  macro(inner_macro a)
    tkl_test_assert_true("\"${a}\" STREQUAL \"222\"" "a=${a}")
  endmacro()
endfunction()

outter_func(111)
inner_macro(222)
