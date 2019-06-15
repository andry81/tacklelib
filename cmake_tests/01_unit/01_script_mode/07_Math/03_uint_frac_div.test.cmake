tkl_uint_frac_div(i f  0  0 0  1)
tkl_test_assert_true("i EQUAL 0" "1 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "1 f=`${f}`")

tkl_uint_frac_div(i f  2  0 0  1)
tkl_test_assert_true("i EQUAL 0" "2 i=${i}")
tkl_test_assert_true("f STREQUAL \"00\"" "2 f=`${f}`")


tkl_uint_frac_div(i f  0  0 1  1)
tkl_test_assert_true("i EQUAL 0" "3 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "3 f=`${f}`")

tkl_uint_frac_div(i f  2  0 1  1)
tkl_test_assert_true("i EQUAL 0" "4 i=${i}")
tkl_test_assert_true("f STREQUAL \"10\"" "4 f=`${f}`")


tkl_uint_frac_div(i f  0  1 0  1)
tkl_test_assert_true("i EQUAL 1" "5 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "5 f=`${f}`")

tkl_uint_frac_div(i f  2  1 0  1)
tkl_test_assert_true("i EQUAL 1" "6 i=${i}")
tkl_test_assert_true("f STREQUAL \"00\"" "6 f=`${f}`")


tkl_uint_frac_div(i f  0  1 0  3)
tkl_test_assert_true("i EQUAL 0" "7 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "7 f=`${f}`")

tkl_uint_frac_div(i f  2  1 0  3)
tkl_test_assert_true("i EQUAL 0" "8 i=${i}")
tkl_test_assert_true("f STREQUAL \"33\"" "8 f=`${f}`")


tkl_uint_frac_div(i f  0  1 5  3)
tkl_test_assert_true("i EQUAL 0" "9 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "9 f=`${f}`")

tkl_uint_frac_div(i f  2  1 5  3)
tkl_test_assert_true("i EQUAL 0" "10 i=${i}")
tkl_test_assert_true("f STREQUAL \"49\"" "10 f=`${f}`")


tkl_uint_frac_div(i f  0  3 5  3)
tkl_test_assert_true("i EQUAL 1" "11 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "11 f=`${f}`")

tkl_uint_frac_div(i f  2  3 5  3)
tkl_test_assert_true("i EQUAL 1" "12 i=${i}")
tkl_test_assert_true("f STREQUAL \"16\"" "12 f=`${f}`")


tkl_uint_frac_div(i f  0  10 999  3)
tkl_test_assert_true("i EQUAL 3" "13 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "13 f=`${f}`")

tkl_uint_frac_div(i f  3  10 999  3)
tkl_test_assert_true("i EQUAL 3" "14 i=${i}")
tkl_test_assert_true("f STREQUAL \"666\"" "14 f=`${f}`")


tkl_uint_frac_div(i f  0  2 111  2)
tkl_test_assert_true("i EQUAL 1" "13 i=${i}")
tkl_test_assert_true("f STREQUAL \"\"" "13 f=`${f}`")

tkl_uint_frac_div(i f  3  2 111  2)
tkl_test_assert_true("i EQUAL 1" "15 i=${i}")
tkl_test_assert_true("f STREQUAL \"055\"" "15 f=`${f}`")
