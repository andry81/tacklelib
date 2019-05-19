# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_STD_INCLUDE_DEFINED)
set(TACKLELIB_STD_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.14)

include(tacklelib/List)
include(tacklelib/File)

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

function(tkl_copy_vars)
  # ARGV0 - out_vars_all_list
  # ARGV1 - out_vars_filtered_list  (names)
  # ARGV2 - out_vars_values_list    (values)
  # ARGV3 - var_prefix_filter
  if (NOT ${ARGC} EQUAL 4)
    message(FATAL_ERROR "function must be called with all 4 arguments")
  endif()

  get_cmake_property(${ARGV0} VARIABLES)

  # reduce intersection probability with the parent scope variables through the unique variable name prefix
  set(_24C487FA_var_name "")
  set(_24C487FA_var_name_prefix "")
  set(_24C487FA_var_value "")

  string(LENGTH "${ARGV3}" _24C487FA_var_prefix_filter_len)

  if (NOT _24C487FA_var_prefix_filter_len)
    message(FATAL_ERROR "ARGV3 must be not empty variable name prefix token")
  endif()

  set(${ARGV1} "")
  set(${ARGV2} ";") # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!

  foreach (_24C487FA_var_name IN LISTS ${ARGV0})
    string(SUBSTRING "${_24C487FA_var_name}" 0 ${_24C487FA_var_prefix_filter_len} _24C487FA_var_name_prefix)
    # copy values only from "parent scope" variables
    if (_24C487FA_var_name_prefix STREQUAL "${ARGV3}")
      continue()
    endif()

    # check for specific builtin variables
    string(SUBSTRING "${_24C487FA_var_name}" 0 3 _24C487FA_var_name_prefix)
    if (_24C487FA_var_name_prefix STREQUAL "ARG")
      continue()
    endif()

    list(APPEND ${ARGV1} "${_24C487FA_var_name}")
    #tkl_list_join(_24C487FA_var_value ${_24C487FA_var_name} "\;")
    # WORKAROUND: we have to replace because `list(APPEND` will join lists together
    string(REPLACE ";" "\;" _24C487FA_var_value "${${_24C487FA_var_name}}")
    list(APPEND ${ARGV2} "${_24C487FA_var_value}")

    #message("${_24C487FA_var_name}=`${_24C487FA_var_value}`")
  endforeach()

  # remove 2 first dummy empty strings
  tkl_list_remove_sublist(${ARGV2} 0 2 ${ARGV2})

  #list(LENGTH ${ARGV1} vars_len)
  #list(LENGTH ${ARGV2} vals_len)
  #
  #message(vars_len=${vars_len})
  #message(vals_len=${vals_len})

  set(${ARGV1} "${${ARGV1}}" PARENT_SCOPE)
  set(${ARGV2} "${${ARGV2}}" PARENT_SCOPE)
endfunction()

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
#
function(tkl_encode_control_chars in_value out_var)
  string(REPLACE "\\" "\\\\" encoded_value "${in_value}")
  string(REPLACE "\n" "\\n" encoded_value "${encoded_value}")
  string(REPLACE "\r" "\\r" encoded_value "${encoded_value}")
  string(REPLACE "\t" "\\t" encoded_value "${encoded_value}")
  string(REPLACE "\$" "\\\$" encoded_value "${encoded_value}")
  set(${out_var} "${encoded_value}" PARENT_SCOPE)
endfunction()

