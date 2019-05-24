# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_FORWARD_VARIABLES_INCLUDE_DEFINED)
set(TACKLELIB_FORWARD_VARIABLES_INCLUDE_DEFINED 1)

# CAUTION:
# 1. Be careful with the `set(... CACHE ...)` because it unsets the original
#    variable!
#    From documentation:
#     "Finally, whenever a cache variable is added or modified by a command,
#     CMake also removes the normal variable of the same name from the current
#     scope so that an immediately following evaluation of it will expose the
#     newly cached value."
# 2. Be careful with the `set(... CACHE ... FORCE)` because it not just resets
#    the cache and unsets the original variable. Additionally to previously
#    mentioned behaviour it overrides a value passed by the `-D` cmake command
#    line parameter!
# 3. Be careful with the usual `set(<var> <value>)` when the cache value has
#    been already exist, because it actually does not change the cache value but
#    changes state of the ${<var>} value. In another words if you try later to
#    unset the original variable by the `unset(<var>)` then the cached value
#    will be revealed and might be different than after a very first set!
#

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

function(tkl_is_ARGV_var out_is_var_def var_name)
  # simple test w/o call to slow MATCH operator
  string(SUBSTRING "${var_name}" 0 4 var_prefix)
  if (var_prefix STREQUAL "ARGV")
    set(${out_is_var_def} 1 PARENT_SCOPE)
  else()
    set(${out_is_var_def} 0 PARENT_SCOPE)
  endif()
endfunction()

function(tkl_is_ARGx_var out_is_var_def var_name)
  # simple test w/o call to slow MATCH operator
  string(SUBSTRING "${var_name}" 0 3 var_prefix)
  if (var_prefix STREQUAL "ARG")
    set(${out_is_var_def} 1 PARENT_SCOPE)
  else()
    set(${out_is_var_def} 0 PARENT_SCOPE)
  endif()
endfunction()

# custom user variables stack over properties

macro(tkl_push_var_to_stack_impl var_name)
  # CAUTION:
  #   All variables here must be unique irrespective to the function scope,
  #   because "if (DEFINED ${var_name})" still can be applied to a local variable!
  #

  get_property(_2BA2974B_is_vars_stack_set GLOBAL PROPERTY tkl::vars_stack[${var_name}]::size SET)
  if (_2BA2974B_is_vars_stack_set)
    get_property(_2BA2974B_vars_stack_size GLOBAL PROPERTY tkl::vars_stack[${var_name}]::size)
  else()
    set(_2BA2974B_vars_stack_size 0)
  endif()

  set_property(GLOBAL PROPERTY tkl::vars_stack[${var_name}]::${_2BA2974B_vars_stack_size} "${${var_name}}")
  if (DEFINED ${var_name})
    set_property(GLOBAL PROPERTY tkl::vars_stack[${var_name}]::${_2BA2974B_vars_stack_size}::is_defined 1)
  else()
    set_property(GLOBAL PROPERTY tkl::vars_stack[${var_name}]::${_2BA2974B_vars_stack_size}::is_defined 0)
  endif()

  math(EXPR _2BA2974B_vars_stack_size ${_2BA2974B_vars_stack_size}+1)
  set_property(GLOBAL PROPERTY tkl::vars_stack[${var_name}]::size ${_2BA2974B_vars_stack_size})
endmacro()

function(tkl_pushset_var_to_stack var_name var_value)
  tkl_push_var_to_stack_impl(${var_name})

  set(${var_name} "${var_value}" PARENT_SCOPE)
endfunction()

function(tkl_pushunset_var_to_stack var_name)
  tkl_push_var_to_stack_impl(${var_name})

  unset(${var_name} PARENT_SCOPE)
endfunction()

