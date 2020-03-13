# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_ENABLE_TARGETS_EXTENSION_INCLUDE_DEFINED)
set(TACKLELIB_ENABLE_TARGETS_EXTENSION_INCLUDE_DEFINED 1)

include(tacklelib/Project)
include(tacklelib/ForwardVariables)
include(tacklelib/Reimpl)

# INFO:
#   Detected an inconsistency in multiple 3dparty projects, like fmt and
#   libarchive, after call to add_subdirectory and others:
#   fmt: https://github.com/fmtlib/fmt/issues/1081
#   libarchive: https://github.com/libarchive/libarchive/issues/1163
#   Have had to add the check to test several most important shared variables
#   on inconsistent change from child projects to stop this bullshit at early
#   pass!
#

# PERFORMANCE INFO:
#   1. * TACKLELIB_ENABLE_TARGETS_EXTENSION_FUNCTION_HANDLERS=OFF:
#      ** Much faster.
#      ** Builtin macro variables ARGx are emulated through the function scope
#        variables with the same name.
#      * TACKLELIB_ENABLE_TARGETS_EXTENSION_FUNCTION_HANDLERS=ON:
#      ** Slower.
#      ** Builtin function variables ARGx are ignored because of a function
#         scope, the rest upper context would be restored on a function return.
#

