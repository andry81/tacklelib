include(TestModule)

set(test_seq_01 a;b\;c)

macro(test_macro_A_no_args)
  make_argn_var_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}")
  set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #print_ARGV()
  make_argn_var_from_ARGV_ARGN_end()
  unset_ARGV()
endmacro()

macro(test_macro_A_with_args argv0 argv1 argv2)
  make_argn_var_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}")
  set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #print_ARGV()
  make_argn_var_from_ARGV_ARGN_end()
  unset_ARGV()

  TestAssertTrue("\"${argv0}\" STREQUAL \"0\"" "argv0=${argv0}")
  TestAssertTrue("\"${argv1}\" STREQUAL \"1\"" "argv1=${argv1}")
  TestAssertTrue("\"${argv2}\" STREQUAL \"2;3\"" "argv2=${argv2}")
endmacro()

function(TestCase_macro_A_no_args)
  test_macro_A_no_args(0 1;2\;3 "4 5" ${test_seq_01})

  list(GET argn 0 argn0)
  list(GET argn 1 argn1)
  list(GET argn 2 argn2)
  list(GET argn 3 argn3)
  list(GET argn 4 argn4)
  list(GET argn 5 argn5)
  list(GET argn 6 argn6)
  list(GET argn 7 argn7)

  TestAssertTrue("argn0 STREQUAL \"0\"" "argn0=${argn0}")
  TestAssertTrue("argn1 STREQUAL \"1\"" "argn1=${argn1}")
  TestAssertTrue("argn2 STREQUAL \"2\"" "argn2=${argn2}")
  TestAssertTrue("argn3 STREQUAL \"3\"" "argn3=${argn3}")
  TestAssertTrue("argn4 STREQUAL \"4 5\"" "argn4=${argn4}")
  TestAssertTrue("argn5 STREQUAL \"a\"" "argn5=${argn5}")
  TestAssertTrue("argn6 STREQUAL \"b\"" "argn6=${argn6}")
  TestAssertTrue("argn7 STREQUAL \"c\"" "argn7=${argn7}")
endfunction()

function(TestCase_macro_A_with_args)
  test_macro_A_with_args(0 1;2\;3 "4 5" ${test_seq_01})

  list(GET argn 0 argn3)
  list(GET argn 1 argn4)
  list(GET argn 2 argn5)
  list(GET argn 3 argn6)

  TestAssertTrue("argn3 STREQUAL \"4 5\"" "argn3=${argn3}")
  TestAssertTrue("argn4 STREQUAL \"a\"" "argn4=${argn4}")
  TestAssertTrue("argn5 STREQUAL \"b\"" "argn5=${argn5}")
  TestAssertTrue("argn6 STREQUAL \"c\"" "argn6=${argn6}")
endfunction()

TestModule_RunTestCases(
  TestCase_macro_A_no_args
  TestCase_macro_A_with_args
)
