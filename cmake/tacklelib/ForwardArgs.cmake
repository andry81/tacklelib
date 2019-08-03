# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_FORWARD_ARGS_INCLUDE_DEFINED)
set(TACKLELIB_FORWARD_ARGS_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.7)

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# NOTE:
#   Read the doc/02_general_variables_set_rules.txt`
#   for variables set rules represented here.
#

include(tacklelib/ForwardVariables)
include(tacklelib/Props)
include(tacklelib/List)
include(tacklelib/Utility)

# CAUTION:
#   Must be a function to avoid expansion of variable arguments like:
#   * `${...}` into a value
#   * `$\{...}` into `${...}`
#   * `\n` into the line return
#   etc
function(tkl_make_var_from_ARGV_begin argv_joined_list out_argv_var)
  if (NOT "${ARGN}" STREQUAL "")
    message(FATAL_ERROR "function must have only 2 arguments")
  endif()

  set(_BBD57550_argv_joined_list "${argv_joined_list}" PARENT_SCOPE)

  unset(${out_argv_var} PARENT_SCOPE)
endfunction()

macro(tkl_make_var_from_ARGV_end out_argv_var)
  if (NOT "${ARGN}" STREQUAL "")
    message(FATAL_ERROR "function must have only 1 argument")
  endif()

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(${out_argv_var} ";")

  # to be able to append empty values at begginning
  if (NOT _BBD57550_argv_joined_list STREQUAL "")
    set(_BBD57550_argv_joined_list ";;${_BBD57550_argv_joined_list}")
  else()
    set(_BBD57550_argv_joined_list ";${_BBD57550_argv_joined_list}")
  endif()
  set(_BBD57550_argv_joined_list_accum ";")

  set(_BBD57550_var_index 0)

  while (NOT _BBD57550_argv_joined_list STREQUAL _BBD57550_argv_joined_list_accum)
    # with finite loop insurance
    if (_BBD57550_var_index GREATER_EQUAL 64)
      message(FATAL_ERROR "ARGV arguments are too many or infinite loop is detected")
    endif()

    set(_BBD57550_argv_value "${ARGV${_BBD57550_var_index}}")

    # WORKAROUND: we have to replace because `list(APPEND` will join lists together
    tkl_escape_string_before_list_append(_BBD57550_argv_value "${_BBD57550_argv_value}")

    list(APPEND ${out_argv_var} "${_BBD57550_argv_value}")

    list(APPEND _BBD57550_argv_joined_list_accum "${ARGV${_BBD57550_var_index}}")

    math(EXPR _BBD57550_var_index ${_BBD57550_var_index}+1)
  endwhile()

  # remove 2 first dummy empty strings
  tkl_list_remove_sublist(${out_argv_var} 0 2 ${out_argv_var})

  unset(_BBD57550_argv_joined_list)
  unset(_BBD57550_argv_joined_list_accum)
  unset(_BBD57550_var_index)
  unset(_BBD57550_argv_value)
  unset(_BBD57550_argv_value_encoded)
endmacro()

# CAUTION:
#   Must be a function to avoid expansion of variable arguments like:
#   * `${...}` into a value
#   * `$\{...}` into `${...}`
#   * `\n` into the line return
#   etc
#
# Params:
#   out_argv_var - optional
#   out_argn_var - required
function(tkl_make_vars_from_ARGV_ARGN_begin argv_joined_list argn_joined_list out_argv_var out_argn_var)
  if (NOT "${ARGN}" STREQUAL "")
    message(FATAL_ERROR "function must have only 4 arguments")
  endif()

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(_9E220B1D_argv_joined_list "${argv_joined_list};")   # 1t phase list
  set(_9E220B1D_argn_joined_list "${argn_joined_list};")

  set(_9E220B1D_argn_offset -1)
  if (NOT "${_9E220B1D_argn_joined_list}" STREQUAL ";")
    # offset could be with last empty element here
    string(FIND "${_9E220B1D_argv_joined_list}" "${_9E220B1D_argn_joined_list}" _9E220B1D_argn_offset REVERSE)
    # found substring must be the same size to the ARGN string length
    string(LENGTH "${_9E220B1D_argv_joined_list}" _9E220B1D_argv_joined_list_len)
    string(LENGTH "${_9E220B1D_argn_joined_list}" _9E220B1D_argn_joined_list_len)
    math(EXPR _9E220B1D_args_joined_list_len ${_9E220B1D_argv_joined_list_len}-${_9E220B1D_argn_joined_list_len})
    if (NOT _9E220B1D_args_joined_list_len EQUAL _9E220B1D_argn_offset)
      message(FATAL_ERROR "invalid offset")
    endif()
  endif()

  if (NOT "${out_argv_var}" STREQUAL "" AND NOT "${out_argv_var}" STREQUAL ".")
    unset(${out_argv_var} PARENT_SCOPE)
  endif()
  unset(${out_argn_var} PARENT_SCOPE)
  set(_9E220B1D_argn_offset "${_9E220B1D_argn_offset}" PARENT_SCOPE)
  set(_9E220B1D_argv_joined_list "${_9E220B1D_argv_joined_list}" PARENT_SCOPE)
  #set(_9E220B1D_argn_joined_list "${_9E220B1D_argn_joined_list}" PARENT_SCOPE)