function(tkl_pop_var_from_stack var_name)
  # INFO:
  #   All variables here are unique just in case.
  #

  get_property(_2BA2974B_vars_stack_size GLOBAL PROPERTY tkl::vars_stack[${var_name}]::size)
  if (NOT _2BA2974B_vars_stack_size)
    message(FATAL_ERROR "variables stack either undefined or empty")
  endif()

  math(EXPR _2BA2974B_vars_stack_next_size ${_2BA2974B_vars_stack_size}-1)

  get_property(_2BA2974B_is_var_defined GLOBAL PROPERTY tkl::vars_stack[${var_name}]::${_2BA2974B_vars_stack_next_size}::is_defined)
  if (_2BA2974B_is_var_defined)
    get_property(_2BA2974B_var_value GLOBAL PROPERTY tkl::vars_stack[${var_name}]::${_2BA2974B_vars_stack_next_size})
    set(${var_name} "${_2BA2974B_var_value}" PARENT_SCOPE)
  else()
    unset(${var_name} PARENT_SCOPE)
  endif()

  if (_2BA2974B_vars_stack_next_size)
    set_property(GLOBAL PROPERTY tkl::vars_stack[${var_name}]::size ${_2BA2974B_vars_stack_next_size})
  else()
    set_property(GLOBAL PROPERTY tkl::vars_stack[${var_name}]::size) # unset property
  endif()

  # unset previous
  set_property(GLOBAL PROPERTY tkl::vars_stack[${var_name}]::${_2BA2974B_vars_stack_size})
  set_property(GLOBAL PROPERTY tkl::vars_stack[${var_name}]::${_2BA2974B_vars_stack_size}::is_defined)
endfunction()

function(tkl_get_var_stack_size out_var var_name)
  get_property(vars_stack_size GLOBAL PROPERTY tkl::vars_stack[${var_name}]::size)
  if (vars_stack_size STREQUAL "")
    set(vars_stack_size 0)
  endif()
  set(out_var ${vars_stack_size} PARENT_SCOPE)
endfunction()

# custom user properties stack over properties

macro(tkl_push_prop_to_stack_impl prop_entry prop_name)
  # INFO:
  #   All variables here are unique just in case.
  #

  get_property(_2BA2974B_is_props_stack_set GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::size SET)
  if (_2BA2974B_is_props_stack_set)
    get_property(_2BA2974B_props_stack_size GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::size)
  else()
    set(_2BA2974B_props_stack_size 0)
  endif()

  get_property(_2BA2974B_prop_value_set "${prop_entry}" PROPERTY "${prop_name}" SET)
  if (_2BA2974B_prop_value_set)
    get_property(_2BA2974B_prop_value "${prop_entry}" PROPERTY "${prop_name}")
    set_property(GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::${_2BA2974B_props_stack_size} "${_2BA2974B_prop_value}")
  endif()
  set_property(GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::${_2BA2974B_props_stack_size}::is_defined ${_2BA2974B_prop_value_set})

  math(EXPR _2BA2974B_props_stack_size ${_2BA2974B_props_stack_size}+1)
  set_property(GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::size ${_2BA2974B_props_stack_size})
endmacro()

function(tkl_pushset_prop_to_stack out_var prop_entry prop_name var_value)
  tkl_push_prop_to_stack_impl("${prop_entry}" "${prop_name}")

  set_property("${prop_entry}" PROPERTY "${prop_name}" "${var_value}")

  if (NOT out_var STREQUAL "" AND NOT out_var STREQUAL ".")
    set(${out_var} "${var_value}" PARENT_SCOPE)
  endif()
endfunction()

function(tkl_pushunset_prop_to_stack prop_entry prop_name)
  tkl_push_prop_to_stack_impl("${prop_entry}" "${prop_name}")

  set_property("${prop_entry}" PROPERTY "${prop_name}") # unset property
endfunction()

