# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_PROPS_INCLUDE_DEFINED)
set(TACKLELIB_PROPS_INCLUDE_DEFINED 1)

# property getter to explicitly state details (set empty or unset if undefined)
function(tkl_get_global_prop var_name prop_name set_empty_if_undefined)
  get_property(prop_is_set GLOBAL PROPERTY "${prop_name}" SET)
  if (prop_is_set)
    get_property(prop_value GLOBAL PROPERTY "${prop_name}")
    set(${var_name} "${prop_value}" PARENT_SCOPE)
  elseif (set_empty_if_undefined)
    set(${var_name} "" PARENT_SCOPE)
  else()
    unset(${var_name} PARENT_SCOPE)
  endif()
endfunction()

# property getter to explicitly state details (set default value if undefined), casts to boolean value if defined
function(tkl_get_global_bool_prop var_name prop_name default_value)
  get_property(prop_is_set GLOBAL PROPERTY "${prop_name}" SET)
  if (prop_is_set)
    get_property(prop_value GLOBAL PROPERTY "${prop_name}")
    if (prop_value)
      set(${var_name} 1 PARENT_SCOPE)
    else()
      set(${var_name} 0 PARENT_SCOPE)
    endif()
  else()
    set(${var_name} ${default_value} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_set_global_prop_and_var var_name prop_name value)
  set_property(GLOBAL PROPERTY "${prop_name}" "${value}")
  if (NOT var_name STREQUAL "" AND NOT var_name STREQUAL ".")
    set(${var_name} "${value}" PARENT_SCOPE)
  endif()
endfunction()

function(tkl_append_global_prop prop_name value)
  get_property(prop_value GLOBAL PROPERTY "${prop_name}")
  list(APPEND prop_value "${value}")
  set_property(GLOBAL PROPERTY "${prop_name}" "${prop_value}")
endfunction()

# portable role checker
function(tkl_get_cmake_role role_name out_var)
  if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.14.0")
    # https://cmake.org/cmake/help/latest/prop_gbl/CMAKE_ROLE.html#prop_gbl:CMAKE_ROLE
    get_property(cmake_role GLOBAL PROPERTY CMAKE_ROLE)
    if (cmake_role STREQUAL role_name)
      set(${out_var} 1 PARENT_SCOPE)
    else()
      set(${out_var} 0 PARENT_SCOPE)
    endif()
  else()
    if (role_name STREQUAL "SCRIPT")
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

endif()
