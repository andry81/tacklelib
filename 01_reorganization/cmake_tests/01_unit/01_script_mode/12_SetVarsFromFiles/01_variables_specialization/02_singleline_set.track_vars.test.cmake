include(tacklelib/SetVarsFromFiles)

#tkl_enable_test_dbg_msg()

tkl_copy_vars(. filtered_vars_list1)
tkl_load_vars_from_files("${TACKLELIB_TESTLIB_TESTMODULE_DIR}/refs/01_singleline_set.vars")
tkl_copy_vars(. filtered_vars_list2)

list(REMOVE_ITEM filtered_vars_list2 filtered_vars_list1)

set(vars_before ${filtered_vars_list1})
set(vars_after ${filtered_vars_list2})

list(REMOVE_ITEM vars_before ${filtered_vars_list2})
list(REMOVE_ITEM vars_after ${filtered_vars_list1})

set(vars_after_ref "n;s1;s2;s3;l;b1;b2;p1;p2")

list(SORT vars_after_ref)

tkl_test_assert_true("vars_before STREQUAL \"\"" "vars_before=${vars_before}")
tkl_test_assert_true("vars_after STREQUAL \"\${vars_after_ref}\"" "vars_after=${vars_after}")
