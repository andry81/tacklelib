# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_MATH_INCLUDE_DEFINED)
set(TACKLELIB_MATH_INCLUDE_DEFINED 1)

# To workaround absence of an integer power arithmetic in the cmake.
#
function(tkl_uint_power_of out_int_var int_num int_power)
  if (int_num LESS 0)
    message(FATAL_ERROR "int_num must be unsigned value")
  endif()
  if (int_power LESS 0)
    message(FATAL_ERROR "int_power must be unsigned value")
  endif()
  if (int_num EQUAL 0 AND int_power EQUAL 0)
    message(FATAL_ERROR "int_num and int_power can not be both equal to 0")
  endif()

  if (int_num)
    if (int_power GREATER 0)
      set(powered_num ${int_num})

      if (int_power GREATER 1)
        math(EXPR upper_bound ${int_power}-2)

        foreach(index RANGE ${upper_bound})
          math(EXPR powered_num ${powered_num}*${int_num})
        endforeach()
      endif()

      set(${out_int_var} ${powered_num} PARENT_SCOPE)
    else()
      set(${out_int_var} 1 PARENT_SCOPE)
    endif()
  else()
    set(${out_int_var} 0 PARENT_SCOPE)
  endif()
endfunction()

# To workaround absence of a floating point arithmetic in the cmake.
#
function(tkl_uint_div out_int_var out_frac_str_var max_frac_digits int_num int_denom)
  if (int_num LESS 0)
    message(FATAL_ERROR "int_num must be unsigned value")
  endif()
  if (NOT int_denom GREATER 0)
    message(FATAL_ERROR "int_denom must be positive value")
  endif()

  if (int_num)
    math(EXPR int_value ${int_num}/${int_denom})
    if (int_num GREATER int_denom)
      math(EXPR remainder_value ${int_num}%${int_denom})
    elseif (int_num LESS int_denom)
      set(remainder_value ${int_num})
    else()
      set(remainder_value 0)
    endif()

    if (max_frac_digits GREATER 0)
      if (int_num LESS int_denom OR remainder_value)
        tkl_uint_power_of(decimal_power 10 ${max_frac_digits})
        math(EXPR frac_value ${remainder_value}*${decimal_power}/${int_denom})

        # complement `frac_value` with leading zeros up to `max_frac_digits` digits
        string(LENGTH "${frac_value}" frac_value_len)
        set(frac_str_value "")
        if (frac_value_len LESS max_frac_digits)
          math(EXPR frac_value_upper_bound ${max_frac_digits}-${frac_value_len}-1)
          foreach(index RANGE ${frac_value_upper_bound})
            set(frac_str_value "${frac_str_value}0")
          endforeach()
        elseif (NOT frac_value_len EQUAL max_frac_digits)
          message(FATAL_ERROR "internal frac_value accumulation error")
        endif()
        set(frac_str_value "${frac_str_value}${frac_value}")
      else()
        set(frac_str_value 0)
      endif()
    else()
      set(frac_str_value "")
    endif()
  else()
    set(int_value 0)
    if (max_frac_digits GREATER 0)
      set(frac_str_value 0)
    else()
      set(frac_str_value "")
    endif()
  endif()

  set(${out_int_var} ${int_value} PARENT_SCOPE)
  set(${out_frac_str_var} "${frac_str_value}" PARENT_SCOPE)
endfunction()

# To workaround absence of a floating point arithmetic in the cmake.
#
function(tkl_uint_frac_div out_int_var out_frac_str_var max_frac_digits int_num int_frac_str int_denom)
  if (NOT int_frac_str STREQUAL "" AND int_frac_str LESS 0)
    message(FATAL_ERROR "int_frac must be unsigned value")
  endif()

  if (int_frac_str STREQUAL "")
    set(int_frac_str 0)
  endif()

  # 9 digits after the point is related to the `int` type decimal digits width in the `C` language (32-bit cmake)
  tkl_uint_div(int_value frac_str_value 9 ${int_num} ${int_denom})
  if (max_frac_digits GREATER 0)
    # convert `frac_str_value` from a string into an integer without leading zeros
    string(REGEX REPLACE "^0+" "" frac_value "${frac_str_value}")
    if (frac_value STREQUAL "")
      set(frac_value 0)
    endif()

    string(LENGTH "${int_frac_str}" int_frac_str_len)
    if (int_frac_str_len GREATER 9)
      string(SUBSTRING "${int_frac_str}" 0 9 int_frac_str)
    endif()

    # convert `int_frac_str` from a string into an integer without leading zeros
    string(REGEX REPLACE "^0+" "" int_frac_value "${int_frac_str}")
    if (int_frac_value STREQUAL "")
      set(int_frac_value 0)
    endif()

    if (int_frac_value AND int_frac_str_len LESS 9)
      math(EXPR int_frac_str_len_remainder 9-${int_frac_str_len})
      tkl_uint_power_of(int_frac_str_decimal_multiplier 10 ${int_frac_str_len_remainder})
      math(EXPR int_frac_value ${int_frac_value}*${int_frac_str_decimal_multiplier})
    endif()

    math(EXPR divided_int_frac_int_value ${int_frac_value}/${int_denom})

    # add to a fraction a divided fraction
    math(EXPR frac_value ${frac_value}+${divided_int_frac_int_value})

    # complement `frac_value` with leading zeros up to 9 digits
    string(LENGTH "${frac_value}" frac_value_len)
    set(frac_value_str "")
    if (frac_value_len LESS 9)
      math(EXPR frac_value_upper_bound 9-${frac_value_len}-1)
      foreach(index RANGE ${frac_value_upper_bound})
        set(frac_value_str "${frac_value_str}0")
      endforeach()
    elseif (NOT frac_value_len EQUAL 9)
      message(FATAL_ERROR "internal frac_value accumulation error")
    endif()
    set(frac_value_str "${frac_value_str}${frac_value}")

    string(LENGTH "${frac_value_str}" frac_value_str_len)
    if (frac_value_str_len GREATER max_frac_digits)
      string(SUBSTRING "${frac_value_str}" 0 ${max_frac_digits} frac_str_value)
    else()
      set(frac_str_value "${frac_value_str}")
    endif()
  else()
    set(frac_str_value "")
  endif()

  set(${out_int_var} ${int_value} PARENT_SCOPE)
  set(${out_frac_str_var} "${frac_str_value}" PARENT_SCOPE)
endfunction()

endif()
