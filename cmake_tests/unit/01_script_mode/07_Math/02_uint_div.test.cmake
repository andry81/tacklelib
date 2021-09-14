tkl_uint_div(i f 0 0 1)
tkl_test_assert_true("i EQUAL 0" "1 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "1 f=`${f}`")

tkl_uint_div(i f 2 0 1)
tkl_test_assert_true("i EQUAL 0" "2 i=${i}")
tkl_test_assert_true("f STREQUAL \"0\"" "2 f=`${f}`")

tkl_uint_div(i f 0 1 1)
tkl_test_assert_true("i EQUAL 1" "3 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "3 f=`${f}`")

tkl_uint_div(i f 2 1 1)
tkl_test_assert_true("i EQUAL 1" "4 i=${i}")
tkl_test_assert_true("f STREQUAL \"0\"" "4 f=`${f}`")

tkl_uint_div(i f 0 3 1)
tkl_test_assert_true("i EQUAL 3" "5 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "5 f=`${f}`")

tkl_uint_div(i f 2 3 1)
tkl_test_assert_true("i EQUAL 3" "6 i=${i}")
tkl_test_assert_true("f STREQUAL \"0\"" "6 f=`${f}`")

tkl_uint_div(i f 0 1 3)
tkl_test_assert_true("i EQUAL 0" "7 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "7 f=`${f}`")

tkl_uint_div(i f 2 1 3)
tkl_test_assert_true("i EQUAL 0" "8 i=${i}")
tkl_test_assert_true("f STREQUAL \"33\"" "8 f=`${f}`")

tkl_uint_div(i f 9 10 3)
tkl_test_assert_true("i EQUAL 3" "9 i=${i}")
tkl_test_assert_true("f STREQUAL \"333333333\"" "9 f=`${f}`")

tkl_uint_div(i f 3 3 200)
tkl_test_assert_true("i EQUAL 0" "9 i=${i}")
tkl_test_assert_true("f STREQUAL \"015\"" "9 f=`${f}`")
