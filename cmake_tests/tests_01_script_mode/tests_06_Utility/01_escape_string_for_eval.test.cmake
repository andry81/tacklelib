include(tacklelib/Utility)

function(dbg_message msg)
  #message("${msg}")
endfunction()

function(test_string_escape in_str ref_str)
  dbg_message("test_string_escape: in_str=${in_str} ref_str=${ref_str}")
  tkl_escape_string_for_eval(out_str "${in_str}")
  tkl_test_assert_true("\"${out_str}\" STREQUAL \"${ref_str}\"" "1 out_str=${out_str} ref_str=${ref_str}")
  if ("${out_str}" STREQUAL "${ref_str}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 out_str=${out_str} ref_str=${ref_str}")
  endif()
endfunction()

function(TestCase_back_slashes_01)
  test_string_escape(\\                 \\\\)
  test_string_escape(\\\\               \\\\\\\\)
  test_string_escape(\\\\\\             \\\\\\\\\\\\)
  test_string_escape(\\\\\\\\           \\\\\\\\\\\\\\\\)
  dbg_message("")
endfunction()

function(TestCase_back_slashes_02)
  test_string_escape("\\"               "\\\\")
  test_string_escape("\\\\"             "\\\\\\\\")
  test_string_escape("\\\\\\"           "\\\\\\\\\\\\")
  test_string_escape("\\\\\\\\"         "\\\\\\\\\\\\\\\\")
  dbg_message("")
endfunction()

function(TestCase_usual_char_01)
  test_string_escape(\\a                \\\\a)
  test_string_escape(\\\\a              \\\\\\\\a)
  test_string_escape(\\\\\\a            \\\\\\\\\\\\a)
  test_string_escape(\\\\\\\\a          \\\\\\\\\\\\\\\\a)
  dbg_message("")
endfunction()

function(TestCase_usual_char_02)
  test_string_escape("\\a"              "\\\\a")
  test_string_escape("\\\\a"            "\\\\\\\\a")
  test_string_escape("\\\\\\a"          "\\\\\\\\\\\\a")
  test_string_escape("\\\\\\\\a"        "\\\\\\\\\\\\\\\\a")
  dbg_message("")
endfunction()

function(TestCase_list_separator_01)
  test_string_escape(\;                 \;)
  test_string_escape(\\\;               \\\;)
  test_string_escape(\\\\\;             \\\\\\\;)
  test_string_escape(\\\\\\\;           \\\\\\\\\\\;)
  dbg_message("")
endfunction()

function(TestCase_list_separator_02)
  test_string_escape("\;"               "\;")
  test_string_escape("\\\;"             "\\\\\;")
  test_string_escape("\\\\\;"           "\\\\\\\\\;")
  test_string_escape("\\\\\\\;"         "\\\\\\\\\\\\\;")
  dbg_message("")
endfunction()

function(TestCase_variable_expander_01)
  test_string_escape(\$                 \$)
  test_string_escape(\\\$               \\\$)
  test_string_escape(\\\\\$             \\\\\\$)
  test_string_escape(\\\\\\\$           \\\\\\\\\\\$)
  dbg_message("")
endfunction()

function(TestCase_variable_expander_02)
  test_string_escape("\$"               "\$")
  test_string_escape("\\\$"             "\\\$")
  test_string_escape("\\\\\$"           "\\\\\\\$")
  test_string_escape("\\\\\\\$"         "\\\\\\\\\\\$")
  dbg_message("")
endfunction()

tkl_testmodule_run_test_cases(
  # \\

  TestCase_back_slashes_01
  TestCase_back_slashes_02

  # \\a

  TestCase_usual_char_01
  TestCase_usual_char_02

  # \\;

  TestCase_list_separator_01
  TestCase_list_separator_02

  # \\$

  TestCase_variable_expander_01
  TestCase_variable_expander_02
)
