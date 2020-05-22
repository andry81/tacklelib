include(tacklelib/Eval)


set(a 123)

tkl_eval("unset(a)")

tkl_test_assert_true("\"\${a}\" STREQUAL \"\"" "1 a=${a}")
if ("${a}" STREQUAL "") # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "2 a=${a}")
endif()

tkl_test_assert_true("NOT DEFINED a" "3 a=${a}")
if (NOT DEFINED a) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "4 a=${a}")
endif()


set(a 123)

tkl_macro_eval("unset(a)")

tkl_test_assert_true("\"\${a}\" STREQUAL \"\"" "1 a=${a}")
if ("${a}" STREQUAL "") # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "2 a=${a}")
endif()

tkl_test_assert_true("NOT DEFINED a" "3 a=${a}")
if (NOT DEFINED a) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "4 a=${a}")
endif()


set(a 123)

tkl_macro_fast_eval("unset(a)")

tkl_test_assert_true("\"\${a}\" STREQUAL \"\"" "1 a=${a}")
if ("${a}" STREQUAL "") # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "2 a=${a}")
endif()

tkl_test_assert_true("NOT DEFINED a" "3 a=${a}")
if (NOT DEFINED a) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "4 a=${a}")
endif()
