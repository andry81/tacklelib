cmake_minimum_required(VERSION 3.14)

# at least cmake 3.14 is required for:
#   * CMAKE_ROLE property: https://cmake.org/cmake/help/latest/prop_gbl/CMAKE_ROLE.html#prop_gbl:CMAKE_ROLE
#

# at least cmake 3.9 is required for:
#   * Multiconfig generator detection support: https://cmake.org/cmake/help/v3.9/prop_gbl/GENERATOR_IS_MULTI_CONFIG.html
#

# at least cmake 3.3 is required for:
# * to use IN_LIST in if command: (https://cmake.org/cmake/help/v3.3/command/if.html )
#   `if(<variable|string> IN_LIST <variable>)`
#

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# Workaround for `list(JOIN ...)` implementation to workaround ;-escaped list implicit discarding.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/18946
#
function(ListJoin out_var in_list_var separator)
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
    string(REGEX REPLACE "([;])" "\\\\\\1" value "${value}")
    #list(LENGTH value len)
    #message("ListJoin: [${len}] value=${value}")
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
function(ListGet out_var in_list_var)
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
      string(REGEX REPLACE "([;])" "\\\\\\1" value "${value}")
      #list(LENGTH value value_len)
      #message("ListGet: index=${index} [${value_len}] value=${value}")
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
function(ListRemoveAt out_var in_list_var)
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
      string(REGEX REPLACE "([;])" "\\\\\\1" value "${value}")
      #list(LENGTH value value_len)
      #message("ListRemoveAt: index=${index} [${value_len}] value=${value}")
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
function(ListSublist out_var begin_index length in_list_var)
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
    string(REGEX REPLACE "([;])" "\\\\\\1" value "${value}")
    #list(LENGTH value value_len)
    #message("ListSublist: index=${index} [${value_len}] value=${value}")
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

# faster replacement of the ListRemoveAt for ranges
function(ListRemoveSublist out_var begin_index length in_list_var)
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
    string(REGEX REPLACE "([;])" "\\\\\\1" value "${value}")
    #list(LENGTH value value_len)
    #message("ListRemoveSublist: index=${index} [${value_len}] value=${value}")
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
      string(REGEX REPLACE "([;])" "\\\\\\1" value "${value}")
      #list(LENGTH value value_len)
      #message("ListRemoveSublist: index=${index} [${value_len}] value=${value}")
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

function(copy_variables)
  # ARGV0 - out_vars_all_list
  # ARGV1 - out_vars_filtered_list  (names)
  # ARGV2 - out_vars_values_list    (values)
  # ARGV3 - var_prefix_filter
  if (NOT ${ARGC} EQUAL 4)
    message(FATAL_ERROR "copy_variables function must be called with all 4 arguments")
  endif()

  get_cmake_property(${ARGV0} VARIABLES)

  # reduce intersection probability with the parent scope variables through the unique variable name prefix
  set(_24C487FA_var_name "")
  set(_24C487FA_var_name_prefix "")
  set(_24C487FA_var_value "")

  string(LENGTH "${ARGV3}" _24C487FA_var_prefix_filter_len)

  if (NOT _24C487FA_var_prefix_filter_len)
    message(FATAL_ERROR "ARGV3 must be not empty variable name prefix token")
  endif()

  set(${ARGV1} "")
  set(${ARGV2} ";") # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!

  foreach (_24C487FA_var_name IN LISTS ${ARGV0})
    string(SUBSTRING "${_24C487FA_var_name}" 0 ${_24C487FA_var_prefix_filter_len} _24C487FA_var_name_prefix)
    # copy values only from "parent scope" variables
    if (_24C487FA_var_name_prefix STREQUAL "${ARGV3}")
      continue()
    endif()

    # check for specific builtin variables
    string(SUBSTRING "${_24C487FA_var_name}" 0 3 _24C487FA_var_name_prefix)
    if (_24C487FA_var_name_prefix STREQUAL "ARG")
      continue()
    endif()

    list(APPEND ${ARGV1} "${_24C487FA_var_name}")
    #ListJoin(_24C487FA_var_value ${_24C487FA_var_name} "\;")
    # WORKAROUND: we have to replace because `list(APPEND` will join lists together
    string(REGEX REPLACE "([;])" "\\\\\\1" _24C487FA_var_value "${${_24C487FA_var_name}}")
    list(APPEND ${ARGV2} "${_24C487FA_var_value}")

    #message("${_24C487FA_var_name}=`${_24C487FA_var_value}`")
  endforeach()

  # remove 2 first dummy empty strings
  ListRemoveSublist(${ARGV2} 0 2 ${ARGV2})

  #list(LENGTH ${ARGV1} vars_len)
  #list(LENGTH ${ARGV2} vals_len)
  #
  #message(vars_len=${vars_len})
  #message(vals_len=${vals_len})

  set(${ARGV1} "${${ARGV1}}" PARENT_SCOPE)
  set(${ARGV2} "${${ARGV2}}" PARENT_SCOPE)
