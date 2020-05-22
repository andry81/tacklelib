# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_UTILITY_INCLUDE_DEFINED)
set(TACKLELIB_UTILITY_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.7)

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# at least cmake 3.3 is required for:
# * to use IN_LIST in if command: (https://cmake.org/cmake/help/v3.3/command/if.html )
#   `if(<variable|string> IN_LIST <variable>)`
#

include(tacklelib/String)

# CAUTION:
#   Must be a function to avoid expansion of variable arguments like:
#   * `${...}` into a value
#   * `$\{...}` into `${...}`
#   * `\n` into the line return
#   etc
function(tkl_decode_control_chars_from_cmd_arg out_var in_str)
  set(decoded_value "")
  set(index 0)
  set(is_escaping 0)
  string(LENGTH "${in_str}" value_len)

  while (index LESS value_len)
    string(SUBSTRING "${in_str}" ${index} 1 char)
    if (NOT is_escaping)
      if (NOT "${char}" STREQUAL "\\")
        set(decoded_value "${decoded_value}${char}")
      else()
        set(is_escaping 1)
      endif()
    else()
      if ("${char}" STREQUAL "n")
        set(decoded_value "${decoded_value}\n")
      elseif ("${char}" STREQUAL "r")
        set(decoded_value "${decoded_value}\r")
      elseif ("${char}" STREQUAL "t")
        set(decoded_value "${decoded_value}\t")
      elseif ("${char}" STREQUAL ";")
        set(decoded_value "${decoded_value}\;") # retain special control character escaping
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

# INFO:
#   This function is required for arguments convertion before an executable or shell call.
#
function(tkl_make_exec_cmdline_from_list out_var)
  set(cmdline "")

  foreach(arg IN LISTS ARGN)
    # WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
    tkl_escape_string_after_list_get(arg "${arg}")

    if (NOT "${arg}" STREQUAL "")
      string(REGEX REPLACE "([\\\\\\\"\\\\\\\$])" "\\\\\\1" escaped_arg "${arg}")

      if (NOT "${cmdline}" STREQUAL "")
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
      if(NOT "${cmdline}" STREQUAL "")
        set(cmdline "${cmdline} \"\"")
      else()
        set(cmdline "\"\"")
      endif()
    endif()
  endforeach()

  set(${out_var} "${cmdline}" PARENT_SCOPE)
endfunction()

# INFO:
#   This function is required for arguments convertion before a macro call AFTER in a macro call (nested macro call).
#   For details: https://gitlab.kitware.com/cmake/cmake/issues/19281
#
function(tkl_make_vars_escaped_expansion_cmdline_from_vars_list out_var)
  set(eval_cmdline "")

  foreach(arg_var IN LISTS ARGN)
    if (NOT "${arg_var}" STREQUAL "")
      if (NOT "${eval_cmdline}" STREQUAL "")
        set(eval_cmdline "${eval_cmdline} \"\\\${${arg_var}}\"")
      else()
        set(eval_cmdline "\"\\\${${arg_var}}\"")
      endif()
    else()
      if(NOT "${eval_cmdline}" STREQUAL "")
        set(eval_cmdline "${eval_cmdline} \"\"")
      else()
        set(eval_cmdline "\"\"")
      endif()
    endif()
  endforeach()

  set(${out_var} "${eval_cmdline}" PARENT_SCOPE)
endfunction()

# INFO:
#   This function is required for all other cases of a call except of a nested macro call for
#   which the `tkl_make_vars_escaped_expansion_cmdline_from_vars_list` function is designed.
#
function(tkl_make_vars_unescaped_expansion_cmdline_from_vars_list out_var)
  set(eval_cmdline "")

  foreach(arg_var IN LISTS ARGN)
    if (NOT "${arg_var}" STREQUAL "")
      if (NOT "${eval_cmdline}" STREQUAL "")
        set(eval_cmdline "${eval_cmdline} \"\${${arg_var}}\"")
      else()
        set(eval_cmdline "\"\${${arg_var}}\"")
      endif()
    else()
      if(NOT "${eval_cmdline}" STREQUAL "")
        set(eval_cmdline "${eval_cmdline} \"\"")
      else()
        set(eval_cmdline "\"\"")
      endif()
    endif()
  endforeach()

  set(${out_var} "${eval_cmdline}" PARENT_SCOPE)
endfunction()

