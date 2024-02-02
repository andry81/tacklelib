# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_FORWARD_VARIABLES_INCLUDE_DEFINED)
set(TACKLELIB_FORWARD_VARIABLES_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.7)

# at least cmake 3.3 is required for:
# * to use IN_LIST in if command: (https://cmake.org/cmake/help/v3.3/command/if.html )
#   `if(<variable|string> IN_LIST <variable>)`
#

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# NOTE:
#   Read the doc/02_general_variables_set_rules.txt`
#   for variables set rules represented here.
#

include(tacklelib/String)
include(tacklelib/List)
include(tacklelib/Props)

function(tkl_is_var _5C580E6F_out_is_var_def _5C580E6F_var_name)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "if (DEFINED ${_5C580E6F_var_name})" still can be applied to a local variable!
  #

  if(("${_5C580E6F_out_is_var_def}" STREQUAL "") OR ("${_5C580E6F_out_is_var_def}" STREQUAL "${_5C580E6F_var_name}"))
    message(FATAL_ERROR "out_is_var_def must be not empty and not equal to var_name: out_is_var_def=`${_5C580E6F_out_is_var_def}` var_name=`${_5C580E6F_var_name}`")
  endif()
  if("${_5C580E6F_var_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty")
  endif()

  if (("${_5C580E6F_var_name}" STREQUAL ".") OR (NOT DEFINED ${_5C580E6F_var_name}))
    set(${_5C580E6F_out_is_var_def} 0 PARENT_SCOPE)
  endif()

  get_cmake_property(_5C580E6F_vars_list VARIABLES)

  list(FIND _5C580E6F_vars_list ${_5C580E6F_var_name} _5C580E6F_var_index)
  if(NOT _5C580E6F_var_index EQUAL -1)
    set(${_5C580E6F_out_is_var_def} 1 PARENT_SCOPE)
  else()
    set(${_5C580E6F_out_is_var_def} 0 PARENT_SCOPE)
  endif()
endfunction()

macro(tkl_is_ARGV_var out_is_var_def var_name)
  if ("${var_name}" STREQUAL "ARGV" OR
      "${var_name}" MATCHES "^ARGV[0-9]\$|^ARGV[1-9][0-9]+\$")
    set(${out_is_var_def} 1)
  else()
    set(${out_is_var_def} 0)
  endif()
endmacro()

macro(tkl_is_ARGx_var out_is_var_def var_name)
  if ("${var_name}" STREQUAL "ARGV" OR
      "${var_name}" STREQUAL "ARGN" OR
      "${var_name}" STREQUAL "ARGC" OR
      "${var_name}" MATCHES "^ARGV[0-9]\$|^ARGV[1-9][0-9]+\$")
    set(${out_is_var_def} 1)
  else()
    set(${out_is_var_def} 0)
  endif()
endmacro()

# CAUTION:
# 1. User must not use builtin ARGC/ARGV/ARGN/ARGV0..N variables because they are a part of function/macro call stack
#
function(tkl_get_var out_uncached_var out_cached_var var_name)
  if ("${var_name}" STREQUAL "" OR "${var_name}" STREQUAL ".")
    message(FATAL_ERROR "var_name must be not empty and valid")
  endif()

  if (NOT "${out_uncached_var}" STREQUAL "" AND NOT "${out_uncached_var}" STREQUAL ".")
    set(out_uncached_var_defined 1)
  else()
    set(out_uncached_var_defined 0)
  endif()

  if (NOT "${out_cached_var}" STREQUAL "" AND NOT "${out_cached_var}" STREQUAL ".")
    set(out_cached_var_defined 1)
  else()
    set(out_cached_var_defined 0)
  endif()

  if (NOT out_uncached_var_defined AND NOT out_cached_var_defined)
    message(FATAL_ERROR "at least one output variable must be defined")
  endif()

  if (out_uncached_var_defined)
    if ("${out_uncached_var}" STREQUAL "${var_name}")
      message(FATAL_ERROR "out_uncached_var and var_name variables must be different: `${out_uncached_var}`")
    endif()
  endif()

  if (out_uncached_var_defined OR out_cached_var_defined)
    if ("${out_uncached_var}" STREQUAL "${out_cached_var}")
      message(FATAL_ERROR "out_uncached_var and out_cached_var variables must be different: `${out_cached_var}`")
    endif()
  endif()

  # check for specific builtin variables
  tkl_is_ARGx_var(is_ARGx_var "${var_name}")
  if (is_ARGx_var)
    message(FATAL_ERROR "specific builtin variables are forbidden to use: `${var_name}`")
  endif()

  # `if (DEFINED CACHE{...})` is supported from 3.14.0: https://cmake.org/cmake/help/v3.14/release/3.14.html#commands
  if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.14.0")
    if (DEFINED CACHE{${var_name}})
      set(var_cache_value_is_set 1)
    else()
      set(var_cache_value_is_set 0)
    endif()
  else()
    get_property(var_cache_value_is_set CACHE "${var_name}" PROPERTY VALUE SET)
  endif()

  if (NOT var_cache_value_is_set)
    # propagate uncached variant of a variable
    if (out_uncached_var_defined)
      if (DEFINED ${var_name})
        set(${out_uncached_var} "${${var_name}}" PARENT_SCOPE)
      else()
        unset(${out_uncached_var} PARENT_SCOPE)
      endif()
    endif()

    # propagate cached variant of a variable
    if (out_cached_var_defined)
      unset(${out_cached_var} PARENT_SCOPE)
    endif()
  else()
    # save cache properties of a variable
    get_property(var_cache_value CACHE "${var_name}" PROPERTY VALUE)
    get_property(var_cache_type CACHE "${var_name}" PROPERTY TYPE)
    get_property(var_cache_docstring CACHE "${var_name}" PROPERTY HELPSTRING)

    # remove cached variant of a variable to avoid interference with the cache
    unset(${var_name} CACHE)

    # propagate uncached variant of a variable
    if (DEFINED ${var_name})
      set(${out_uncached_var} "${${var_name}}" PARENT_SCOPE)
    else()
      unset(${out_uncached_var} PARENT_SCOPE)
    endif()

    # propagate cached variant of a variable
    if (out_cached_var_defined)
      set(${out_cached_var} "${var_cache_value}" PARENT_SCOPE)
    endif()

    # restore cache properties of a variable
    #message("set(${var_name} `${var_cache_value}` CACHE `${var_cache_type}` `${var_cache_docstring}`)")
    set(${var_name} "${var_cache_value}" CACHE ${var_cache_type} "${var_cache_docstring}")

    # no need to restore not cache value here, because we are in a function scope
  endif()
