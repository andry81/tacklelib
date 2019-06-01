set(a 123)

### tkl_make_var_from_ARGV_begin + tkl_set_ARGV + tkl_make_var_from_ARGV_end + tkl_unset_ARGV (in a macro call)

macro(test_macro_A_no_args_01)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_var_from_ARGV_end(argv)
  tkl_unset_ARGV()

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)
  list(GET argv 3 argv3)
  list(GET argv 4 argv4)
  list(GET argv 5 argv5)

  tkl_test_assert_true("argv0 STREQUAL \"123\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"2\"" "argv2=${argv2}")
  tkl_test_assert_true("argv3 STREQUAL \"3;4;5\"" "argv3=${argv3}")
  tkl_test_assert_true("argv4 STREQUAL \"123\"" "argv4=${argv4}")
  tkl_test_assert_true("argv5 STREQUAL \"1;2;3;4;5\"" "argv5=${argv5}")
endmacro()

macro(test_macro_A_with_args_01 arg0 arg1 arg2)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_var_from_ARGV_end(argv)
  tkl_unset_ARGV()

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)
  list(GET argv 3 argv3)
  list(GET argv 4 argv4)
  list(GET argv 5 argv5)

  tkl_test_assert_true("\"${arg0}\" STREQUAL \"123\"" "arg0=${arg0}")
  tkl_test_assert_true("\"${arg1}\" STREQUAL \"1;2;3\;4\;5\"" "arg1=${arg1}")
  tkl_test_assert_true("\"${arg2}\" STREQUAL \"123;1\;2\;3\;4\;5\"" "arg2=${arg2}")

  tkl_test_assert_true("argv0 STREQUAL \"123\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"2\"" "argv2=${argv2}")
  tkl_test_assert_true("argv3 STREQUAL \"3;4;5\"" "argv3=${argv3}")
  tkl_test_assert_true("argv4 STREQUAL \"123\"" "argv4=${argv4}")
  tkl_test_assert_true("argv5 STREQUAL \"1;2;3;4;5\"" "argv5=${argv5}")
endmacro()

function(TestCase_macro_A_no_args_01)
  test_macro_A_no_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

function(TestCase_macro_A_with_args_01)
  test_macro_A_with_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

### tkl_make_var_from_ARGV_begin + tkl_make_var_from_ARGV_end (in a function call)

function(test_func_A_no_args_01)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_var_from_ARGV_end(argv)

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)
  list(GET argv 3 argv3)
  list(GET argv 4 argv4)
  list(GET argv 5 argv5)

  tkl_test_assert_true("argv0 STREQUAL \"\\\${a}\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"2\"" "argv2=${argv2}")
  tkl_test_assert_true("argv3 STREQUAL \"3;4;5\"" "argv3=${argv3}")
  tkl_test_assert_true("argv4 STREQUAL \"\\\${a}\"" "argv4=${argv4}")
  tkl_test_assert_true("argv5 STREQUAL \"1;2;3\;4\;5\"" "argv5=${argv5}")
endfunction()

function(test_func_A_with_args_01 arg0 arg1 arg2)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_var_from_ARGV_end(argv)

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)
  list(GET argv 3 argv3)
  list(GET argv 4 argv4)
  list(GET argv 5 argv5)

  tkl_test_assert_true("arg0 STREQUAL \"\\\${a}\"" "arg0=${arg0}")
  tkl_test_assert_true("arg1 STREQUAL \"1;2;3\;4\;5\"" "arg1=${arg1}")
  tkl_test_assert_true("arg2 STREQUAL \"\${a};1\;2\\;3\\\;4\\\\;5\"" "arg2=${arg2}")

  tkl_test_assert_true("argv0 STREQUAL \"\\\${a}\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"2\"" "argv2=${argv2}")
  tkl_test_assert_true("argv3 STREQUAL \"3;4;5\"" "argv3=${argv3}")
  tkl_test_assert_true("argv4 STREQUAL \"\\\${a}\"" "argv4=${argv4}")
  tkl_test_assert_true("argv5 STREQUAL \"1;2;3\;4\;5\"" "argv5=${argv5}")
endfunction()

function(TestCase_func_A_no_args_01)
  test_func_A_no_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

function(TestCase_func_A_with_args_01)
  test_func_A_with_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

### tkl_make_vars_from_ARGV_ARGN_begin + tkl_set_ARGV + tkl_make_vars_from_ARGV_ARGN_end + tkl_unset_ARGV (in a macro call)

