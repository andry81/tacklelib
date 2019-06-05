# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_FORWARD_ARGS_INCLUDE_DEFINED)
set(TACKLELIB_FORWARD_ARGS_INCLUDE_DEFINED 1)

include(tacklelib/ForwardVariables)
include(tacklelib/Props)

function(tkl_use_ARGVn_stack_begin stack_entry)
  if (stack_entry STREQUAL "" OR stack_entry STREQUAL ".")
    tkl_pushunset_prop_to_stack(GLOBAL "tkl::ARGVn_stack::stack_entry" "tkl::ARGVn_stack")
  else()
    tkl_pushset_prop_to_stack(. GLOBAL "tkl::ARGVn_stack::stack_entry" "tkl::ARGVn_stack" "${stack_entry}")
  endif()
endfunction()

function(tkl_use_ARGVn_stack_end)
  tkl_pop_prop_from_stack(. GLOBAL "tkl::ARGVn_stack::stack_entry" "tkl::ARGVn_stack")
endfunction()

macro(tkl_get_ARGVn_stack_entry out_var)
  tkl_get_global_prop(${out_var} "tkl::ARGVn_stack::stack_entry" 0)
  if ("${${out_var}}" STREQUAL "")
    set(${out_var} "default")
  endif()
endmacro()

# CAUTION:
#   Must be a macro to:
#   1. Access upper caller function ARGVn arguments.
#
macro(tkl_push_ARGVn_to_stack_from_vars) # WITH OUT ARGUMENTS
  if (${ARGC} GREATER 0)
    message(FATAL_ERROR "function must have no arguments")
  endif()

  tkl_get_ARGVn_stack_entry(_775085E8_ARGVn_stack_entry)

  unset(_775085E8_empty)

  # push ARGV, ARGC variables

  # special syntaxes to bypass macro arguments expansion
  tkl_set_global_prop(. "tkl::builtin::ARGV" "${ARGV${_775085E8_empty}}")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV${_775085E8_empty}" "${_775085E8_ARGVn_stack_entry}")

  tkl_set_global_prop(. "tkl::builtin::ARGC" "${ARGC${_775085E8_empty}}")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGC${_775085E8_empty}" "${_775085E8_ARGVn_stack_entry}")

  # real number of pushed ARGVn variables
  tkl_set_global_prop(. "tkl::builtin::ARGVn" "${ARGC${_775085E8_empty}}")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGVn${_775085E8_empty}" "${_775085E8_ARGVn_stack_entry}")

  # set ARGVn variables
  set(_775085E8_argv_index 0)
  while(_775085E8_argv_index LESS ARGC) # ARGC as a variable
    tkl_set_global_prop(. "tkl::builtin::ARGV${_775085E8_argv_index}" "${ARGV${_775085E8_argv_index}}")
    tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV${_775085E8_argv_index}" "${_775085E8_ARGVn_stack_entry}")
    math(EXPR _775085E8_argv_index ${_775085E8_argv_index}+1)
  endwhile()

  unset(_775085E8_ARGVn_stack_entry)
  unset(_775085E8_argv_index)
