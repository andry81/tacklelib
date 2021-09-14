include(tacklelib/Eval)


tkl_eval("set(a 123)")

tkl_test_assert_true("\"${a}\" STREQUAL \"123\"" "1 a=${a}")
tkl_test_assert_true("a STREQUAL \"123\"" "2 a=${a}")


unset(a)
tkl_macro_eval("set(a 123)")

tkl_test_assert_true("\"${a}\" STREQUAL \"123\"" "1 a=${a}")
tkl_test_assert_true("a STREQUAL \"123\"" "2 a=${a}")


unset(a)
tkl_macro_fast_eval("set(a 123)")

tkl_test_assert_true("\"${a}\" STREQUAL \"123\"" "1 a=${a}")
tkl_test_assert_true("a STREQUAL \"123\"" "2 a=${a}")
