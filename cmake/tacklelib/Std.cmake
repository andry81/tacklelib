# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_STD_INCLUDE_DEFINED)
set(TACKLELIB_STD_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.14)

include(tacklelib/List)
include(tacklelib/File)
include(tacklelib/Props)
include(tacklelib/Reimpl)
include(tacklelib/Utility)

# at least cmake 3.14 is required for:
#   * CMAKE_ROLE property: https://cmake.org/cmake/help/latest/prop_gbl/CMAKE_ROLE.html#prop_gbl:CMAKE_ROLE
#

# at least cmake 3.9 is required for:
#   * Multiconfig generator detection support: https://cmake.org/cmake/help/v3.9/prop_gbl/GENERATOR_IS_MULTI_CONFIG.html
#

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# at least cmake 3.3 is required for:
# * to use IN_LIST in if command: (https://cmake.org/cmake/help/v3.3/command/if.html )
#   `if(<variable|string> IN_LIST <variable>)`
#

macro(tkl_include_and_echo path)
  message(STATUS "(*) Include: \"${path}\"")
  include(${path})
endmacro()

macro(tkl_unset_all var)
  unset(${var})
  unset(${var} CACHE)
endmacro()

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

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  # WORKAROUND: we have to recode all control characters because `${ARGV}` and `${ARGN}` will be evaluated on expansion
  tkl_escape_string_for_ARGx(_BBD57550_argv_joined_list_encoded "${argv_joined_list}")

  set(_BBD57550_argv_joined_list "${_BBD57550_argv_joined_list_encoded}" PARENT_SCOPE)

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
    string(REPLACE ";" "\;" _BBD57550_argv_value "${_BBD57550_argv_value}")

    list(APPEND ${out_argv_var} "${_BBD57550_argv_value}")

    # WORKAROUND: we have to recode all control characters because `${ARGV0..N}` will be evaluated on expansion
    tkl_escape_string_for_ARGx(_BBD57550_argv_value_encoded "${ARGV${_BBD57550_var_index}}")

    list(APPEND _BBD57550_argv_joined_list_accum "${_BBD57550_argv_value_encoded}")

    math(EXPR _BBD57550_var_index "${_BBD57550_var_index}+1")
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

  # WORKAROUND: we have to recode all control characters because `${ARGV}` and `${ARGN}` will be evaluated on expansion
  tkl_escape_string_for_ARGx(_9E220B1D_argv_joined_list_encoded "${argv_joined_list}")
  tkl_escape_string_for_ARGx(_9E220B1D_argn_joined_list_encoded "${argn_joined_list}")

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(_9E220B1D_argv_joined_list "${_9E220B1D_argv_joined_list_encoded};")   # 1t phase list
  set(_9E220B1D_argn_joined_list "${_9E220B1D_argn_joined_list_encoded};")

  set(_9E220B1D_argn_offset -1)
  if (NOT "${_9E220B1D_argn_joined_list}" STREQUAL ";")
    # offset could be with last empty element here
    string(FIND "${_9E220B1D_argv_joined_list}" "${_9E220B1D_argn_joined_list}" _9E220B1D_argn_offset REVERSE)
    # found substring must be the same size to the ARGN string length
    string(LENGTH "${_9E220B1D_argv_joined_list}" _9E220B1D_argv_joined_list_len)
    string(LENGTH "${_9E220B1D_argn_joined_list}" _9E220B1D_argn_joined_list_len)
    math(EXPR _9E220B1D_args_joined_list_len "${_9E220B1D_argv_joined_list_len}-${_9E220B1D_argn_joined_list_len}")
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
      list(APPEND ${out_argv_var} "${_9E220B1D_argv_value}")
    endif()

    # WORKAROUND: we have to recode all control characters because `${ARGV0..N}` will be evaluated on expansion
    tkl_escape_string_for_ARGx(_9E220B1D_argv_value_encoded "${ARGV${_9E220B1D_var_index}}")

    # WORKAROUND: we have to replace because `list(APPEND` will join lists together
    string(REPLACE ";" "\;" _9E220B1D_argv_value_encoded "${_9E220B1D_argv_value_encoded}")

    list(APPEND _9E220B1D_argv_joined_list_accum "${_9E220B1D_argv_value_encoded}")

    math(EXPR _9E220B1D_var_index "${_9E220B1D_var_index}+1")
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

    #message("[${_9E220B1D_var_index}] _9E220B1D_argv_value=${_9E220B1D_argv_value}")
    ## WORKAROUND: we have to replace because `list(APPEND` will join lists together
    #string(REPLACE ";" "\;" _9E220B1D_argv_value "${_9E220B1D_argv_value}")
    if (NOT "${out_argv_var}" STREQUAL "" AND NOT "${out_argv_var}" STREQUAL ".")
      list(APPEND ${out_argv_var} "${_9E220B1D_argv_value}")
    endif()
    list(APPEND ${out_argn_var} "${_9E220B1D_argv_value}")

    # WORKAROUND: we have to recode all control characters because `${ARGV0..N}` will be evaluated on expansion
    tkl_escape_string_for_ARGx(_9E220B1D_argv_value_encoded "${ARGV${_9E220B1D_var_index}}")

    # WORKAROUND: we have to replace because `list(APPEND` will join lists together
    string(REPLACE ";" "\;" _9E220B1D_argv_value_encoded "${_9E220B1D_argv_value_encoded}")

    list(APPEND _9E220B1D_argv_joined_list_accum "${_9E220B1D_argv_value_encoded}")

    math(EXPR _9E220B1D_var_index "${_9E220B1D_var_index}+1")
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
      string(REPLACE ";" "\;" arg_value "${CMAKE_ARGV${cmake_arg_index}}")

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
          string(REPLACE ";" "\;" arg_value "${arg_value}")

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
          string(REPLACE ";" "\;" arg_value "${arg_value}")

          list(APPEND ${out_var} "${arg_value}") # converted into the absolute path
        endif()
      else()
        if (arg_value STREQUAL "-P")
          math(EXPR script_file_path_offset ${cmake_arg_index}+1)
        endif()
      endif()

      math(EXPR cmake_arg_index "${cmake_arg_index}+1")
    endwhile()
  endif()

  set(${out_var} "${${out_var}}" PARENT_SCOPE)
