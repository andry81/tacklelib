# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_FORWARD_ARGS_INCLUDE_DEFINED)
set(TACKLELIB_FORWARD_ARGS_INCLUDE_DEFINED 1)

include(tacklelib/ForwardVariables)

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_set_ARGVn) # WITH OUT ARGUMENTS
  set_property(GLOBAL PROPERTY "tkl::builtin::ARGV" "${ARGV}")
  set(ARGV "${ARGV}" PARENT_SCOPE)

  set_property(GLOBAL PROPERTY "tkl::builtin::ARGC" "${ARGC}")
  set(ARGC "${ARGC}" PARENT_SCOPE)

  set(argv_index 0)
  while(argv_index LESS ARGC)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}" "${ARGV${argv_index}}")
    set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
    math(EXPR argv_index ${argv_index}+1)
  endwhile()
endfunction()

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_unset_ARGVn num_args)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  set_property(GLOBAL PROPERTY "tkl::builtin::ARGV") # unset property
  unset(ARGV PARENT_SCOPE)

  set_property(GLOBAL PROPERTY "tkl::builtin::ARGC") # unset property
  unset(ARGC PARENT_SCOPE)

  set(argv_index 0)
  while(argv_index LESS num_args)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}") # unset property
    unset(ARGV${argv_index} PARENT_SCOPE)
    math(EXPR argv_index ${argv_index}+1)
  endwhile()
endfunction()

# CAUTION:
#   Must be a macro to:
#   1. Access upper caller function ARGVn arguments.
#
macro(tkl_set_ARGVn_props_from_vars) # WITH OUT ARGUMENTS
  if (${ARGC} GREATER 0)
    message(FATAL_ERROR "function must have no arguments")
  endif()

  if ((NOT DEFINED ARGV) OR (NOT DEFINED ARGC))
    message(FATAL_ERROR "both ARGV and ARGC variables must be defined")
  endif()

  unset(_775085E8_empty)

  # special syntaxes to bypass macro arguments expansion
  set_property(GLOBAL PROPERTY "tkl::builtin::ARGV" "${ARGV${_775085E8_empty}}")
  set_property(GLOBAL PROPERTY "tkl::builtin::ARGC" "${ARGC${_775085E8_empty}}")

  # set ARGVn variables
  set(_775085E8_argv_index 0)
  while(_775085E8_argv_index LESS ARGC) # ARGC as a variable
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${_775085E8_argv_index}" "${ARGV${_775085E8_argv_index}}")
    math(EXPR _775085E8_argv_index ${_775085E8_argv_index}+1)
  endwhile()

  unset(_775085E8_argv_index)
endmacro()

# CAUTION:
#   Must be a macro to:
#   1. Access upper caller function ARGVn arguments.
#
macro(tkl_pushset_ARGVn_props_from_vars) # WITH OUT ARGUMENTS
  if (${ARGC} GREATER 0)
    message(FATAL_ERROR "function must have no arguments")
  endif()

  unset(_775085E8_empty)

  # special syntaxes to bypass macro arguments expansion
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::builtin::ARGV" "${ARGV${_775085E8_empty}}")
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::builtin::ARGC" "${ARGC${_775085E8_empty}}")

  # set ARGVn variables
  set(_775085E8_argv_index 0)
  while(_775085E8_argv_index LESS ARGC) # ARGC as a variable
    tkl_pushset_prop_to_stack(. GLOBAL "tkl::builtin::ARGV${_775085E8_argv_index}" "${ARGV${_775085E8_argv_index}}")
    math(EXPR _775085E8_argv_index ${_775085E8_argv_index}+1)
  endwhile()

  unset(_775085E8_argv_index)
