include(tacklelib/ForwardArgs)

#tkl_enable_test_dbg_msg()

macro(test_inner_macro)
  tkl_test_dbg_msg("ARGV=${ARGV} ARGC=${ARGC} ARGV0=${ARGV0} ARGV1=${ARGV1}")
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_var_from_ARGV_end(argv)
  tkl_pop_ARGVn_from_stack()
  
  tkl_test_assert_true("\"${ARGV0}\" STREQUAL \"1\"" "ARGV0=${ARGV0}")
  tkl_test_assert_true("\"${ARGV1}\" STREQUAL \"\"" "ARGV1=${ARGV1}")
  tkl_test_assert_true("${ARGC} EQUAL 1" "ARGC=${ARGC}")

  tkl_test_assert_true("argv STREQUAL \"1\"" "argv=${argv}")
endmacro()

macro(test_outter_macro)
  test_inner_macro(1)
endmacro()

test_outter_macro(x y)