function(tkl_pop_prop_from_stack out_var prop_entry prop_name)
  # INFO:
  #   All variables here are unique just in case.
  #

  get_property(_2BA2974B_props_stack_size GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::size)
  if (NOT _2BA2974B_props_stack_size)
    message(FATAL_ERROR "properties stack either undefined or empty")
  endif()

  math(EXPR _2BA2974B_props_stack_next_size ${_2BA2974B_props_stack_size}-1)

  get_property(_2BA2974B_is_prop_defined GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::${_2BA2974B_props_stack_next_size}::is_defined)
  if (_2BA2974B_is_prop_defined)
    get_property(_2BA2974B_prop_value GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::${_2BA2974B_props_stack_next_size})
    set_property("${prop_entry}" PROPERTY "${prop_name}" "${_2BA2974B_prop_value}")
  else()
    set(_2BA2974B_prop_value "")
    set_property("${prop_entry}" PROPERTY "${prop_name}") # unset property
  endif()

  if (_2BA2974B_props_stack_next_size)
    set_property(GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::size ${_2BA2974B_props_stack_next_size})
  else()
    set_property(GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::size) # unset property
  endif()

  # unset previous
  set_property(GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::${_2BA2974B_props_stack_size})
  set_property(GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::${_2BA2974B_props_stack_size}::is_defined)

  if (NOT out_var STREQUAL "" AND NOT out_var STREQUAL ".")
    set(${out_var} "${_2BA2974B_prop_value}" PARENT_SCOPE)
  endif()
endfunction()

function(tkl_get_prop_stack_size out_var prop_entry prop_name)
  get_property(props_stack_size GLOBAL PROPERTY tkl::props_stack[${prop_entry}::${prop_name}]::size)
  if (props_stack_size STREQUAL "")
    set(props_stack_size 0)
  endif()
  set(out_var ${props_stack_size} PARENT_SCOPE)
endfunction()

macro(tkl_begin_emulate_shift_ARGVn) # WITH OUT ARGUMENTS!
  # WORKAROUND:
  #  Because we can not change values of ARGV0..N arguments, then we have to
  #  replace them by local variables to emulate arguments shift!
  #

  if (NOT ${ARGC} GREATER 0)
    message(FATAL_ERROR "function must not be called with arguments")
  endif()

  if (NOT "${ARGV}" STREQUAL "")
    tkl_pushset_var_to_stack(ARGV "${ARGV}")
  else()
    tkl_pushunset_var_to_stack(ARGV)
  endif()

  # update ARGVn variables
  set(_6CFB89A4_index 0)
  foreach(_6CFB89A4_arg IN LISTS ARGV)
    if (NOT "${_6CFB89A4_arg}" STREQUAL "")
      tkl_pushset_var_to_stack(ARGV${_6CFB89A4_index} "${_6CFB89A4_arg}")
    else()
      tkl_pushunset_var_to_stack(ARGV${_6CFB89A4_index})
    endif()
    math(EXPR _6CFB89A4_index ${_6CFB89A4_index}+1)
  endforeach()

  tkl_pushset_var_to_stack(_6CFB89A4_num_emul_argv ${_6CFB89A4_index})

  # cleanup local variables
  unset(_6CFB89A4_arg)
  unset(_6CFB89A4_index)
endmacro()

macro(tkl_end_emulate_shift_ARGVn)
  if (NOT ${ARGC} GREATER 0)
    message(FATAL_ERROR "function must not be called with arguments")
  endif()

  set(_6CFB89A4_index 0)
  while(_6CFB89A4_index LESS _6CFB89A4_num_emul_argv)
    tkl_popset_var_from_stack(ARGV${_6CFB89A4_index})
    math(EXPR _6CFB89A4_index ${_6CFB89A4_index}+1)
  endwhile()
  tkl_popset_var_from_stack(_6CFB89A4_num_emul_argv)

  tkl_popset_var_from_stack(ARGV)

  # cleanup local variables
  unset(_6CFB89A4_index)
endmacro()