endmacro()

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_pushset_ARGVn_to_stack) # WITH OUT ARGUMENTS!
  # WORKAROUND:
  #  Because we can not change values of ARGC and ARGV0..N arguments, then we have to
  #  replace them by local variables to obscure arguments from the upper caller context!
  #

  if (NOT ${ARGC} GREATER 0)
    message(FATAL_ERROR "function must have arguments")
  endif()

  tkl_pushset_prop_to_stack(ARGV GLOBAL "tkl::builtin::ARGV" "${ARGV}")
  set(ARGV "${ARGV}" PARENT_SCOPE)

  tkl_pushset_prop_to_stack(ARGC GLOBAL "tkl::builtin::ARGC" "${ARGC}")
  set(ARGC "${ARGC}" PARENT_SCOPE)

  if (${ARGC} GREATER 0)
    # update ARGVn variables, must be write w/o index substutution
    if (0 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV0 GLOBAL "tkl::builtin::ARGV0" "${ARGV0}")
      set(ARGV0 "${ARGV0}" PARENT_SCOPE) # CAUTION: macro argument must be used WITH OUT index expansion
    endif()
    if (1 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV1 GLOBAL "tkl::builtin::ARGV1" "${ARGV1}")
      set(ARGV1 "${ARGV1}" PARENT_SCOPE)
    endif()
    if (2 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV2 GLOBAL "tkl::builtin::ARGV2" "${ARGV2}")
      set(ARGV2 "${ARGV2}" PARENT_SCOPE)
    endif()
    if (3 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV3 GLOBAL "tkl::builtin::ARGV3" "${ARGV3}")
      set(ARGV3 "${ARGV3}" PARENT_SCOPE)
    endif()
    if (4 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV4 GLOBAL "tkl::builtin::ARGV4" "${ARGV4}")
      set(ARGV4 "${ARGV4}" PARENT_SCOPE)
    endif()
    if (5 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV5 GLOBAL "tkl::builtin::ARGV5" "${ARGV5}")
      set(ARGV5 "${ARGV5}" PARENT_SCOPE)
    endif()
    if (6 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV6 GLOBAL "tkl::builtin::ARGV6" "${ARGV6}")
      set(ARGV6 "${ARGV6}" PARENT_SCOPE)
    endif()
    if (7 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV7 GLOBAL "tkl::builtin::ARGV7" "${ARGV7}")
      set(ARGV7 "${ARGV7}" PARENT_SCOPE)
    endif()
    if (8 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV8 GLOBAL "tkl::builtin::ARGV8" "${ARGV8}")
      set(ARGV8 "${ARGV8}" PARENT_SCOPE)
    endif()
    if (9 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV9 GLOBAL "tkl::builtin::ARGV9" "${ARGV9}")
      set(ARGV9 "${ARGV9}" PARENT_SCOPE)
    endif()
    if (10 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV10 GLOBAL "tkl::builtin::ARGV10" "${ARGV10}")
      set(ARGV10 "${ARGV10}" PARENT_SCOPE)
    endif()
    if (11 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV11 GLOBAL "tkl::builtin::ARGV11" "${ARGV11}")
      set(ARGV11 "${ARGV11}" PARENT_SCOPE)
    endif()
    if (12 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV12 GLOBAL "tkl::builtin::ARGV12" "${ARGV12}")
      set(ARGV12 "${ARGV12}" PARENT_SCOPE)
    endif()
    if (13 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV13 GLOBAL "tkl::builtin::ARGV13" "${ARGV13}")
      set(ARGV13 "${ARGV13}" PARENT_SCOPE)
    endif()
    if (14 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV14 GLOBAL "tkl::builtin::ARGV14" "${ARGV14}")
      set(ARGV14 "${ARGV14}" PARENT_SCOPE)
    endif()
    if (15 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV15 GLOBAL "tkl::builtin::ARGV15" "${ARGV15}")
      set(ARGV15 "${ARGV15}" PARENT_SCOPE)
    endif()
    if (16 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV16 GLOBAL "tkl::builtin::ARGV16" "${ARGV16}")
      set(ARGV16 "${ARGV16}" PARENT_SCOPE)
    endif()
    if (17 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV17 GLOBAL "tkl::builtin::ARGV17" "${ARGV17}")
      set(ARGV17 "${ARGV17}" PARENT_SCOPE)
    endif()
    if (18 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV18 GLOBAL "tkl::builtin::ARGV18" "${ARGV18}")
      set(ARGV18 "${ARGV18}" PARENT_SCOPE)
    endif()
    if (19 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV19 GLOBAL "tkl::builtin::ARGV19" "${ARGV19}")
      set(ARGV19 "${ARGV19}" PARENT_SCOPE)
    endif()
    if (20 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV20 GLOBAL "tkl::builtin::ARGV20" "${ARGV20}")
      set(ARGV20 "${ARGV20}" PARENT_SCOPE)
    endif()
    if (21 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV21 GLOBAL "tkl::builtin::ARGV21" "${ARGV21}")
      set(ARGV21 "${ARGV21}" PARENT_SCOPE)
    endif()
    if (22 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV22 GLOBAL "tkl::builtin::ARGV22" "${ARGV22}")
      set(ARGV22 "${ARGV22}" PARENT_SCOPE)
    endif()
    if (23 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV23 GLOBAL "tkl::builtin::ARGV23" "${ARGV23}")
      set(ARGV23 "${ARGV23}" PARENT_SCOPE)
    endif()
    if (24 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV24 GLOBAL "tkl::builtin::ARGV24" "${ARGV24}")
      set(ARGV24 "${ARGV24}" PARENT_SCOPE)
    endif()
    if (25 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV25 GLOBAL "tkl::builtin::ARGV25" "${ARGV25}")
      set(ARGV25 "${ARGV25}" PARENT_SCOPE)
    endif()
    if (26 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV26 GLOBAL "tkl::builtin::ARGV26" "${ARGV26}")
      set(ARGV26 "${ARGV26}" PARENT_SCOPE)
    endif()
    if (27 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV27 GLOBAL "tkl::builtin::ARGV27" "${ARGV27}")
      set(ARGV27 "${ARGV27}" PARENT_SCOPE)
    endif()
    if (28 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV28 GLOBAL "tkl::builtin::ARGV28" "${ARGV28}")
      set(ARGV28 "${ARGV28}" PARENT_SCOPE)
    endif()
    if (29 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV29 GLOBAL "tkl::builtin::ARGV29" "${ARGV29}")
      set(ARGV29 "${ARGV29}" PARENT_SCOPE)
    endif()
    if (30 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV30 GLOBAL "tkl::builtin::ARGV30" "${ARGV30}")
      set(ARGV30 "${ARGV30}" PARENT_SCOPE)
    endif()
    if (31 LESS ${ARGC})
      tkl_pushset_prop_to_stack(ARGV31 GLOBAL "tkl::builtin::ARGV31" "${ARGV31}")
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
function(tkl_pushunset_ARGVn_to_stack num_args)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  # CAUTION"
  #   We should not actually unset anything here, so we replaces unset by set empty.
  #

  tkl_pushset_prop_to_stack(. GLOBAL "tkl::builtin::ARGV" "")
  set(ARGV "" PARENT_SCOPE)

  tkl_pushset_prop_to_stack(. GLOBAL "tkl::builtin::ARGC" 0)
  set(ARGC 0 PARENT_SCOPE)

  # unset ARGVn variables
  set(argv_index 0)
  while(argv_index LESS num_args) # ARGC as a variable
    tkl_pushset_prop_to_stack(. GLOBAL "tkl::builtin::ARGV${argv_index}" "")
    set(ARGV${argv_index} "" PARENT_SCOPE)
    math(EXPR argv_index ${argv_index}+1)
  endwhile()
