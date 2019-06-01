# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_LIST_INCLUDE_DEFINED)
set(TACKLELIB_LIST_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.7)

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# at least cmake 3.3 is required for:
# * to use IN_LIST in if command: (https://cmake.org/cmake/help/v3.3/command/if.html )
#   `if(<variable|string> IN_LIST <variable>)`
#

# CMake Warning (dev) at ... (list):
#  Policy CMP0007 is not set: list command no longer ignores empty elements.
#  Run "cmake --help-policy CMP0007" for policy details.  Use the cmake_policy
#  command to set the policy and suppress this warning. ...
#
cmake_policy(SET CMP0007 NEW)

# Workaround for `list(JOIN ...)` implementation to workaround ;-escaped list implicit discarding.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/18946
#
function(tkl_list_join out_var in_list_var separator)
  if ((separator STREQUAL ";") OR (separator STREQUAL "\;")) # check on builtin control separator to faster join
    set(${out_var} "${${in_list_var}}" PARENT_SCOPE)
    return()
  endif()

  set(joined_value "")

  set(in_list "${${in_list_var}}")
  #message("join: ${in_list}")

  set(index -1)

  list(LENGTH in_list in_list_len)

  foreach(value IN LISTS in_list)
    math(EXPR index "${index}+1")
    # WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
    string(REPLACE ";" "\;" value "${value}")
    #list(LENGTH value len)
    #message("tkl_list_join: [${len}] value=${value}")
    if (index)
      set(joined_value "${joined_value}${separator}${value}")
    else()
      set(joined_value "${value}")
    endif()
  endforeach()

  #message("joined: ${joined_value}")
  set(${out_var} "${joined_value}" PARENT_SCOPE)
endfunction()

# Workaround for `list(GET ...)` implementation to workaround ;-escaped list implicit discarding.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/18946
#
function(tkl_list_get out_var in_list_var)
  if ("${ARGN}" STREQUAL "")
    message(FATAL_ERROR "must have at least one index")
  endif()

  # CAUTION: empty list with one empty string treats as an empty list
  set(out_list "")
  set(left_list "")
  set(right_list "")

  set(in_list "${${in_list_var}}")

  list(LENGTH in_list in_list_len)

  if (NOT in_list_len)
    set(${out_var} "" PARENT_SCOPE)
    return()
  endif()

  set(index_list "${ARGN}")

  # WORKAROUND: number of empty strings at the beginning of a list to workaround empty elements in empty list collapsing issue
  set(num_first_empty_strings 0)
  set(is_collapse_passed 0)

  math(EXPR index_max "${in_list_len}-1")
  foreach(index RANGE ${index_max})
    if (index IN_LIST index_list)
      list(GET in_list ${index} value)
      # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
      string(REPLACE ";" "\;" value "${value}")
      #list(LENGTH value value_len)
      #message("tkl_list_get: index=${index} [${value_len}] value=${value}")
      # WORKAROUND: empty list with one empty string treats as an empty list
      if (is_collapse_passed OR (NOT value STREQUAL ""))
        list(APPEND right_list "${value}")
        set(is_collapse_passed 1)
      else()
        # both are empty, counting empty strings instead of appending it
        math(EXPR num_first_empty_strings "${num_first_empty_strings}+1")
      endif()
    endif()
  endforeach()

  # join together
  if (num_first_empty_strings GREATER 1)
    set(left_list ";") # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
    math(EXPR index_max "${num_first_empty_strings}-3")
    if (index_max GREATER_EQUAL 0)
      foreach (index RANGE ${index_max})
        list(APPEND left_list "")
      endforeach()
    endif()
    if (right_list)
      list(APPEND out_list "${left_list}" "${right_list}")
    else()
      set(out_list "${left_list}")
    endif()
  elseif (num_first_empty_strings)
    if (right_list)
      list(APPEND out_list "" "${right_list}")
    endif()
  else()
    set(out_list "${right_list}")
  endif()

  set(${out_var} "${out_list}" PARENT_SCOPE)