macro(tkl_pushset_package_vars)
  # push-set all registered context variables for a package source directory
  get_property(_9DB7D667_global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR")

  tkl_has_system_context_vars("tkl_register_package_var" "${_9DB7D667_global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}" _9DB7D667_has_system_context_vars)
  if (_9DB7D667_has_system_context_vars)
    tkl_pushset_all_system_context_vars("tkl_register_package_var" "${_9DB7D667_global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
  endif()

  unset(_9DB7D667_global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR)
  unset(_9DB7D667_has_system_context_vars)
endmacro()

macro(tkl_popset_package_vars)
  # pop-set all registered context variables for a package source directory
  get_property(_9DB7D667_global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR")

  tkl_has_system_context_vars("tkl_register_package_var" "${_9DB7D667_global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}" _9DB7D667_has_system_context_vars)
  if (_9DB7D667_has_system_context_vars)
    tkl_pop_all_system_context_vars("tkl_register_package_var" "${_9DB7D667_global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
  endif()

  unset(_9DB7D667_global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR)
  unset(_9DB7D667_has_system_context_vars)
endmacro()

if (NOT TACKLELIB_ENABLE_TARGETS_EXTENSION_FUNCTION_HANDLERS)
  macro(tkl_add_library_invoker)
    _add_library(${ARGV})
  endmacro()

  macro(tkl_add_executable_invoker)
    _add_executable(${ARGV})
  endmacro()

  macro(tkl_add_custom_target_invoker)
    _add_custom_target(${ARGV})
  endmacro()

  macro(tkl_add_subdirectory_invoker)
    tkl_pushset_package_vars()

    _add_subdirectory(${ARGV})

    tkl_popset_package_vars()

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()
  endmacro()

  macro(tkl_add_target_subdirectory_invoker)
    # WORKAROUND:
    #  Because builtin system functions like `add_subdirectory` behaves like a
    #  macro, then it would use ARGx variables from the upper caller context.
    #  We have to replace them reentrantly by a local context variables to
    #  avoid use ARGVn variables from an upper caller context.
    #
    tkl_pushset_ARGVn_to_stack(${ARGV})

    tkl_add_subdirectory_begin(${ARGV})

    tkl_pushset_package_vars()

    _add_subdirectory(${ARGV}) # DOES NOT CHANGE ARGVn arguments!

    tkl_popset_package_vars()

    tkl_add_subdirectory_end(${ARGV})
    tkl_pop_ARGVn_from_stack()

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()
  endmacro()

  macro(tkl_find_package_invoker)
    # WORKAROUND:
    #  Because builtin system functions like `find_package` could behave like a
    #  macro (like said in the above workaround), then it would use ARGVn
    #  variables from the upper caller context.
    #  We have to replace them reentrantly by a local context variables to
    #  avoid use ARGVn variables from an upper caller context.
    #
    tkl_pushset_ARGVn_to_stack(${ARGV})

    tkl_pushset_package_vars()

    _find_package(${ARGV})

    tkl_popset_package_vars()

    tkl_pop_ARGVn_from_stack()

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()
  endmacro()
else()
  function(tkl_add_library_invoker)
    # Now ARGx built-in variables would be related to the function parameters
    # list instead of the upper caller context which might have has
    # different/shifted parameters list, so now we have to propagate all
    # changed variables (except the builtins) into upper context by ourselves!
    tkl_track_vars_begin()

    _add_library(${ARGV})

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endfunction()

  function(tkl_add_executable_invoker)
    # Now ARGx built-in variables would be related to the function parameters
    # list instead of the upper caller context which might have has
    # different/shifted parameters list, so now we have to propagate all
    # changed variables (except the builtins) into upper context by ourselves!
    tkl_track_vars_begin()

    _add_executable(${ARGV})

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endfunction()

  function(tkl_add_custom_target_invoker)
    # Now ARGx built-in variables would be related to the function parameters
    # list instead of the upper caller context which might have has
    # different/shifted parameters list, so now we have to propagate all
    # changed variables (except the builtins) into upper context by ourselves!
    tkl_track_vars_begin()

    _add_custom_target(${ARGV})

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endfunction()

  # CAUTION:
  #   Must be a macro to automatically propagate changes from the inner
  #   `_add_subdirectory`.
  #
  macro(tkl_add_target_subdirectory_invoker)
    tkl_add_subdirectory_begin(${ARGV})
    tkl_add_subdirectory_invoker(${ARGV})

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()

    tkl_add_subdirectory_end(${ARGV})
  endmacro()

  function(tkl_add_subdirectory_invoker)
    # Now ARGx built-in variables would be related to the function parameters
    # list instead of the upper caller context which might have has
    # different/shifted parameters list, so now we have to propagate all
    # changed variables (except the builtins) into upper context by ourselves!
    tkl_track_vars_begin()

    tkl_pushset_package_vars()

    _add_subdirectory(${ARGV})

    tkl_popset_package_vars()

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endfunction()

  function(tkl_find_package_invoker)
    # Now ARGx built-in variables would be related to the function parameters
    # list instead of the upper caller context which might have has
    # different/shifted parameters list, so now we have to propagate all
    # changed variables (except the builtins) into upper context by ourselves!
    tkl_track_vars_begin()

    tkl_pushset_package_vars()

    _find_package(${ARGV})

    tkl_popset_package_vars()

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endfunction()
endif()

# cmake system functions reimplementation

# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can
#   take a place!
#
macro(add_library)
  tkl_add_library_begin(${ARGV})
  tkl_add_library_invoker(${ARGV})
  tkl_add_library_end(${ARGV})
endmacro()

tkl_register_implementation(macro add_library)

# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can
#   take a place!
#
macro(add_executable)
  tkl_add_executable_begin(${ARGV})
  tkl_add_executable_invoker(${ARGV})
  tkl_add_executable_end(${ARGV})
endmacro()

tkl_register_implementation(macro add_executable)

# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can
#   take a place!
#
macro(add_custom_target)
  tkl_add_custom_target_begin(${ARGV})
  tkl_add_custom_target_invoker(${ARGV})
  tkl_add_custom_target_end(${ARGV})
endmacro()

tkl_register_implementation(macro add_custom_target)

# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can
#   take a place!
#
macro(add_subdirectory)
  tkl_add_subdirectory_begin(${ARGV})
  tkl_add_subdirectory_invoker(${ARGV})
  tkl_add_subdirectory_end(${ARGV})
endmacro()

tkl_register_implementation(macro add_subdirectory)

# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can
#   take a place!
#
macro(find_package _arg0)
  if(${ARGC} GREATER 1)
    # drop extension parameters before call to a system function
    tkl_is_var(_4E6AC8D8_is_argv0_var_name ${ARGV0})
    if (_4E6AC8D8_is_argv0_var_name AND IS_DIRECTORY "${${ARGV0}}")
      tkl_find_package_begin(${ARGV})
      #message(" 1 tkl_find_package_invoker(${ARGN})")
      tkl_find_package_invoker(${ARGN})
      tkl_find_package_end(${ARGV})
    elseif (_4E6AC8D8_is_argv0_var_name AND EXISTS "${${ARGV0}}")
      # not a directory path
      #message(" 2 tkl_find_package_invoker(${ARGN})")
      tkl_find_package_begin(. ${ARGN})
      tkl_find_package_invoker(${ARGN})
      tkl_find_package_end(. ${ARGN})
    else()
      # compatability
      #message(" 3 tkl_find_package_invoker(${ARGV})")
      tkl_find_package_begin(. ${ARGV})
      tkl_find_package_invoker(${ARGV})
      tkl_find_package_end(. ${ARGV})
    endif()
    unset(_4E6AC8D8_is_argv0_var_name)
  else()
    # compatability
    #message(" 4 tkl_find_package_invoker(${ARGV})")
    tkl_find_package_begin(. ${ARGV})
    tkl_find_package_invoker(${ARGV})
    tkl_find_package_end(. ${ARGV})
  endif()
endmacro()

tkl_register_implementation(macro find_package)

endif()