# CAUTION:
# 1. User must not use builtin ARGC/ARGV/ARGN/ARGV0..N variables because they are a part of function/macro call stack
#
function(tkl_get_var out_uncached_var out_cached_var var_name)
  if (out_uncached_var AND NOT out_uncached_var STREQUAL ".")
    set(out_uncached_var_is_defined 1)
  else()
    set(out_uncached_var_is_defined 0)
  endif()

  if (out_cached_var AND NOT out_cached_var STREQUAL ".")
    set(out_cached_var_is_defined 1)
  else()
    set(out_cached_var_is_defined 0)
  endif()

  if (NOT out_uncached_var_is_defined AND NOT out_cached_var_is_defined)
    message(FATAL_ERROR "at least one output variable must be defined")
  endif()

  if (out_uncached_var_is_defined)
    if (out_uncached_var STREQUAL var_name)
      message(FATAL_ERROR "out_uncached_var and var_name variables must be different: `${out_uncached_var}`")
    endif()
  endif()

  if (out_uncached_var_is_defined OR out_cached_var_is_defined)
    if (out_uncached_var STREQUAL out_cached_var)
      message(FATAL_ERROR "out_uncached_var and out_cached_var variables must be different: `${out_cached_var}`")
    endif()
  endif()

  # check for specific builtin variables
  string(SUBSTRING "${var_name}" 0 3 _5FC3B9AA_var_forbidden)
  if (_5FC3B9AA_var_forbidden STREQUAL "ARG")
    message(FATAL_ERROR "specific builtin variables are forbidden to use: `${var_name}`")
  endif()

  get_property(_5FC3B9AA_var_cache_value_is_set CACHE "${var_name}" PROPERTY VALUE SET)

  if (NOT _5FC3B9AA_var_cache_value_is_set)
    if (out_cached_var_is_defined)
      unset(${out_uncached_var} PARENT_SCOPE)
    endif()
    if (out_uncached_var_is_defined)
      set(${out_uncached_var} "${${var_name}}" PARENT_SCOPE)
    endif()
  else()
    if (out_cached_var_is_defined)
      # propagate cached variant of a variable
      if (DEFINED ${var_name})
        set(${out_cached_var} "${${var_name}}" PARENT_SCOPE)
      else()
        unset(${out_cached_var} PARENT_SCOPE)
      endif()
    endif()

    if (out_uncached_var_is_defined)
      # save cache properties of a variable
      get_property(_5FC3B9AA_var_cache_value CACHE "${var_name}" PROPERTY VALUE)
      get_property(_5FC3B9AA_var_cache_type CACHE "${var_name}" PROPERTY TYPE)
      get_property(_5FC3B9AA_var_cache_docstring CACHE "${var_name}" PROPERTY HELPSTRING)

      # remove cached variant of a variable
      unset(${var_name} CACHE)

      # propagate uncached variant of a variable
      if (DEFINED ${var_name})
        set(${out_uncached_var} "${${var_name}}" PARENT_SCOPE)
      else()
        unset(${out_uncached_var} PARENT_SCOPE)
      endif()

      # restore cache properties of a variable
      #message("set(${var_name} `${_5FC3B9AA_var_cache_value}` CACHE `${_5FC3B9AA_var_cache_type}` `${_5FC3B9AA_var_cache_docstring}`)")
      set(${var_name} "${_5FC3B9AA_var_cache_value}" CACHE ${_5FC3B9AA_var_cache_type} "${_5FC3B9AA_var_cache_docstring}")
    endif()
  endif()
endfunction()

# Start to track variables for change or adding.
# Note that variables starting with underscore are NOT ignored.
function(tkl_begin_track_vars)
  # all variables with the `_39067B90_` prefix will be gnored by the search logic itself
  get_cmake_property(_39067B90_old_vars VARIABLES)

  #message(" _39067B90_old_vars=${_39067B90_old_vars}")

  foreach(_39067B90_var IN LISTS _39067B90_old_vars)
    # check for this function variables
    string(SUBSTRING "${_39067B90_var}" 0 10 _39067B90_var_prefix)
    if (_39067B90_var_prefix STREQUAL "_39067B90_")
      continue()
    endif()

    # check for special stack variables, should not be tracked, handles separately
    string(SUBSTRING "${_39067B90_var}" 0 10 _39067B90_var_prefix)
    if (_39067B90_var_prefix STREQUAL "_2BA2974B_")
      continue()
    endif()

    # check for specific builtin variables
    string(SUBSTRING "${_39067B90_var}" 0 3 _39067B90_var_prefix)
    if (_39067B90_var_prefix STREQUAL "ARG")
      continue()
    endif()

    # we must compare with uncached variable variant ONLY
    tkl_get_var(_39067B90_old_var_${_39067B90_var} . ${_39067B90_var})
    if (DEFINED _39067B90_old_var_${_39067B90_var})
      set(_39067B90_old_var_${_39067B90_var} ${_39067B90_old_var_${_39067B90_var}} PARENT_SCOPE)
    # no need to unset because of uniqueness of a variable name
    #else()
    #  unset(_39067B90_old_var_${_39067B90_var} PARENT_SCOPE)
    endif()
    #message(" _39067B90_old_var_${_39067B90_var}=`${_39067B90_old_var_${_39067B90_var}}`")
  endforeach()