# CAUTION:
#   Must be a function to avoid expansion of variable arguments like:
#   * `${...}` into a value
#   * `$\{...}` into `${...}`
#   * `\n` into the line return
#   etc
function(tkl_decode_control_chars in_value out_var)
  set(decoded_value "")
  set(index 0)
  set(is_escaping 0)
  string(LENGTH "${in_value}" value_len)

  while (index LESS value_len)
    string(SUBSTRING "${in_value}" ${index} 1 char)
    if (NOT is_escaping)
      if (NOT char STREQUAL "\\")
        set(decoded_value "${decoded_value}${char}")
      else()
        set(is_escaping 1)
      endif()
    else()
      if (char STREQUAL "n")
        set(decoded_value "${decoded_value}\n")
      elseif (char STREQUAL "r")
        set(decoded_value "${decoded_value}\r")
      elseif (char STREQUAL "t")
        set(decoded_value "${decoded_value}\t")
      elseif (char STREQUAL ";")
        set(decoded_value "${decoded_value}\\;") # retain special control character escaping
      else()
        set(decoded_value "${decoded_value}${char}")
      endif()
      set(is_escaping 0)
    endif()

    math(EXPR index "${index}+1")
  endwhile()

  if (is_escaping)
    set(decoded_value "${decoded_value}\\")
  endif()

  set(${out_var} "${decoded_value}" PARENT_SCOPE)
endfunction()

# CAUTION:
#   Must be a function to avoid expansion of variable arguments like:
#   * `${...}` into a value
#   * `$\{...}` into `${...}`
#   * `\n` into the line return
#   etc
function(tkl_make_var_from_ARGV_begin argv_joined_list argv_var)
  if (NOT "${ARGN}" STREQUAL "")
    message(FATAL_ERROR "function must have only 2 arguments")
  endif()

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  # WORKAROUND: we have to recode all control characters because `${ARGV}` and `${ARGN}` will be evaluated on expansion
  tkl_encode_control_chars("${argv_joined_list}" _BBD57550_argv_joined_list_encoded)

  set(_BBD57550_argv_joined_list ";;${_BBD57550_argv_joined_list_encoded}" PARENT_SCOPE)

  unset(${argv_var})
endfunction()

macro(tkl_make_var_from_ARGV_end argv_var)
  if (NOT "${ARGN}" STREQUAL "")
    message(FATAL_ERROR "function must have only 2 arguments")
  endif()

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(${argv_var} ";")
  set(_BBD57550_argv_joined_list_accum ";")

  set(_BBD57550_var_index 0)

  while (NOT _BBD57550_argv_joined_list STREQUAL _BBD57550_argv_joined_list_accum)
    # with finite loop insurance
    if (_BBD57550_var_index GREATER_EQUAL 64)
      message(FATAL_ERROR "ARGV arguments are too many or infinite loop is detected")
    endif()

    set(_BBD57550_argv_value "${ARGV${_BBD57550_var_index}}")

    ## WORKAROUND: we have to replace because `list(APPEND` will join lists together
    #string(REPLACE ";" "\;" _BBD57550_argv_value "${_BBD57550_argv_value}")
    list(APPEND ${argv_var} "${_BBD57550_argv_value}")

    # WORKAROUND: we have to recode all control characters because `${ARGV0..N}` will be evaluated on expansion
    tkl_encode_control_chars("${ARGV${_BBD57550_var_index}}" _BBD57550_argv_value_encoded) # w/o escaping

    list(APPEND _BBD57550_argv_joined_list_accum "${_BBD57550_argv_value_encoded}")

    math(EXPR _BBD57550_var_index "${_BBD57550_var_index}+1")
  endwhile()

  # remove 2 first dummy empty strings
  tkl_list_remove_sublist(${argv_var} 0 2 ${argv_var})

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
#   argv_var - optional
#   argn_var - required
function(tkl_make_vars_from_ARGV_ARGN_begin argv_joined_list argn_joined_list argv_var argn_var)
  if (NOT "${ARGN}" STREQUAL "")
    message(FATAL_ERROR "function must have only 4 arguments")
  endif()

  # WORKAROUND: we have to recode all control characters because `${ARGV}` and `${ARGN}` will be evaluated on expansion
  tkl_encode_control_chars("${argv_joined_list}" _9E220B1D_argv_joined_list_encoded)
  tkl_encode_control_chars("${argn_joined_list}" _9E220B1D_argn_joined_list_encoded)

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(_9E220B1D_argv_joined_list "${_9E220B1D_argv_joined_list_encoded};;")   # 1t phase list
  set(_9E220B1D_argn_joined_list "${_9E220B1D_argn_joined_list_encoded};;")
  # 2d phase list
  if (NOT _9E220B1D_argv_joined_list_encoded STREQUAL "")
    set(_9E220B1D_argv_joined_list2 ";;${_9E220B1D_argv_joined_list_encoded}")
  else()
    set(_9E220B1D_argv_joined_list2 ";")
  endif()

  set(_9E220B1D_argn_offset -1)
  if (NOT "${_9E220B1D_argn_joined_list}" STREQUAL ";;")
    # offset could be with last empty element here
    string(FIND "${_9E220B1D_argv_joined_list}" "${_9E220B1D_argn_joined_list}" _9E220B1D_argn_offset REVERSE)
    # found substring must be the same size to the ARGN string length
    string(LENGTH "${_9E220B1D_argv_joined_list}" _9E220B1D_argv_joined_list_len)
    string(LENGTH "${_9E220B1D_argn_joined_list}" _9E220B1D_argn_joined_list_len)
    math(EXPR _9E220B1D_args_joined_list_len "${_9E220B1D_argv_joined_list_len}-${_9E220B1D_argn_joined_list_len}")
    if (NOT _9E220B1D_args_joined_list_len EQUAL _9E220B1D_argn_offset)
      set(_9E220B1D_argn_offset -1) # reset the offset
    endif()
  endif()

  if (NOT "${argv_var}" STREQUAL "")
    unset(${argv_var} PARENT_SCOPE)
  endif()
  unset(${argn_var} PARENT_SCOPE)
  set(_9E220B1D_argn_offset "${_9E220B1D_argn_offset}" PARENT_SCOPE)
  set(_9E220B1D_argv_joined_list "${_9E220B1D_argv_joined_list}" PARENT_SCOPE)
  set(_9E220B1D_argn_joined_list "${_9E220B1D_argn_joined_list}" PARENT_SCOPE)
  set(_9E220B1D_argv_joined_list2 "${_9E220B1D_argv_joined_list2}" PARENT_SCOPE)