# To escape characters from cmake builtin escape discarder which will discard escaping
# from `;` and `\` characters on passing list items into function arguments.
function(tkl_escape_list_expansion out_var in_list)
  if (ARGC GREATER 5)
    message(FATAL_ERROR "function must be called maximum with 3 optional arguments: `${ARGC}`")
  endif()

  if (ARGC GREATER 2)
    set(escape_backslash ${ARGV2})
  else()
    set(escape_backslash 0)
  endif()

  if (ARGC GREATER 3)
    set(escape_list_separator ${ARGV3})
  else()
    set(escape_list_separator 0)
  endif()

  if (ARGC GREATER 4)
    set(escape_string_quotes ${ARGV4})
  else()
    set(escape_string_quotes 0)
  endif()

  # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
  set(escaped_list ";")

  foreach(arg IN LISTS in_list)
    # 1. WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
    tkl_escape_string_after_list_get(escaped_arg "${arg}")

    # 2. another escape sequence to retain exact values in the list after pass into a function without quotes: `foo(${mylist})`
    if (escape_backslash)
      string(REPLACE "\\" "\\\\" escaped_arg "${escaped_arg}")
    endif()
    if (escape_list_separator)
      string(REPLACE ";" "\;" escaped_arg "${escaped_arg}")
    endif()
    if (escape_string_quotes)
      string(REPLACE "\"" "\\\"" escaped_arg "${escaped_arg}")
    endif()

    #message("arg: `${arg}` -> `${escaped_arg}`")
    list(APPEND escaped_list "${escaped_arg}")
  endforeach()

  # remove 2 first dummy empty strings
  tkl_list_remove_sublist(escaped_list 0 2 escaped_list)

  set(${out_var} "${escaped_list}" PARENT_SCOPE)
endfunction()

# To escape characters from cmake builtin escape discarder which will discard escaping
# from `;` and `\` characters on passing list items into macro arguments.
function(tkl_escape_list_expansion_as_cmdline out_var in_list)
  if (ARGC GREATER 5)
    message(FATAL_ERROR "function must be called maximum with 3 optional arguments: `${ARGC}`")
  endif()

  if (ARGC GREATER 2)
    set(escape_backslash ${ARGV2})
  else()
    set(escape_backslash 0)
  endif()

  if (ARGC GREATER 3)
    set(escape_list_separator ${ARGV3})
  else()
    set(escape_list_separator 0)
  endif()

  set(eval_cmdline "")

  foreach(arg IN LISTS in_list)
    # 1. WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
    tkl_escape_string_after_list_get(escaped_arg "${arg}")

    # 2. another escape sequence to retain exact values in the list after pass into a function without quotes: `foo(${mylist})`
    if (escape_backslash)
      string(REPLACE "\\" "\\\\" escaped_arg "${escaped_arg}")
    endif()
    if (escape_list_separator)
      string(REPLACE ";" "\;" escaped_arg "${escaped_arg}")
    endif()
    string(REPLACE "\"" "\\\"" escaped_arg "${escaped_arg}")

    #message("arg: `${arg}` -> `${escaped_arg}`")
    if (NOT "${eval_cmdline}" STREQUAL "")
      set(eval_cmdline "${eval_cmdline} \"${escaped_arg}\"")
    else()
      set(eval_cmdline "\"${escaped_arg}\"")
    endif()
  endforeach()

  set(${out_var} "${eval_cmdline}" PARENT_SCOPE)
endfunction()

function(tkl_is_path_var_by_name out_is_var var_name)
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

      if ("${var_name_ending_upper}" STREQUAL "${var_ending_str}${var_ending_of_ending_str}")
        #message("var_name=`${var_name}` is PATH (ending=`${var_ending_str}${var_ending_of_ending_str}`)")
        set(${is_out_is_var} 1 PARENT_SCOPE)
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
        set(${is_out_is_var} 1 PARENT_SCOPE)
        return()
      endif()
    endforeach()
  endforeach()

  #message("var_name=`${var_name}` is not PATH")
  set(${is_out_is_var} 0 PARENT_SCOPE)
endfunction()

function(tkl_regex_to_lower out_var in_str)
  set(regex_value "")
  set(index 0)
  set(is_escaping 0)
  string(LENGTH "${in_str}" value_len)

  while (index LESS value_len)
    string(SUBSTRING "${in_str}" ${index} 1 char)
    if (NOT is_escaping)
      if (NOT "${char}" STREQUAL "\\")
        string(TOLOWER "${char}" char)
        set(regex_value "${regex_value}${char}")
      else()
        set(is_escaping 1)
      endif()
    else()
      # retain character escaping
      set(regex_value "${regex_value}\\${char}")
      set(is_escaping 0)
    endif()

    math(EXPR index "${index}+1")
  endwhile()

  if (is_escaping)
    set(regex_value "${regex_value}\\")
  endif()

  set(${out_var} "${regex_value}" PARENT_SCOPE)
endfunction()

function(tkl_regex_to_upper out_var in_str)
  set(regex_value "")
  set(index 0)
  set(is_escaping 0)
  string(LENGTH "${in_str}" value_len)

  while (index LESS value_len)
    string(SUBSTRING "${in_str}" ${index} 1 char)
    if (NOT is_escaping)
      if (NOT "${char}" STREQUAL "\\")
        string(TOUPPER "${char}" char)
        set(regex_value "${regex_value}${char}")
      else()
        set(is_escaping 1)
      endif()
    else()
      # retain character escaping
      set(regex_value "${regex_value}\\${char}")
      set(is_escaping 0)
    endif()

    math(EXPR index "${index}+1")
  endwhile()

  if (is_escaping)
    set(regex_value "${regex_value}\\")
  endif()

  set(${out_var} "${regex_value}" PARENT_SCOPE)
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
    "${set0_params_list}" "${set1_params_list}" "${multichar_flag_params_list}" .)