endfunction()

macro(include_and_echo path)
  message(STATUS "(*) Include: \"${path}\"")
  include(${path})
endmacro()

macro(unset_all var)
  unset(${var})
  unset(${var} CACHE)
endmacro()

# returns "." if paths are equal
function(subtract_absolute_paths from_path to_path var_out)
  string(TOLOWER "${from_path}" from_path_lower)
  string(TOLOWER "${to_path}" to_path_lower)

  if (NOT from_path_lower STREQUAL "")
    if (${to_path_lower} STREQUAL ${from_path_lower})
      set(${var_out} "." PARENT_SCOPE)
      return()
    else()
      file(RELATIVE_PATH rel_path ${to_path_lower} ${from_path_lower})
      if (DEFINED rel_path)
        string(SUBSTRING "${rel_path}" 0 2 rel_path_first_component)
        if(NOT rel_path_first_component STREQUAL ".." AND NOT rel_path STREQUAL from_path_lower)
          set(${var_out} ${rel_path} PARENT_SCOPE)
          return()
        endif()
      endif()
    endif()
  endif()

  set(${var_out} "" PARENT_SCOPE)
endfunction()

macro(make_argv_var_from_ARGV_begin joined_list)
  if (NOT "${ARGN}" STREQUAL "")
    message(FATAL_ERROR "make_argv_var_from_ARGV_begin must have only 1 argument")
  endif()

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(_BBD57550_argv_joined_list ";;${joined_list}")
endmacro()

macro(make_argv_var_from_ARGV_end)
  if (NOT ${ARGC} EQUAL 0)
    message(FATAL_ERROR "make_argv_var_from_ARGV_end must not have arguments")
  endif()

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(argv ";")
  set(_BBD57550_argv_joined_list_accum ";")

  set(_BBD57550_var_index 0)
  set(_BBD57550_argv_value "${ARGV${_BBD57550_var_index}}")

  # WORKAROUND: we have to replace because `list(APPEND` will join lists together
  string(REGEX REPLACE "([;])" "\\\\\\1" _BBD57550_argv_value "${_BBD57550_argv_value}")

  list(APPEND argv "${_BBD57550_argv_value}")
  list(APPEND _BBD57550_argv_joined_list_accum "${ARGV${_BBD57550_var_index}}")

  while (NOT _BBD57550_argv_joined_list STREQUAL _BBD57550_argv_joined_list_accum AND _BBD57550_var_index LESS 32) # with finite loop insurance
    math(EXPR _BBD57550_var_index "${_BBD57550_var_index}+1")

    set(_BBD57550_argv_value "${ARGV${_BBD57550_var_index}}")
    # WORKAROUND: we have to replace because `list(APPEND` will join lists together
    string(REGEX REPLACE "([;])" "\\\\\\1" _BBD57550_argv_value "${_BBD57550_argv_value}")
    list(APPEND argv "${_BBD57550_argv_value}")
    list(APPEND _BBD57550_argv_joined_list_accum "${ARGV${_BBD57550_var_index}}")
  endwhile()

  # remove 2 first dummy empty strings
  ListRemoveSublist(argv 0 2 argv)

  unset(_BBD57550_argv_joined_list)
  unset(_BBD57550_argv_joined_list_accum)
  unset(_BBD57550_var_index)
  unset(_BBD57550_argv_value)