endmacro()

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
# PIPELINE:
#                                   +--push--> [ STACK ]
#                                   |
# INPUT [ ARGV, ARGC, ARGV0..N] --->+-assign-> [ tkl::builtin::ARG* ]
#                                   |
#                                   +-assign-> OUTPUT [ ARGV, ARGC, ARGV0..N ]
#
function(tkl_pushset_ARGVn_to_stack) # WITH OUT ARGUMENTS!
  # WORKAROUND:
  #  Because we can not change values of ARGC and ARGV0..N arguments, then we have to
  #  replace them by local variables to obscure arguments from the upper caller context!
  #

  if (NOT ${ARGC} GREATER 0)
    message(FATAL_ERROR "function must have arguments")
  endif()

  tkl_get_ARGVn_stack_entry(ARGVn_stack_entry)

  # push ARGV, ARGC variables
  tkl_set_global_prop(ARGV "tkl::builtin::ARGV" "${ARGV}")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}")
  set(ARGV "${ARGV}" PARENT_SCOPE)

  tkl_set_global_prop(ARGC "tkl::builtin::ARGC" "${ARGC}")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}")
  set(ARGC "${ARGC}" PARENT_SCOPE)

  # real number of pushed ARGVn variables
  tkl_set_global_prop(ARGVn "tkl::builtin::ARGVn" ${ARGC})
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}")

  if (${ARGC} GREATER 0)
    # push ARGVn variables

    # CAUTION: macro argument must be used WITH OUT index expansion: ${ARGV0}...${ARGVN}

    if (0 LESS ${ARGC})
      tkl_set_global_prop(ARGV0 "tkl::builtin::ARGV0" "${ARGV0}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV0" "${ARGVn_stack_entry}")
      set(ARGV0 "${ARGV0}" PARENT_SCOPE)
    endif()
    if (1 LESS ${ARGC})
      tkl_set_global_prop(ARGV1 "tkl::builtin::ARGV1" "${ARGV1}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV1" "${ARGVn_stack_entry}")
      set(ARGV1 "${ARGV1}" PARENT_SCOPE)
    endif()
    if (2 LESS ${ARGC})
      tkl_set_global_prop(ARGV2 "tkl::builtin::ARGV2" "${ARGV2}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV2" "${ARGVn_stack_entry}")
      set(ARGV2 "${ARGV2}" PARENT_SCOPE)
    endif()
    if (3 LESS ${ARGC})
      tkl_set_global_prop(ARGV3 "tkl::builtin::ARGV3" "${ARGV3}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV3" "${ARGVn_stack_entry}")
      set(ARGV3 "${ARGV3}" PARENT_SCOPE)
    endif()
    if (4 LESS ${ARGC})
      tkl_set_global_prop(ARGV4 "tkl::builtin::ARGV4" "${ARGV4}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV4" "${ARGVn_stack_entry}")
      set(ARGV4 "${ARGV4}" PARENT_SCOPE)
    endif()
    if (5 LESS ${ARGC})
      tkl_set_global_prop(ARGV5 "tkl::builtin::ARGV5" "${ARGV5}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV5" "${ARGVn_stack_entry}")
      set(ARGV5 "${ARGV5}" PARENT_SCOPE)
    endif()
    if (6 LESS ${ARGC})
      tkl_set_global_prop(ARGV6 "tkl::builtin::ARGV6" "${ARGV6}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV6" "${ARGVn_stack_entry}")
      set(ARGV6 "${ARGV6}" PARENT_SCOPE)
    endif()
    if (7 LESS ${ARGC})
      tkl_set_global_prop(ARGV7 "tkl::builtin::ARGV7" "${ARGV7}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV7" "${ARGVn_stack_entry}")
      set(ARGV7 "${ARGV7}" PARENT_SCOPE)
    endif()
    if (8 LESS ${ARGC})
      tkl_set_global_prop(ARGV8 "tkl::builtin::ARGV8" "${ARGV8}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV8" "${ARGVn_stack_entry}")
      set(ARGV8 "${ARGV8}" PARENT_SCOPE)
    endif()
    if (9 LESS ${ARGC})
      tkl_set_global_prop(ARGV9 "tkl::builtin::ARGV9" "${ARGV9}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV9" "${ARGVn_stack_entry}")
      set(ARGV9 "${ARGV9}" PARENT_SCOPE)
    endif()
    if (10 LESS ${ARGC})
      tkl_set_global_prop(ARGV10 "tkl::builtin::ARGV10" "${ARGV10}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV10" "${ARGVn_stack_entry}")
      set(ARGV10 "${ARGV10}" PARENT_SCOPE)
    endif()
    if (11 LESS ${ARGC})
      tkl_set_global_prop(ARGV11 "tkl::builtin::ARGV11" "${ARGV11}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV11" "${ARGVn_stack_entry}")
      set(ARGV11 "${ARGV11}" PARENT_SCOPE)
    endif()
    if (12 LESS ${ARGC})
      tkl_set_global_prop(ARGV12 "tkl::builtin::ARGV12" "${ARGV12}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV12" "${ARGVn_stack_entry}")
      set(ARGV12 "${ARGV12}" PARENT_SCOPE)
    endif()
    if (13 LESS ${ARGC})
      tkl_set_global_prop(ARGV13 "tkl::builtin::ARGV13" "${ARGV13}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV13" "${ARGVn_stack_entry}")
      set(ARGV13 "${ARGV13}" PARENT_SCOPE)
    endif()
    if (14 LESS ${ARGC})
      tkl_set_global_prop(ARGV14 "tkl::builtin::ARGV14" "${ARGV14}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV14" "${ARGVn_stack_entry}")
      set(ARGV14 "${ARGV14}" PARENT_SCOPE)
    endif()
    if (15 LESS ${ARGC})
      tkl_set_global_prop(ARGV15 "tkl::builtin::ARGV15" "${ARGV15}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV15" "${ARGVn_stack_entry}")
      set(ARGV15 "${ARGV15}" PARENT_SCOPE)
    endif()
    if (16 LESS ${ARGC})
      tkl_set_global_prop(ARGV16 "tkl::builtin::ARGV16" "${ARGV16}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV16" "${ARGVn_stack_entry}")
      set(ARGV16 "${ARGV16}" PARENT_SCOPE)
    endif()
    if (17 LESS ${ARGC})
      tkl_set_global_prop(ARGV17 "tkl::builtin::ARGV17" "${ARGV17}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV17" "${ARGVn_stack_entry}")
      set(ARGV17 "${ARGV17}" PARENT_SCOPE)
    endif()
    if (18 LESS ${ARGC})
      tkl_set_global_prop(ARGV18 "tkl::builtin::ARGV18" "${ARGV18}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV18" "${ARGVn_stack_entry}")
      set(ARGV18 "${ARGV18}" PARENT_SCOPE)
    endif()
    if (19 LESS ${ARGC})
      tkl_set_global_prop(ARGV19 "tkl::builtin::ARGV19" "${ARGV19}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV19" "${ARGVn_stack_entry}")
      set(ARGV19 "${ARGV19}" PARENT_SCOPE)
    endif()
    if (20 LESS ${ARGC})
      tkl_set_global_prop(ARGV20 "tkl::builtin::ARGV20" "${ARGV20}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV20" "${ARGVn_stack_entry}")
      set(ARGV20 "${ARGV20}" PARENT_SCOPE)
    endif()
    if (21 LESS ${ARGC})
      tkl_set_global_prop(ARGV21 "tkl::builtin::ARGV21" "${ARGV21}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV21" "${ARGVn_stack_entry}")
      set(ARGV21 "${ARGV21}" PARENT_SCOPE)
    endif()
    if (22 LESS ${ARGC})
      tkl_set_global_prop(ARGV22 "tkl::builtin::ARGV22" "${ARGV22}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV22" "${ARGVn_stack_entry}")
      set(ARGV22 "${ARGV22}" PARENT_SCOPE)
    endif()
    if (23 LESS ${ARGC})
      tkl_set_global_prop(ARGV23 "tkl::builtin::ARGV23" "${ARGV23}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV23" "${ARGVn_stack_entry}")
      set(ARGV23 "${ARGV23}" PARENT_SCOPE)
    endif()
    if (24 LESS ${ARGC})
      tkl_set_global_prop(ARGV24 "tkl::builtin::ARGV24" "${ARGV24}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV24" "${ARGVn_stack_entry}")
      set(ARGV24 "${ARGV24}" PARENT_SCOPE)
    endif()
    if (25 LESS ${ARGC})
      tkl_set_global_prop(ARGV25 "tkl::builtin::ARGV25" "${ARGV25}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV25" "${ARGVn_stack_entry}")
      set(ARGV25 "${ARGV25}" PARENT_SCOPE)
    endif()
    if (26 LESS ${ARGC})
      tkl_set_global_prop(ARGV26 "tkl::builtin::ARGV26" "${ARGV26}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV26" "${ARGVn_stack_entry}")
      set(ARGV26 "${ARGV26}" PARENT_SCOPE)
    endif()
    if (27 LESS ${ARGC})
      tkl_set_global_prop(ARGV27 "tkl::builtin::ARGV27" "${ARGV27}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV27" "${ARGVn_stack_entry}")
      set(ARGV27 "${ARGV27}" PARENT_SCOPE)
    endif()
    if (28 LESS ${ARGC})
      tkl_set_global_prop(ARGV28 "tkl::builtin::ARGV28" "${ARGV28}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV28" "${ARGVn_stack_entry}")
      set(ARGV28 "${ARGV28}" PARENT_SCOPE)
    endif()
    if (29 LESS ${ARGC})
      tkl_set_global_prop(ARGV29 "tkl::builtin::ARGV29" "${ARGV29}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV29" "${ARGVn_stack_entry}")
      set(ARGV29 "${ARGV29}" PARENT_SCOPE)
    endif()
    if (30 LESS ${ARGC})
      tkl_set_global_prop(ARGV30 "tkl::builtin::ARGV30" "${ARGV30}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV30" "${ARGVn_stack_entry}")
      set(ARGV30 "${ARGV30}" PARENT_SCOPE)
    endif()
    if (31 LESS ${ARGC})
      tkl_set_global_prop(ARGV31 "tkl::builtin::ARGV31" "${ARGV31}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV31" "${ARGVn_stack_entry}")
      set(ARGV31 "${ARGV31}" PARENT_SCOPE)
    endif()
    if (32 LESS ${ARGC})
      message(FATAL_ERROR "out of limit number of macro arguments")
    endif()
  endif()