endfunction()

# tkl_forward_changed_vars_to_parent_scope([exclusions])
# Forwards variables that was added/changed since last call to start_track_vars() to the parent scope.
# Note that variables starting with underscore are NOT ignored.
macro(tkl_forward_changed_vars_to_parent_scope)
  # all variables with the `_39067B90_` prefix will be gnored by the search logic itself
  get_cmake_property(_39067B90_vars VARIABLES)
  set(_39067B90_ignore_vars ${ARGN})

  #message(" _39067B90_vars=${_39067B90_vars}")
  foreach(_39067B90_var IN LISTS _39067B90_vars)
    list(FIND _39067B90_ignore_vars ${_39067B90_var} _39067B90_is_var_ignored)
    if(NOT _39067B90_is_var_ignored EQUAL -1)
      continue()
    endif()

    # check for this function variables
    string(SUBSTRING "${_39067B90_var}" 0 10 _39067B90_var_prefix)
    if (_39067B90_var_prefix STREQUAL "_39067B90_")
      continue()
    endif()

    # check for special stack variables, should not be tracked, handles separately
    string(SUBSTRING "${_39067B90_var}" 0 10 _39067B90_var_prefix)
    if (_39067B90_var_prefix STREQUAL "_2BA2974B_")
      continue()
    endif()

    # check for specific builtin variables
    string(SUBSTRING "${_39067B90_var}" 0 3 _39067B90_var_prefix)
    if (_39067B90_var_prefix STREQUAL "ARG")
      continue()
    endif()

    # we must compare with uncached variable variant ONLY
    tkl_get_var(_39067B90_var_uncached . ${_39067B90_var})

    if(DEFINED _39067B90_old_var_${_39067B90_var})
      if (DEFINED _39067B90_var_uncached)
        if(NOT _39067B90_var_uncached STREQUAL _39067B90_old_var_${_39067B90_var})
          set(${_39067B90_var} ${_39067B90_var_uncached} PARENT_SCOPE)
        endif()
      else()
        unset(${_39067B90_var} PARENT_SCOPE)
      endif()
    elseif (DEFINED _39067B90_var_uncached)
      set(${_39067B90_var} ${_39067B90_var_uncached} PARENT_SCOPE)
    endif()
  endforeach()
endmacro()

function(tkl_end_track_vars)
  get_cmake_property(_9F05B048_vars VARIABLES)
  #message(" _9F05B048_vars=${_9F05B048_vars}")

  foreach(_9F05B048_var IN LISTS _9F05B048_vars)
    string(SUBSTRING "${_9F05B048_var}" 0 10 _9F05B048_var_prefix)
    if (NOT _9F05B048_var_prefix STREQUAL "_39067B90_")
      continue()
    endif()

    unset(${_9F05B048_var} PARENT_SCOPE)
    #unset(${_9F05B048_var}) # must be unset here too to retest at the end
    #message(" unset ${_9F05B048_var}")
  endforeach()

  # CAUTION: For correct check all variables must be unset in the current scope too!
  #get_cmake_property(_9F05B048_vars VARIABLES)
  #message(" _9F05B048_vars=${_9F05B048_vars}")
endfunction()

endif()
