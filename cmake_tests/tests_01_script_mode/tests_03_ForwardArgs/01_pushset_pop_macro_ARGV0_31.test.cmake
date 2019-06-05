include(tacklelib/ForwardArgs)

function(dbg_message msg)
  #message("${msg}")
endfunction()

# CAUTION
#   Use intermediate expansion stage to avoid substitution of the macro arguments!
#
set(empty "")

macro(test_macro)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  tkl_pop_ARGVn_from_stack()

  tkl_test_assert_true("NOT DEFINED ARGV0" "ARGV0=${ARGV0${empty}}")
  if (NOT DEFINED ARGV0)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV0=${ARGV0${empty}}")
  endif()
  tkl_test_assert_true("NOT DEFINED ARGV1" "ARGV1=${ARGV1${empty}}")
  if (NOT DEFINED ARGV1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV1=${ARGV1${empty}}")
  endif()
  tkl_test_assert_true("NOT DEFINED ARGV2" "ARGV2=${ARGV2${empty}}")
  if (NOT DEFINED ARGV2)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "ARGV2=${ARGV2${empty}}")
  endif()
endmacro()

test_macro("" 2)
test_macro(;2)
