include(tacklelib/ForwardArgs)

function(test_func)
  tkl_set_func_args_ARGVn()
  tkl_pushset_macro_args_ARGVn_to_stack(a b "" "")

  tkl_test_assert_true("ARGV STREQUAL \"a;b;;\"" "ARGV=${ARGV}")
  tkl_test_assert_true("ARGV0 STREQUAL \"a\"" "ARGV0=${ARGV0}")
  tkl_test_assert_true("ARGV1 STREQUAL \"b\"" "ARGV1=${ARGV1}")
  tkl_test_assert_true("ARGV2 STREQUAL \"\"" "ARGV2=${ARGV2}")
  tkl_test_assert_true("ARGV3 STREQUAL \"\"" "ARGV3=${ARGV3}")
  tkl_test_assert_true("ARGC EQUAL 4" "ARGC=${ARGC}")

  tkl_pop_vars_ARGVn_from_stack()

  tkl_test_assert_true("ARGV STREQUAL \"1;2;3\"" "ARGV=${ARGV}")
  tkl_test_assert_true("ARGV0 STREQUAL \"1\"" "ARGV0=${ARGV0}")
  tkl_test_assert_true("ARGV1 STREQUAL \"2\"" "ARGV1=${ARGV1}")
  tkl_test_assert_true("ARGV2 STREQUAL \"3\"" "ARGV2=${ARGV2}")
  tkl_test_assert_true("NOT DEFINED ARGV3" "ARGV3=${ARGV3}")
  tkl_test_assert_true("ARGC EQUAL 3" "ARGC=${ARGC}")
endfunction()

tkl_copy_vars(. filtered_vars_list1)
test_func(1 2 3)
tkl_copy_vars(. filtered_vars_list2)

list(REMOVE_ITEM filtered_vars_list2 filtered_vars_list1)

tkl_test_assert_true("filtered_vars_list1 STREQUAL filtered_vars_list2" "filtered_vars_list1=${filtered_vars_list1}\nfiltered_vars_list2=${filtered_vars_list2}")