macro(test_macro_B_no_args_01)
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  tkl_set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)
  tkl_unset_ARGV()

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)
  list(GET argv 3 argv3)
  list(GET argv 4 argv4)
  list(GET argv 5 argv5)
  list(GET argv 6 argv6)
  list(GET argv 7 argv7)

  tkl_test_assert_true("argv0 STREQUAL \"0\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"2\"" "argv2=${argv2}")
  tkl_test_assert_true("argv3 STREQUAL \"3\"" "argv3=${argv3}")
  tkl_test_assert_true("argv4 STREQUAL \"4 5\"" "argv4=${argv4}")
  tkl_test_assert_true("argv5 STREQUAL \"a\"" "argv5=${argv5}")
  tkl_test_assert_true("argv6 STREQUAL \"b\"" "argv6=${argv6}")
  tkl_test_assert_true("argv7 STREQUAL \"c\"" "argv7=${argv7}")

  list(GET argn 0 argn0)
  list(GET argn 1 argn1)
  list(GET argn 2 argn2)
  list(GET argn 3 argn3)
  list(GET argn 4 argn4)
  list(GET argn 5 argn5)
  list(GET argn 6 argn6)
  list(GET argn 7 argn7)

  tkl_test_assert_true("argn0 STREQUAL \"0\"" "argn0=${argn0}")
  tkl_test_assert_true("argn1 STREQUAL \"1\"" "argn1=${argn1}")
  tkl_test_assert_true("argn2 STREQUAL \"2\"" "argn2=${argn2}")
  tkl_test_assert_true("argn3 STREQUAL \"3\"" "argn3=${argn3}")
  tkl_test_assert_true("argn4 STREQUAL \"4 5\"" "argn4=${argn4}")
  tkl_test_assert_true("argn5 STREQUAL \"a\"" "argn5=${argn5}")
  tkl_test_assert_true("argn6 STREQUAL \"b\"" "argn6=${argn6}")
  tkl_test_assert_true("argn7 STREQUAL \"c\"" "argn7=${argn7}")
endmacro()

macro(test_macro_B_with_args_01 arg0 arg1 arg2)
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  tkl_set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)
  tkl_unset_ARGV()

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)
  list(GET argv 3 argv3)
  list(GET argv 4 argv4)
  list(GET argv 5 argv5)
  list(GET argv 6 argv6)
  list(GET argv 7 argv7)

  tkl_test_assert_true("argv0 STREQUAL \"0\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"2\"" "argv2=${argv2}")
  tkl_test_assert_true("argv3 STREQUAL \"3\"" "argv3=${argv3}")
  tkl_test_assert_true("argv4 STREQUAL \"4 5\"" "argv4=${argv4}")
  tkl_test_assert_true("argv5 STREQUAL \"a\"" "argv5=${argv5}")
  tkl_test_assert_true("argv6 STREQUAL \"b\"" "argv6=${argv6}")
  tkl_test_assert_true("argv7 STREQUAL \"c\"" "argv7=${argv7}")

  list(GET argn 0 argn3)
  list(GET argn 1 argn4)
  list(GET argn 2 argn5)
  list(GET argn 3 argn6)

  tkl_test_assert_true("\"${arg0}\" STREQUAL \"0\"" "arg0=${arg0}")
  tkl_test_assert_true("\"${arg1}\" STREQUAL \"1\"" "arg1=${arg1}")
  tkl_test_assert_true("\"${arg2}\" STREQUAL \"2;3\"" "arg2=${arg2}")

  tkl_test_assert_true("argn3 STREQUAL \"4 5\"" "argn3=${argn3}")
  tkl_test_assert_true("argn4 STREQUAL \"a\"" "argn4=${argn4}")
  tkl_test_assert_true("argn5 STREQUAL \"b\"" "argn5=${argn5}")
  tkl_test_assert_true("argn6 STREQUAL \"c\"" "argn6=${argn6}")
endmacro()

function(TestCase_macro_B_no_args_01)
  test_macro_B_no_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

function(TestCase_macro_B_with_args_01)
  test_macro_B_with_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

### make_argn_var_from_ARGV_ARGN_begin + make_argn_var_from_ARGV_ARGN_end (in a function call)

