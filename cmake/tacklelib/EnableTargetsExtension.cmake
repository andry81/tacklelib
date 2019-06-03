# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_ENABLE_TARGETS_EXTENSION_INCLUDE_DEFINED)
set(TACKLELIB_ENABLE_TARGETS_EXTENSION_INCLUDE_DEFINED 1)

include(tacklelib/Project)
include(tacklelib/ForwardVariables)
include(tacklelib/Reimpl)

# INFO:
#   Detected inconsistency in multiple 3dparty projects, like fmt and libarchive, after call to add_subdirectory and others:
#   fmt: https://github.com/fmtlib/fmt/issues/1081
#   libarchive: https://github.com/libarchive/libarchive/issues/1163
#   Has added the check to test several most important shared variables on inconsistent change from child projects to stop this
#   bullshit at early pass!
#

# PERFORMANCE INFO:
#   1. TACKLELIB_ENABLE_TARGETS_EXTENSION_FUNCTION_INVOKERS=OFF:
#     * Much faster.
#     * Builtin macro variables ARGx are emulated through the function scope
#       variables with the same name.
#      TACKLELIB_ENABLE_TARGETS_EXTENSION_FUNCTION_INVOKERS=ON:
#     * Slower.
#     * Builtin function variables ARGx does ignore, upper context restores
#       automatically by function return.
#

if (NOT TACKLELIB_ENABLE_TARGETS_EXTENSION_FUNCTION_INVOKERS)
  macro(tkl_add_executable_invoker)
    _add_executable(${ARGV})
  endmacro()

  macro(tkl_add_custom_target_invoker)
    _add_custom_target(${ARGV})

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()
  endmacro()

  macro(tkl_add_subdirectory_invoker)
    _add_subdirectory(${ARGV})

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
    tkl_pushset_macro_args_ARGVn_to_stack(${ARGV})

    tkl_add_subdirectory_begin(${ARGV})

    _add_subdirectory(${ARGV}) # DOES NOT CHANGE ARGVn arguments!

    tkl_add_subdirectory_end(${ARGV})
    tkl_pop_vars_ARGVn_from_stack()

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
    tkl_pushset_macro_args_ARGVn_to_stack(${ARGV})

    _find_package(${ARGV})

    tkl_pop_vars_ARGVn_from_stack()

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()
  endmacro()
else()
  function(tkl_add_library_invoker)
    # Now ARGx built-in variables would be related to the add_library_invoker function parameters list instead of upper caller
    # which might has different/shifted parameters list!
    # But now we have to propagate all changed variables here into upper context by ourselves!
    tkl_track_vars_begin()

    _add_library(${ARGV})

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endfunction()

  function(tkl_add_executable_invoker)
    # Now ARGx built-in variables would be related to the add_executable_invoker function parameters list instead of upper caller
    # which might has different/shifted parameters list!
    # But now we have to propagate all changed variables here into upper context by ourselves!
    tkl_track_vars_begin()

    _add_executable(${ARGV})

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endfunction()

  function(tkl_add_custom_target_invoker)
    # Now ARGx built-in variables would be related to the add_custom_target_invoker function parameters list instead of upper caller
    # which might has different/shifted parameters list!
    # But now we have to propagate all changed variables here into upper context by ourselves!
    tkl_track_vars_begin()

    _add_custom_target(${ARGV})

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endfunction()

  # CAUTION:
  #   Must be a macro to automatically propagate changes from inner `_add_subdirectory`.
  #
  macro(tkl_add_target_subdirectory_invoker)
    tkl_add_subdirectory_begin(${ARGV})
    tkl_add_subdirectory_invoker(${ARGV})

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()

    tkl_add_subdirectory_end(${ARGV})
  endmacro()

  function(tkl_add_subdirectory_invoker)
    # Now ARGx built-in variables would be related to the add_subdirectory_invoker function parameters list instead of upper caller
    # which might has different/shifted parameters list!
    # But now we have to propagate all changed variables here into upper context by ourselves!
    tkl_track_vars_begin()

    _add_subdirectory(${ARGV})

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endfunction()

  function(tkl_find_package_invoker)
    # Now ARGx built-in variables would be related to the `tkl_find_package_invoker` function parameters list instead of upper caller
    # which might has different/shifted parameters list!
    # But now we have to propagate all changed variables here into upper context by ourselves!
    tkl_track_vars_begin()

    _find_package(${ARGV})

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endfunction()
endif()

# functions reimplementation

macro(add_library)
  tkl_add_library_begin(${ARGV})
  tkl_add_library_invoker(${ARGV})
  tkl_add_library_end(${ARGV})
endmacro()

tkl_register_implementation(macro add_library)

# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can take a place!
#
macro(add_executable)
  tkl_add_executable_begin(${ARGV})
  tkl_add_executable_invoker(${ARGV})
  tkl_add_executable_end(${ARGV})
endmacro()

tkl_register_implementation(macro add_executable)

# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can take a place!
#
macro(add_custom_target)
  tkl_add_custom_target_begin(${ARGV})
  tkl_add_custom_target_invoker(${ARGV})
  tkl_add_custom_target_end(${ARGV})
endmacro()

tkl_register_implementation(macro add_custom_target)

# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can take a place!
#
macro(add_subdirectory)
  tkl_add_subdirectory_begin(${ARGV})
  tkl_add_subdirectory_invoker(${ARGV})
  tkl_add_subdirectory_end(${ARGV})
endmacro()

tkl_register_implementation(macro add_subdirectory)

# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can take a place!
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