endfunction()

# Usage:
#   <func_argv_index_var> <func_argv_var> <func_char_flags_list> <set0_params_list> <set1_params_list> <multichar_flag_params_list>
#
# func_argv_index_var:
#   Variable name to increment on each parsed function input flag argument.
#
# func_argv_var:
#   List variable name with a function input arguments.
#
# func_char_flags_list:
#   dash (single char) flag list.
#
# set0_params_list:
#   2 level nested list for dash (single char) flag associated character to `set(${varK_N} 0)` over associated variables.
#   Format:
#     [char_flag0\;var0_0[...\;var0_N][...;char_flagK\;varK_0[...\;varK_M]]]
#
# set1_params_list:
#   2 level nested list for dash (single char) flag associated character to `set(${varK_N} 1)` over associated variables.
#   Format:
#     [char_flag0\;var0_0[...\;var0_N][...;char_flagK\;varK_0[...\;varK_M]]]
#
# multichar_flag_params_list:
#   2 level nested list for double dash (multichar string) flag associated string to `set(${set1_varK} 1)` over associated variable and
#   to consume following parameters into associated variables by `set(${varK_N} ...)`.
#   Format:
#     [string_flag0\;set1_var0\;var0_0[...\;var0_N][...;string_flagK\;set1_varK\;varK_0[...\;varK_M]]]
#
macro(tkl_parse_function_optional_flags_into_vars func_argv_index_var func_argv_var func_char_flags_list set0_params_list set1_params_list multichar_flag_params_list)
  tkl_parse_function_optional_flags_into_vars_impl("${func_argv_index_var}" "${func_argv_var}" "${func_char_flags_list}"
    "${set0_params_list}" "${set1_params_list}" "${multichar_flag_params_list}" "")
endmacro()