endfunction()

# Workaround for `list(REMOVE_AT ...)` implementation to workaround ;-escaped list implicit discarding.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/18946
#
function(tkl_list_remove_at out_var in_list_var)
  if ("${ARGN}" STREQUAL "")
    message(FATAL_ERROR "must have at least one index")
  endif()

  # CAUTION: empty list with one empty string treats as an empty list
  set(out_list "")
  set(left_list "")
  set(right_list "")

  set(in_list "${${in_list_var}}")

  list(LENGTH in_list in_list_len)

  if (NOT in_list_len)
    set(${out_var} "" PARENT_SCOPE)
    return()
  endif()

  set(index_list "${ARGN}")

  # WORKAROUND: number of empty strings at the beginning of a list to workaround empty elements in empty list collapsing issue
  set(num_first_empty_strings 0)
  set(is_collapse_passed 0)

  math(EXPR index_max "${in_list_len}-1")
  foreach(index RANGE ${index_max})
    if (NOT index IN_LIST index_list)
      list(GET in_list ${index} value)
      # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
      string(REPLACE ";" "\;" value "${value}")
      #list(LENGTH value value_len)
      #message("tkl_list_remove_at: index=${index} [${value_len}] value=${value}")
      # WORKAROUND: empty list with one empty string treats as an empty list
      if (is_collapse_passed OR (NOT value STREQUAL ""))
        list(APPEND right_list "${value}")
        set(is_collapse_passed 1)
      else()
        # both are empty, counting empty strings instead of appending it
        math(EXPR num_first_empty_strings "${num_first_empty_strings}+1")
      endif()
    endif()
  endforeach()

  # join together
  if (num_first_empty_strings GREATER 1)
    set(left_list ";") # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
    math(EXPR index_max "${num_first_empty_strings}-3")
    if (index_max GREATER_EQUAL 0)
      foreach (index RANGE ${index_max})
        list(APPEND left_list "")
      endforeach()
    endif()
    if (right_list)
      list(APPEND out_list "${left_list}" "${right_list}")
    else()
      set(out_list "${left_list}")
    endif()
  elseif (num_first_empty_strings)
    if (right_list)
      list(APPEND out_list "" "${right_list}")
    endif()
  else()
    set(out_list "${right_list}")
  endif()

  set(${out_var} "${out_list}" PARENT_SCOPE)
endfunction()

# Workaround for `list(SUBLIST ...)` implementation to workaround ;-escaped list implicit discarding.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/18946
#
function(tkl_list_sublist out_var begin_index length in_list_var)
  # CAUTION: empty list with one empty string treats as an empty list
  set(out_list "")
  set(left_list "")
  set(right_list "")

  set(in_list "${${in_list_var}}")

  list(LENGTH in_list in_list_len)

  if (NOT in_list_len)
    set(${out_var} "" PARENT_SCOPE)
    return()
  endif()

  set(index_list "${ARGN}")

  # WORKAROUND: number of empty strings at the beginning of a list to workaround empty elements in empty list collapsing issue
  set(num_first_empty_strings 0)
  set(is_collapse_passed 0)

  set(index ${begin_index})
  if (length GREATER_EQUAL 0)
    math(EXPR index_upper "${begin_index}+${length}")
  else()
    list(LENGTH ${in_list_var} index_upper)
  endif()

  while(index LESS index_upper)
    list(GET in_list ${index} value)
    # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
    string(REPLACE ";" "\;" value "${value}")
    #list(LENGTH value value_len)
    #message("tkl_list_sublist: index=${index} [${value_len}] value=${value}")
    # WORKAROUND: empty list with one empty string treats as an empty list
    if (is_collapse_passed OR (NOT value STREQUAL ""))
      list(APPEND right_list "${value}")
      set(is_collapse_passed 1)
    else()
      # both are empty, counting empty strings instead of appending it
      math(EXPR num_first_empty_strings "${num_first_empty_strings}+1")
    endif()

    math(EXPR index "${index}+1")
  endwhile()

  # join together
  if (num_first_empty_strings GREATER 1)
    set(left_list ";") # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
    math(EXPR index_max "${num_first_empty_strings}-3")
    if (index_max GREATER_EQUAL 0)
      foreach (index RANGE ${index_max})
        list(APPEND left_list "")
      endforeach()
    endif()
    if (right_list)
      list(APPEND out_list "${left_list}" "${right_list}")
    else()
      set(out_list "${left_list}")
    endif()
  elseif (num_first_empty_strings)
    if (right_list)
      list(APPEND out_list "" "${right_list}")
    endif()
  else()
    set(out_list "${right_list}")
  endif()

  set(${out_var} "${out_list}" PARENT_SCOPE)
