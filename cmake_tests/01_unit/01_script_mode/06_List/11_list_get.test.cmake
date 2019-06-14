include(tacklelib/List)

#tkl_enable_test_dbg_message()

set(l1 "")
set(l2 ";")
set(l3 ";;")
set(l4 ";1;")
set(l5 "1;2 3; 4 ")

function(TestCase_01)
  tkl_list_get(v0 l1 0)
  tkl_test_assert_true("v0 STREQUAL \"\"" "v0=${v0}")
endfunction()

function(TestCase_02)
  tkl_list_get(v0 l2 0)
  tkl_list_get(v1 l2 1)
  tkl_test_assert_true("v0 STREQUAL \"\"" "v0=${v0}")
  tkl_test_assert_true("v1 STREQUAL \"\"" "v1=${v1}")
endfunction()

function(TestCase_03)
  tkl_list_get(v0 l3 0)
  tkl_list_get(v1 l3 1)
  tkl_list_get(v2 l3 2)
  tkl_test_assert_true("v0 STREQUAL \"\"" "v0=${v0}")
  tkl_test_assert_true("v1 STREQUAL \"\"" "v1=${v1}")
  tkl_test_assert_true("v2 STREQUAL \"\"" "v2=${v2}")
endfunction()

function(TestCase_04)
  tkl_list_get(v0 l4 0)
  tkl_list_get(v1 l4 1)
  tkl_list_get(v2 l4 2)
  tkl_test_assert_true("v0 STREQUAL \"\"" "v0=${v0}")
  tkl_test_assert_true("v1 STREQUAL \"1\"" "v1=${v1}")
  tkl_test_assert_true("v2 STREQUAL \"\"" "v2=${v2}")
endfunction()

function(TestCase_05)
  tkl_list_get(v0 l5 0)
  tkl_list_get(v1 l5 1)
  tkl_list_get(v2 l5 2)
  tkl_test_assert_true("v0 STREQUAL \"1\"" "v0=${v0}")
  tkl_test_assert_true("v1 STREQUAL \"2 3\"" "v1=${v1}")
  tkl_test_assert_true("v2 STREQUAL \" 4 \"" "v2=${v2}")
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_01
  TestCase_02
  TestCase_03
  TestCase_04
  TestCase_05
)
