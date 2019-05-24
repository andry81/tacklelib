include(tacklelib/testlib/TestModule)

tkl_testmodule_init()

macro(macro_assert a)
  tkl_test_assert_true("a STREQUAL \"\"" "a=${a}")
  tkl_test_assert_true("\"${a}\" STREQUAL \"111\"" "a=${a}")
endmacro()

function(func_assert a)
  tkl_test_assert_true("a STREQUAL \"222\"" "a=${a}")
  tkl_test_assert_true("\"${a}\" STREQUAL \"222\"" "a=${a}")
endfunction()

macro_assert(111)
func_assert(222)

tkl_testmodule_update_status()