function(test_func_B_no_args_01)
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)
  list(GET argv 3 argv3)
  list(GET argv 4 argv4)
  list(GET argv 5 argv5)
  list(GET argv 6 argv6)
  list(GET argv 7 argv7)

  tkl_test_assert_true("argv0 STREQUAL \"0\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"2\"" "argv2=${argv2}")
  tkl_test_assert_true("argv3 STREQUAL \"3\"" "argv3=${argv3}")
  tkl_test_assert_true("argv4 STREQUAL \"4 5\"" "argv4=${argv4}")
  tkl_test_assert_true("argv5 STREQUAL \"a\"" "argv5=${argv5}")
  tkl_test_assert_true("argv6 STREQUAL \"b\"" "argv6=${argv6}")
  tkl_test_assert_true("argv7 STREQUAL \"c\"" "argv7=${argv7}")

  list(GET argn 0 argn0)
  list(GET argn 1 argn1)
  list(GET argn 2 argn2)
  list(GET argn 3 argn3)
  list(GET argn 4 argn4)
  list(GET argn 5 argn5)
  list(GET argn 6 argn6)
  list(GET argn 7 argn7)

  tkl_test_assert_true("argn0 STREQUAL \"0\"" "argn0=${argn0}")
  tkl_test_assert_true("argn1 STREQUAL \"1\"" "argn1=${argn1}")
  tkl_test_assert_true("argn2 STREQUAL \"2\"" "argn2=${argn2}")
  tkl_test_assert_true("argn3 STREQUAL \"3\"" "argn3=${argn3}")
  tkl_test_assert_true("argn4 STREQUAL \"4 5\"" "argn4=${argn4}")
  tkl_test_assert_true("argn5 STREQUAL \"a\"" "argn5=${argn5}")
  tkl_test_assert_true("argn6 STREQUAL \"b\"" "argn6=${argn6}")
  tkl_test_assert_true("argn7 STREQUAL \"c\"" "argn7=${argn7}")
endfunction()

function(test_func_B_with_args_01 arg0 arg1 arg2)
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)
  list(GET argv 3 argv3)
  list(GET argv 4 argv4)
  list(GET argv 5 argv5)
  list(GET argv 6 argv6)
  list(GET argv 7 argv7)

  tkl_test_assert_true("argv0 STREQUAL \"0\"" "argv0=${argv0}")
  tkl_test_assert_true("argv1 STREQUAL \"1\"" "argv1=${argv1}")
  tkl_test_assert_true("argv2 STREQUAL \"2\"" "argv2=${argv2}")
  tkl_test_assert_true("argv3 STREQUAL \"3\"" "argv3=${argv3}")
  tkl_test_assert_true("argv4 STREQUAL \"4 5\"" "argv4=${argv4}")
  tkl_test_assert_true("argv5 STREQUAL \"a\"" "argv5=${argv5}")
  tkl_test_assert_true("argv6 STREQUAL \"b\"" "argv6=${argv6}")
  tkl_test_assert_true("argv7 STREQUAL \"c\"" "argv7=${argv7}")

  list(GET argn 0 argn3)
  list(GET argn 1 argn4)
  list(GET argn 2 argn5)
  list(GET argn 3 argn6)

  tkl_test_assert_true("\"${arg0}\" STREQUAL \"0\"" "arg0=${arg0}")
  tkl_test_assert_true("\"${arg1}\" STREQUAL \"1\"" "arg1=${arg1}")
  tkl_test_assert_true("\"${arg2}\" STREQUAL \"2;3\"" "arg2=${arg2}")

  tkl_test_assert_true("argn3 STREQUAL \"4 5\"" "argn3=${argn3}")
  tkl_test_assert_true("argn4 STREQUAL \"a\"" "argn4=${argn4}")
  tkl_test_assert_true("argn5 STREQUAL \"b\"" "argn5=${argn5}")
  tkl_test_assert_true("argn6 STREQUAL \"c\"" "argn6=${argn6}")
endfunction()

function(TestCase_func_B_no_args_01)
  test_func_B_no_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

function(TestCase_func_B_with_args_01)
  test_func_B_with_args_01(\${a};1\;2\\;3\\\;4\\\\;5 "\${a};1\;2\\;3\\\;4\\\\;5")
endfunction()

tkl_testmodule_run_test_cases(
  ### make_argv_var_from_ARGV_begin + make_argv_var_from_ARGV_end

  TestCase_macro_A_no_args_01
  TestCase_macro_A_with_args_01
  TestCase_func_A_no_args_01
  TestCase_func_A_with_args_01

  ### make_argn_var_from_ARGV_ARGN_begin + make_argn_var_from_ARGV_ARGN_end

  TestCase_macro_B_no_args_01
  TestCase_macro_B_with_args_01
  TestCase_func_B_no_args_01
  TestCase_func_B_with_args_01
)
