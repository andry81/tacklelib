include(tacklelib/ForwardArgs)

#tkl_enable_test_dbg_msg()

# CAUTION
#   Use intermediate expansion stage to avoid substitution of the macro arguments!
#
set(empty "")

macro(test_macro)
  tkl_test_dbg_msg("ARGV=${ARGV} ARGV=${ARGV${empty}}")
  tkl_pushset_ARGVn_to_stack("${ARGV0}" "${ARGV1}" "${ARGV2}")
  tkl_test_dbg_msg("ARGV=${ARGV} ARGV=${ARGV${empty}}")
  tkl_pushset_ARGVn_to_stack(a b "" "")
  tkl_test_dbg_msg("ARGV=${ARGV} ARGV=${ARGV${empty}}")

  tkl_test_assert_true("ARGV STREQUAL \"a;b;;\"" "ARGV=$\\{ARGV}")
  if (ARGV STREQUAL "a;b;;")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV=$\\{ARGV}")
  endif()

  tkl_test_assert_true("ARGV0 STREQUAL \"a\"" "ARGV0=$\\{ARGV0}")
  if (ARGV0 STREQUAL "a")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV0=$\\{ARGV0}")
  endif()

  tkl_test_assert_true("ARGV1 STREQUAL \"b\"" "ARGV1=$\\{ARGV1}")
  if (ARGV1 STREQUAL "b")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV1=$\\{ARGV1}")
  endif()

  tkl_test_assert_true("ARGV2 STREQUAL \"\"" "ARGV2=$\\{ARGV2}")
  if (ARGV2 STREQUAL "")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV2=$\\{ARGV2}")
  endif()

  tkl_test_assert_true("ARGV3 STREQUAL \"\"" "ARGV3=$\\{ARGV3}")
  if (ARGV3 STREQUAL "")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV3=$\\{ARGV3}")
  endif()

  tkl_test_assert_true("ARGC EQUAL 4" "ARGC=$\\{ARGC}")
  if (ARGC EQUAL 4)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGC=$\\{ARGC}")
  endif()

  tkl_pop_ARGVn_from_stack()
  tkl_test_dbg_msg("ARGV=${ARGV} ARGV=$\\{ARGV}")

  tkl_test_assert_true("ARGV STREQUAL \"1;2;3\"" "ARGV=$\\{ARGV}")
  if (ARGV STREQUAL "1;2;3")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV=$\\{ARGV}")
  endif()

  tkl_test_assert_true("ARGV0 STREQUAL \"1\"" "ARGV0=$\\{ARGV0}")
  if (ARGV0 STREQUAL "1")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV0=$\\{ARGV0}")
  endif()

  tkl_test_assert_true("ARGV1 STREQUAL \"2\"" "ARGV1=$\\{ARGV1}")
  if (ARGV1 STREQUAL "2")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV1=$\\{ARGV1}")
  endif()

  tkl_test_assert_true("ARGV2 STREQUAL \"3\"" "ARGV2=$\\{ARGV2}")
  if (ARGV2 STREQUAL "3")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV2=$\\{ARGV2}")
  endif()

  tkl_test_assert_true("NOT DEFINED ARGV3" "ARGV3=$\\{ARGV3}")
  if (NOT DEFINED ARGV3)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV3=$\\{ARGV3}")
  endif()

  tkl_test_assert_true("ARGC EQUAL 3" "ARGC=$\\{ARGC}")
  if (ARGC EQUAL 3)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGC=$\\{ARGC}")
  endif()

  tkl_pop_ARGVn_from_stack()
endmacro()

tkl_copy_vars(. filtered_vars_list1)
test_macro(1 2 3)
tkl_copy_vars(. filtered_vars_list2)

list(REMOVE_ITEM filtered_vars_list2 filtered_vars_list1)

tkl_test_assert_true("filtered_vars_list1 STREQUAL filtered_vars_list2" "filtered_vars_list1=${filtered_vars_list1}\nfiltered_vars_list2=${filtered_vars_list2}")
