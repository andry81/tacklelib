include(tacklelib/ForwardArgs)

function(dbg_message msg)
  #message("${msg}")
endfunction()

# CAUTION
#   Use intermediate expansion stage to avoid substitution of the macro arguments!
#
set(empty "")

macro(test_macro)
  dbg_message("ARGV=${ARGV} ARGV=${ARGV${empty}}")
  tkl_pushset_ARGVn_to_stack("${ARGV0}" "${ARGV1}" "${ARGV2}")
  dbg_message("ARGV=${ARGV} ARGV=${ARGV${empty}}")
  tkl_pushset_ARGVn_to_stack(a b "" "")
  dbg_message("ARGV=${ARGV} ARGV=${ARGV${empty}}")

  tkl_test_assert_true("ARGV STREQUAL \"a;b;;\"" "ARGV=${ARGV${empty}}")
  tkl_test_assert_true("ARGV0 STREQUAL \"a\"" "ARGV0=${ARGV0${empty}}")
  tkl_test_assert_true("ARGV1 STREQUAL \"b\"" "ARGV1=${ARGV1${empty}}")
  tkl_test_assert_true("ARGV2 STREQUAL \"\"" "ARGV2=${ARGV2${empty}}")
  tkl_test_assert_true("ARGV3 STREQUAL \"\"" "ARGV3=${ARGV3${empty}}")
  tkl_test_assert_true("ARGC EQUAL 4" "ARGC=${ARGC${empty}}")

  tkl_pop_ARGVn_from_stack()
  dbg_message("ARGV=${ARGV} ARGV=${ARGV${empty}}")

  tkl_test_assert_true("ARGV STREQUAL \"1;2;3\"" "ARGV=${ARGV${empty}}")
  tkl_test_assert_true("ARGV0 STREQUAL \"1\"" "ARGV0=${ARGV0${empty}}")
  tkl_test_assert_true("ARGV1 STREQUAL \"2\"" "ARGV1=${ARGV1${empty}}")
  tkl_test_assert_true("ARGV2 STREQUAL \"3\"" "ARGV2=${ARGV2${empty}}")
  tkl_test_assert_true("NOT DEFINED ARGV3" "ARGV3=${ARGV3${empty}}")
  tkl_test_assert_true("ARGC EQUAL 3" "ARGC=${ARGC${empty}}")
endmacro()

tkl_copy_vars(. filtered_vars_list1)
test_macro(1 2 3)
tkl_copy_vars(. filtered_vars_list2)

list(REMOVE_ITEM filtered_vars_list2 filtered_vars_list1)

tkl_test_assert_true("filtered_vars_list1 STREQUAL filtered_vars_list2" "filtered_vars_list1=${filtered_vars_list1}\nfiltered_vars_list2=${filtered_vars_list2}")