endmacro()

macro(make_argn_var_from_ARGV_ARGN_begin argv_joined_list argn_joined_list)
  if (NOT "${ARGN}" STREQUAL "")
    message(FATAL_ERROR "make_argn_var_from_ARGV_ARGN_begin must have only 2 argument")
  endif()

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(_9E220B1D_argv_joined_list ";;${argv_joined_list}")
  set(_9E220B1D_argn_joined_list "${argn_joined_list}")
  set(_9E220B1D_argn_offset -1)
  if (NOT "${_9E220B1D_argn_joined_list}" STREQUAL "")
    string(FIND "${_9E220B1D_argv_joined_list}" "${_9E220B1D_argn_joined_list}" _9E220B1D_argn_offset REVERSE)
  endif()
endmacro()

macro(make_argn_var_from_ARGV_ARGN_end)
  if (NOT ${ARGC} EQUAL 0)
    message(FATAL_ERROR "make_argn_var_from_ARGV_ARGN_end must not have arguments")
  endif()

  if (_9E220B1D_argn_offset GREATER_EQUAL 0)
    # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
    set(argn ";")
    set(_9E220B1D_argv_joined_list_accum ";")

    string(SUBSTRING "${_9E220B1D_argv_joined_list}" 0 ${_9E220B1D_argn_offset} _9E220B1D_argv_joined_list_truncated)

    # truncate last empty element
    if (_9E220B1D_argv_joined_list_truncated MATCHES "(.*);$")
      set(_9E220B1D_argv_joined_list_truncated "${CMAKE_MATCH_1}")
    endif()

    set(_9E220B1D_var_index 0)

    while (NOT _9E220B1D_argv_joined_list_truncated STREQUAL _9E220B1D_argv_joined_list_accum AND _9E220B1D_var_index LESS 32) # with finite loop insurance
      list(APPEND _9E220B1D_argv_joined_list_accum "${ARGV${_9E220B1D_var_index}}")
      math(EXPR _9E220B1D_var_index "${_9E220B1D_var_index}+1")
    endwhile()

    while (NOT _9E220B1D_argv_joined_list STREQUAL _9E220B1D_argv_joined_list_accum AND _9E220B1D_var_index LESS 32) # with finite loop insurance
      set(_9E220B1D_argv_value "${ARGV${_9E220B1D_var_index}}")
      #message("[${_9E220B1D_var_index}] _9E220B1D_argv_value=${_9E220B1D_argv_value}")
      # WORKAROUND: we have to replace because `list(APPEND` will join lists together
      string(REGEX REPLACE "([;])" "\\\\\\1" _9E220B1D_argv_value "${_9E220B1D_argv_value}")
      list(APPEND argn "${_9E220B1D_argv_value}")
      list(APPEND _9E220B1D_argv_joined_list_accum "${ARGV${_9E220B1D_var_index}}")

      math(EXPR _9E220B1D_var_index "${_9E220B1D_var_index}+1")
    endwhile()

    # remove 2 first dummy empty strings
    ListRemoveSublist(argn 0 2 argn)

    unset(_9E220B1D_argv_joined_list_accum)
    unset(_9E220B1D_var_index)
    unset(_9E220B1D_argv_value)
  else()
    set(argn "")
  endif()

  unset(_9E220B1D_argv_joined_list)
  unset(_9E220B1D_argn_joined_list)
  unset(_9E220B1D_argn_offset)
endmacro()