endfunction()

# faster replacement of the `tkl_list_remove_at` for ranges
function(tkl_list_remove_sublist out_var begin_index length in_list_var)
  # CAUTION: empty list with one empty string treats as an empty list
  set(out_list "")
  set(left_list "")
  set(right_list "")

  set(in_list "${${in_list_var}}")

  list(LENGTH in_list in_list_len)

  if (NOT in_list_len)
    set(${out_var} "" PARENT_SCOPE)
    return()
  endif()

  set(index_list "${ARGN}")

  # WORKAROUND: number of empty strings at the beginning of a list to workaround empty elements in empty list collapsing issue
  set(num_first_empty_strings 0)
  set(is_collapse_passed 0)

  set(index 0)

  while(index LESS begin_index)
    list(GET in_list ${index} value)
    # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
    string(REPLACE ";" "\;" value "${value}")
    #list(LENGTH value value_len)
    #message("tkl_list_remove_sublist: index=${index} [${value_len}] value=${value}")
    # WORKAROUND: empty list with one empty string treats as an empty list
    if (is_collapse_passed OR (NOT value STREQUAL ""))
      list(APPEND right_list "${value}")
      set(is_collapse_passed 1)
    else()
      # both are empty, counting empty strings instead of appending it
      math(EXPR num_first_empty_strings "${num_first_empty_strings}+1")
    endif()

    math(EXPR index "${index}+1")
  endwhile()

  if (length GREATER_EQUAL 0)
    math(EXPR index "${begin_index}+${length}")

    while(index LESS in_list_len)
      list(GET in_list ${index} value)
      # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
      string(REPLACE ";" "\;" value "${value}")
      #list(LENGTH value value_len)
      #message("tkl_list_remove_sublist: index=${index} [${value_len}] value=${value}")
      # WORKAROUND: empty list with one empty string treats as an empty list
      if (is_collapse_passed OR (NOT value STREQUAL ""))
        list(APPEND right_list "${value}")
        set(is_collapse_passed 1)
      else()
        # both are empty, counting empty strings instead of appending it
        math(EXPR num_first_empty_strings "${num_first_empty_strings}+1")
      endif()

      math(EXPR index "${index}+1")
    endwhile()
  endif()

  # join together
  if (num_first_empty_strings GREATER 1)
    set(left_list ";") # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
    math(EXPR index_max "${num_first_empty_strings}-3")
    if (index_max GREATER_EQUAL 0)
      foreach (index RANGE ${index_max})
        list(APPEND left_list "")
      endforeach()
    endif()
    if (right_list)
      list(APPEND out_list "${left_list}" "${right_list}")
    else()
      set(out_list "${left_list}")
    endif()
  elseif (num_first_empty_strings)
    if (right_list)
      list(APPEND out_list "" "${right_list}")
    endif()
  else()
    set(out_list "${right_list}")
  endif()

  set(${out_var} "${out_list}" PARENT_SCOPE)
endfunction()

endif()
