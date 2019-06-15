# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_FORWARD_VARIABLES_INCLUDE_DEFINED)
set(TACKLELIB_FORWARD_VARIABLES_INCLUDE_DEFINED 1)

# NOTE:
#   Read the doc/02_general_variables_set_rules.txt`
#   for variables set rules represented here.
#

include(tacklelib/List)
include(tacklelib/Props)

function(tkl_is_var out_is_var_def var_name)
  if(("${out_is_var_def}" STREQUAL "") OR (out_is_var_def STREQUAL var_name))
    message(FATAL_ERROR "out_is_var_def must be not empty and not equal to var_name: out_is_var_def=`${out_is_var_def}` var_name=`${var_name}`")
  endif()
  if("${var_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty")
  endif()

  if ((var_name STREQUAL ".") OR (NOT DEFINED ${var_name}))
    set(${out_is_var_def} 0 PARENT_SCOPE)
  endif()

  get_cmake_property(vars_list VARIABLES)

  list(FIND vars_list ${var_name} var_index)
  if(NOT var_index EQUAL -1)
    set(${out_is_var_def} 1 PARENT_SCOPE)
  else()
    set(${out_is_var_def} 0 PARENT_SCOPE)
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
  if (var_name STREQUAL "" OR var_name STREQUAL ".")
    message(FATAL_ERROR "var_name must be not empty and valid")
  endif()

  if (out_uncached_var AND NOT out_uncached_var STREQUAL ".")
    set(out_uncached_var_defined 1)
  else()
    set(out_uncached_var_defined 0)
  endif()

  if (out_cached_var AND NOT out_cached_var STREQUAL ".")
    set(out_cached_var_defined 1)
  else()
    set(out_cached_var_defined 0)
  endif()

  if (NOT out_uncached_var_defined AND NOT out_cached_var_defined)
    message(FATAL_ERROR "at least one output variable must be defined")
  endif()

  if (out_uncached_var_defined)
    if (out_uncached_var STREQUAL var_name)
      message(FATAL_ERROR "out_uncached_var and var_name variables must be different: `${out_uncached_var}`")
    endif()
  endif()

  if (out_uncached_var_defined OR out_cached_var_defined)
    if (out_uncached_var STREQUAL out_cached_var)
      message(FATAL_ERROR "out_uncached_var and out_cached_var variables must be different: `${out_cached_var}`")
    endif()
  endif()

  # check for specific builtin variables
  tkl_is_ARGx_var(is_ARGx_var "${var_name}")
  if (is_ARGx_var)
    message(FATAL_ERROR "specific builtin variables are forbidden to use: `${var_name}`")
  endif()

  get_property(var_cache_value_is_set CACHE "${var_name}" PROPERTY VALUE SET)

  if (NOT var_cache_value_is_set)
    if (out_cached_var_defined)
      unset(${out_cached_var} PARENT_SCOPE)
    endif()
    if (out_uncached_var_defined)
      set(${out_uncached_var} "${${var_name}}" PARENT_SCOPE)
    endif()
  else()
    if (out_cached_var_defined)
      # propagate cached variant of a variable
      if (DEFINED ${var_name})
        set(${out_cached_var} "${${var_name}}" PARENT_SCOPE)
      else()
        unset(${out_cached_var} PARENT_SCOPE)
      endif()
    endif()

    if (out_uncached_var_defined)
      # save cache properties of a variable
      get_property(var_cache_value CACHE "${var_name}" PROPERTY VALUE)
      get_property(var_cache_type CACHE "${var_name}" PROPERTY TYPE)
      get_property(var_cache_docstring CACHE "${var_name}" PROPERTY HELPSTRING)

      # remove cached variant of a variable
      unset(${var_name} CACHE)

      # propagate uncached variant of a variable
      if (DEFINED ${var_name})
        set(${out_uncached_var} "${${var_name}}" PARENT_SCOPE)
      else()
        unset(${out_uncached_var} PARENT_SCOPE)
      endif()

      # restore cache properties of a variable
      #message("set(${var_name} `${var_cache_value}` CACHE `${var_cache_type}` `${var_cache_docstring}`)")
      set(${var_name} "${var_cache_value}" CACHE ${var_cache_type} "${var_cache_docstring}")
    endif()
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
        if (_24C487FA_var_name_prefix STREQUAL "${ARGV3}")
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
    #message(vars_len=${vars_len})
    #message(vals_len=${vals_len})
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