endfunction()

# Params:
#   out_argv_var - optional
#   out_argn_var - required
macro(tkl_make_vars_from_ARGV_ARGN_end out_argv_var out_argn_var)
  if (NOT "${ARGN}" STREQUAL "")
    message(FATAL_ERROR "function must have only 2 arguments")
  endif()

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  if (NOT "${out_argv_var}" STREQUAL "" AND NOT "${out_argv_var}" STREQUAL ".")
    set(${out_argv_var} ";")
  endif()
  set(${out_argn_var} ";")
  set(_9E220B1D_argv_joined_list_accum "")

  string(SUBSTRING "${_9E220B1D_argv_joined_list}" 0 ${_9E220B1D_argn_offset} _9E220B1D_args_joined_list)

  # remove last separator
  if (NOT _9E220B1D_args_joined_list STREQUAL "")
    # remove last `;` character
    string(REGEX REPLACE "(.*)\;$" "\\1" _9E220B1D_args_joined_list "${_9E220B1D_args_joined_list}")
  endif()
  if (NOT _9E220B1D_argv_joined_list STREQUAL ";")
    # remove last `;` character
    string(REGEX REPLACE "(.*)\;$" "\\1" _9E220B1D_argv_joined_list "${_9E220B1D_argv_joined_list}")
  endif()

  set(_9E220B1D_var_index 0)

  # to be able to append empty values at begginning
  if (NOT _9E220B1D_args_joined_list STREQUAL "")
    set(_9E220B1D_args_joined_list ";;${_9E220B1D_args_joined_list}")
  else()
    set(_9E220B1D_args_joined_list ";${_9E220B1D_args_joined_list}")
  endif()
  set(_9E220B1D_argv_joined_list_accum ";${_9E220B1D_argv_joined_list_accum}")

  while (NOT _9E220B1D_args_joined_list STREQUAL _9E220B1D_argv_joined_list_accum)
    # with finite loop insurance
    if (_9E220B1D_var_index GREATER_EQUAL 64)
      message(FATAL_ERROR "(1) ARGV arguments are too many or infinite loop is detected")
    endif()

    if (NOT "${out_argv_var}" STREQUAL "" AND NOT "${out_argv_var}" STREQUAL ".")
      set(_9E220B1D_argv_value "${ARGV${_9E220B1D_var_index}}")

      # WORKAROUND: we have to replace because `list(APPEND` will join lists together
      tkl_escape_string_before_list_append(_9E220B1D_argv_value "${_9E220B1D_argv_value}")

      list(APPEND ${out_argv_var} "${_9E220B1D_argv_value}")
    endif()

    list(APPEND _9E220B1D_argv_joined_list_accum "${ARGV${_9E220B1D_var_index}}")

    math(EXPR _9E220B1D_var_index ${_9E220B1D_var_index}+1)
  endwhile()

  # to be able to append empty values at begginning
  if (NOT _9E220B1D_argv_joined_list STREQUAL "")
    set(_9E220B1D_argv_joined_list ";;${_9E220B1D_argv_joined_list}")
  else()
    set(_9E220B1D_argv_joined_list ";${_9E220B1D_argv_joined_list}")
  endif()

  while (NOT _9E220B1D_argv_joined_list STREQUAL _9E220B1D_argv_joined_list_accum)
    # with finite loop insurance
    if (_9E220B1D_var_index GREATER_EQUAL 64)
      message(FATAL_ERROR "(2) ARGV arguments are too many or infinite loop is detected")
    endif()

    set(_9E220B1D_argv_value "${ARGV${_9E220B1D_var_index}}")

    # WORKAROUND: we have to replace because `list(APPEND` will join lists together
    tkl_escape_string_before_list_append(_9E220B1D_argv_value "${_9E220B1D_argv_value}")

    if (NOT "${out_argv_var}" STREQUAL "" AND NOT "${out_argv_var}" STREQUAL ".")
      list(APPEND ${out_argv_var} "${_9E220B1D_argv_value}")
    endif()
    list(APPEND ${out_argn_var} "${_9E220B1D_argv_value}")

    list(APPEND _9E220B1D_argv_joined_list_accum "${ARGV${_9E220B1D_var_index}}")

    math(EXPR _9E220B1D_var_index ${_9E220B1D_var_index}+1)
  endwhile()

  # remove 2 first dummy empty strings
  if (NOT "${out_argv_var}" STREQUAL "" AND NOT "${out_argv_var}" STREQUAL ".")
    tkl_list_remove_sublist(${out_argv_var} 0 2 ${out_argv_var})
  endif()
  tkl_list_remove_sublist(${out_argn_var} 0 2 ${out_argn_var})

  unset(_9E220B1D_argv_joined_list_accum)
  unset(_9E220B1D_var_index)
  unset(_9E220B1D_argv_value)
  unset(_9E220B1D_argv_value_encoded)

  unset(_9E220B1D_argv_joined_list)
  #unset(_9E220B1D_argn_joined_list)
  unset(_9E220B1D_argn_offset)