endfunction()

function(tkl_copy_vars)
  # ARGV0 - out_vars_all_list
  # ARGV1 - out_vars_filtered_list  (names)
  # ARGV2 - out_vars_values_list    (values)
  # ARGV3 - var_prefix_filter
  if (NOT ${ARGC} GREATER_EQUAL 1)
    message(FATAL_ERROR "function must have at least 1 argument")
  endif()

  # unset because ARGVn can inherit from upper caller scope
  if (${ARGC} LESS 4)
    unset(ARGV3)
    if (${ARGC} LESS 3)
      unset(ARGV2)
      if (${ARGC} LESS 2)
        unset(ARGV1)
      endif()
    endif()
  endif()

  # reduce intersection probability with the parent scope variables through the unique local variable name prefix
  get_cmake_property(_24C487FA_vars_all_list VARIABLES)

  set(_24C487FA_var_name "")
  set(_24C487FA_var_name_prefix "")
  set(_24C487FA_var_value "")

  if (NOT "${ARGV3}" STREQUAL "" AND NOT "${ARGV3}" STREQUAL ".")
    string(LENGTH "${ARGV3}" _24C487FA_var_prefix_filter_len)
  else()
    set(_24C487FA_var_prefix_filter_len 0)
  endif()

  if ((NOT "${ARGV1}" STREQUAL "" AND NOT "${ARGV1}" STREQUAL ".") OR
    (NOT "${ARGV2}" STREQUAL "" AND NOT "${ARGV2}" STREQUAL "."))
    if (NOT "${ARGV1}" STREQUAL "" AND NOT "${ARGV1}" STREQUAL ".")
      set(${ARGV1} "")
    endif()
    if (NOT "${ARGV2}" STREQUAL "" AND NOT "${ARGV2}" STREQUAL ".")
      set(${ARGV2} ";") # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
    endif()

    foreach(_24C487FA_var_name IN LISTS _24C487FA_vars_all_list)
      if (_24C487FA_var_prefix_filter_len)
        string(SUBSTRING "${_24C487FA_var_name}" 0 ${_24C487FA_var_prefix_filter_len} _24C487FA_var_name_prefix)
        # copy values only from "parent scope" variables
        if ("${_24C487FA_var_name_prefix}" STREQUAL "${ARGV3}")
          continue()
        endif()
      endif()

      # check for specific builtin variables
      tkl_is_ARGx_var(_24C487FA_is_ARGx_var "${_24C487FA_var_name}")
      if (_24C487FA_is_ARGx_var)
        continue()
      endif()

      if (NOT "${ARGV1}" STREQUAL "" AND NOT "${ARGV1}" STREQUAL ".")
        # does not need `;` escape
        list(APPEND ${ARGV1} "${_24C487FA_var_name}")
      endif()

      if (NOT "${ARGV2}" STREQUAL "" AND NOT "${ARGV2}" STREQUAL ".")
        # WORKAROUND: we have to replace because `list(APPEND` will join lists together
        tkl_escape_string_before_list_append(_24C487FA_var_value "${${_24C487FA_var_name}}")

        list(APPEND ${ARGV2} "${_24C487FA_var_value}")

        #message("${_24C487FA_var_name}=`${_24C487FA_var_value}`")
      endif()
    endforeach()

    if (NOT "${ARGV2}" STREQUAL "" AND NOT "${ARGV2}" STREQUAL ".")
      # remove 2 first dummy empty strings
      tkl_list_remove_sublist(${ARGV2} 0 2 ${ARGV2})
    endif()

    #list(LENGTH ${ARGV1} vars_len)
    #list(LENGTH ${ARGV2} vals_len)
    #
    #message(vars_len=`${vars_len}`)
    #message(vals_len=`${vals_len}`)
  endif()

  if (NOT "${ARGV0}" STREQUAL "" AND NOT "${ARGV0}" STREQUAL ".")
    set(${ARGV0} "${_24C487FA_vars_all_list}" PARENT_SCOPE)
  endif()
  if (NOT "${ARGV1}" STREQUAL "" AND NOT "${ARGV1}" STREQUAL ".")
    set(${ARGV1} "${${ARGV1}}" PARENT_SCOPE)
  endif()
  if (NOT "${ARGV2}" STREQUAL "" AND NOT "${ARGV2}" STREQUAL ".")
    set(${ARGV2} "${${ARGV2}}" PARENT_SCOPE)
  endif()