function(tkl_parse_function_optional_flags_into_vars_impl func_argv_index_var func_argv_var func_char_flags_list set0_params_list set1_params_list multichar_flag_params_list flags_out_var)
  if (NOT func_argv_index_var STREQUAL "" AND NOT func_argv_index_var STREQUAL ".")
    set(func_argv_index "${${func_argv_index_var}}")
  else()
    set(func_argv_index 0)
  endif()
  set(func_argv "${${func_argv_var}}")

  # parse flags until no flags
  list(LENGTH func_argv func_argv_len)

  if (func_argv_len GREATER 0)
    list(GET func_argv 0 func_flags)
    # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
    string(REPLACE ";" "\;" func_flags "${func_flags}")

    string(SUBSTRING "${func_flags}" 0 1 func_flags_prefix_char0)
  else()
    set(func_flags_prefix_char0 "")
  endif()

  set(flags "")

  while (func_flags_prefix_char0 STREQUAL "-")
    string(LENGTH "${func_flags}" func_flags_len)
    if (1 LESS func_flags_len)
      string(SUBSTRING "${func_flags}" 1 1 func_flags_prefix_char1)
    else()
      set(func_flags_prefix_char1 "")
    endif()

    if (NOT func_flags_prefix_char1 STREQUAL "-")
      if (1 LESS func_flags_len)
        string(SUBSTRING "${func_flags}" 1 -1 func_flags_suffix)
      endif()

      if (NOT func_flags_suffix STREQUAL "")
        if (NOT func_char_flags_list STREQUAL "")
          foreach (char_flag ${func_char_flags_list})
            string(SUBSTRING "${char_flag}" 0 1 char_flag) # just in case
            string(REGEX REPLACE "[${char_flag}]" "" func_flags_next_suffix "${func_flags_suffix}")

            if (NOT func_flags_next_suffix STREQUAL func_flags_suffix)
              foreach (set0_params_sublist ${set0_params_list})
                list(SUBLIST set0_params_sublist 0 1 set0_char_flag)
                list(SUBLIST set0_params_sublist 1 -1 set0_vars_sublist)

                if (set0_char_flag STREQUAL char_flag)
                  foreach (set0_var IN LISTS set0_vars_sublist)
                    set(${set0_var} 0 PARENT_SCOPE)
                  endforeach()
                endif()
              endforeach()

              foreach (set1_params_sublist ${set1_params_list})
                list(SUBLIST set1_params_sublist 0 1 set1_char_flag)
                list(SUBLIST set1_params_sublist 1 -1 set1_vars_sublist)

                if (set1_char_flag STREQUAL char_flag)
                  foreach (set1_var IN LISTS set1_vars_sublist)
                    set(${set1_var} 1 PARENT_SCOPE)
                  endforeach()
                endif()
              endforeach()
            endif()

            set(func_flags_suffix "${func_flags_next_suffix}")
          endforeach()
        else()
          set(func_flags_suffix .) # just to ignore below check
        endif()
      endif()

      if (NOT func_flags_suffix STREQUAL "")
        message(FATAL_ERROR "flags is not recognized: `${func_flags}`")
      endif()

      if (NOT flags_out_var STREQUAL "")
        list(APPEND flags "${func_flags}")
      endif()

      math(EXPR func_argv_index "${func_argv_index}+1")
    else()
      set(is_multichar_flag_processed 0)

      if (2 LESS func_flags_len)
        string(SUBSTRING "${func_flags}" 2 -1 func_flags_suffix)

        foreach (multichar_flag_params_sublist IN LISTS multichar_flag_params_list)
          list(SUBLIST multichar_flag_params_sublist 0 1 multichar_flag_string)
          list(LENGTH multichar_flag_params_sublist multichar_flag_params_sublist_len)

          if (multichar_flag_params_sublist_len GREATER 1)
            list(SUBLIST multichar_flag_params_sublist 1 1 multichar_flag_set1_var)
            if (multichar_flag_params_sublist_len GREATER 2)
              list(SUBLIST multichar_flag_params_sublist 2 -1 multichar_flag_vars_sublist)
            endif()
          endif()

          if (multichar_flag_params_sublist_len LESS 3)
            set(multichar_flag_vars_sublist "")
          endif()

          if (multichar_flag_string STREQUAL func_flags_suffix)
            set(is_multichar_flag_processed 1)
            math(EXPR func_argv_index "${func_argv_index}+1")

            if (NOT flags_out_var STREQUAL "")
              list(APPEND flags "${func_flags}")
            endif()

            if (multichar_flag_set1_var STREQUAL ".")
              set(multichar_flag_set1_var "")
            endif()

            if (NOT multichar_flag_set1_var STREQUAL "")
              set(${multichar_flag_set1_var} 1 PARENT_SCOPE)
            endif()

            # consume next arguments
            foreach (multichar_flag_var IN LISTS multichar_flag_vars_sublist)
              if (func_argv_index GREATER_EQUAL func_argv_len)
                message(FATAL_ERROR "flag's argument is absent for the flag: `${func_flags}`")
              endif()

              list(GET func_argv ${func_argv_index} multichar_flag_var_value)
              # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
              string(REPLACE ";" "\;" multichar_flag_var_value_escaped "${multichar_flag_var_value}")

              if ((multichar_flag_var STREQUAL ".") OR (multichar_flag_var STREQUAL "*"))
                set(multichar_flag_var "")
              endif()

              if (NOT multichar_flag_var STREQUAL "")
                set(${multichar_flag_var} "${multichar_flag_var_value}" PARENT_SCOPE)
              endif()
              math(EXPR func_argv_index "${func_argv_index}+1")

              if (NOT flags_out_var STREQUAL "")
                list(APPEND flags "${multichar_flag_var_value_escaped}")
              endif()
            endforeach()

            break()
          endif()
        endforeach()
      endif()

      if (NOT is_multichar_flag_processed)
        message(FATAL_ERROR "unknown flag argument: `${func_flags}`")
      endif()
    endif()

    if (func_argv_index GREATER_EQUAL func_argv_len)
      break()
    endif()

    # read next flags
    list(GET func_argv ${func_argv_index} func_flags)
    # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
    string(REPLACE ";" "\;" func_flags "${func_flags}")

    string(SUBSTRING "${func_flags}" 0 1 func_flags_prefix_char0)
  endwhile()

  if (NOT func_argv_index_var STREQUAL "" AND NOT func_argv_index_var STREQUAL ".")
    set(${func_argv_index_var} ${func_argv_index} PARENT_SCOPE)
  endif()

  if (NOT flags_out_var STREQUAL "")
    # append to already existed flags
    set(flags_out "${${flags_out_var}}")
    list(APPEND flags_out "${flags}")
    set(${flags_out_var} "${flags_out}" PARENT_SCOPE)
  endif()
endfunction()

endif()
