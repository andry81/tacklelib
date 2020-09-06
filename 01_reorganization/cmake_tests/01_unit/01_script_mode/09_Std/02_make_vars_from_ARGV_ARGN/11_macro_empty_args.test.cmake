include(tacklelib/ForwardArgs)

macro(test_empty_in_begin_01)
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)
  tkl_pop_ARGVn_from_stack()

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"\"" "1 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"2\"" "1 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 2" "1 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \";2\"" "1 argv=${argv}")
  tkl_test_assert_true("argn STREQUAL \";2\"" "1 argn=${argn}")
endmacro()

macro(test_empty_in_begin_02)
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)
  tkl_pop_ARGVn_from_stack()

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"2\"" "2 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"\"" "2 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 1" "2 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"2\"" "2 argv=${argv}")
  tkl_test_assert_true("argn STREQUAL \"2\"" "2 argn=${argn}")
endmacro()

macro(test_empty_in_mid_01)
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)
  tkl_pop_ARGVn_from_stack()

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "3 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"\"" "3 ARGV1=${ARGV1}")
  tkl_test_assert_true("\"${ARGV2}\" STREQUAL \"3\"" "3 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 3" "3 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1;;3\"" "3 argv=${argv}")
  tkl_test_assert_true("argn STREQUAL \"1;;3\"" "3 argn=${argn}")
endmacro()

macro(test_empty_in_mid_02)
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)
  tkl_pop_ARGVn_from_stack()

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "4 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"3\"" "4 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 2" "4 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1;3\"" "4 argv=${argv}")
  tkl_test_assert_true("argn STREQUAL \"1;3\"" "4 argn=${argn}")
endmacro()

macro(test_empty_in_end_01)
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)
  tkl_pop_ARGVn_from_stack()

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "5 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"\"" "5 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 2" "5 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1;\"" "5 argv=${argv}")
  tkl_test_assert_true("argn STREQUAL \"1;\"" "5 argn=${argn}")
endmacro()

macro(test_empty_in_end_02)
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" argv argn)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_vars_from_ARGV_ARGN_end(argv argn)
  tkl_pop_ARGVn_from_stack()

  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "6 ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"\"" "6 ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 1" "6 ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1\"" "6 argv=${argv}")
  tkl_test_assert_true("argn STREQUAL \"1\"" "6 argn=${argn}")
endmacro()

test_empty_in_begin_01("" 2)
test_empty_in_begin_02(;2)

test_empty_in_mid_01(1 "" 3)
test_empty_in_mid_02(1;;3)

test_empty_in_end_01(1 "")
test_empty_in_end_02(1;)
