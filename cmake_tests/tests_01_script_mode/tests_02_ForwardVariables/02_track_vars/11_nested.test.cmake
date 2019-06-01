include(tacklelib/ForwardVariables)

function(test_inner_track_vars)
  tkl_begin_track_vars()

  set(a 111)
  unset(b)

  tkl_forward_changed_vars_to_parent_scope()
  tkl_end_track_vars()
endfunction()

function(test_outter_track_vars)
  tkl_begin_track_vars()

  test_inner_track_vars()
  set(c 333)
  unset(d)

  tkl_forward_changed_vars_to_parent_scope()
  tkl_end_track_vars()
endfunction()

set(b 222)
set(d 444)

tkl_copy_vars(. filtered_vars_list1)
test_outter_track_vars()
tkl_copy_vars(. filtered_vars_list2)

list(REMOVE_ITEM filtered_vars_list2 filtered_vars_list1)

tkl_test_assert_true("a STREQUAL \"111\"" "1 a=${a}")

tkl_test_assert_true("NOT DEFINED b" "2 b=${b}")
if (NOT DEFINED b) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "3 b=${b}")
endif()

tkl_test_assert_true("c STREQUAL \"333\"" "4 c=${c}")

tkl_test_assert_true("NOT DEFINED d" "5 d=${d}")
if (NOT DEFINED d) # double check
  tkl_test_assert_true(1)
else()
  tkl_test_assert_true(0 "6 d=${d}")
endif()

set(vars_before ${filtered_vars_list1})
set(vars_after ${filtered_vars_list2})

list(REMOVE_ITEM vars_before ${filtered_vars_list2})
list(REMOVE_ITEM vars_after ${filtered_vars_list1})

tkl_test_assert_true("vars_before STREQUAL \"b;d\"" "vars_before=${vars_before}")
tkl_test_assert_true("vars_after STREQUAL \"a;c\"" "vars_after=${vars_after}")
