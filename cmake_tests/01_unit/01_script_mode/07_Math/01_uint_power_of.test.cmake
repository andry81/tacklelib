tkl_uint_power_of(p 0 10)
tkl_test_assert_true("p EQUAL 0" "1 p=${p}")

tkl_uint_power_of(p 10 0)
tkl_test_assert_true("p EQUAL 1" "2 p=${p}")

tkl_uint_power_of(p 10 1)
tkl_test_assert_true("p EQUAL 10" "3 p=${p}")

tkl_uint_power_of(p 10 2)
tkl_test_assert_true("p EQUAL 100" "4 p=${p}")