# CAUTION:
#   Function must be without arguments to:
#   1. support optional leading arguments like flags beginning by the `-` character
#
# Usage:
#   [<flags>] <out_var>
#
# flags:
#   -P - Enumerate script arguments (including a script absolute file path) instead of a cmake process arguments
#     (for the sciprt mode only, where the cmake has called with the `-P` flag).
#
function(make_argv_var_from_CMAKE_ARGV_ARGC) # WITH OUT ARGUMENTS!
  make_argn_var_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}")
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  make_argn_var_from_ARGV_ARGN_end()

  list(LENGTH argn argn_len)
  set(argn_index 0)
  set(set_script_args 0)

  # parse flags until no flags
  parse_function_optional_flags_into_vars(
    argn_index
    argn
    "P"
    ""
    "P\;set_script_args"
    "")

  if (NOT argn_index LESS argn_len)
    message(FATAL_ERROR "make_argv_var_from_CMAKE_ARGV_ARGC function must be called at least with 1 not optional argument: argn_len=${argn_len} argn_index=${argn_index}")
  endif()

  IsCmakeRole(SCRIPT is_in_script_mode)
  if (NOT is_in_script_mode)
    message(FATAL_ERROR "call must be made from the script mode only")
  endif()

  list(GET argn ${argn_index} out_var)
  math(EXPR argn_index "${argn_index}+1")

  set(${out_var} "")
  set(cmake_arg_index 0)

  if (NOT set_script_args)
    while(cmake_arg_index LESS CMAKE_ARGC)
      list(APPEND ${out_var} "${CMAKE_ARGV${cmake_arg_index}}")
      math(EXPR cmake_arg_index "${cmake_arg_index}+1")
    endwhile()
  else()
    get_filename_component(this_script_file_path_abs "${CMAKE_SCRIPT_MODE_FILE}" ABSOLUTE)

    set(script_file_path_offset -1)
    while(cmake_arg_index LESS CMAKE_ARGC)
      set(arg_value "${CMAKE_ARGV${cmake_arg_index}}")
      if (script_file_path_offset GREATER_EQUAL 0 )
        if (script_file_path_offset LESS cmake_arg_index)
          # WORKAROUND: we have to replace because `list(APPEND` will join lists together
          string(REGEX REPLACE "([;])" "\\\\\\1" arg_value "${arg_value}")
          list(APPEND ${out_var} "${arg_value}")
        else()
          # Parse the value as a path to the script file, convert to the absolute path and
          # then compare on equality with the absolute path in the CMAKE_SCRIPT_MODE_FILE variable.
          get_filename_component(script_file_path_abs "${arg_value}" ABSOLUTE)
          if (NOT this_script_file_path_abs STREQUAL script_file_path_abs)
            message(FATAL_ERROR "path to this script file and a command line argument after the `-P` option must be the same")
          endif()
          list(APPEND ${out_var} "${script_file_path_abs}") # converted into the absolute path
        endif()
      else()
        if (arg_value STREQUAL "-P")
          math(EXPR script_file_path_offset "${cmake_arg_index}+1")
        endif()
      endif()

      math(EXPR cmake_arg_index "${cmake_arg_index}+1")
    endwhile()
  endif()

  set(${out_var} "${${out_var}}" PARENT_SCOPE)
endfunction()

function(set_ARGV)
  set(argv_index 0)

  while (argv_index LESS ${ARGC})
    set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
    math(EXPR argv_index "${argv_index}+1")
  endwhile()

  if (NOT "${ARGC}" STREQUAL "")
    set(ARGC_ "${ARGC}" PARENT_SCOPE)
  endif()
endfunction()

function(unset_ARGV)
  set(argv_index 0)

  while (argv_index LESS ARGC_)
    set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
    math(EXPR argv_index "${argv_index}+1")
  endwhile()

  unset(ARGC_ PARENT_SCOPE)
endfunction()

function(print_ARGV)
  set(argn_index 0)

  while(argn_index LESS ARGC_)
    message("ARGV${argn_index}=`${ARGV${argn_index}}`")
    math(EXPR argn_index "${argn_index}+1")
  endwhile()
endfunction()