endfunction()

# Params:
#   argv_var - optional
#   argn_var - required
macro(tkl_make_vars_from_ARGV_ARGN_end argv_var argn_var)
  if (NOT "${ARGN}" STREQUAL "")
    message(FATAL_ERROR "function must have only 2 arguments")
  endif()

  if (_9E220B1D_argn_offset GREATER_EQUAL 0)
    # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
    if (NOT "${argv_var}" STREQUAL "")
      set(${argv_var} ";")
    endif()
    set(${argn_var} ";")
    set(_9E220B1D_argv_joined_list_accum ";")

    math(EXPR _9E220B1D_argn_offset "${_9E220B1D_argn_offset}")

    string(SUBSTRING "${_9E220B1D_argv_joined_list}" 0 ${_9E220B1D_argn_offset} _9E220B1D_args_joined_list)
    if (NOT _9E220B1D_args_joined_list STREQUAL "")
      # remove last `;` character
      string(REGEX REPLACE "(.*)\;$" ";;\\1" _9E220B1D_args_joined_list "${_9E220B1D_args_joined_list}")
    else()
      set(_9E220B1D_args_joined_list ";")
    endif()

    set(_9E220B1D_var_index 0)

    while (NOT _9E220B1D_args_joined_list STREQUAL _9E220B1D_argv_joined_list_accum)
      # with finite loop insurance
      if (_9E220B1D_var_index GREATER_EQUAL 64)
        message(FATAL_ERROR "ARGV arguments are too many or infinite loop is detected")
      endif()

      if (NOT "${argv_var}" STREQUAL "")
        set(_9E220B1D_argv_value "${ARGV${_9E220B1D_var_index}}")
        list(APPEND ${argv_var} "${_9E220B1D_argv_value}")
      endif()

      # WORKAROUND: we have to recode all control characters because `${ARGV0..N}` will be evaluated on expansion
      tkl_encode_control_chars("${ARGV${_9E220B1D_var_index}}" _9E220B1D_argv_value_encoded) # w/o escaping

      list(APPEND _9E220B1D_argv_joined_list_accum "${_9E220B1D_argv_value_encoded}")

      math(EXPR _9E220B1D_var_index "${_9E220B1D_var_index}+1")
    endwhile()

    while (NOT _9E220B1D_argv_joined_list2 STREQUAL _9E220B1D_argv_joined_list_accum)
      # with finite loop insurance
      if (_9E220B1D_var_index GREATER_EQUAL 64)
        message(FATAL_ERROR "ARGV arguments are too many or infinite loop is detected")
      endif()

      set(_9E220B1D_argv_value "${ARGV${_9E220B1D_var_index}}")

      #message("[${_9E220B1D_var_index}] _9E220B1D_argv_value=${_9E220B1D_argv_value}")
      ## WORKAROUND: we have to replace because `list(APPEND` will join lists together
      #string(REPLACE ";" "\;" _9E220B1D_argv_value "${_9E220B1D_argv_value}")
      if (NOT "${argv_var}" STREQUAL "")
        list(APPEND ${argv_var} "${_9E220B1D_argv_value}")
      endif()
      list(APPEND ${argn_var} "${_9E220B1D_argv_value}")

      # WORKAROUND: we have to recode all control characters because `${ARGV0..N}` will be evaluated on expansion
      tkl_encode_control_chars("${ARGV${_9E220B1D_var_index}}" _9E220B1D_argv_value_encoded) # w/o escaping

      list(APPEND _9E220B1D_argv_joined_list_accum "${_9E220B1D_argv_value_encoded}")

      math(EXPR _9E220B1D_var_index "${_9E220B1D_var_index}+1")
    endwhile()

    # remove 2 first dummy empty strings
    if (NOT "${argv_var}" STREQUAL "")
      tkl_list_remove_sublist(${argv_var} 0 2 ${argv_var})
    endif()
    tkl_list_remove_sublist(${argn_var} 0 2 ${argn_var})

    unset(_9E220B1D_argv_joined_list_accum)
    unset(_9E220B1D_var_index)
    unset(_9E220B1D_argv_value)
    unset(_9E220B1D_argv_value_encoded)
  else()
    if (NOT "${argv_var}" STREQUAL "")
      set(${argv_var} "")
    endif()
    set(${argn_var} "")
  endif()

  unset(_9E220B1D_argv_joined_list)
  unset(_9E220B1D_argn_joined_list)
  unset(_9E220B1D_argv_joined_list2)
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
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" "" argn)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_vars_from_ARGV_ARGN_end("" argn)
  #message("tkl_make_var_from_CMAKE_ARGV_ARGC: argv=${argv}")
  #message("tkl_make_var_from_CMAKE_ARGV_ARGC: argn=${argn}")

  list(LENGTH argn argn_len)
  set(argn_index 0)
  set(set_script_args 0)

  # parse flags until no flags
  tkl_parse_function_optional_flags_into_vars(
    argn_index
    argn
    "P"
    ""
    "P\;set_script_args"
    "")

  if (NOT argn_index LESS argn_len)
    message(FATAL_ERROR "function must be called at least with 1 not optional argument: argn_len=${argn_len} argn_index=${argn_index}")
  endif()

  tkl_get_cmake_role(SCRIPT is_in_script_mode)
  if (NOT is_in_script_mode)
    message(FATAL_ERROR "call must be made from the script mode only")
  endif()

  list(GET argn ${argn_index} out_var)
  math(EXPR argn_index "${argn_index}+1")

  set(${out_var} "")
  set(cmake_arg_index 0)

  if (NOT set_script_args)
    while(cmake_arg_index LESS CMAKE_ARGC)
      list(APPEND ${out_var} "${CMAKE_ARGV${cmake_arg_index}}")
      math(EXPR cmake_arg_index "${cmake_arg_index}+1")
    endwhile()
  else()
    get_filename_component(this_script_file_path_abs "${CMAKE_SCRIPT_MODE_FILE}" ABSOLUTE)

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
          # Parse the value as a path to the script file, convert to the absolute path and
          # then compare on equality with the absolute path in the CMAKE_SCRIPT_MODE_FILE variable.
          get_filename_component(script_file_path_abs "${arg_value}" ABSOLUTE)
          if (NOT this_script_file_path_abs STREQUAL script_file_path_abs)
            message(FATAL_ERROR "path to this script file and a command line argument after the `-P` option must be the same")
          endif()
          list(APPEND ${out_var} "${script_file_path_abs}") # converted into the absolute path
        endif()
      else()
        if (arg_value STREQUAL "-P")
          math(EXPR script_file_path_offset "${cmake_arg_index}+1")
        endif()
      endif()

      math(EXPR cmake_arg_index "${cmake_arg_index}+1")
    endwhile()
  endif()

  set(${out_var} "${${out_var}}" PARENT_SCOPE)
