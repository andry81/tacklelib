include(tacklelib/File)
include(tacklelib/Utility)

#tkl_enable_test_dbg_msg()

tkl_file_encode_strings(file_content "${TACKLELIB_TESTLIB_TESTMODULE_DIR}/refs/03_basic_test_mac_eols.txt")

set(line_number 0)

foreach (line IN LISTS file_content)
  math(EXPR line_number ${line_number}+1)

  tkl_file_decode_string(line "${line}")

  if (line_number EQUAL 1)
    tkl_test_assert_true("line STREQUAL \"1\"" "line=`${line}`")
  elseif (line_number EQUAL 2)
    tkl_test_assert_true("line STREQUAL \"2\\\\\"" "line=`${line}`")
  elseif (line_number EQUAL 3)
    tkl_test_assert_true("line STREQUAL \"3?\"" "line=`${line}`")
  elseif (line_number EQUAL 4)
    tkl_test_assert_true("line STREQUAL \"4;\"" "line=`${line}`")
  elseif (line_number EQUAL 5)
    tkl_test_assert_true("line STREQUAL \"5\;\"" "line=`${line}`")
  elseif (line_number EQUAL 6)
    tkl_test_assert_true("line STREQUAL \"6]\"" "line=`${line}`")
  elseif (line_number EQUAL 7)
    tkl_test_assert_true("line STREQUAL \"7[\"" "line=`${line}`")
  elseif (line_number EQUAL 8)
    tkl_test_assert_true("line STREQUAL \"\"" "line=`${line}`")
  elseif (line_number EQUAL 9)
    tkl_test_assert_true("line STREQUAL \"9\"" "line=`${line}`")
  elseif (line_number EQUAL 10)
    tkl_test_assert_true("line STREQUAL \"\"" "line=`${line}`")
  else()
    tkl_test_assert_true(0 "not implemented")
  endif()
endforeach()

message("warning: `file(READ ....)` implementation is truncated trailing `\\r` character here")
tkl_test_assert_true("line_number EQUAL 9" "line_number=`${line_number}`") # WTF? Trailing `\r` is somehow truncated in that case (cmake 3.14.3).