endfunction()

# custom user variables stack over properties

function(tkl_push_var_to_stack _B85ED509_stack_entry _B85ED509_var_name)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "if (DEFINED ${_B85ED509_var_name})" still can be applied to a local variable!
  #

  if ("${_B85ED509_stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()
  if ("${_B85ED509_var_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty: stack_entry=`${_B85ED509_stack_entry}`")
  endif()

  get_property(_B85ED509_is_vars_stack_set GLOBAL PROPERTY "tkl::vars_stack[${_B85ED509_stack_entry}][${_B85ED509_var_name}]::size" SET)
  if (_B85ED509_is_vars_stack_set)
    get_property(_B85ED509_vars_stack_size GLOBAL PROPERTY "tkl::vars_stack[${_B85ED509_stack_entry}][${_B85ED509_var_name}]::size")
  else()
    set(_B85ED509_vars_stack_size 0)
  endif()

  set_property(GLOBAL PROPERTY "tkl::vars_stack[${_B85ED509_stack_entry}][${_B85ED509_var_name}]::${_B85ED509_vars_stack_size}" "${${_B85ED509_var_name}}")
  if (DEFINED ${_B85ED509_var_name})
    set_property(GLOBAL PROPERTY "tkl::vars_stack[${_B85ED509_stack_entry}][${_B85ED509_var_name}]::${_B85ED509_vars_stack_size}::defined" 1)
  else()
    set_property(GLOBAL PROPERTY "tkl::vars_stack[${_B85ED509_stack_entry}][${_B85ED509_var_name}]::${_B85ED509_vars_stack_size}::defined" 0)
  endif()

  math(EXPR _B85ED509_vars_stack_size ${_B85ED509_vars_stack_size}+1)
  set_property(GLOBAL PROPERTY "tkl::vars_stack[${_B85ED509_stack_entry}][${_B85ED509_var_name}]::size" ${_B85ED509_vars_stack_size})
endfunction()

function(tkl_pushset_var_to_stack _B85ED509_stack_entry _B85ED509_var_name _B85ED509_var_value)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "${_B85ED509_var_name}" still can expand to a local variable!
  #

  tkl_push_var_to_stack("${_B85ED509_stack_entry}" "${_B85ED509_var_name}")

  set(${_B85ED509_var_name} "${_B85ED509_var_value}" PARENT_SCOPE)
endfunction()

function(tkl_pushunset_var_to_stack _B85ED509_stack_entry _B85ED509_var_name)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "${_B85ED509_var_name}" still can expand to a local variable!
  #

  tkl_push_var_to_stack("${_B85ED509_stack_entry}" "${_B85ED509_var_name}")

  unset(${_B85ED509_var_name} PARENT_SCOPE)
endfunction()

function(tkl_pop_var_from_stack stack_entry var_name)
  # INFO:
  #   All local variables here are unique, just in case.
  #

  # ARGV2 - update_var
  if (${ARGC} GREATER 3)
    message(FATAL_ERROR "maximum 3 arguments is supported")
  endif()

  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()
  if ("${var_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty: stack_entry=`${stack_entry}`")
  endif()

  get_property(vars_stack_size GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size")
  if (NOT vars_stack_size)
    message(FATAL_ERROR "variables stack either undefined or empty")
  endif()

  math(EXPR vars_stack_next_size ${vars_stack_size}-1)

  # update the var_name by default
  if ("${ARGV2}" STREQUAL "")
    get_property(is_var_defined GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_next_size}::defined")
    if (is_var_defined)
      get_property(var_value GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_next_size}")
      set(${var_name} "${var_value}" PARENT_SCOPE)
    else()
      unset(${var_name} PARENT_SCOPE)
    endif()
  elseif (NOT "${ARGV2}" STREQUAL ".")
    get_property(is_var_defined GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_next_size}::defined")
    if (is_var_defined)
      get_property(var_value GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_next_size}")
      set(${ARGV2} "${var_value}" PARENT_SCOPE)
    else()
      unset(${ARGV2} PARENT_SCOPE)
    endif()
  endif()

  if (vars_stack_next_size)
    set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size" ${vars_stack_next_size})
  else()
    set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size") # unset property
  endif()

  # unset previous
  set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_next_size}")
  set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_next_size}::defined")
endfunction()