endfunction()

function(tkl_set_ARGV)
  set(argv_index 0)

  while (argv_index LESS ${ARGC})
    set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
    math(EXPR argv_index "${argv_index}+1")
  endwhile()

  if (NOT "${ARGC}" STREQUAL "")
    set(ARGC_ "${ARGC}" PARENT_SCOPE)
  endif()
endfunction()

function(tkl_unset_ARGV)
  set(argv_index 0)

  while (argv_index LESS ARGC_)
    set(ARGV${argv_index} "${ARGV${argv_index}}" PARENT_SCOPE)
    math(EXPR argv_index "${argv_index}+1")
  endwhile()

  unset(ARGC_ PARENT_SCOPE)
endfunction()

function(tkl_print_ARGV)
  set(argn_index 0)

  while(argn_index LESS ARGC_)
    message("ARGV${argn_index}=`${ARGV${argn_index}}`")
    math(EXPR argn_index "${argn_index}+1")
  endwhile()
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
  set(func_argv_index "${${func_argv_index_var}}")
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

    # read next flags
    list(GET func_argv ${func_argv_index} func_flags)
    # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
    string(REPLACE ";" "\;" func_flags "${func_flags}")

    string(SUBSTRING "${func_flags}" 0 1 func_flags_prefix_char0)
  endwhile()

  set(${func_argv_index_var} ${func_argv_index} PARENT_SCOPE)

  if (NOT flags_out_var STREQUAL "")
    # append to already existed flags
    set(flags_out "${${flags_out_var}}")
    list(APPEND flags_out "${flags}")
    set(${flags_out_var} "${flags_out}" PARENT_SCOPE)
  endif()