# Usage:
#   <func_argv_index_var> <func_argv_var> <func_char_flags_list> <set0_params_list> <set1_params_list> <multichar_flag_params_list>
#
# func_argv_index_var:
#   Variable name to increment on each parsed function input flag argument.
#
# func_argv_var:
#   List variable name with a function input arguments.
#
# func_char_flags_list:
#   dash (single char) flag list.
#
# set0_params_list:
#   2 level nested list for dash (single char) flag associated character to `set(${varK_N} 0)` over associated variables.
#   Format:
#     [char_flag0\;var0_0[...\;var0_N][...;char_flagK\;varK_0[...\;varK_M]]]
#
# set1_params_list:
#   2 level nested list for dash (single char) flag associated character to `set(${varK_N} 1)` over associated variables.
#   Format:
#     [char_flag0\;var0_0[...\;var0_N][...;char_flagK\;varK_0[...\;varK_M]]]
#
# multichar_flag_params_list:
#   2 level nested list for double dash (multichar string) flag associated string to `set(${set1_varK} 1)` over associated variable and
#   to consume following parameters into associated variables by `set(${varK_N} ...)`.
#   Format:
#     [string_flag0\;set1_var0\;var0_0[...\;var0_N][...;string_flagK\;set1_varK\;varK_0[...\;varK_M]]]
#
macro(parse_function_optional_flags_into_vars func_argv_index_var func_argv_var func_char_flags_list set0_params_list set1_params_list multichar_flag_params_list)
  parse_function_optional_flags_into_vars_impl("${func_argv_index_var}" "${func_argv_var}" "${func_char_flags_list}"
    "${set0_params_list}" "${set1_params_list}" "${multichar_flag_params_list}" "")
endmacro()

function(parse_function_optional_flags_into_vars_impl func_argv_index_var func_argv_var func_char_flags_list set0_params_list set1_params_list multichar_flag_params_list flags_out_var)
  set(func_argv_index "${${func_argv_index_var}}")
  set(func_argv "${${func_argv_var}}")

  # parse flags until no flags
  list(GET func_argv 0 func_flags)
  # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
  string(REGEX REPLACE "([;])" "\\\\\\1" func_flags "${func_flags}")

  string(SUBSTRING "${func_flags}" 0 1 func_flags_prefix_char0)

  set(flags "")

  while (func_flags_prefix_char0 STREQUAL "-")
    string(LENGTH "${func_flags}" func_flags_len)
    if (1 LESS func_flags_len)
      string(SUBSTRING "${func_flags}" 1 1 func_flags_prefix_char1)
    else()
      set(func_flags_prefix_char1 "")
    endif()

    if (NOT func_flags_prefix_char1 STREQUAL "-")
      if (1 LESS func_flags_len)
        string(SUBSTRING "${func_flags}" 1 -1 func_flags_suffix)
      endif()

      if (NOT func_flags_suffix STREQUAL "")
        if (NOT func_char_flags_list STREQUAL "")
          foreach (char_flag ${func_char_flags_list})
            string(SUBSTRING "${char_flag}" 0 1 char_flag) # just in case
            string(REGEX REPLACE "[${char_flag}]" "" func_flags_next_suffix "${func_flags_suffix}")

            if (NOT func_flags_next_suffix STREQUAL func_flags_suffix)
              foreach (set0_params_sublist ${set0_params_list})
                list(SUBLIST set0_params_sublist 0 1 set0_char_flag)
                list(SUBLIST set0_params_sublist 1 -1 set0_vars_sublist)

                if (set0_char_flag STREQUAL char_flag)
                  foreach (set0_var IN LISTS set0_vars_sublist)
                    set(${set0_var} 0 PARENT_SCOPE)
                  endforeach()
                endif()
              endforeach()

              foreach (set1_params_sublist ${set1_params_list})
                list(SUBLIST set1_params_sublist 0 1 set1_char_flag)
                list(SUBLIST set1_params_sublist 1 -1 set1_vars_sublist)

                if (set1_char_flag STREQUAL char_flag)
                  foreach (set1_var IN LISTS set1_vars_sublist)
                    set(${set1_var} 1 PARENT_SCOPE)
                  endforeach()
                endif()
              endforeach()
            endif()

            set(func_flags_suffix "${func_flags_next_suffix}")
          endforeach()
        else()
          set(func_flags_suffix .) # just to ignore below check
        endif()
      endif()

      if (NOT func_flags_suffix STREQUAL "")
        message(FATAL_ERROR "flags is not recognized: `${func_flags}`")
      endif()

      if (NOT flags_out_var STREQUAL "")
        list(APPEND flags "${func_flags}")
      endif()

      math(EXPR func_argv_index "${func_argv_index}+1")
    else()
      set(is_multichar_flag_processed 0)

      if (2 LESS func_flags_len)
        string(SUBSTRING "${func_flags}" 2 -1 func_flags_suffix)

        foreach (multichar_flag_params_sublist IN LISTS multichar_flag_params_list)
          list(SUBLIST multichar_flag_params_sublist 0 1 multichar_flag_string)
          list(LENGTH multichar_flag_params_sublist multichar_flag_params_sublist_len)

          if (multichar_flag_params_sublist_len GREATER 1)
            list(SUBLIST multichar_flag_params_sublist 1 1 multichar_flag_set1_var)
            if (multichar_flag_params_sublist_len GREATER 2)
              list(SUBLIST multichar_flag_params_sublist 2 -1 multichar_flag_vars_sublist)
            endif()
          endif()

          if (multichar_flag_params_sublist_len LESS 3)
            set(multichar_flag_vars_sublist "")
          endif()

          if (multichar_flag_string STREQUAL func_flags_suffix)
            set(is_multichar_flag_processed 1)
            math(EXPR func_argv_index "${func_argv_index}+1")

            if (NOT flags_out_var STREQUAL "")
              list(APPEND flags "${func_flags}")
            endif()

            if (multichar_flag_set1_var STREQUAL ".")
              set(multichar_flag_set1_var "")
            endif()

            if (NOT multichar_flag_set1_var STREQUAL "")
              set(${multichar_flag_set1_var} 1 PARENT_SCOPE)
            endif()

            # consume next arguments
            foreach (multichar_flag_var IN LISTS multichar_flag_vars_sublist)
              list(GET func_argv ${func_argv_index} multichar_flag_var_value)
              # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
              string(REGEX REPLACE "([;])" "\\\\\\1" multichar_flag_var_value_escaped "${multichar_flag_var_value}")

              if ((multichar_flag_var STREQUAL ".") OR (multichar_flag_var STREQUAL "*"))
                set(multichar_flag_var "")
              endif()

              if (NOT multichar_flag_var STREQUAL "")
                set(${multichar_flag_var} "${multichar_flag_var_value}" PARENT_SCOPE)
              endif()
              math(EXPR func_argv_index "${func_argv_index}+1")

              if (NOT flags_out_var STREQUAL "")
                list(APPEND flags "${multichar_flag_var_value_escaped}")
              endif()
            endforeach()

            break()
          endif()
        endforeach()
      endif()

      if (NOT is_multichar_flag_processed)
        message(FATAL_ERROR "unknown flag argument: `${func_flags}`")
      endif()
    endif()

    # read next flags
    list(GET func_argv ${func_argv_index} func_flags)
    # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
    string(REGEX REPLACE "([;])" "\\\\\\1" func_flags "${func_flags}")

    string(SUBSTRING "${func_flags}" 0 1 func_flags_prefix_char0)
  endwhile()

  set(${func_argv_index_var} ${func_argv_index} PARENT_SCOPE)

  if (NOT flags_out_var STREQUAL "")
    # append to already existed flags
    set(flags_out "${${flags_out_var}}")
    list(APPEND flags_out "${flags}")
    set(${flags_out_var} "${flags_out}" PARENT_SCOPE)
  endif()
