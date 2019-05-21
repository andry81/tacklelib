# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_PROPS_INCLUDE_DEFINED)
set(TACKLELIB_PROPS_INCLUDE_DEFINED 1)

macro(tkl_get_global_prop var_name prop_name)
  get_property(${var_name} GLOBAL PROPERTY "${prop_name}")
endmacro()

function(tkl_set_global_prop_and_var var_name prop_name value)
  set_property(GLOBAL PROPERTY "${prop_name}" "${value}")
  set(${var_name} "${value}" PARENT_SCOPE)
endfunction()

function(tkl_append_global_prop prop_name value)
  get_property(prop_value GLOBAL PROPERTY "${prop_name}")
  list(APPEND prop_value "${value}")
  set_property(GLOBAL PROPERTY "${prop_name}" "${prop_value}")
endfunction()

# portable role checker
function(tkl_get_cmake_role role_name var_out)
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

endif()