endfunction()

function(tkl_make_cmdline_from_list out_var)
  set(cmdline "")

  foreach(arg IN LISTS ARGN)
    if (NOT arg STREQUAL "")
      string(REGEX REPLACE "([;\\\\\\\"])" "\\\\\\1" escaped_arg "${arg}")

      if(cmdline)
        if(NOT arg MATCHES "[;, \t\"]")
          set(cmdline "${cmdline} ${escaped_arg}")
        else()
          set(cmdline "${cmdline} \"${escaped_arg}\"")
        endif()
      else()
        if(NOT arg MATCHES "[;, \t\"]")
          set(cmdline "${escaped_arg}")
        else()
          set(cmdline "\"${escaped_arg}\"")
        endif()
      endif()
    else()
      if(cmdline)
        set(cmdline "${cmdline} \"\"")
      else()
        set(cmdline "\"\"")
      endif()
    endif()
  endforeach()

  set(${out_var} "${cmdline}" PARENT_SCOPE)
endfunction()

# To escape characters from cmake builtin escape discarder which will discard escaping
# from `;` and `\` characters on passing list items into function arguments.
function(tkl_escape_list_expansion out_var in_list)
  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(escaped_list ";")

  foreach(arg IN LISTS in_list)
    # 1. WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
    string(REPLACE ";" "\;" escaped_arg "${arg}")
    # 2. another escape sequence to retain exact values in the list after pass into a function without quotes: `foo(${mylist})`
    string(REPLACE "\\" "\\\\" escaped_arg "${escaped_arg}")
    # 3. escape variables expansion
    string(REPLACE "\$" "\\\$" escaped_arg "${escaped_arg}")
    #message("arg: `${arg}` -> `${escaped_arg}`")
    list(APPEND escaped_list "${escaped_arg}")
  endforeach()

  # remove 2 first dummy empty strings
  tkl_list_remove_sublist(escaped_list 0 2 escaped_list)

  set(${out_var} "${escaped_list}" PARENT_SCOPE)
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