endfunction()

function(tkl_pop_ARGVn_from_stack)
  if (${ARGC} GREATER 0)
    message(FATAL_ERROR "function must have no arguments")
  endif()

  tkl_get_global_prop(prev_ARGC "tkl::builtin::ARGC" 0)
  if (NOT DEFINED prev_ARGC)
    set(prev_ARGC 0)
  endif()

  # pop ARGVn variables
  tkl_pop_prop_from_stack(ARGV GLOBAL "tkl::builtin::ARGV")
  set(ARGV "${ARGV}" PARENT_SCOPE)

  tkl_pop_prop_from_stack(ARGC GLOBAL "tkl::builtin::ARGC")
  set(ARGC "${ARGC}" PARENT_SCOPE)

  if ("${ARGC}" STREQUAL "")
    set(ARGC 0)
  endif()

  # pop ARGVn variables
  set(argv_index 0)
  while(argv_index LESS ARGC) # ARGC as a variable
    tkl_pop_prop_from_stack(ARGV${argv_index} GLOBAL "tkl::builtin::ARGV${argv_index}")

    if (DEFINED ARGV${argv_index})
      set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
    else()
      unset(ARGV${argv_index} PARENT_SCOPE)
    endif()

    math(EXPR argv_index ${argv_index}+1)
  endwhile()

  if (ARGC LESS prev_ARGC)
    # unset rest of variables
    set(argv_index ${ARGC})
    while(argv_index LESS prev_ARGC)
      unset(ARGV${argv_index} PARENT_SCOPE)
      tkl_unset_global_prop(. "tkl::builtin::ARGV${argv_index}")

      math(EXPR argv_index ${argv_index}+1)
    endwhile()

    set(from_argv_index ${prev_ARGC})
  else()
    set(from_argv_index ${ARGC})
  endif()

  # cascade restore from stack top to bottom
  tkl_get_prop_stack_size(stack_size GLOBAL "tkl::builtin::ARGC")

  set(stack_index 0)
  while(stack_index LESS stack_size)
    tkl_get_prop_stack_value(ARGC GLOBAL "tkl::builtin::ARGC" ${stack_index})

    if (from_argv_index LESS ARGC)
      # get ARGVn variables from stack top to bottom
      set(argv_index ${from_argv_index})

      while(argv_index LESS ARGC) # ARGC as a variable
        tkl_get_prop_stack_value(arg GLOBAL "tkl::builtin::ARGV${argv_index}" ${stack_index})
        if (DEFINED arg)
          set(ARGV${argv_index} "${arg}" PARENT_SCOPE)
        else()
          unset(ARGV${argv_index} PARENT_SCOPE)
        endif()

        math(EXPR argv_index ${argv_index}+1)
      endwhile()

      set(from_argv_index ${ARGC})
    endif()

    math(EXPR stack_index ${stack_index}+1)
  endwhile()
