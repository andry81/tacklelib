include(tacklelib/Eval)

tkl_eval("set(a 123)")

tkl_test_assert_true("\"${a}\" STREQUAL \"123\"" "a=${a}")
tkl_test_assert_true("a STREQUAL \"123\"" "a=${a}")
