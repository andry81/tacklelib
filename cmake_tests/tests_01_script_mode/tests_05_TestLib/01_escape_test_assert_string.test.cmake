include(tacklelib/Utility)

#tkl_enable_test_dbg_message()

function(test_string_escape num in_str ref_str)
  tkl_test_dbg_message("test_string_escape: in_str=${in_str} ref_str=${ref_str}")
  tkl_escape_test_assert_string(out_str "${in_str}")
  tkl_test_assert_true("\"${out_str}\" STREQUAL \"${ref_str}\"" "${num} out_str=${out_str} ref_str=${ref_str}")
endfunction()

function(TestCase_back_slashes_01)
  test_string_escape(1 \\                 \\\\)
  test_string_escape(2 \\\\               \\\\\\\\)
  test_string_escape(3 \\\\\\             \\\\\\\\\\\\)
  test_string_escape(4 \\\\\\\\           \\\\\\\\\\\\\\\\)
  tkl_test_dbg_message("")
endfunction()

function(TestCase_back_slashes_02)
  test_string_escape(1 "\\"               "\\\\")
  test_string_escape(2 "\\\\"             "\\\\\\\\")
  test_string_escape(3 "\\\\\\"           "\\\\\\\\\\\\")
  test_string_escape(4 "\\\\\\\\"         "\\\\\\\\\\\\\\\\")
  tkl_test_dbg_message("")
endfunction()

function(TestCase_usual_char_01)
  test_string_escape(1 \\a                \\\\a)
  test_string_escape(2 \\\\a              \\\\\\\\a)
  test_string_escape(3 \\\\\\a            \\\\\\\\\\\\a)
  test_string_escape(4 \\\\\\\\a          \\\\\\\\\\\\\\\\a)
  tkl_test_dbg_message("")
endfunction()

function(TestCase_usual_char_02)
  test_string_escape(1 "\\a"              "\\\\a")
  test_string_escape(2 "\\\\a"            "\\\\\\\\a")
  test_string_escape(3 "\\\\\\a"          "\\\\\\\\\\\\a")
  test_string_escape(4 "\\\\\\\\a"        "\\\\\\\\\\\\\\\\a")
  tkl_test_dbg_message("")
endfunction()

function(TestCase_list_separator_01)
  test_string_escape(1 \;                 \;)
  test_string_escape(2 \\\;               \\\;)
  test_string_escape(3 \\\\\;             \\\\\\\;)
  test_string_escape(4 \\\\\\\;           \\\\\\\\\\\;)
  tkl_test_dbg_message("")
endfunction()

function(TestCase_list_separator_02)
  test_string_escape(1 "\;"               "\;")
  test_string_escape(2 "\\\;"             "\\\\\;")
  test_string_escape(3 "\\\\\;"           "\\\\\\\\\;")
  test_string_escape(4 "\\\\\\\;"         "\\\\\\\\\\\\\;")
  tkl_test_dbg_message("")
endfunction()

function(TestCase_variable_expander_01)
  test_string_escape(1 \$                 \\$)
  test_string_escape(2 \\$                \\\$)
  test_string_escape(3 \\\$               \\\$)
  test_string_escape(4 \\\\$              \\\\\$)
  tkl_test_dbg_message("")
endfunction()

function(TestCase_variable_expander_02)
  test_string_escape(1 "\$"               "\\\$")
  test_string_escape(2 "\\$"              "\\\$")
  test_string_escape(3 "\\\$"             "\\\$")
  test_string_escape(4 "\\\\$"            "\\\\\$")
  tkl_test_dbg_message("")
endfunction()

tkl_testmodule_run_test_cases(
  # `\` -> `\\`

  TestCase_back_slashes_01
  TestCase_back_slashes_02

  # `\a` -> `\\a`

  TestCase_usual_char_01
  TestCase_usual_char_02

  # `\;` -> `\;`

  TestCase_list_separator_01
  TestCase_list_separator_02

  # `$` -> `\$`

  TestCase_variable_expander_01
  TestCase_variable_expander_02
)