endmacro()

# CAUTION:
#   Function must be without arguments to:
#   1. support optional leading arguments like flags beginning by the `-` character
#
# Usage:
#   [<flags>] <out_var>
#
# flags:
#   -P - Enumerate script arguments (including a script absolute file path) instead of a cmake process arguments
#     (for the script mode only, where the cmake has called with the `-P` flag).
#
function(tkl_make_var_from_CMAKE_ARGV_ARGC) # WITH OUT ARGUMENTS!
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_var_from_ARGV_end(argv)
  #message("tkl_make_var_from_CMAKE_ARGV_ARGC: argv=${argv}")

  list(LENGTH argv argv_len)
  set(argv_index 0)

  set(set_script_args 0)
  set(strict_checks 0)
  set(dont_convert_module_path 1) # do not convert module path to the absolute path

  # parse flags until no flags
  tkl_parse_function_optional_flags_into_vars(
    argv_index
    argv
    "P;s;a"
    "\
a\;dont_convert_module_path\
"
    "\
P\;set_script_args;\
s\;strict_checks\
"
    "")

  if (NOT argv_index LESS argv_len)
    message(FATAL_ERROR "function must be called at least with 1 not optional argument: argv_len=${argv_len} argv_index=${argv_index}")
  endif()

  tkl_get_cmake_role(is_in_script_mode SCRIPT)
  if (NOT is_in_script_mode)
    message(FATAL_ERROR "call must be made from the script mode only")
  endif()

  list(GET argv ${argv_index} out_var)
  math(EXPR argv_index ${argv_index}+1)

  set(${out_var} "")
  set(cmake_arg_index 0)

  if (NOT set_script_args)
    while(cmake_arg_index LESS CMAKE_ARGC)
      # WORKAROUND: we have to replace because `list(APPEND` will join lists together
      tkl_escape_string_before_list_append(arg_value "${CMAKE_ARGV${cmake_arg_index}}")

      list(APPEND ${out_var} "${arg_value}")

      math(EXPR cmake_arg_index ${cmake_arg_index}+1)
    endwhile()
  else()
    if (strict_checks)
      get_filename_component(this_script_file_path_abs "${CMAKE_SCRIPT_MODE_FILE}" ABSOLUTE)
    endif()

    set(script_file_path_offset -1)
    while(cmake_arg_index LESS CMAKE_ARGC)
      set(arg_value "${CMAKE_ARGV${cmake_arg_index}}")
      #message("arg_value=${arg_value}")
      if (script_file_path_offset GREATER_EQUAL 0 )
        if (script_file_path_offset LESS cmake_arg_index)
          # WORKAROUND: we have to replace because `list(APPEND` will join lists together
          tkl_escape_string_before_list_append(arg_value "${arg_value}")

          list(APPEND ${out_var} "${arg_value}")
        else()
          if (NOT dont_convert_module_path)
            # Parse the value as a path to the script file, convert to the absolute path and
            # then compare on equality with the absolute path in the CMAKE_SCRIPT_MODE_FILE variable.
            get_filename_component(script_file_path_abs "${arg_value}" ABSOLUTE)
            if (strict_checks)
              if (NOT this_script_file_path_abs STREQUAL script_file_path_abs)
                message(FATAL_ERROR "path to this script file and a command line argument after the `-P` option must be the same: `this_script_file_path_abs=${this_script_file_path_abs}` script_file_path_abs=1${script_file_path_abs}1")
              endif()
            endif()
            set(arg_value "${script_file_path_abs}")
          endif()

          # WORKAROUND: we have to replace because `list(APPEND` will join lists together
          tkl_escape_string_before_list_append(arg_value "${arg_value}")

          list(APPEND ${out_var} "${arg_value}") # converted into the absolute path
        endif()
      else()
        if (arg_value STREQUAL "-P")
          math(EXPR script_file_path_offset ${cmake_arg_index}+1)
        endif()
      endif()

      math(EXPR cmake_arg_index ${cmake_arg_index}+1)
    endwhile()
  endif()

  set(${out_var} "${${out_var}}" PARENT_SCOPE)
