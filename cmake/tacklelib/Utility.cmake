# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_UTILITY_INCLUDE_DEFINED)
set(TACKLELIB_UTILITY_INCLUDE_DEFINED 1)

# CAUTION:
#   Must be a function to avoid expansion of variable arguments like:
#   * `${...}` into a value
#   * `$\{...}` into `${...}`
#   * `\n` into the line return
#   etc
#
function(tkl_encode_control_chars in_str out_var)
  string(REPLACE "\\" "\\\\" encoded_value "${in_str}")
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
function(tkl_decode_control_chars in_str out_var)
  set(decoded_value "")
  set(index 0)
  set(is_escaping 0)
  string(LENGTH "${in_str}" value_len)

  while (index LESS value_len)
    string(SUBSTRING "${in_str}" ${index} 1 char)
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

# INFO:
#   This function is required for arguments convertion before an executable or shell call.
#
function(tkl_make_exec_cmdline_from_list out_var)
  set(cmdline "")

  foreach(arg IN LISTS ARGN)
    # WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
    string(REPLACE ";" "\;" arg "${arg}")

    if (NOT arg STREQUAL "")
      string(REGEX REPLACE "([\\\\\\\"\\\\\\\$])" "\\\\\\1" escaped_arg "${arg}")

      if (NOT cmdline STREQUAL "")
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
      if(NOT cmdline STREQUAL "")
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
    if (NOT arg_var STREQUAL "")
      if (NOT eval_cmdline STREQUAL "")
        set(eval_cmdline "${eval_cmdline} \"\\\${${arg_var}}\"")
      else()
        set(eval_cmdline "\"\\\${${arg_var}}\"")
      endif()
    else()
      if(NOT eval_cmdline STREQUAL "")
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
#   which the `tkl_make_macro_cmdline_from_macro_vars_list` function is designed.
#
function(tkl_make_vars_unescaped_expansion_cmdline_from_vars_list out_var)
  set(eval_cmdline "")

  foreach(arg_var IN LISTS ARGN)
    if (NOT arg_var STREQUAL "")
      if (NOT eval_cmdline STREQUAL "")
        set(eval_cmdline "${eval_cmdline} \"\${${arg_var}}\"")
      else()
        set(eval_cmdline "\"\${${arg_var}}\"")
      endif()
    else()
      if(NOT eval_cmdline STREQUAL "")
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

      if (var_name_ending_upper STREQUAL "${var_ending_str}${var_ending_of_ending_str}")
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

function(tkl_regex_to_lower in_str out_var)
  set(regex_value "")
  set(index 0)
  set(is_escaping 0)
  string(LENGTH "${in_str}" value_len)

  while (index LESS value_len)
    string(SUBSTRING "${in_str}" ${index} 1 char)
    if (NOT is_escaping)
      if (NOT char STREQUAL "\\")
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

function(tkl_regex_to_upper in_str out_var)
  set(regex_value "")
  set(index 0)
  set(is_escaping 0)
  string(LENGTH "${in_str}" value_len)

  while (index LESS value_len)
    string(SUBSTRING "${in_str}" ${index} 1 char)
    if (NOT is_escaping)
      if (NOT char STREQUAL "\\")
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

endif()