endmacro()

function(tkl_parse_function_optional_flags_into_vars_impl func_argv_index_var func_argv_var func_char_flags_list set0_params_list set1_params_list multichar_flag_params_list flags_out_var)
  if (NOT "${func_argv_index_var}" STREQUAL "" AND NOT "${func_argv_index_var}" STREQUAL ".")
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
    tkl_escape_string_after_list_get(func_flags "${func_flags}")

    string(SUBSTRING "${func_flags}" 0 1 func_flags_prefix_char0)
  else()
    set(func_flags_prefix_char0 "")
  endif()

  set(flags "")

  while ("${func_flags_prefix_char0}" STREQUAL "-")
    string(LENGTH "${func_flags}" func_flags_len)
    if (1 LESS func_flags_len)
      string(SUBSTRING "${func_flags}" 1 1 func_flags_prefix_char1)
    else()
      set(func_flags_prefix_char1 "")
    endif()

    if (NOT "${func_flags_prefix_char1}" STREQUAL "-")
      if (1 LESS func_flags_len)
        string(SUBSTRING "${func_flags}" 1 -1 func_flags_suffix)
      endif()

      if (NOT "${func_flags_suffix}" STREQUAL "")
        if (NOT "${func_char_flags_list}" STREQUAL "")
          foreach (char_flag ${func_char_flags_list})
            string(SUBSTRING "${char_flag}" 0 1 char_flag) # just in case
            string(REGEX REPLACE "[${char_flag}]" "" func_flags_next_suffix "${func_flags_suffix}")

            if (NOT "${func_flags_next_suffix}" STREQUAL "${func_flags_suffix}")
              foreach (set0_params_sublist ${set0_params_list})
                list(SUBLIST set0_params_sublist 0 1 set0_char_flag)
                list(SUBLIST set0_params_sublist 1 -1 set0_vars_sublist)

                if ("${set0_char_flag}" STREQUAL "${char_flag}")
                  foreach (set0_var IN LISTS set0_vars_sublist)
                    set(${set0_var} 0 PARENT_SCOPE)
                  endforeach()
                endif()
              endforeach()

              foreach (set1_params_sublist ${set1_params_list})
                list(SUBLIST set1_params_sublist 0 1 set1_char_flag)
                list(SUBLIST set1_params_sublist 1 -1 set1_vars_sublist)

                if ("${set1_char_flag}" STREQUAL "${char_flag}")
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

      if (NOT "${func_flags_suffix}" STREQUAL "")
        message(FATAL_ERROR "flags is not recognized: `${func_flags}`")
      endif()

      if (NOT "${flags_out_var}" STREQUAL "" AND NOT "${flags_out_var}" STREQUAL ".")
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

          if ("${multichar_flag_string}" STREQUAL "${func_flags_suffix}")
            set(is_multichar_flag_processed 1)
            math(EXPR func_argv_index "${func_argv_index}+1")

            if (NOT "${flags_out_var}" STREQUAL "")
              list(APPEND flags "${func_flags}")
            endif()

            if ("${multichar_flag_set1_var}" STREQUAL ".")
              set(multichar_flag_set1_var "")
            endif()

            if (NOT "${multichar_flag_set1_var}" STREQUAL "")
              set(${multichar_flag_set1_var} 1 PARENT_SCOPE)
            endif()

            # consume next arguments
            foreach (multichar_flag_var IN LISTS multichar_flag_vars_sublist)
              if (func_argv_index GREATER_EQUAL func_argv_len)
                message(FATAL_ERROR "flag's argument is absent for the flag: `${func_flags}`")
              endif()

              list(GET func_argv ${func_argv_index} multichar_flag_var_value)
              # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
              tkl_escape_string_after_list_get(multichar_flag_var_value_escaped "${multichar_flag_var_value}")

              if (("${multichar_flag_var}" STREQUAL ".") OR ("${multichar_flag_var}" STREQUAL "*"))
                set(multichar_flag_var "")
              endif()

              if (NOT "${multichar_flag_var}" STREQUAL "")
                set(${multichar_flag_var} "${multichar_flag_var_value}" PARENT_SCOPE)
              endif()
              math(EXPR func_argv_index "${func_argv_index}+1")

              if (NOT "${flags_out_var}" STREQUAL "")
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
    tkl_escape_string_after_list_get(func_flags "${func_flags}")

    string(SUBSTRING "${func_flags}" 0 1 func_flags_prefix_char0)
  endwhile()

  if (NOT "${func_argv_index_var}" STREQUAL "" AND NOT "${func_argv_index_var}" STREQUAL ".")
    set(${func_argv_index_var} ${func_argv_index} PARENT_SCOPE)
  endif()

  if (NOT "${flags_out_var}" STREQUAL "")
    # append to already existed flags
    set(flags_out "${${flags_out_var}}")
    list(APPEND flags_out "${flags}")
    set(${flags_out_var} "${flags_out}" PARENT_SCOPE)
  endif()
endfunction()

endif()
