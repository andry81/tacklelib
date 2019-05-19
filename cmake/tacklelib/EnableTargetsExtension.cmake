# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_ENABLE_TARGETS_EXTENSION_INCLUDE_DEFINED)
set(TACKLELIB_ENABLE_TARGETS_EXTENSION_INCLUDE_DEFINED 1)

include(tacklelib/Project)
include(tacklelib/ForwardVariables)
include(tacklelib/Handlers)

# INFO:
#   Detected inconsistency in multiple 3dparty projects, like fmt and libarchive, after call to add_subdirectory and others:
#   fmt: https://github.com/fmtlib/fmt/issues/1081
#   libarchive: https://github.com/libarchive/libarchive/issues/1163
#   Has added the check to test several most important shared variables on inconsistent change from child projects to stop this
#   bullshit at early pass!
#

if (NOT TACKLELIB_ENABLE_TARGETS_EXTENSION_FUNCTION_INVOKERS)
  # much faster, but builtin variables ARGx are emulated here

  macro(tkl_add_library_invoker)
    _add_library(${ARGV})
  endmacro()

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
    #  Because builtin system functions like add_subdirectory does not change
    #  some builtin variables like ARGVn, then we have to replace them by local
    #  variants to emulate arguments shift!
    #
    tkl_begin_emulate_shift_ARGVn()
    tkl_add_subdirectory_begin(${ARGV})

    _add_subdirectory(${ARGV}) # DOES NOT CHANGE ARGVn arguments!

    tkl_add_subdirectory_end(${ARGV})
    tkl_end_emulate_shift_ARGVn()

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()
  endmacro()

  macro(tkl_find_package_invoker)
    # WORKAROUND:
    #  Because builtin system functions like add_subdirectory does not change
    #  some builtin variables like ARGVn, then we have to replace them by local
    #  variants to emulate arguments shift!
    #
    #tkl_begin_emulate_shift_ARGVn()

    _find_package(${ARGV})

    #tkl_end_emulate_shift_ARGVn()

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()
  endmacro()
else()
  # slower, but builtin variables ARGx can be controlled here through the variable forwarding logic

  # We should prepare arguments list before call to system function because in the real world a function can exist as a MACRO.
  # This means the ARGx built-in variables MAY BECOME INVALID and relate to a different function signature!
  # We must restore them into original state by call to a potential macro through an intermediate function!

  function(tkl_add_library_invoker)
    # Now ARGx built-in variables would be related to the add_library_invoker function parameters list instead of upper caller
    # which might has different/shifted parameters list!
    # But now we have to propagate all changed variables here into upper context by ourselves!
    tkl_begin_track_vars()

    _add_library(${ARGV})

    tkl_forward_changed_vars_to_parent_scope()
    tkl_end_track_vars()
  endfunction()

  function(tkl_add_executable_invoker)
    # Now ARGx built-in variables would be related to the add_executable_invoker function parameters list instead of upper caller
    # which might has different/shifted parameters list!
    # But now we have to propagate all changed variables here into upper context by ourselves!
    tkl_begin_track_vars()

    _add_executable(${ARGV})

    tkl_forward_changed_vars_to_parent_scope()
    tkl_end_track_vars()
  endfunction()

  function(tkl_add_custom_target_invoker)
    # Now ARGx built-in variables would be related to the add_custom_target_invoker function parameters list instead of upper caller
    # which might has different/shifted parameters list!
    # But now we have to propagate all changed variables here into upper context by ourselves!
    tkl_begin_track_vars()

    _add_custom_target(${ARGV})

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()

    tkl_forward_changed_vars_to_parent_scope()
    tkl_end_track_vars()
  endfunction()

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
    tkl_begin_track_vars()

    _add_subdirectory(${ARGV})

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()

    tkl_forward_changed_vars_to_parent_scope()
    tkl_end_track_vars()
  endfunction()

  function(tkl_find_package_invoker)
    # Now ARGx built-in variables would be related to the `tkl_find_package_invoker` function parameters list instead of upper caller
    # which might has different/shifted parameters list!
    # But now we have to propagate all changed variables here into upper context by ourselves!
    tkl_begin_track_vars()

    _find_package(${ARGV})

    # Global variables inconsistency check, see details in this file header.
    tkl_check_global_vars_consistency()

    tkl_forward_changed_vars_to_parent_scope()
    tkl_end_track_vars()
  endfunction()
endif()

macro(add_library)
  tkl_add_library_begin(${ARGV})
  tkl_add_library_invoker(${ARGV})
  tkl_add_library_end(${ARGV})
endmacro()

macro(add_executable)
  tkl_add_executable_begin(${ARGV})
  tkl_add_executable_invoker(${ARGV})
  tkl_add_executable_end(${ARGV})
endmacro()

macro(add_custom_target)
  tkl_add_custom_target_begin(${ARGV})
  tkl_add_custom_target_invoker(${ARGV})
  tkl_add_custom_target_end(${ARGV})
endmacro()

macro(add_subdirectory)
  tkl_add_subdirectory_begin(${ARGV})
  tkl_add_subdirectory_invoker(${ARGV})
  tkl_add_subdirectory_end(${ARGV})
endmacro()

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

endif()
