include(tacklelib/ForwardArgs)

#tkl_enable_test_dbg_msg()

# CAUTION
#   Use intermediate expansion stage to avoid substitution of the macro arguments!
#

macro(test_macro)
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  tkl_pop_ARGVn_from_stack()

  # CAUTION:
  #   Avoid any call to `tkl_*` here, because it might has nested calls to `tkl_push*_ARGVn_*`/`tkl_pop_ARGVn_*`!
  #

  set(index 0)
  while(index LESS 33)
    # remember the state in a variable
    if (NOT DEFINED ARGV${index})
      set(assert_true_${index} 1)
    else()
      set(assert_true_${index} 0)
    endif()

    math(EXPR index ${index}+1)
  endwhile()

  # now can use any call to `tkl_*`

  set(index 0)
  while(index LESS 33)
    if (assert_true_${index})
      tkl_test_assert_true(1)
    else()
      tkl_test_assert_true(0 "2 ARGV${index}=${ARGV${index}}")
    endif()

    math(EXPR index ${index}+1)
  endwhile()
endmacro()

test_macro("" 2)
test_macro(;2)