function(tkl_push_var_to_stack stack_entry var_name)
  # CAUTION:
  #   All local variables here must be unique irrespective to the function scope,
  #   because "if (DEFINED ${var_name})" still can be applied to a local variable!
  #

  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()
  if ("${var_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty: stack_entry=`${stack_entry}`")
  endif()

  get_property(_2BA2974B_is_vars_stack_set GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size" SET)
  if (_2BA2974B_is_vars_stack_set)
    get_property(_2BA2974B_vars_stack_size GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size")
  else()
    set(_2BA2974B_vars_stack_size 0)
  endif()

  set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${_2BA2974B_vars_stack_size}" "${${var_name}}")
  if (DEFINED ${var_name})
    set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${_2BA2974B_vars_stack_size}::defined" 1)
  else()
    set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${_2BA2974B_vars_stack_size}::defined" 0)
  endif()

  math(EXPR _2BA2974B_vars_stack_size ${_2BA2974B_vars_stack_size}+1)
  set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size" ${_2BA2974B_vars_stack_size})
endfunction()

function(tkl_pushset_var_to_stack stack_entry var_name var_value)
  tkl_push_var_to_stack("${stack_entry}" "${var_name}")

  set(${var_name} "${var_value}" PARENT_SCOPE)
endfunction()

function(tkl_pushunset_var_to_stack stack_entry var_name)
  tkl_push_var_to_stack("${stack_entry}" "${var_name}")

  unset(${var_name} PARENT_SCOPE)
endfunction()

function(tkl_pop_var_from_stack stack_entry var_name)
  # INFO:
  #   All local variables here are unique, just in case.
  #

  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()
  if ("${var_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty: stack_entry=`${stack_entry}`")
  endif()

  get_property(_2BA2974B_vars_stack_size GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size")
  if (NOT _2BA2974B_vars_stack_size)
    message(FATAL_ERROR "variables stack either undefined or empty")
  endif()

  math(EXPR _2BA2974B_vars_stack_next_size ${_2BA2974B_vars_stack_size}-1)

  get_property(_2BA2974B_is_var_defined GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${_2BA2974B_vars_stack_next_size}::defined")
  if (_2BA2974B_is_var_defined)
    get_property(_2BA2974B_var_value GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${_2BA2974B_vars_stack_next_size}")
    set(${var_name} "${_2BA2974B_var_value}" PARENT_SCOPE)
  else()
    unset(${var_name} PARENT_SCOPE)
  endif()

  if (_2BA2974B_vars_stack_next_size)
    set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size" ${_2BA2974B_vars_stack_next_size})
  else()
    set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::size") # unset property
  endif()

  # unset previous
  set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${_2BA2974B_vars_stack_next_size}")
  set_property(GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${_2BA2974B_vars_stack_next_size}::defined")
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

function(tkl_get_var_stack_value out_var stack_entry prop_name index)
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

  if (NOT vars_stack_size)
    message(FATAL_ERROR "variables stack either undefined or empty")
  endif()

  if (NOT index LESS vars_stack_size)
    message(FATAL_ERROR "index out of stack bounds: index=${index} vars_stack_size=${vars_stack_size}")
  endif()

  math(EXPR vars_stack_index ${vars_stack_size}-1-${index})

  get_property(is_var_defined GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_index}::defined")
  if (is_var_defined)
    get_property(var_value GLOBAL PROPERTY "tkl::vars_stack[${stack_entry}][${var_name}]::${vars_stack_index}")
    set(${var_name} "${var_value}" PARENT_SCOPE)
  else()
    unset(${var_name} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_get_var_stack_value_no_error out_var stack_entry prop_name index)
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
      set(${var_name} "${var_value}" PARENT_SCOPE)
    else()
      unset(${var_name} PARENT_SCOPE)
    endif()
  else()
    unset(${var_name} PARENT_SCOPE)
  endif()
endfunction()

# custom user properties stack over properties

function(tkl_push_prop_to_stack prop_entry prop_name stack_entry)
  if ("${prop_entry}" STREQUAL "")
    message(FATAL_ERROR "prop_entry must be not empty")
  endif()
  if ("${prop_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty")
  endif()
  if ("${stack_entry}" STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()

  get_property(_2BA2974B_is_props_stack_set GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size" SET)
  if (_2BA2974B_is_props_stack_set)
    get_property(_2BA2974B_props_stack_size GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size")
  else()
    set(_2BA2974B_props_stack_size 0)
  endif()

  get_property(_2BA2974B_prop_value_set "${prop_entry}" PROPERTY "${prop_name}" SET)
  if (_2BA2974B_prop_value_set)
    get_property(_2BA2974B_prop_value "${prop_entry}" PROPERTY "${prop_name}")
    set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${_2BA2974B_props_stack_size}" "${_2BA2974B_prop_value}")
  endif()
  set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${_2BA2974B_props_stack_size}::defined" ${_2BA2974B_prop_value_set})

  math(EXPR _2BA2974B_props_stack_size ${_2BA2974B_props_stack_size}+1)
  set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size" ${_2BA2974B_props_stack_size})
endfunction()

function(tkl_pushset_prop_to_stack out_var prop_entry prop_name stack_entry var_value)
  tkl_push_prop_to_stack("${prop_entry}" "${prop_name}" "${stack_entry}")

  set_property("${prop_entry}" PROPERTY "${prop_name}" "${var_value}")

  if (NOT out_var STREQUAL "" AND NOT out_var STREQUAL ".")
    set(${out_var} "${var_value}" PARENT_SCOPE)
  endif()
endfunction()

function(tkl_pushunset_prop_to_stack out_var prop_entry prop_name stack_entry)
  tkl_push_prop_to_stack("${prop_entry}" "${prop_name}" "${stack_entry}")

  set_property("${prop_entry}" PROPERTY "${prop_name}") # unset property

  if (NOT out_var STREQUAL "" AND NOT out_var STREQUAL ".")
    unset(${out_var} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_pop_prop_from_stack out_var prop_entry prop_name stack_entry)
  # INFO:
  #   All local variables here are unique, just in case.
  #

  if (prop_entry STREQUAL "")
    message(FATAL_ERROR "prop_entry must be not empty")
  endif()
  if (prop_name STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty")
  endif()
  if (stack_entry STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()

  get_property(_2BA2974B_props_stack_size GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size")
  if (NOT _2BA2974B_props_stack_size)
    message(FATAL_ERROR "properties stack either undefined or empty")
  endif()

  math(EXPR _2BA2974B_props_stack_next_size ${_2BA2974B_props_stack_size}-1)

  get_property(_2BA2974B_is_prop_defined GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${_2BA2974B_props_stack_next_size}::defined")
  if (_2BA2974B_is_prop_defined)
    get_property(_2BA2974B_prop_value GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${_2BA2974B_props_stack_next_size}")
    set_property("${prop_entry}" PROPERTY "${prop_name}" "${_2BA2974B_prop_value}")
  else()
    set(_2BA2974B_prop_value "")
    set_property("${prop_entry}" PROPERTY "${prop_name}") # unset property
  endif()

  if (_2BA2974B_props_stack_next_size)
    set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size" ${_2BA2974B_props_stack_next_size})
  else()
    set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size") # unset property
  endif()

  # unset previous
  set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${_2BA2974B_props_stack_next_size}")
  set_property(GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::${_2BA2974B_props_stack_next_size}::defined")

  if (NOT out_var STREQUAL "" AND NOT out_var STREQUAL ".")
    if (_2BA2974B_is_prop_defined)
      set(${out_var} "${_2BA2974B_prop_value}" PARENT_SCOPE)
    else()
      unset(${out_var} PARENT_SCOPE)
    endif()
  endif()
endfunction()

function(tkl_get_prop_stack_size out_var prop_entry prop_name stack_entry)
  if (prop_entry STREQUAL "")
    message(FATAL_ERROR "prop_entry must be not empty")
  endif()
  if (prop_name STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty")
  endif()
  if (stack_entry STREQUAL "")
    message(FATAL_ERROR "stack_entry must be not empty")
  endif()

  get_property(props_stack_size GLOBAL PROPERTY "tkl::props_stack[${stack_entry}][${prop_name}]::size")
  if ("${props_stack_size}" STREQUAL "")
    set(props_stack_size 0)
  endif()

  set(${out_var} ${props_stack_size} PARENT_SCOPE)
endfunction()

function(tkl_get_prop_stack_value out_var prop_entry prop_name stack_entry index)
  if (prop_entry STREQUAL "")
    message(FATAL_ERROR "prop_entry must be not empty")
  endif()
  if (prop_name STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty")
  endif()
  if (stack_entry STREQUAL "")
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
    message(FATAL_ERROR "index out of stack bounds: index=${index} props_stack_size=${props_stack_size}")
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
  if (prop_entry STREQUAL "")
    message(FATAL_ERROR "prop_entry must be not empty")
  endif()
  if (prop_name STREQUAL "")
    message(FATAL_ERROR "var_name must be not empty")
  endif()
  if (stack_entry STREQUAL "")
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

  #message(" _39067B90_filtered_vars=${_39067B90_filtered_vars}")

  tkl_pushset_prop_to_stack(. GLOBAL "tkl::track_vars::vars_stack::vars" "tkl::track_vars" "${_39067B90_filtered_vars}")
endfunction()

# Forwards variables that was added/changed/removed since last call to `bagin_track_vars` to the parent scope.
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
  list(REMOVE_ITEM _39067B90_vars_to_set ${_39067B90_prev_vars})

  # to ignore
  if (NOT "${ARGN}" STREQUAL "")
    list(REMOVE_ITEM _39067B90_vars_to_unset ${ARGN})
    list(REMOVE_ITEM _39067B90_vars_to_set ${ARGN})
  endif()

  # propagate unset
  foreach(_39067B90_var IN LISTS _39067B90_vars_to_unset)
    unset(${_39067B90_var} PARENT_SCOPE)
    #message("unset: ${_39067B90_var}")
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

endif()
