include(tacklelib/ForwardArgs)
include(tacklelib/Eval)

#tkl_enable_test_dbg_message()

# CAUTION
#   Use intermediate expansion stage to avoid substitution of the macro arguments!
#
set(empty "")

macro(test_ARGVn)
  tkl_test_assert_true("ARGV STREQUAL \"\"" "1 ARGV=${ARGV${empty}}")
  if (ARGV STREQUAL "")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 ARGV=${ARGV${empty}}")
  endif()

  tkl_test_assert_true("ARGC EQUAL 0" "1 ARGC=${ARGC${empty}}")
  if (ARGC EQUAL 0)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 ARGC=${ARGC${empty}}")
  endif()

  set(index 0)
  while(index LESS 33)
    tkl_test_assert_true("NOT DEFINED ARGV${index}" "1 ARGV${index}=${ARGV${index}}")
    if (NOT DEFINED ARGV${index})
      tkl_test_assert_true(1)
    else()
      tkl_test_assert_true(0 "2 ARGV${index}=${ARGV${index}}")
    endif()

    math(EXPR index ${index}+1)
  endwhile()
endmacro()

macro(test_macro)
  if (NOT DEFINED ARGV)
    message(222)
  endif()

  tkl_pushset_ARGVn_to_stack(1 2 3)

  tkl_eval("\
tkl_test_assert_true(\"ARGV STREQUAL \\\"1;2;3\\\"\" \"ARGV=`$\\{ARGV}`\")
tkl_test_assert_true(\"ARGC EQUAL 3\" \"ARGC=`$\\{ARGC}`\")
tkl_test_assert_true(\"ARGV0 STREQUAL \\\"1\\\"\" \"ARGV0=`$\\{ARGV0}`\")
tkl_test_assert_true(\"ARGV1 STREQUAL \\\"2\\\"\" \"ARGV1=`$\\{ARGV1}`\")
tkl_test_assert_true(\"ARGV2 STREQUAL \\\"3\\\"\" \"ARGV2=`$\\{ARGV2}`\")
tkl_test_assert_true(\"NOT DEFINED ARGV3\" \"ARGV3=`$\\{ARGV3}`\")
")

  tkl_pop_ARGVn_from_stack()

  test_ARGVn()

  tkl_eval("\
tkl_test_assert_true(\"ARGV STREQUAL \\\"\\\"\" \"ARGV=`$\\{ARGV}`\")
tkl_test_assert_true(\"ARGC EQUAL 0\" \"ARGC=`$\\{ARGC}`\")
tkl_test_assert_true(\"NOT DEFINED ARGV0\" \"ARGV0=`$\\{ARGV0}`\")
tkl_test_assert_true(\"NOT DEFINED ARGV1\" \"ARGV1=`$\\{ARGV1}`\")
tkl_test_assert_true(\"NOT DEFINED ARGV2\" \"ARGV2=`$\\{ARGV2}`\")
tkl_test_assert_true(\"NOT DEFINED ARGV3\" \"ARGV3=`$\\{ARGV3}`\")
")

  test_ARGVn()
endmacro()

test_macro()