endfunction()

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
# PIPELINE:
#                                   +--push--> [ STACK ]
#                                   |
# INPUT [ ARGV, ARGC, ARGV0..N] --->+-assign-> [ tkl::builtin::ARG* ]
#
function(tkl_push_ARGVn_to_stack) # WITH OUT ARGUMENTS!
  # WORKAROUND:
  #  Because we can not change values of ARGC and ARGV0..N arguments, then we have to
  #  replace them by local variables to obscure arguments from the upper caller context!
  #

  if (NOT ${ARGC} GREATER 0)
    message(FATAL_ERROR "function must have arguments")
  endif()

  tkl_get_ARGVn_stack_entry(ARGVn_stack_entry)

  # push ARGV, ARGC variables
  tkl_set_global_prop(. "tkl::builtin::ARGV" "${ARGV}")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}")

  tkl_set_global_prop(. "tkl::builtin::ARGC" "${ARGC}")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}")

  # real number of pushed ARGVn variables
  tkl_set_global_prop(. "tkl::builtin::ARGVn" ${ARGC})
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}")

  if (${ARGC} GREATER 0)
    # push ARGVn variables

    # CAUTION: macro argument must be used WITH OUT index expansion: ${ARGV0}...${ARGVN}

    if (0 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV0" "${ARGV0}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV0" "${ARGVn_stack_entry}")
    endif()
    if (1 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV1" "${ARGV1}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV1" "${ARGVn_stack_entry}")
      set(ARGV1 "${ARGV1}" PARENT_SCOPE)
    endif()
    if (2 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV2" "${ARGV2}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV2" "${ARGVn_stack_entry}")
    endif()
    if (3 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV3" "${ARGV3}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV3" "${ARGVn_stack_entry}")
    endif()
    if (4 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV4" "${ARGV4}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV4" "${ARGVn_stack_entry}")
    endif()
    if (5 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV5" "${ARGV5}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV5" "${ARGVn_stack_entry}")
    endif()
    if (6 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV6" "${ARGV6}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV6" "${ARGVn_stack_entry}")
    endif()
    if (7 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV7" "${ARGV7}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV7" "${ARGVn_stack_entry}")
    endif()
    if (8 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV8" "${ARGV8}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV8" "${ARGVn_stack_entry}")
    endif()
    if (9 LESS ${ARGC})
      tkl_set_global_prop(ARGV9 "tkl::builtin::ARGV9" "${ARGV9}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV9" "${ARGVn_stack_entry}")
      set(ARGV9 "${ARGV9}" PARENT_SCOPE)
    endif()
    if (10 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV10" "${ARGV10}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV10" "${ARGVn_stack_entry}")
    endif()
    if (11 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV11" "${ARGV11}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV11" "${ARGVn_stack_entry}")
    endif()
    if (12 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV12" "${ARGV12}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV12" "${ARGVn_stack_entry}")
    endif()
    if (13 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV13" "${ARGV13}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV13" "${ARGVn_stack_entry}")
    endif()
    if (14 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV14" "${ARGV14}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV14" "${ARGVn_stack_entry}")
    endif()
    if (15 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV15" "${ARGV15}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV15" "${ARGVn_stack_entry}")
    endif()
    if (16 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV16" "${ARGV16}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV16" "${ARGVn_stack_entry}")
    endif()
    if (17 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV17" "${ARGV17}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV17" "${ARGVn_stack_entry}")
    endif()
    if (18 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV18" "${ARGV18}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV18" "${ARGVn_stack_entry}")
    endif()
    if (19 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV19" "${ARGV19}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV19" "${ARGVn_stack_entry}")
    endif()
    if (20 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV20" "${ARGV20}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV20" "${ARGVn_stack_entry}")
    endif()
    if (21 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV21" "${ARGV21}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV21" "${ARGVn_stack_entry}")
    endif()
    if (22 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV22" "${ARGV22}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV22" "${ARGVn_stack_entry}")
    endif()
    if (23 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV23" "${ARGV23}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV23" "${ARGVn_stack_entry}")
    endif()
    if (24 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV24" "${ARGV24}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV24" "${ARGVn_stack_entry}")
    endif()
    if (25 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV25" "${ARGV25}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV25" "${ARGVn_stack_entry}")
    endif()
    if (26 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV26" "${ARGV26}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV26" "${ARGVn_stack_entry}")
    endif()
    if (27 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV27" "${ARGV27}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV27" "${ARGVn_stack_entry}")
    endif()
    if (28 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV28" "${ARGV28}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV28" "${ARGVn_stack_entry}")
    endif()
    if (29 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV29" "${ARGV29}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV29" "${ARGVn_stack_entry}")
    endif()
    if (30 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV30" "${ARGV30}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV30" "${ARGVn_stack_entry}")
    endif()
    if (31 LESS ${ARGC})
      tkl_set_global_prop(. "tkl::builtin::ARGV31" "${ARGV31}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV31" "${ARGVn_stack_entry}")
    endif()
    if (32 LESS ${ARGC})
      message(FATAL_ERROR "out of limit number of macro arguments")
    endif()
  endif()
endfunction()

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
# PIPELINE:
#                                   +--push--> [ STACK ]
#                                   |
# INPUT [ ARGV, ARGC, ARGV0..N] --->+-assign-> [ tkl::builtin::ARG* ]
#                                   |
#                                   +-assign-> OUTPUT [ ARGV, ARGC, ARGV0..N ]
#
function(tkl_pushset_empty_ARGVn_to_stack num_args)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  # CAUTION"
  #   We should not actually unset anything here, otherwise the builtin
  #   arguments ARGx would be in an inconsistent state,
  #   so instead we replace the unset by set to an empty string.
  #

  tkl_get_ARGVn_stack_entry(ARGVn_stack_entry)

  # set empty ARGV, ARGC variables
  tkl_set_global_prop(ARGV "tkl::builtin::ARGV" "")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}")
  set(ARGV "${ARGV}" PARENT_SCOPE)

  tkl_set_global_prop(ARGC "tkl::builtin::ARGC" 0)
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}")
  set(ARGC "${ARGC}" PARENT_SCOPE)

  # real number of pushed ARGVn variables
  tkl_set_global_prop(ARGVn "tkl::builtin::ARGVn" ${num_args})
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}")

  # set empty ARGVn variables
  set(argv_index 0)
  while(argv_index LESS ${ARGVn})
    tkl_set_global_prop(ARGV${argv_index} "tkl::builtin::ARGV${argv_index}" "")
    tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV${argv_index}" "${ARGVn_stack_entry}")
    set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
    math(EXPR argv_index ${argv_index}+1)
  endwhile()
endfunction()

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
# PIPELINE:
#                                   +--push--> [ STACK ]
#                                   |
# INPUT [ ARGV, ARGC, ARGV0..N] --->+-assign-> [ tkl::builtin::ARG* ]
#
function(tkl_push_empty_ARGVn_to_stack num_args)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  # CAUTION"
  #   We should not actually unset anything here, otherwise the builtin
  #   arguments ARGx would be in an inconsistent state,
  #   so instead we replace the unset by set to an empty string.
  #

  tkl_get_ARGVn_stack_entry(ARGVn_stack_entry)

  # set empty ARGV, ARGC variables
  tkl_set_global_prop(. "tkl::builtin::ARGV" "")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}")

  tkl_set_global_prop(. "tkl::builtin::ARGC" 0)
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}")

  # real number of pushed ARGVn variables
  tkl_set_global_prop(. "tkl::builtin::ARGVn" ${num_args})
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}")

  # set empty ARGVn variables
  set(argv_index 0)
  while(argv_index LESS ${num_args})
    tkl_set_global_prop(. "tkl::builtin::ARGV${argv_index}" "")
    tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV${argv_index}" "${ARGVn_stack_entry}")
    math(EXPR argv_index ${argv_index}+1)
  endwhile()
endfunction()

# PIPELINE:
#
# [ STACK ] ---pop--> OUTPUT [ ARGV, ARGC, ARGV0..N ]
#
# [ STACK ] -assign-> [ tkl::builtin::ARG* ]
#
function(tkl_pop_ARGVn_from_stack)
  if (${ARGC} GREATER 0)
    message(FATAL_ERROR "function must have no arguments")
  endif()

  tkl_get_ARGVn_stack_entry(ARGVn_stack_entry)

  # pop ARGV, ARGC variables
  tkl_pop_prop_from_stack(ARGV GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}")
  set(ARGV "${ARGV}" PARENT_SCOPE)
  tkl_get_prop_stack_value_no_error(prop_ARGV GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}" 0)
  if (prop_ARGV)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV" "${prop_ARGV}")
  else()
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV") # unset property
  endif()

  if (NOT DEFINED ARGV)
    message(FATAL_ERROR "ARGV must be defined after the pop")
  endif()

  tkl_pop_prop_from_stack(ARGC GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}")
  set(ARGC "${ARGC}" PARENT_SCOPE)
  tkl_get_prop_stack_value_no_error(prop_ARGC GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}" 0)
  if (DEFINED prop_ARGC)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGC" "${prop_ARGC}")
  else()
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGC") # unset property
  endif()

  if ("${ARGC}" STREQUAL "")
    message(FATAL_ERROR "ARGC must be not empty after the pop")
  endif()

  # real number of pushed ARGVn variables
  tkl_pop_prop_from_stack(ARGVn GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}")
  tkl_get_prop_stack_value_no_error(prop_ARGVn GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}" 0)
  if (DEFINED prop_ARGVn)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGVn" "${prop_ARGVn}")
  else()
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGVn") # unset property
  endif()

  if ("${ARGVn}" STREQUAL "")
    message(FATAL_ERROR "ARGVn must be not empty after the pop")
  endif()

  # pop ARGVn variables
  set(argv_index 0)
  while(argv_index LESS ARGVn)
    tkl_pop_prop_from_stack(ARGV${argv_index} GLOBAL "tkl::builtin::ARGV${argv_index}" "${ARGVn_stack_entry}")
    set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
    tkl_get_prop_stack_value_no_error(prop_ARGV${argv_index} GLOBAL "tkl::builtin::ARGV${argv_index}" "${ARGVn_stack_entry}" 0)
    if (DEFINED prop_ARGV${argv_index})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}" "${prop_ARGV${argv_index}}")
    else()
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}") # unset property
    endif()

    math(EXPR argv_index ${argv_index}+1)
  endwhile()

  # unset previously used ARGV0..N
  tkl_get_global_prop(prev_ARGVn "tkl::builtin::prev_ARGVn[${ARGVn_stack_entry}]" 0)
  if (prev_ARGVn STREQUAL "")
    set(prev_ARGVn 0)
  endif()

  if (ARGVn LESS prev_ARGVn)
    # unset rest of variables
    set(argv_index ${ARGVn})
    while(argv_index LESS prev_ARGVn)
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}") # unset property
      unset(ARGV${argv_index} PARENT_SCOPE)

      math(EXPR argv_index ${argv_index}+1)
    endwhile()
  endif()

  # remember last popped ARGVn to unset ARGV0..N
  if (DEFINED prop_ARGVn)
    set_property(GLOBAL PROPERTY "tkl::builtin::prev_ARGVn[${ARGVn_stack_entry}]" "${ARGVn}")
  else()
    # stack is empty, nothing to compare anymore
    set_property(GLOBAL PROPERTY "tkl::builtin::prev_ARGVn[${ARGVn_stack_entry}]") # unset property
  endif()

  # cascade restore from stack top to bottom
  tkl_get_prop_stack_size(ARGVn_stack_size GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}")

  set(from_argv_index ${ARGVn})

  set(ARGVn_stack_index 0)
  while(ARGVn_stack_index LESS ARGVn_stack_size)
    tkl_get_prop_stack_value(ARGVn GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}" ${ARGVn_stack_index})

    if (from_argv_index LESS ARGVn)
      # get ARGVn variables from stack top to bottom
      set(argv_index ${from_argv_index})

      while(argv_index LESS ARGVn)
        tkl_get_prop_stack_value(ARGV${argv_index} GLOBAL "tkl::builtin::ARGV${argv_index}" "${ARGVn_stack_entry}" 0)
        if (DEFINED ARGV${argv_index})
          set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}" "${ARGV${argv_index}}")
          set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
        else()
          set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}") # unset property
          unset(ARGV${argv_index} PARENT_SCOPE)
        endif()

        math(EXPR argv_index ${argv_index}+1)
      endwhile()

      set(from_argv_index ${ARGVn})
    endif()

    math(EXPR ARGVn_stack_index ${ARGVn_stack_index}+1)
  endwhile()
endfunction()

macro(tkl_get_ARGVn_stack_size out_var stack_entry)
  tkl_get_prop_stack_size(${out_var} GLOBAL "tkl::builtin::ARGVn" "${stack_entry}")
endmacro()

function(tkl_restore_ARGVn_from_stack stack_index)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  tkl_get_ARGVn_stack_entry(ARGVn_stack_entry)

  tkl_get_prop_stack_size(ARGVn_stack_size GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}")

  # pop ARGV, ARGC variables
  tkl_get_prop_stack_value_no_error(ARGV GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}" ${stack_index})
  if (DEFINED ARGV)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV" "${ARGV}")
    set(ARGV "${ARGV}" PARENT_SCOPE)
  else()
    # set empty instead of unset
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV" "")
    set(ARGV "" PARENT_SCOPE)
  endif()

  tkl_get_prop_stack_value_no_error(ARGC GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}" ${stack_index})
  if (DEFINED ARGC)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGC" "${ARGC}")
    set(ARGC "${ARGC}" PARENT_SCOPE)
  else()
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGC" 0)
    set(ARGC 0 PARENT_SCOPE)
  endif()

  # real number of pushed ARGVn variables
  tkl_get_prop_stack_value_no_error(ARGVn GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}" ${stack_index})
  if (DEFINED ARGVn)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGVn" "${ARGVn}")
  else()
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGVn" 0)
    set(ARGVn 0)
  endif()

  # restore ARGVn variables
  set(ARGVn_index 0)
  while(ARGVn_index LESS ARGVn)
    # recalculate stack index from ARGVn to ARGV0..N
    set(ARGVn_stack_index -1)
    set(args_stack_index 0)
    while(${stack_index} GREATER_EQUAL args_stack_index)
      tkl_get_prop_stack_value_no_error(num_args_by_ARGVn_stack_index GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}" ${args_stack_index})
      if (NOT "${num_args_by_ARGVn_stack_index}" STREQUAL "" AND ARGVn_index LESS num_args_by_ARGVn_stack_index)
        math(EXPR ARGVn_stack_index ${ARGVn_stack_index}+1)
      endif()

      math(EXPR args_stack_index ${args_stack_index}+1)
    endwhile()

    tkl_get_prop_stack_size(ARGV${ARGVn_index}_stack_size GLOBAL "tkl::builtin::ARGV${ARGVn_index}" "${ARGVn_stack_entry}")
    if (NOT (ARGVn_stack_index GREATER_EQUAL 0 AND ARGVn_stack_index LESS ARGV${ARGVn_index}_stack_size))
      message(FATAL_ERROR "invalid stack index for ARGV${ARGVn_index}:
stack_index=${stack_index}
ARGVn_index=${ARGVn_index}
ARGVn=${ARGVn}
ARGVn_stack_size=${ARGVn_stack_size}
ARGV${ARGVn_index}_stack_size=${ARGV${ARGVn_index}_stack_size}
ARGVn_stack_index=${ARGVn_stack_index}")
    endif()

    tkl_get_prop_stack_value(ARGV${ARGVn_index} GLOBAL "tkl::builtin::ARGV${ARGVn_index}" "${ARGVn_stack_entry}" ${ARGVn_stack_index})
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${ARGVn_index}" "${ARGV${ARGVn_index}}")
    set(ARGV${ARGVn_index} "${ARGV${ARGVn_index}}" PARENT_SCOPE)

    math(EXPR ARGVn_index ${ARGVn_index}+1)
  endwhile()

  # unset previously used ARGV0..N
  if (${stack_index} LESS ARGVn_stack_size)
    tkl_get_global_prop(prev_ARGVn "tkl::builtin::prev_ARGVn[${ARGVn_stack_entry}]" ${stack_index})
    if (prev_ARGVn STREQUAL "")
      set(prev_ARGVn 0)
    endif()
  else()
    set(prev_ARGVn 32) # clear maximum number
  endif()

  if (ARGVn LESS prev_ARGVn)
    # unset rest of variables
    set(ARGVn_index ${ARGVn})
    while(ARGVn_index LESS prev_ARGVn)
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${ARGVn_index}") # unset property
      unset(ARGV${ARGVn_index} PARENT_SCOPE)

      math(EXPR ARGVn_index ${ARGVn_index}+1)
    endwhile()
  endif()

  # cascade restore from stack top to bottom
  set(from_ARGVn_index ${ARGVn})

  math(EXPR ARGVn_stack_index ${stack_index}+1)
  while(ARGVn_stack_index LESS ARGVn_stack_size)
    tkl_get_prop_stack_value(ARGVn GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}" ${ARGVn_stack_index})

    if (from_ARGVn_index LESS ARGVn)
      # get ARGVn variables from stack top to bottom
      set(ARGVn_index ${from_ARGVn_index})

      while(ARGVn_index LESS ARGVn)
        # recalculate stack index from ARGVn to ARGV0..N
        set(ARGVn_stack_index -1)
        set(args_stack_index 0)
        while(${stack_index} GREATER_EQUAL args_stack_index)
          tkl_get_prop_stack_value_no_error(num_args_by_ARGVn_stack_index GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}" ${args_stack_index})
          if (NOT "${num_args_by_ARGVn_stack_index}" STREQUAL "" AND ARGVn_index LESS num_args_by_ARGVn_stack_index)
            math(EXPR ARGVn_stack_index ${ARGVn_stack_index}+1)
          endif()

          math(EXPR args_stack_index ${args_stack_index}+1)
        endwhile()

        tkl_get_prop_stack_size(ARGV${ARGVn_index}_stack_size GLOBAL "tkl::builtin::ARGV${ARGVn_index}" "${ARGVn_stack_entry}")
        if (NOT (ARGVn_stack_index GREATER_EQUAL 0 AND ARGVn_stack_index LESS ARGV${ARGVn_index}_stack_size))
          message(FATAL_ERROR "invalid stack index for ARGV${ARGVn_index}:
stack_index=${stack_index}
ARGVn_index=${ARGVn_index}
ARGVn=${ARGVn}
ARGVn_stack_size=${ARGVn_stack_size}
ARGV${ARGVn_index}_stack_size=${ARGV${ARGVn_index}_stack_size}
ARGVn_stack_index=${ARGVn_stack_index}")
        endif()

        tkl_get_prop_stack_value(ARGV${argv_index} GLOBAL "tkl::builtin::ARGV${argv_index}" "${ARGVn_stack_entry}" ${ARGVn_stack_index})
        set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}" "${ARGV${argv_index}}")
        set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)

        math(EXPR argv_index ${argv_index}+1)
      endwhile()

      set(from_argv_index ${ARGVn})
    endif()

    math(EXPR ARGVn_stack_index ${ARGVn_stack_index}+1)
  endwhile()
endfunction()

macro(tkl_print_ARGVn)
  tkl_get_global_prop(_22D2CE04_prop_ARGV "tkl::builtin::ARGV" 0)
  tkl_get_global_prop(_22D2CE04_prop_ARGC "tkl::builtin::ARGC" 0)

  unset(_22D2CE04_empty)

  message("---")
  message("tkl::builtin::ARGV=`${_22D2CE04_prop_ARGV}`")
  message("tkl::builtin::ARGC=${_22D2CE04_prop_ARGC}")

  message("ARGV=`${ARGV${_22D2CE04_empty}}`")
  message("ARGC=${ARGC${_22D2CE04_empty}}")

  set(_22D2CE04_argn_index 0)
  while(_22D2CE04_argn_index LESS ARGC)
    message("ARGV${_22D2CE04_argn_index}=`${ARGV${_22D2CE04_argn_index}}`")
    math(EXPR _22D2CE04_argn_index ${_22D2CE04_argn_index}+1)
  endwhile()
  message("---")

  unset(_22D2CE04_prop_ARGV)
  unset(_22D2CE04_prop_ARGC)
  unset(_22D2CE04_argn_index)
endmacro()

endif()
