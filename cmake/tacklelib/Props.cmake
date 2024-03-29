# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_PROPS_INCLUDE_DEFINED)
set(TACKLELIB_PROPS_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.7)

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# property getter to explicitly state details (set empty or unset if undefined)
function(tkl_get_global_prop out_var prop_name set_empty_if_undefined)
  get_property(prop_is_set GLOBAL PROPERTY "${prop_name}" SET)
  if (prop_is_set)
    get_property(prop_value GLOBAL PROPERTY "${prop_name}")
    set(${out_var} "${prop_value}" PARENT_SCOPE)
  elseif (set_empty_if_undefined)
    set(${out_var} "" PARENT_SCOPE)
  else()
    unset(${out_var} PARENT_SCOPE)
  endif()
endfunction()

# property getter to explicitly state details (set default value if undefined), casts to boolean value if defined
function(tkl_get_global_bool_prop out_var prop_name default_value)
  get_property(prop_is_set GLOBAL PROPERTY "${prop_name}" SET)
  if (prop_is_set)
    get_property(prop_value GLOBAL PROPERTY "${prop_name}")
    if (prop_value)
      set(${out_var} 1 PARENT_SCOPE)
    else()
      set(${out_var} 0 PARENT_SCOPE)
    endif()
  else()
    set(${out_var} ${default_value} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_set_global_prop out_var prop_name value)
  set_property(GLOBAL PROPERTY "${prop_name}" "${value}")
  if (NOT "${out_var}" STREQUAL "" AND NOT "${out_var}" STREQUAL ".")
    set(${out_var} "${value}" PARENT_SCOPE)
  endif()
endfunction()

function(tkl_unset_global_prop out_var prop_name)
  set_property(GLOBAL PROPERTY "${prop_name}") # unset property
  if (NOT "${out_var}" STREQUAL "" AND NOT "${out_var}" STREQUAL ".")
    unset(${out_var} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_append_global_prop out_var prop_name value)
  get_property(prop_value GLOBAL PROPERTY "${prop_name}")
  list(APPEND prop_value "${value}")
  set_property(GLOBAL PROPERTY "${prop_name}" "${prop_value}")
  if (NOT "${out_var}" STREQUAL "" AND NOT "${out_var}" STREQUAL ".")
    set(${out_var} "${prop_value}" PARENT_SCOPE)
  endif()
endfunction()

function(tkl_prepend_global_prop out_var prop_name value)
  get_property(prop_value GLOBAL PROPERTY "${prop_name}")
  list(INSERT prop_value 0 "${value}")
  set_property(GLOBAL PROPERTY "${prop_name}" "${prop_value}")
  if (NOT "${out_var}" STREQUAL "" AND NOT "${out_var}" STREQUAL ".")
    set(${out_var} "${prop_value}" PARENT_SCOPE)
  endif()
endfunction()

# portable role checker
function(tkl_get_cmake_role out_var role_name)
  if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.14.0")
    # https://cmake.org/cmake/help/latest/prop_gbl/CMAKE_ROLE.html#prop_gbl:CMAKE_ROLE
    get_property(cmake_role GLOBAL PROPERTY CMAKE_ROLE)
    if ("${cmake_role}" STREQUAL "${role_name}")
      set(${out_var} 1 PARENT_SCOPE)
    else()
      set(${out_var} 0 PARENT_SCOPE)
    endif()
  else()
    if ("${role_name}" STREQUAL "SCRIPT")
      # https://cmake.org/cmake/help/latest/variable/CMAKE_SCRIPT_MODE_FILE.html
      if (CMAKE_SCRIPT_MODE_FILE)
        set(${out_var} 1 PARENT_SCOPE)
      else()
        set(${out_var} 0 PARENT_SCOPE)
      endif()
    else()
      message(FATAL_ERROR "not implemented")
    endif()
  endif()
endfunction()

function(tkl_is_var_cached out_is_var_def var_name)
  # `if (DEFINED CACHE{...})` is supported from 3.14.0: https://cmake.org/cmake/help/v3.14/release/3.14.html#commands
  if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.14.0")
    if (DEFINED CACHE{${var_name}})
      set(${out_is_var_def} 1)
    else()
      set(${out_is_var_def} 0)
    endif()
  else()
    get_property(${out_is_var_def} CACHE "${var_name}" PROPERTY VALUE SET)
  endif()
endfunction()

endif()
