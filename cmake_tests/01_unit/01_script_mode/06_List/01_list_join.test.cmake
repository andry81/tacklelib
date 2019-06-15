include(tacklelib/List)

#tkl_enable_test_dbg_msg()

set(l1 "1;2 3; 4 ")

tkl_list_join(joined_l1 l1 /)

tkl_test_assert_true("joined_l1 STREQUAL \"1/2 3/ 4 \"" "joined_l1=${joined_l1}")
