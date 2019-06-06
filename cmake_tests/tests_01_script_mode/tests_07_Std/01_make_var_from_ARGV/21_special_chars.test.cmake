include(tacklelib/ForwardArgs)

set(a 123)

macro(test_macro_no_args_01)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_var_from_ARGV_end(argv)
  tkl_pop_ARGVn_from_stack()

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)

  tkl_test_assert_true("argv0 STREQUAL \"123\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1;2;3\;4\;5\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"123;1\;2\;3\;4\;5\"" "argv2=${argv2}")
endmacro()

macro(test_macro_with_args_01 arg0 arg1 arg2)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_var_from_ARGV_end(argv)
  tkl_pop_ARGVn_from_stack()

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)

  tkl_test_assert_true("\"${arg0}\" STREQUAL \"\${a}\"" "arg0=${arg0}")
  tkl_test_assert_true("\"${arg1}\" STREQUAL \"1;2;3\;4\;5\"" "arg1=${arg1}")
  tkl_test_assert_true("\"${arg2}\" STREQUAL \"123;1\;2\;3\;4\;5\"" "arg2=${arg2}")

  tkl_test_assert_true("argv0 STREQUAL \"\${a}\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1;2;3\;4\;5\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"123;1\;2\;3\;4\;5\"" "argv2=${argv2}")
endmacro()

function(TestCase_macro_no_args_01)
  test_macro_no_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

function(TestCase_macro_with_args_01)
  test_macro_with_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

### tkl_make_var_from_ARGV_begin + tkl_make_var_from_ARGV_end (in a function call)

function(test_func_no_args_01)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_var_from_ARGV_end(argv)

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)

  tkl_test_assert_true("argv0 STREQUAL \"\\\${a}\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1;2;3\;4\;5\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"\${a};1\;2\;3\\\;4\\\;5\"" "argv2=${argv2}")
endfunction()

function(test_func_with_args_01 arg0 arg1 arg2)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_var_from_ARGV_end(argv)

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)

  tkl_test_assert_true("arg0 STREQUAL \"\\\${a}\"" "arg0=${arg0}")
  tkl_test_assert_true("arg1 STREQUAL \"1;2;3\;4\;5\"" "arg1=${arg1}")
  tkl_test_assert_true("arg2 STREQUAL \"\\\${a};1\\\;2\\\\;3\\\\\\\;4\\\\\\\\;5\"" "arg2=${arg2}")

  tkl_test_assert_true("argv0 STREQUAL \"\\\${a}\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1;2;3\;4\;5\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"\\\${a};1\\\;2\\\\;3\\\\\\\;4\\\\\\\\;5\"" "argv2=${argv2}")
endfunction()

function(TestCase_func_no_args_01)
  test_func_no_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

function(TestCase_func_with_args_01)
  test_func_with_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_macro_no_args_01
  TestCase_macro_with_args_01
  TestCase_func_no_args_01
  TestCase_func_with_args_01
)
