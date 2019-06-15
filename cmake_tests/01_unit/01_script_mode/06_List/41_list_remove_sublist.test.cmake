include(tacklelib/List)

#tkl_enable_test_dbg_msg()

function(TestCase_01)
  set(l ";")
  foreach (i RANGE 1)
    tkl_list_remove_sublist(v ${i} 1 l)
    tkl_test_assert_true("v STREQUAL \"\"" "v=${v}")
  endforeach()
endfunction()

function(TestCase_02)
  set(l ";;")
  foreach (i RANGE 1)
    tkl_list_remove_sublist(v ${i} 2 l)
    tkl_test_assert_true("v STREQUAL \"\"" "v=${v}")
  endforeach()
  foreach (i RANGE 2)
    tkl_list_remove_sublist(v ${i} 1 l)
    tkl_test_assert_true("v STREQUAL \";\"" "v=${v}")
  endforeach()
endfunction()

function(TestCase_03)
  set(l ";;;")
  foreach (i RANGE 1)
    tkl_list_remove_sublist(v ${i} 3 l)
    tkl_test_assert_true("v STREQUAL \"\"" "v=${v}")
  endforeach()
  foreach (i RANGE 2)
    tkl_list_remove_sublist(v ${i} 2 l)
    tkl_test_assert_true("v STREQUAL \";\"" "v=${v}")
  endforeach()
  foreach (i RANGE 3)
    tkl_list_remove_sublist(v ${i} 1 l)
    tkl_test_assert_true("v STREQUAL \";;\"" "v=${v}")
  endforeach()
endfunction()

function(TestCase_04)
  set(l "1;2;3")
  tkl_list_remove_sublist(v0 0 1 l)
  tkl_list_remove_sublist(v1 1 1 l)
  tkl_list_remove_sublist(v2 2 1 l)
  tkl_test_assert_true("v0 STREQUAL \"2;3\"" "v0=${v0}")
  tkl_test_assert_true("v1 STREQUAL \"1;3\"" "v1=${v1}")
  tkl_test_assert_true("v2 STREQUAL \"1;2\"" "v2=${v2}")
endfunction()

function(TestCase_05)
  set(l "1;2;3")
  tkl_list_remove_sublist(v0 0 2 l)
  tkl_list_remove_sublist(v1 1 2 l)
  tkl_list_remove_sublist(v2 0 3 l)
  tkl_test_assert_true("v0 STREQUAL \"3\"" "v0=${v0}")
  tkl_test_assert_true("v1 STREQUAL \"1\"" "v1=${v1}")
  tkl_test_assert_true("v2 STREQUAL \"\"" "v2=${v2}")
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_01
  TestCase_02
  TestCase_03
  TestCase_04
  TestCase_05
)