endfunction()

function(tkl_pop_ARGVn_props_from_stack)
  if (${ARGC} GREATER 0)
    message(FATAL_ERROR "function must have no arguments")
  endif()

  # pop ARGVn properties
  tkl_pop_prop_from_stack(ARGV GLOBAL "tkl::builtin::ARGV")
  tkl_pop_prop_from_stack(ARGC GLOBAL "tkl::builtin::ARGC")

  if ("${ARGC}" STREQUAL "")
    set(ARGC 0)
  endif()

  # pop ARGVn variables
  set(argv_index 0)
  while(argv_index LESS ARGC) # ARGC as a variable
    tkl_pop_prop_from_stack(ARGV${argv_index} GLOBAL "tkl::builtin::ARGV${argv_index}")
    math(EXPR argv_index ${argv_index}+1)
  endwhile()
endfunction()

function(tkl_restore_ARGVn_vars_from_stack error_if_no_stack)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  tkl_get_global_prop(ARGV "tkl::builtin::ARGV" 0)
  tkl_get_global_prop(ARGC "tkl::builtin::ARGC" 0)

  if ((NOT DEFINED ARGV) OR (NOT DEFINED ARGC))
    if (error_if_no_stack)
      message(FATAL_ERROR "variables stack either undefined or empty")
    else()
      return()
    endif()
  endif()

  set(ARGV "${ARGV}" PARENT_SCOPE)
  set(ARGC "${ARGC}" PARENT_SCOPE)

  # get ARGVn variables from stack top to bottom
  set(argv_index 0)
  while(argv_index LESS ARGC) # ARGC as a variable
    tkl_get_global_prop(ARGV${argv_index} "tkl::builtin::ARGV${argv_index}" 0)

    if (DEFINED ARGV${argv_index})
      set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
    else()
      unset(ARGV${argv_index} PARENT_SCOPE)
    endif()

    math(EXPR argv_index ${argv_index}+1)
  endwhile()

  set(from_argv_index ${ARGC})

  tkl_get_prop_stack_size(stack_size GLOBAL "tkl::builtin::ARGC")

  set(stack_index 0)
  while(stack_index LESS stack_size)
    tkl_get_prop_stack_value(ARGC GLOBAL "tkl::builtin::ARGC" ${stack_index})

    if (from_argv_index LESS ARGC)
      # get ARGVn variables from stack top to bottom
      set(argv_index ${from_argv_index})

      while(argv_index LESS ARGC) # ARGC as a variable
        tkl_get_prop_stack_value(arg GLOBAL "tkl::builtin::ARGV${argv_index}" ${stack_index})
        if (DEFINED arg)
          set(ARGV${argv_index} "${arg}" PARENT_SCOPE)
        else()
          unset(ARGV${argv_index} PARENT_SCOPE)
        endif()

        math(EXPR argv_index ${argv_index}+1)
      endwhile()

      set(from_argv_index ${ARGC})
    endif()

    math(EXPR stack_index ${stack_index}+1)
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
