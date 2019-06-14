include(tacklelib/ForwardVariables)

tkl_copy_vars(. filtered_vars_list1)

set_property(GLOBAL PROPERTY "x" 111)
set_property(GLOBAL PROPERTY "y") # unset property

tkl_pushunset_prop_to_stack(. GLOBAL "x" test)
tkl_pushunset_prop_to_stack(. GLOBAL "y" test)

get_property(a GLOBAL PROPERTY "x")
get_property(b GLOBAL PROPERTY "y")

tkl_test_assert_true("NOT DEFINED a" "1 a=${a}")
if (NOT DEFINED a) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "2 a=${a}")
endif()

tkl_test_assert_true("NOT DEFINED b" "2 b=${b}")
if (NOT DEFINED b) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "2 b=${b}")
endif()

tkl_pop_prop_from_stack(a GLOBAL "x" test)
tkl_pop_prop_from_stack(b GLOBAL "y" test)

tkl_test_assert_true("a STREQUAL \"111\"" "3 a=${a}")

tkl_test_assert_true("NOT DEFINED b" "4 b=${b}")
if (NOT DEFINED b) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "5 b=${b}")
endif()

get_property(a GLOBAL PROPERTY "x")
get_property(b GLOBAL PROPERTY "y")

tkl_test_assert_true("a STREQUAL \"111\"" "3 a=${a}")

tkl_test_assert_true("NOT DEFINED b" "4 b=${b}")
if (NOT DEFINED b) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "5 b=${b}")
endif()

tkl_copy_vars(. filtered_vars_list2)

list(REMOVE_ITEM filtered_vars_list2 filtered_vars_list1;a)

tkl_test_assert_true("filtered_vars_list1 STREQUAL filtered_vars_list2" "filtered_vars_list1=${filtered_vars_list1}\nfiltered_vars_list2=${filtered_vars_list2}")