function(tkl_is_path_var_by_name is_var_out var_name)
  # variable name endings
  set (var_ending_strs
    _ROOT _PATH _DIR _SUBDIR _DIRECTORY _SUBDIRECTORY _FILE
    _ROOTS _PATHS _DIRS _SUBDIRS _DIRECTORIES _SUBDIRECTORIES _FILES
    _INSTALL_PREFIX _FILE_PREFIX
    _INSTALL_PREFIXES _FILE_PREFIXES
    _LIB _LIBS
    _LIBRARY _LIBRARIES
    _INCLUDE _INCLUDES
    _INCLUDEDIR _LIBRARYDIR
    _INCLUDEDIRS _LIBRARYDIRS
    _LOCATION _LOCATIONS
    _SRC _SOURCE
    _SRCS _SOURCES
    _EXE _EXECUTABLE _EXECUTABLES
  )

  # variable name endings of all endings
  set (var_ending_of_ending_strs ";_LIST") # CAUTION: all must be in the upper case

  # complete variable names
  set (var_name_strs
    ROOT PATH DIR SUBDIR DIRECTORY SUBDIRECTORY FILE
    ROOTS PATHS DIRS SUBDIRS DIRECTORIES SUBDIRECTORIES FILES
    PREFIX INSTALL_PREFIX FILE_PREFIX
    PREFIXES INSTALL_PREFIXES FILE_PREFIXES
    LIB LIBS
    LIBRARY LIBRARIES
    INCLUDE INCLUDES
    INCLUDEDIR LIBRARYDIR
    INCLUDEDIRS LIBRARYDIRS
    LOCATION LOCATIONS
    SRC SOURCE
    SRCS SOURCES
    EXE EXECUTABLE EXECUTABLES
  ) # CAUTION: all must be in the upper case

  # check name ending at first
  foreach (var_ending_of_ending_str IN LISTS var_ending_of_ending_strs)
    string(LENGTH "${var_name}" var_name_len)
    string(TOUPPER "${var_name}" var_name_upper)

    #message("= [${var_name_len}] ${var_name_upper}")

    foreach (var_ending_str IN LISTS var_ending_strs)
      string(LENGTH "${var_ending_str}${var_ending_of_ending_str}" var_ending_str_len)
      if (var_name_len LESS var_ending_str_len)
        continue()
      endif()

      #message("== [${var_ending_str_len}] ${var_ending_str}${var_ending_of_ending_str}")

      if (var_ending_str_len LESS var_name_len)
        math(EXPR var_name_remainder_len "${var_name_len}-${var_ending_str_len}")
        string(SUBSTRING "${var_name_upper}" ${var_name_remainder_len} -1 var_name_ending_upper)
      else()
        set(var_name_ending_upper "${var_name_upper}")
      endif()

      #message("=== [${var_name_remainder_len}] ${var_name_ending_upper}\n")

      if (var_name_ending_upper STREQUAL "${var_ending_str}${var_ending_of_ending_str}")
        #message("var_name=`${var_name}` is PATH (ending=`${var_ending_str}${var_ending_of_ending_str}`)")
        set(${is_var_out} 1 PARENT_SCOPE)
        return()
      endif()
    endforeach()
  endforeach()

  # check complete names
  foreach (var_ending_of_ending_str IN LISTS var_ending_of_ending_strs)
    string(TOUPPER "${var_name}" var_name_upper)

    #message("= ${var_name_upper}")

    foreach (var_name_str IN LISTS var_name_strs)
      #message("== ${var_name_str}${var_ending_of_ending_str}")
      if ("${var_name_str}${var_ending_of_ending_str}" STREQUAL var_name_upper)
        #message("var_name=`${var_name}` is PATH")
        set(${is_var_out} 1 PARENT_SCOPE)
        return()
      endif()
    endforeach()
  endforeach()

  #message("var_name=`${var_name}` is not PATH")
  set(${is_var_out} 0 PARENT_SCOPE)
endfunction()

endif()