function(tkl_get_var_stack_size out_var stack_entry var_name)
  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()
  if ("${var_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty: stack_entry=`${stack_entry}`")
  endif()

  get_property(vars_stack_size GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size")
  if ("${vars_stack_size}" STREQUAL "")
    set(vars_stack_size 0)
  endif()

  set(${out_var} ${vars_stack_size} PARENT_SCOPE)
endfunction()

function(tkl_get_var_stack_value out_var stack_entry var_name index)
  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()
  if ("${out_var}" STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty: stack_entry=`${stack_entry}`")
  endif()

  get_property(vars_stack_size GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size")
  if ("${vars_stack_size}" STREQUAL "")
    set(vars_stack_size 0)
  endif()

  if (NOT vars_stack_size)
    message(FATAL_ERROR "variables stack either undefined or empty")
  endif()

  if (NOT index LESS vars_stack_size)
    message(FATAL_ERROR "index out of stack bounds: index=`${index}` vars_stack_size=`${vars_stack_size}`")
  endif()

  math(EXPR vars_stack_index ${vars_stack_size}-1-${index})

  get_property(is_var_defined GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_index}::defined")
  if (is_var_defined)
    get_property(var_value GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_index}")
    set(${out_var} "${var_value}" PARENT_SCOPE)
  else()
    unset(${out_var} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_get_var_stack_value_no_error out_var stack_entry var_name index)
  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()
  if ("${var_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty: stack_entry=`${stack_entry}`")
  endif()

  get_property(vars_stack_size GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size")
  if ("${vars_stack_size}" STREQUAL "")
    set(vars_stack_size 0)
  endif()

  if (vars_stack_size AND index LESS vars_stack_size)
    math(EXPR vars_stack_index ${vars_stack_size}-1-${index})

    get_property(is_var_defined GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_index}::defined")
    if (is_var_defined)
      get_property(var_value GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_index}")
      set(${out_var} "${var_value}" PARENT_SCOPE)
    else()
      unset(${out_var} PARENT_SCOPE)
    endif()
  else()
    unset(${out_var} PARENT_SCOPE)
  endif()
endfunction()

# custom user properties stack over properties

function(tkl_push_prop_to_stack prop_entry prop_name stack_entry)
  if ("${prop_entry}" STREQUAL "")
    message(FATAL_ERROR "prop_entry must be not empty")
  endif()
  if ("${prop_name}" STREQUAL "")
    message(FATAL_ERROR "prop_name must be not empty")
  endif()
  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()

  get_property(is_props_stack_set GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size" SET)
  if (is_props_stack_set)
    get_property(props_stack_size GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size")
  else()
    set(props_stack_size 0)
  endif()

  get_property(prop_value_set "${prop_entry}" PROPERTY "${prop_name}" SET)
  if (prop_value_set)
    get_property(prop_value "${prop_entry}" PROPERTY "${prop_name}")
    set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${props_stack_size}" "${prop_value}")
  endif()
  set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${props_stack_size}::defined" ${prop_value_set})

  math(EXPR props_stack_size ${props_stack_size}+1)
  set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size" ${props_stack_size})
endfunction()

function(tkl_pushset_prop_to_stack out_var prop_entry prop_name stack_entry var_value)
  tkl_push_prop_to_stack("${prop_entry}" "${prop_name}" "${stack_entry}")

  set_property("${prop_entry}" PROPERTY "${prop_name}" "${var_value}")

  if (NOT "${out_var}" STREQUAL "" AND NOT "${out_var}" STREQUAL ".")
    set(${out_var} "${var_value}" PARENT_SCOPE)
  endif()
endfunction()

function(tkl_pushunset_prop_to_stack out_var prop_entry prop_name stack_entry)
  tkl_push_prop_to_stack("${prop_entry}" "${prop_name}" "${stack_entry}")

  set_property("${prop_entry}" PROPERTY "${prop_name}") # unset property

  if (NOT "${out_var}" STREQUAL "" AND NOT "${out_var}" STREQUAL ".")
    unset(${out_var} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_pop_prop_from_stack out_var prop_entry prop_name stack_entry)
  # INFO:
  #   All local variables here are unique, just in case.
  #

  if ("${prop_entry}" STREQUAL "")
    message(FATAL_ERROR "prop_entry must be not empty")
  endif()
  if ("${prop_name}" STREQUAL "")
    message(FATAL_ERROR "prop_name must be not empty")
  endif()
  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()

  get_property(props_stack_size GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size")
  if (NOT props_stack_size)
    message(FATAL_ERROR "properties stack either undefined or empty")
  endif()

  math(EXPR props_stack_next_size ${props_stack_size}-1)

  get_property(is_prop_defined GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${props_stack_next_size}::defined")
  if (is_prop_defined)
    get_property(prop_value GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${props_stack_next_size}")
    set_property("${prop_entry}" PROPERTY "${prop_name}" "${prop_value}")
  else()
    set(prop_value "")
    set_property("${prop_entry}" PROPERTY "${prop_name}") # unset property
  endif()

  if (props_stack_next_size)
    set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size" ${props_stack_next_size})
  else()
    set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size") # unset property
  endif()

  # unset previous
  set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${props_stack_next_size}")
  set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${props_stack_next_size}::defined")

  if (NOT "${out_var}" STREQUAL "" AND NOT "${out_var}" STREQUAL ".")
    if (is_prop_defined)
      set(${out_var} "${prop_value}" PARENT_SCOPE)
    else()
      unset(${out_var} PARENT_SCOPE)
    endif()
  endif()
endfunction()

function(tkl_get_prop_stack_size out_var prop_entry prop_name stack_entry)
  if ("${prop_entry}" STREQUAL "")
    message(FATAL_ERROR "prop_entry must be not empty")
  endif()
  if ("${prop_name}" STREQUAL "")
    message(FATAL_ERROR "prop_name must be not empty")
  endif()
  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()

  get_property(props_stack_size GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size")
  if ("${props_stack_size}" STREQUAL "")
    set(props_stack_size 0)
  endif()

  set(${out_var} ${props_stack_size} PARENT_SCOPE)
endfunction()

function(tkl_get_prop_stack_value out_var prop_entry prop_name stack_entry index)
  if ("${prop_entry}" STREQUAL "")
    message(FATAL_ERROR "prop_entry must be not empty")
  endif()
  if ("${prop_name}" STREQUAL "")
    message(FATAL_ERROR "prop_name must be not empty")
  endif()
  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()

  get_property(props_stack_size GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size")
  if ("${props_stack_size}" STREQUAL "")
    set(props_stack_size 0)
  endif()

  if (NOT props_stack_size)
    message(FATAL_ERROR "properties stack either undefined or empty")
  endif()

  if (NOT index LESS props_stack_size)
    message(FATAL_ERROR "index out of stack bounds: index=`${index}` props_stack_size=`${props_stack_size}`")
  endif()

  math(EXPR props_stack_index ${props_stack_size}-1-${index})

  get_property(is_prop_defined GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${props_stack_index}::defined")
  if (is_prop_defined)
    get_property(prop_value GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${props_stack_index}")
    set(${out_var} "${prop_value}" PARENT_SCOPE)
  else()
    unset(${out_var} PARENT_SCOPE) # unset property
  endif()
endfunction()

function(tkl_get_prop_stack_value_no_error out_var prop_entry prop_name stack_entry index)
  if ("${prop_entry}" STREQUAL "")
    message(FATAL_ERROR "prop_entry must be not empty")
  endif()
  if ("${prop_name}" STREQUAL "")
    message(FATAL_ERROR "prop_name must be not empty")
  endif()
  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()

  get_property(props_stack_size GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size")
  if ("${props_stack_size}" STREQUAL "")
    set(props_stack_size 0)
  endif()

  if (props_stack_size AND index LESS props_stack_size)
    math(EXPR props_stack_index ${props_stack_size}-1-${index})

    get_property(is_prop_defined GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${props_stack_index}::defined")
    if (is_prop_defined)
      get_property(prop_value GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${props_stack_index}")
      set(${out_var} "${prop_value}" PARENT_SCOPE)
    else()
      unset(${out_var} PARENT_SCOPE) # unset property
    endif()
  else()
    unset(${out_var} PARENT_SCOPE) # unset property
  endif()
endfunction()

# Begin to track variables for change or adding.
# Note that variables starting with underscore are NOT ignored.
#
# CAUTION:
#   Have to be a function, but all local variables still must be unique to
#   avoid intersection with the parent one.
#
function(tkl_track_vars_begin) # WITH OUT ARGUMENTS!
  if (${ARGC} GREATER 0)
    message(FATAL_ERROR "function must be called without arguments")
  endif()

  tkl_copy_vars(. _39067B90_filtered_vars)

  #message(" _39067B90_filtered_vars=`${_39067B90_filtered_vars}`")

  tkl_pushset_prop_to_stack(. GLOBAL "tkl::track_vars::vars_stack::vars" "tkl::track_vars" "${_39067B90_filtered_vars}")
endfunction()

# Forwards variables that were added/changed/removed since the last call to the `begin_track_vars` to the parent scope.
# Note that variables starting with underscore are NOT ignored.
#
# Parameters:
#   ARGN - variables exclusion list
#
macro(tkl_forward_changed_vars_to_parent_scope) # WITH OUT ARGUMENTS!
  # must be the first call
  tkl_copy_vars(. _39067B90_filtered_vars)

  tkl_get_global_prop(_39067B90_prev_vars "tkl::track_vars::vars_stack::vars" 0)
  if (NOT DEFINED _39067B90_prev_vars)
    message(FATAL_ERROR "the function is called out of `tkl_track_vars_begin`/`tkl_track_vars_end` scope")
  endif()

  # to unset
  set(_39067B90_vars_to_unset "${_39067B90_prev_vars}")
  list(REMOVE_ITEM _39067B90_vars_to_unset ${_39067B90_filtered_vars})

  # to set
  set(_39067B90_vars_to_set "${_39067B90_filtered_vars}")

  # to ignore
  if (NOT "${ARGN}" STREQUAL "")
    list(REMOVE_ITEM _39067B90_vars_to_unset ${ARGN})
    list(REMOVE_ITEM _39067B90_vars_to_set ${ARGN})
  endif()

  # propagate unset
  foreach(_39067B90_var IN LISTS _39067B90_vars_to_unset)
    unset(${_39067B90_var} PARENT_SCOPE)
    #message("unset: `${_39067B90_var}`")
  endforeach()

  # propagate set
  foreach(_39067B90_var IN LISTS _39067B90_vars_to_set)
    set(${_39067B90_var} "${${_39067B90_var}}" PARENT_SCOPE)
    #message("set: ${_39067B90_var}=`${${_39067B90_var}}`")
  endforeach()

  unset(_39067B90_filtered_vars)
  unset(_39067B90_prev_vars)
  unset(_39067B90_vars_to_unset)
  unset(_39067B90_vars_to_set)
  unset(_39067B90_var)
endmacro()

macro(tkl_track_vars_end) # WITH OUT ARGUMENTS!
  if (${ARGC} GREATER 0)
    message(FATAL_ERROR "function must be called without arguments")
  endif()

  tkl_pop_prop_from_stack(. GLOBAL "tkl::track_vars::vars_stack::vars" "tkl::track_vars")
endmacro()

function(tkl_register_context_var_set ctx_name scope_name var_name var_value inheritable_var)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "if (DEFINED ${var_name})" still can be applied to a local variable!
  #

  if ("${ctx_name}" STREQUAL "" OR "${ctx_name}" STREQUAL ".")
    message(FATAL_ERROR "ctx_name must be not empty and valid")
  endif()
  if ("${scope_name}" STREQUAL "" OR "${scope_name}" STREQUAL ".")
    message(FATAL_ERROR "scope_name must be not empty and valid")
  endif()

  get_property(_46AC7C2B_is_vars_register_set GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${var_name}]" SET)
  if (_46AC7C2B_is_vars_stack_set)
    message(FATAL_ERROR "`${var_name}` is already registered: ctx_name=`${ctx_name}` scope_name=`${scope_name}`")
  endif()

  message("register context variable set: ${var_name}=`${var_value}`; ctx=`${ctx_name}`; scope=`${scope_name}`; inheritable=`${inheritable_var}`")

  get_property(_46AC7C2B_var_names_register_list GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}]::var_names")
  list(APPEND _46AC7C2B_var_names_register_list "${var_name}")

  set_property(GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${var_name}]" "${var_value}")
  set_property(GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${var_name}]::inheritable" "${inheritable_var}")

  set_property(GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}]::var_names" "${_46AC7C2B_var_names_register_list}")
endfunction()

function(tkl_unregister_context_var ctx_name scope_name var_name)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "if (DEFINED ${var_name})" still can be applied to a local variable!
  #

  if ("${ctx_name}" STREQUAL "" OR "${ctx_name}" STREQUAL ".")
    message(FATAL_ERROR "ctx_name must be not empty and valid")
  endif()
  if ("${scope_name}" STREQUAL "" OR "${scope_name}" STREQUAL ".")
    message(FATAL_ERROR "scope_name must be not empty and valid")
  endif()

  get_property(_46AC7C2B_is_vars_register_set GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${var_name}]" SET)
  if (NOT _46AC7C2B_is_vars_stack_set)
    message(FATAL_ERROR "`${var_name}` is already unregistered: ctx_name=`${ctx_name}` scope_name=`${scope_name}`")
  endif()

  message("unregister context variable: `${var_name}`: ctx=`${ctx_name}`; scope=`${scope_name}`")

  get_property(_46AC7C2B_var_names_register_list GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}]::var_names")
  list(REMOVE_ITEM _46AC7C2B_var_names_register_list "${var_name}")

  set_property(GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${var_name}]") # unset property
  set_property(GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${var_name}]::inheritable") # unset property

  list(LENGTH _46AC7C2B_var_names_register_list _46AC7C2B_var_names_register_list_size)
  if (_46AC7C2B_var_names_register_list_size)
    set_property(GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}]::var_names" "${_46AC7C2B_var_names_register_list}")
  else()
    set_property(GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}]::var_names") # unset property
  endif()
endfunction()

function(tkl_has_context_vars out_var ctx_name scope_name)
  if ("${ctx_name}" STREQUAL "" OR "${ctx_name}" STREQUAL ".")
    message(FATAL_ERROR "ctx_name must be not empty and valid: ctx_name=`${ctx_name}`")
  endif()
  if ("${scope_name}" STREQUAL "" OR "${scope_name}" STREQUAL ".")
    message(FATAL_ERROR "scope_name must be not empty and valid: scope_name=`${scope_name}`")
  endif()

  get_property(is_vars_register_set GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}]::var_names" SET)
  set(${out_var} ${is_vars_register_set} PARENT_SCOPE)
endfunction()

function(tkl_has_ctx_context_var out_var ctx_name scope_name var_name)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "if (DEFINED ${var_name})" still can be applied to a local variable!
  #

  if ("${ctx_name}" STREQUAL "" OR "${ctx_name}" STREQUAL ".")
    message(FATAL_ERROR "ctx_name must be not empty and valid")
  endif()
  if ("${scope_name}" STREQUAL "" OR "${scope_name}" STREQUAL ".")
    message(FATAL_ERROR "scope_name must be not empty and valid")
  endif()

  get_property(_46AC7C2B_is_var_set GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${var_name}]" SET)
  set(${out_var} "${_46AC7C2B_is_var_set}" PARENT_SCOPE)
endfunction()

function(tkl_get_context_var out_var ctx_name scope_name var_name)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "if (DEFINED ${var_name})" still can be applied to a local variable!
  #

  if ("${ctx_name}" STREQUAL "" OR "${ctx_name}" STREQUAL ".")
    message(FATAL_ERROR "ctx_name must be not empty and valid")
  endif()
  if ("${scope_name}" STREQUAL "" OR "${scope_name}" STREQUAL ".")
    message(FATAL_ERROR "scope_name must be not empty and valid")
  endif()

  get_property(_46AC7C2B_is_var_set GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${var_name}]" SET)
  if (_46AC7C2B_is_var_set)
    get_property(_46AC7C2B_is_var_value GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${var_name}]")
    set(${out_var} "${_46AC7C2B_is_var_value}" PARENT_SCOPE)
  else()
    unset(${out_var} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_push_all_context_vars ctx_name scope_name)
  tkl_push_all_context_vars_macro("${ctx_name}" "${scope_name}")
endfunction()

function(tkl_restore_not_inheritable_context_vars ctx_name scope_name)
  tkl_restore_not_inheritable_context_vars_macro("${ctx_name}" "${scope_name}")
endfunction()

function(tkl_pop_all_context_vars ctx_name scope_name)
  tkl_pop_all_context_vars_macro("${scope_name}" "${scope_name}")
endfunction()

macro(tkl_push_all_context_vars_macro ctx_name scope_name)
  if ("${ctx_name}" STREQUAL "" OR "${ctx_name}" STREQUAL ".")
    message(FATAL_ERROR "ctx_name must be not empty and valid")
  endif()
  if ("${scope_name}" STREQUAL "" OR "${scope_name}" STREQUAL ".")
    message(FATAL_ERROR "scope_name must be not empty and valid")
  endif()

  get_property(_46AC7C2B_var_names_register_list GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}]::var_names")

  foreach(_46AC7C2B_var_name IN LISTS _46AC7C2B_var_names_register_list)
    get_property(_46AC7C2B_is_var_inheritable GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${_46AC7C2B_var_name}]::inheritable")
    get_property(_46AC7C2B_var_value_set GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${_46AC7C2B_var_name}]" SET)
    if (_46AC7C2B_var_value_set)
      get_property(_46AC7C2B_var_value GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${_46AC7C2B_var_name}]")
      message("context variable push-set: ${_46AC7C2B_var_name}=`${_46AC7C2B_var_value}`; ctx=`${ctx_name}`; scope=`${scope_name}`; inheritable=`${_46AC7C2B_is_var_inheritable}`")
      tkl_push_var_to_stack("tkl::ctx_vars_register_stack" ${_46AC7C2B_var_name})
      set(${_46AC7C2B_var_name} "${_46AC7C2B_var_value}" PARENT_SCOPE)
    else()
      message("context variable push-unset: `${_46AC7C2B_var_name}`: ctx=`${ctx_name}`; scope=`${scope_name}`; inheritable=`${_46AC7C2B_is_var_inheritable}`")
      tkl_push_var_to_stack("tkl::ctx_vars_register_stack" ${_46AC7C2B_var_name})
      unset(${_46AC7C2B_var_name} PARENT_SCOPE)
    endif()
  endforeach()

  unset(_46AC7C2B_var_name)
  unset(_46AC7C2B_var_names_register_list)
  unset(_46AC7C2B_is_var_inheritable)
  unset(_46AC7C2B_var_value_set)
  unset(_46AC7C2B_var_value)
endmacro()

macro(tkl_pushreset_not_inheritable_context_vars_macro ctx_name scope_name)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "${_46AC7C2B_var_name}" still can expand to a local variable!
  #

  if ("${ctx_name}" STREQUAL "" OR "${ctx_name}" STREQUAL ".")
    message(FATAL_ERROR "ctx_name must be not empty and valid")
  endif()
  if ("${scope_name}" STREQUAL "" OR "${scope_name}" STREQUAL ".")
    message(FATAL_ERROR "scope_name must be not empty and valid")
  endif()

  get_property(_46AC7C2B_var_names_register_list GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}]::var_names")

  foreach(_46AC7C2B_var_name IN LISTS _46AC7C2B_var_names_register_list)
    get_property(_46AC7C2B_is_var_inheritable GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${_46AC7C2B_var_name}]::inheritable")
    if (NOT _46AC7C2B_is_var_inheritable)
      tkl_get_prop_stack_size(_46AC7C2B_prop_stack_size GLOBAL "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${_46AC7C2B_var_name}]" "tkl::ctx_vars_register_stack")
      if (_46AC7C2B_prop_stack_size)
        message("context variable push-reset: `${_46AC7C2B_var_name}`: ctx=`${ctx_name}`; scope=`${scope_name}`; inheritable=`${_46AC7C2B_is_var_inheritable}`")
        tkl_get_var_stack_value(_46AC7C2B_var_value "tkl::ctx_vars_register_stack" "${_46AC7C2B_var_name}" 0)
        tkl_push_var_to_stack("tkl::ctx_not_inheritable_vars_register_stack" ${_46AC7C2B_var_name})
        if (DEFINED _46AC7C2B_var_value)
          set(${_46AC7C2B_var_name} "${_46AC7C2B_var_value}" PARENT_SCOPE)
        else()
          unset(${_46AC7C2B_var_name} PARENT_SCOPE)
        endif()
      endif()
    endif()
  endforeach()

  unset(_46AC7C2B_var_name)
  unset(_46AC7C2B_var_names_register_list)
  unset(_46AC7C2B_is_var_inheritable)
  unset(_46AC7C2B_prop_stack_size)
  unset(_46AC7C2B_var_value)
endmacro()

macro(tkl_poprestore_not_inheritable_context_vars_macro ctx_name scope_name)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "${_46AC7C2B_var_name}" still can expand to a local variable!
  #

  if ("${ctx_name}" STREQUAL "" OR "${ctx_name}" STREQUAL ".")
    message(FATAL_ERROR "ctx_name must be not empty and valid")
  endif()
  if ("${scope_name}" STREQUAL "" OR "${scope_name}" STREQUAL ".")
    message(FATAL_ERROR "scope_name must be not empty and valid")
  endif()

  get_property(_46AC7C2B_var_names_register_list GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}]::var_names")

  foreach(_46AC7C2B_var_name IN LISTS _46AC7C2B_var_names_register_list)
    get_property(_46AC7C2B_is_var_inheritable GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${_46AC7C2B_var_name}]::inheritable")
    if (NOT _46AC7C2B_is_var_inheritable)
      tkl_get_prop_stack_size(_46AC7C2B_prop_stack_size GLOBAL "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${_46AC7C2B_var_name}]" "tkl::ctx_vars_register_stack")
      if (_46AC7C2B_prop_stack_size)
        tkl_pop_var_from_stack("tkl::ctx_not_inheritable_vars_register_stack" "${_46AC7C2B_var_name}" _46AC7C2B_var_value)
        if (DEFINED _46AC7C2B_var_value)
          message("context variable pop-restore: ${_46AC7C2B_var_name}=`${_46AC7C2B_var_value}`: ctx=`${ctx_name}`; scope=`${scope_name}`; inheritable=`${_46AC7C2B_is_var_inheritable}`")
          set(${_46AC7C2B_var_name} "${_46AC7C2B_var_value}" PARENT_SCOPE)
        else()
          message("context variable pop-restore: `${_46AC7C2B_var_name}`: ctx=`${ctx_name}`; scope=`${scope_name}`; inheritable=`${_46AC7C2B_is_var_inheritable}`")
          unset(${_46AC7C2B_var_name} PARENT_SCOPE)
        endif()
      endif()
    endif()
  endforeach()

  unset(_46AC7C2B_var_name)
  unset(_46AC7C2B_var_names_register_list)
  unset(_46AC7C2B_is_var_inheritable)
  unset(_46AC7C2B_prop_stack_size)
  unset(_46AC7C2B_var_value)
endmacro()

macro(tkl_pop_all_context_vars_macro ctx_name scope_name)
  if ("${ctx_name}" STREQUAL "" OR "${ctx_name}" STREQUAL ".")
    message(FATAL_ERROR "ctx_name must be not empty and valid")
  endif()
  if ("${scope_name}" STREQUAL "" OR "${scope_name}" STREQUAL ".")
    message(FATAL_ERROR "scope_name must be not empty and valid")
  endif()

  get_property(_46AC7C2B_var_names_register_list GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}]::var_names")

  foreach(_46AC7C2B_var_name IN LISTS _46AC7C2B_var_names_register_list)
    get_property(_46AC7C2B_is_var_inheritable GLOBAL PROPERTY "tkl::ctx_vars_register[${ctx_name}][${scope_name}][${_46AC7C2B_var_name}]::inheritable")
    tkl_pop_var_from_stack("tkl::ctx_vars_register_stack" "${_46AC7C2B_var_name}" _46AC7C2B_var_value)
    if (DEFINED _46AC7C2B_var_value)
      message("context variable pop-set: ${_46AC7C2B_var_name}=`${_46AC7C2B_var_value}`; ctx=`${ctx_name}`; scope=`${scope_name}`; inheritable=`${_46AC7C2B_is_var_inheritable}`")
      set(${_46AC7C2B_var_name} "${_46AC7C2B_var_value}" PARENT_SCOPE)
    else()
      message("context variable pop-unset: `${_46AC7C2B_var_name}`: ctx=`${ctx_name}`; scope=`${scope_name}`; inheritable=`${_46AC7C2B_is_var_inheritable}`")
      unset(${_46AC7C2B_var_name} PARENT_SCOPE)
    endif()
  endforeach()

  unset(_46AC7C2B_var_name)
  unset(_46AC7C2B_var_names_register_list)
  unset(_46AC7C2B_is_var_inheritable)
  unset(_46AC7C2B_var_value)
endmacro()

endif()
