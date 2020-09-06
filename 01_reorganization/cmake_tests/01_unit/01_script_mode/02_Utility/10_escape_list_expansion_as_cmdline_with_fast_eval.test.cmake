include(tacklelib/Eval)

# TODO:
#  Fix visibility of ARGV, ARGC, ARGV0..N in the first argument from the inside of the `tkl_test_assert_true` function.
#  Temporary workarounded is by usage of explicit arguments: argv0, argv1, argv2
#
function(test_macro_with_list_sep_escape argv0 argv1 argv2)
  tkl_test_assert_true("argv0 STREQUAL \"1\"" "1 argv0=${argv0}")
  if (argv0 STREQUAL "1")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv0=${argv0}")
  endif()

  tkl_test_assert_true("argv1 STREQUAL \"\"" "1 argv1=${argv1}")
  if (argv1 STREQUAL "")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv1=${argv1}")
  endif()

  tkl_test_assert_true("argv2 STREQUAL \"3\\\\;4\"" "1 argv2=${argv2}")
  if (argv2 STREQUAL "3\\;4")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv2=${argv2}")
  endif()
endfunction()

function(test_macro_wo_list_sep_escape argv0 argv1 argv2)
  tkl_test_assert_true("argv0 STREQUAL \"1\"" "1 argv0=${argv0}")
  if (argv0 STREQUAL "1")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv0=${argv0}")
  endif()

  tkl_test_assert_true("argv1 STREQUAL \"\"" "1 argv1=${argv1}")
  if (argv1 STREQUAL "")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv1=${argv1}")
  endif()

  tkl_test_assert_true("argv2 STREQUAL \"3\\\;4\"" "1 argv2=${argv2}")
  if (argv2 STREQUAL "3\;4")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv2=${argv2}")
  endif()
endfunction()

macro(test_func_with_list_sep_escape argv0 argv1 argv2)
  set(argv0 "${argv0}")
  set(argv1 "${argv1}")
  set(argv2 "${argv2}")

  tkl_test_assert_true("argv0 STREQUAL \"1\"" "1 argv0=${argv0}")
  if (argv0 STREQUAL "1")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv0=${argv0}")
  endif()

  tkl_test_assert_true("argv1 STREQUAL \"\"" "1 argv1=${argv1}")
  if (argv1 STREQUAL "")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv1=${argv1}")
  endif()

  tkl_test_assert_true("argv2 STREQUAL \"3\\;4\"" "1 argv2=${argv2}")
  if (argv2 STREQUAL "3\;4")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv2=${argv2}")
  endif()
endmacro()

macro(test_func_wo_list_sep_escape argv0 argv1 argv2)
  set(argv0 "${argv0}")
  set(argv1 "${argv1}")
  set(argv2 "${argv2}")

  tkl_test_assert_true("argv0 STREQUAL \"1\"" "1 argv0=${argv0}")
  if (argv0 STREQUAL "1")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv0=${argv0}")
  endif()

  tkl_test_assert_true("argv1 STREQUAL \"\"" "1 argv1=${argv1}")
  if (argv1 STREQUAL "")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv1=${argv1}")
  endif()

  tkl_test_assert_true("argv2 STREQUAL \"3\;4\"" "1 argv2=${argv2}")
  if (argv2 STREQUAL "3\;4")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv2=${argv2}")
  endif()
endmacro()


function(TestCase_macro_with_list_sep_escape_01)
  set(in_str "1;;3\;4")

  tkl_escape_list_expansion_as_cmdline(cmdline "${in_str}" 0 1)

  tkl_macro_fast_eval("test_macro_with_list_sep_escape(${cmdline})")
endfunction()

function(TestCase_macro_wo_list_sep_escape_01)
  set(in_str "1;;3\;4")

  tkl_escape_list_expansion_as_cmdline(cmdline "${in_str}")

  tkl_macro_fast_eval("test_macro_wo_list_sep_escape(${cmdline})")
endfunction()

function(TestCase_func_with_list_sep_escape_01)
  set(in_str "1;;3\;4")

  tkl_escape_list_expansion_as_cmdline(cmdline "${in_str}" 0 1)

  tkl_macro_fast_eval("test_func_with_list_sep_escape(${cmdline})")
endfunction()

function(TestCase_func_wo_list_sep_escape_01)
  set(in_str "1;;3\;4")

  tkl_escape_list_expansion_as_cmdline(cmdline "${in_str}")

  tkl_macro_fast_eval("test_func_wo_list_sep_escape(${cmdline})")
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_macro_with_list_sep_escape_01
  TestCase_macro_wo_list_sep_escape_01
  TestCase_func_with_list_sep_escape_01
  TestCase_func_wo_list_sep_escape_01
)
