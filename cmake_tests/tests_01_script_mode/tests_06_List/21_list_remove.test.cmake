include(tacklelib/List)

#tkl_enable_test_dbg_message()

function(TestCase_01)
  set(l ";")
  foreach (i RANGE 1)
    tkl_list_remove_at(v l ${i})
    tkl_test_assert_true("v STREQUAL \"\"" "v=${v}")
  endforeach()
endfunction()

function(TestCase_02)
  set(l ";;")
  foreach (i RANGE 2)
    tkl_list_remove_at(v l ${i})
    tkl_test_assert_true("v STREQUAL \";\"" "v=${v}")
  endforeach()
endfunction()

function(TestCase_03)
  set(l ";;;")
  foreach (i RANGE 3)
    tkl_list_remove_at(v l ${i})
    tkl_test_assert_true("v STREQUAL \";;\"" "v=${v}")
  endforeach()
endfunction()

function(TestCase_04)
  set(l "1;2;3")
  tkl_list_remove_at(v0 l 0)
  tkl_list_remove_at(v1 l 1)
  tkl_list_remove_at(v2 l 2)
  tkl_test_assert_true("v0 STREQUAL \"2;3\"" "v0=${v0}")
  tkl_test_assert_true("v1 STREQUAL \"1;3\"" "v1=${v1}")
  tkl_test_assert_true("v2 STREQUAL \"1;2\"" "v2=${v2}")
endfunction()

function(TestCase_05)
  set(l "1;2;3")
  tkl_list_remove_at(v0 l 0 1)
  tkl_list_remove_at(v1 l 1 2)
  tkl_list_remove_at(v2 l 2 0)
  tkl_test_assert_true("v0 STREQUAL \"3\"" "v0=${v0}")
  tkl_test_assert_true("v1 STREQUAL \"1\"" "v1=${v1}")
  tkl_test_assert_true("v2 STREQUAL \"2\"" "v2=${v2}")
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_01
  TestCase_02
  TestCase_03
  TestCase_04
  TestCase_05
)