endfunction()

function(make_cmdline_from_list out_var)
  set(cmdline "")

  foreach(arg IN LISTS ARGN)
    if (NOT arg STREQUAL "")
      string(REGEX REPLACE "([;\\\\\\\"])" "\\\\\\1" escaped_arg "${arg}")

      if(cmdline)
        if(NOT arg MATCHES "[;, \t\"]")
          set(cmdline "${cmdline} ${escaped_arg}")
        else()
          set(cmdline "${cmdline} \"${escaped_arg}\"")
        endif()
      else()
        if(NOT arg MATCHES "[;, \t\"]")
          set(cmdline "${escaped_arg}")
        else()
          set(cmdline "\"${escaped_arg}\"")
        endif()
      endif()
    else()
      if(cmdline)
        set(cmdline "${cmdline} \"\"")
      else()
        set(cmdline "\"\"")
      endif()
    endif()
  endforeach()

  set(${out_var} "${cmdline}" PARENT_SCOPE)
endfunction()

# To escape characters from cmake builtin escape discarder which will discard escaping
# from `;` and `\` characters on passing list items into function arguments.
function(escape_list_expansion out_var in_list)
  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(escaped_list ";")

  foreach(arg IN LISTS in_list)
    # 1. WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
    string(REGEX REPLACE "([;])" "\\\\\\1" escaped_arg "${arg}")
    # 2. another escape sequence to retain exact values in the list after pass into a function without quotes: `foo(${mylist})`
    string(REGEX REPLACE "([\\\\])" "\\\\\\1" escaped_arg "${escaped_arg}")
    #message("arg: `${arg}` -> `${escaped_arg}`")
    list(APPEND escaped_list "${escaped_arg}")
  endforeach()

  # remove 2 first dummy empty strings
  ListRemoveSublist(escaped_list 0 2 escaped_list)

  set(${out_var} "${escaped_list}" PARENT_SCOPE)
