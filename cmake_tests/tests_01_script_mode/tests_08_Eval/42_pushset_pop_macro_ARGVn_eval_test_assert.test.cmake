include(tacklelib/ForwardArgs)
include(tacklelib/Eval)

function(dbg_message msg)
  #message("${msg}")
endfunction()

# CAUTION
#   Use intermediate expansion stage to avoid substitution of the macro arguments!
#

macro(test_macro)
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
endmacro()

test_macro(test_macro)