endfunction()

function(tkl_use_ARGVn_stack_begin stack_entry)
  if (stack_entry STREQUAL "" OR stack_entry STREQUAL ".")
    tkl_pushunset_prop_to_stack(. GLOBAL "tkl::ARGVn_stack::stack_entry" "tkl::ARGVn_stack")
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
  if (DEFINED ARGV)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV" "${ARGV${_775085E8_empty}}")
  else()
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV") # unset property
  endif()
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV${_775085E8_empty}" "${_775085E8_ARGVn_stack_entry}")

  if (DEFINED ARGC)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGC" "${ARGC${_775085E8_empty}}")
  else()
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGC") # unset property
  endif()
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGC${_775085E8_empty}" "${_775085E8_ARGVn_stack_entry}")

  # real number of pushed ARGVn variables
  set_property(GLOBAL PROPERTY "tkl::builtin::ARGVn" "${ARGC${_775085E8_empty}}")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGVn${_775085E8_empty}" "${_775085E8_ARGVn_stack_entry}")

  # set ARGVn variables
  set(_775085E8_argv_index 0)
  while(_775085E8_argv_index LESS ARGC) # ARGC as a variable
    if (DEFINED ARGV${_775085E8_argv_index})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${_775085E8_argv_index}" "${ARGV${_775085E8_argv_index}}")
    else()
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${_775085E8_argv_index}") # unset property
    endif()
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
  set_property(GLOBAL PROPERTY "tkl::builtin::ARGV" "${ARGV}")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}")

  set_property(GLOBAL PROPERTY "tkl::builtin::ARGC" "${ARGC}")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}")

  # real number of pushed ARGVn variables
  set_property(GLOBAL PROPERTY "tkl::builtin::ARGVn" ${ARGC})
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}")

  if (${ARGC} GREATER 0)
    # push ARGVn variables

    # CAUTION: macro argument must be used WITH OUT index expansion: ${ARGV0}...${ARGVN}

    if (0 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV0" "${ARGV0}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV0" "${ARGVn_stack_entry}")
    endif()
    if (1 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV1" "${ARGV1}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV1" "${ARGVn_stack_entry}")
      set(ARGV1 "${ARGV1}" PARENT_SCOPE)
    endif()
    if (2 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV2" "${ARGV2}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV2" "${ARGVn_stack_entry}")
    endif()
    if (3 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV3" "${ARGV3}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV3" "${ARGVn_stack_entry}")
    endif()
    if (4 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV4" "${ARGV4}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV4" "${ARGVn_stack_entry}")
    endif()
    if (5 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV5" "${ARGV5}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV5" "${ARGVn_stack_entry}")
    endif()
    if (6 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV6" "${ARGV6}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV6" "${ARGVn_stack_entry}")
    endif()
    if (7 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV7" "${ARGV7}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV7" "${ARGVn_stack_entry}")
    endif()
    if (8 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV8" "${ARGV8}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV8" "${ARGVn_stack_entry}")
    endif()
    if (9 LESS ${ARGC})
      tkl_set_global_prop(ARGV9 "tkl::builtin::ARGV9" "${ARGV9}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV9" "${ARGVn_stack_entry}")
    endif()
    if (10 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV10" "${ARGV10}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV10" "${ARGVn_stack_entry}")
    endif()
    if (11 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV11" "${ARGV11}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV11" "${ARGVn_stack_entry}")
    endif()
    if (12 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV12" "${ARGV12}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV12" "${ARGVn_stack_entry}")
    endif()
    if (13 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV13" "${ARGV13}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV13" "${ARGVn_stack_entry}")
    endif()
    if (14 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV14" "${ARGV14}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV14" "${ARGVn_stack_entry}")
    endif()
    if (15 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV15" "${ARGV15}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV15" "${ARGVn_stack_entry}")
    endif()
    if (16 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV16" "${ARGV16}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV16" "${ARGVn_stack_entry}")
    endif()
    if (17 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV17" "${ARGV17}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV17" "${ARGVn_stack_entry}")
    endif()
    if (18 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV18" "${ARGV18}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV18" "${ARGVn_stack_entry}")
    endif()
    if (19 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV19" "${ARGV19}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV19" "${ARGVn_stack_entry}")
    endif()
    if (20 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV20" "${ARGV20}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV20" "${ARGVn_stack_entry}")
    endif()
    if (21 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV21" "${ARGV21}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV21" "${ARGVn_stack_entry}")
    endif()
    if (22 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV22" "${ARGV22}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV22" "${ARGVn_stack_entry}")
    endif()
    if (23 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV23" "${ARGV23}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV23" "${ARGVn_stack_entry}")
    endif()
    if (24 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV24" "${ARGV24}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV24" "${ARGVn_stack_entry}")
    endif()
    if (25 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV25" "${ARGV25}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV25" "${ARGVn_stack_entry}")
    endif()
    if (26 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV26" "${ARGV26}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV26" "${ARGVn_stack_entry}")
    endif()
    if (27 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV27" "${ARGV27}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV27" "${ARGVn_stack_entry}")
    endif()
    if (28 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV28" "${ARGV28}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV28" "${ARGVn_stack_entry}")
    endif()
    if (29 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV29" "${ARGV29}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV29" "${ARGVn_stack_entry}")
    endif()
    if (30 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV30" "${ARGV30}")
      tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV30" "${ARGVn_stack_entry}")
    endif()
    if (31 LESS ${ARGC})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV31" "${ARGV31}")
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
function(tkl_pushunset_ARGVn_to_stack num_args)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  tkl_get_ARGVn_stack_entry(ARGVn_stack_entry)

  # set empty ARGV, ARGC variables
  set_property(GLOBAL PROPERTY "tkl::builtin::ARGV" "")
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}")
  # must always exist
  set(ARGV "" PARENT_SCOPE)

  set_property(GLOBAL PROPERTY "tkl::builtin::ARGC" 0)
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}")
  # must always exist
  set(ARGC 0 PARENT_SCOPE)

  # real number of pushed ARGVn variables
  set_property(GLOBAL PROPERTY "tkl::builtin::ARGVn" ${num_args})
  tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}")

  # set empty ARGVn variables
  set(argv_index 0)
  while(argv_index LESS ${num_args})
    if (DEFINED ARGV${argv_index})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}" "${ARGV${argv_index}}")
    else()
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}") # unset property
    endif()
    tkl_push_prop_to_stack(GLOBAL "tkl::builtin::ARGV${argv_index}" "${ARGVn_stack_entry}")
    unset(ARGV${argv_index} PARENT_SCOPE)

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
  tkl_pop_prop_from_stack(. GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}")
  tkl_get_prop_stack_value_no_error(ARGV GLOBAL "tkl::builtin::ARGV" "${ARGVn_stack_entry}" 0)
  if (DEFINED ARGV)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV" "${ARGV}")
    set(ARGV "${ARGV}" PARENT_SCOPE)
  else()
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV") # unset property
    # must always exist
    set(ARGV "" PARENT_SCOPE)
  endif()

  tkl_pop_prop_from_stack(. GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}")
  tkl_get_prop_stack_value_no_error(ARGC GLOBAL "tkl::builtin::ARGC" "${ARGVn_stack_entry}" 0)
  if (DEFINED ARGC)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGC" "${ARGC}")
    set(ARGC "${ARGC}" PARENT_SCOPE)
  else()
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGC") # unset property
    # must always exist
    set(ARGC 0 PARENT_SCOPE)
  endif()

  # real number of pushed ARGVn variables
  tkl_pop_prop_from_stack(prev_ARGVn GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}")
  tkl_get_prop_stack_value_no_error(ARGVn GLOBAL "tkl::builtin::ARGVn" "${ARGVn_stack_entry}" 0)
  if (DEFINED ARGVn)
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGVn" "${ARGVn}")
    # remember previous popped ARGVn to unset ARGV0..N it in the restore function upon a call to (the last pop cleanup)
#    set_property(GLOBAL PROPERTY "tkl::builtin::last_ARGVn[${ARGVn_stack_entry}]" "${ARGVn}")
  else()
    set_property(GLOBAL PROPERTY "tkl::builtin::ARGVn") # unset property
    # stack is empty, nothing to compare anymore
#    set_property(GLOBAL PROPERTY "tkl::builtin::last_ARGVn[${ARGVn_stack_entry}]") # unset property
    set(ARGVn 0)
  endif()

  if ("${prev_ARGVn}" STREQUAL "")
    message(FATAL_ERROR "previous ARGVn must be not empty after the pop")
  endif()

  # pop ARGVn variables
  set(argv_index 0)
  while(argv_index LESS prev_ARGVn)
    tkl_pop_prop_from_stack(. GLOBAL "tkl::builtin::ARGV${argv_index}" "${ARGVn_stack_entry}")
    tkl_get_prop_stack_value_no_error(ARGV${argv_index} GLOBAL "tkl::builtin::ARGV${argv_index}" "${ARGVn_stack_entry}" 0)
    if (DEFINED ARGV${argv_index})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}" "${ARGV${argv_index}}")
      set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
    else()
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}") # unset property
      unset(ARGV${argv_index} PARENT_SCOPE)
    endif()

    math(EXPR argv_index ${argv_index}+1)
  endwhile()

#  # unset rest of variables, it would be last pop cleanup (last_ARGVn) to be available rerun it in the restore function
#  set(argv_index ${ARGVn})
#  while(argv_index LESS prev_ARGVn)
#    set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${argv_index}") # unset property
#    unset(ARGV${argv_index} PARENT_SCOPE)
#  
#    math(EXPR argv_index ${argv_index}+1)
#  endwhile()

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
        # no need to recalculate stack index because 0 is always the existing stack top here
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
    if (DEFINED ARGV${ARGVn_index})
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${ARGVn_index}" "${ARGV${ARGVn_index}}")
      set(ARGV${ARGVn_index} "${ARGV${ARGVn_index}}" PARENT_SCOPE)
    else()
      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${ARGVn_index}") # unset property
      set(ARGV${ARGVn_index} "${ARGV${ARGVn_index}}" PARENT_SCOPE)
    endif()

    math(EXPR ARGVn_index ${ARGVn_index}+1)
  endwhile()

#  # unset previously used ARGV0..N
#  if (${stack_index} LESS ARGVn_stack_size)
#    tkl_get_global_prop(last_ARGVn "tkl::builtin::last_ARGVn[${ARGVn_stack_entry}]" ${stack_index})
#    if (last_ARGVn STREQUAL "")
#      set(last_ARGVn 0)
#    endif()
#  endif()
#
#  if (ARGVn LESS last_ARGVn)
#    # unset rest of variables
#    set(ARGVn_index ${ARGVn})
#    while(ARGVn_index LESS last_ARGVn)
#      set_property(GLOBAL PROPERTY "tkl::builtin::ARGV${ARGVn_index}") # unset property
#      unset(ARGV${ARGVn_index} PARENT_SCOPE)
#
#      math(EXPR ARGVn_index ${ARGVn_index}+1)
#    endwhile()
#  endif()

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
