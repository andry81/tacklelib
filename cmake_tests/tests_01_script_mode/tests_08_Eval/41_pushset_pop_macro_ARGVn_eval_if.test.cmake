include(tacklelib/ForwardArgs)
include(tacklelib/Eval)

function(dbg_message msg)
  #message("${msg}")
endfunction()

# CAUTION
#   Use intermediate expansion stage to avoid substitution of the macro arguments!
#
set(empty "")

macro(test_macro)
  tkl_pushset_ARGVn_to_stack(1 2 3)

  tkl_eval("\
if (ARGV STREQUAL \"1;2;3\")
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 \"ARGV=`$\{ARGV}`\")
endif()
if (ARGC EQUAL 3)
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 \"ARGC=`$\{ARGC}`\")
endif()
if (ARGV0 STREQUAL \"1\")
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 \"ARGV0=`$\{ARGV0}`\")
endif()
if (ARGV1 STREQUAL \"2\")
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 \"ARGV1=`$\{ARGV1}`\")
endif()
if (ARGV2 STREQUAL \"3\")
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 \"ARGV2=`$\{ARGV2}`\")
endif()
if (NOT DEFINED ARGV3)
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 \"ARGV3=`$\{ARGV3}`\")
endif()
")

  tkl_pop_ARGVn_from_stack()
endmacro()

test_macro(test_macro)