endfunction()

# Workaround for `file(LOCK ...)` to avoid immediate cmake exit in case of usage in the script mode.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/19007
#
function(FileLockFile file_path scope_type)
  IsCmakeRole(SCRIPT is_in_script_mode)
  if (NOT is_in_script_mode)
    file(LOCK "${file_path}" GUARD ${scope_type})
  else()
    file(LOCK "${file_path}")
  endif()
endfunction()

# CAUTION:
#   Function must be without arguments to:
#   1. support optional leading arguments like flags beginning by the `-` character
#
# Usage:
#   [<flags>] <out_file_path>
#
# flags:
#   --flock <flock_file>        - file lock to lock write into <out_file_path> file
#
# out_file_path:
#   File path to write in.
#
function(write_GENERATOR_IS_MULTI_CONFIG_into_file) # WITH OUT ARGUMENTS!
  make_argn_var_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}")
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  make_argn_var_from_ARGV_ARGN_end()

  list(LENGTH argn argn_len)
  set(argn_index 0)

  unset(flock_file_path)

  # parse flags until no flags
  parse_function_optional_flags_into_vars(
    argn_index
    argn
    ""
    ""
    ""
    "flock\;.\;flock_file_path")

  if (NOT argn_index LESS argn_len)
    message(FATAL_ERROR "write_GENERATOR_IS_MULTI_CONFIG_into_file function must be called at least with 1 not optional argument: argn_len=${argn_len} argn_index=${argn_index}")
  endif()

  if (DEFINED flock_file_path)
    get_filename_component(flock_file_path_abs "${flock_file_path}" ABSOLUTE)
    get_filename_component(flock_dir_path "${flock_file_path_abs}" DIRECTORY)
    if (NOT IS_DIRECTORY "${flock_dir_path}")
      message(FATAL_ERROR "--flock argument must be path to a file in existed directory: `${flock_file_path_abs}`")
    endif()
  endif()

  list(GET argn ${argn_index} out_file_path)
  math(EXPR argn_index "${argn_index}+1")

  get_property(GENERATOR_IS_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

  # create create/truncate output files and append values under flock
  if (DEFINED flock_file_path)
    FileLockFile("${flock_file_path}" FILE)
  endif()

  file(WRITE "${out_file_path}" "${GENERATOR_IS_MULTI_CONFIG}")

  if (DEFINED flock_file_path)
    file(LOCK "${flock_file_path}" RELEASE)
    file(REMOVE "${flock_file_path}")
  endif()
endfunction()

# portable role checker
function(IsCmakeRole role_name var_out)
  if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.14.0")
    # https://cmake.org/cmake/help/latest/prop_gbl/CMAKE_ROLE.html#prop_gbl:CMAKE_ROLE
    get_property(cmake_role GLOBAL PROPERTY CMAKE_ROLE)
    if (cmake_role STREQUAL role_name)
      set(${var_out} 1 PARENT_SCOPE)
    else()
      set(${var_out} 0 PARENT_SCOPE)
    endif()
  else()
    if (role_name STREQUAL "SCRIPT")
      # https://cmake.org/cmake/help/latest/variable/CMAKE_SCRIPT_MODE_FILE.html
      if (CMAKE_SCRIPT_MODE_FILE)
        set(${var_out} 1 PARENT_SCOPE)
      else()
        set(${var_out} 0 PARENT_SCOPE)
      endif()
    else()
      message(FATAL_ERROR "not implemented")
    endif()
  endif()
endfunction()

function(is_path_variable_by_name is_var_out var_name)
  # variable name endings
  set (var_ending_strs
    _ROOT _PATH _DIR _SUBDIR _DIRECTORY _SUBDIRECTORY _FILE
    _ROOTS _PATHS _DIRS _SUBDIRS _DIRECTORIES _SUBDIRECTORIES _FILES
    _INSTALL_PREFIX _FILE_PREFIX
    _INSTALL_PREFIXES _FILE_PREFIXES
    _LIB _LIBS
    _LIBRARY _LIBRARIES
    _INCLUDE _INCLUDES
    _INCLUDEDIR _LIBRARYDIR
    _INCLUDEDIRS _LIBRARYDIRS
    _LOCATION _LOCATIONS
    _SRC _SOURCE
    _SRCS _SOURCES
    _EXE _EXECUTABLE _EXECUTABLES
  )

  # variable name endings of all endings
  set (var_ending_of_ending_strs ";_LIST") # CAUTION: all must be in the upper case

  # complete variable names
  set (var_name_strs
    ROOT PATH DIR SUBDIR DIRECTORY SUBDIRECTORY FILE
    ROOTS PATHS DIRS SUBDIRS DIRECTORIES SUBDIRECTORIES FILES
    PREFIX INSTALL_PREFIX FILE_PREFIX
    PREFIXES INSTALL_PREFIXES FILE_PREFIXES
    LIB LIBS
    LIBRARY LIBRARIES
    INCLUDE INCLUDES
    INCLUDEDIR LIBRARYDIR
    INCLUDEDIRS LIBRARYDIRS
    LOCATION LOCATIONS
    SRC SOURCE
    SRCS SOURCES
    EXE EXECUTABLE EXECUTABLES
  ) # CAUTION: all must be in the upper case

  # check name ending at first
  foreach (var_ending_of_ending_str IN LISTS var_ending_of_ending_strs)
    string(LENGTH "${var_name}" var_name_len)
    string(TOUPPER "${var_name}" var_name_upper)

    #message("= [${var_name_len}] ${var_name_upper}")

    foreach (var_ending_str IN LISTS var_ending_strs)
      string(LENGTH "${var_ending_str}${var_ending_of_ending_str}" var_ending_str_len)
      if (var_name_len LESS var_ending_str_len)
        continue()
      endif()

      #message("== [${var_ending_str_len}] ${var_ending_str}${var_ending_of_ending_str}")

      if (var_ending_str_len LESS var_name_len)
        math(EXPR var_name_remainder_len "${var_name_len}-${var_ending_str_len}")
        string(SUBSTRING "${var_name_upper}" ${var_name_remainder_len} -1 var_name_ending_upper)
      else()
        set(var_name_ending_upper "${var_name_upper}")
      endif()

      #message("=== [${var_name_remainder_len}] ${var_name_ending_upper}\n")

      if (var_name_ending_upper STREQUAL "${var_ending_str}${var_ending_of_ending_str}")
        #message("var_name=`${var_name}` is PATH (ending=`${var_ending_str}${var_ending_of_ending_str}`)")
        set(${is_var_out} 1 PARENT_SCOPE)
        return()
      endif()
    endforeach()
  endforeach()

  # check complete names
  foreach (var_ending_of_ending_str IN LISTS var_ending_of_ending_strs)
    string(TOUPPER "${var_name}" var_name_upper)

    #message("= ${var_name_upper}")

    foreach (var_name_str IN LISTS var_name_strs)
      #message("== ${var_name_str}${var_ending_of_ending_str}")
      if ("${var_name_str}${var_ending_of_ending_str}" STREQUAL var_name_upper)
        #message("var_name=`${var_name}` is PATH")
        set(${is_var_out} 1 PARENT_SCOPE)
        return()
      endif()
    endforeach()
  endforeach()

  #message("var_name=`${var_name}` is not PATH")
  set(${is_var_out} 0 PARENT_SCOPE)
endfunction()
