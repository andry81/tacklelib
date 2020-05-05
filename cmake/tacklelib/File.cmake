# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_FILE_INCLUDE_DEFINED)
set(TACKLELIB_FILE_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.7)

include(tacklelib/Std)
include(tacklelib/Reimpl)
include(tacklelib/ForwardArgs)

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# at least cmake 3.3 is required for:
# * to use IN_LIST in if command: (https://cmake.org/cmake/help/v3.3/command/if.html )
#   `if(<variable|string> IN_LIST <variable>)`
#

function(tkl_detect_file_system_paths_sensitivity out_is_name_case_sensitive_var out_is_back_and_forward_slash_separator_var)
  tkl_get_global_prop(is_name_case_sensitive "tkl::file_system::name_case_sensitive" 0)
  if (NOT DEFINED is_name_case_sensitive)
    if (NOT DEFINED CMAKE_FILE_SYSTEM_CASE_SENSITIVE AND
        (WIN32 OR MSYS OR MINGW OR CYGWIN))
      tkl_set_global_prop(is_name_case_sensitive "tkl::file_system::name_case_sensitive" 0)
    else()
      tkl_set_global_prop(is_name_case_sensitive "tkl::file_system::name_case_sensitive" 1)
    endif()
  endif()

  # file system a back slash character separator treatment
  tkl_get_global_prop(is_back_and_forward_slash_separator "tkl::file_system::back_and_forward_slash_separator" 0)
  if (NOT DEFINED is_back_and_forward_slash_separator AND
      (WIN32 OR MSYS OR MINGW OR CYGWIN))
    tkl_set_global_prop(is_back_and_forward_slash_separator "tkl::file_system::back_and_forward_slash_separator" 1)
  else()
    tkl_set_global_prop(is_back_and_forward_slash_separator "tkl::file_system::back_and_forward_slash_separator" 0)
  endif()

  set(num_out_vars 0)

  if (NOT "${out_is_name_case_sensitive_var}" STREQUAL "" AND NOT "${out_is_name_case_sensitive_var}" STREQUAL ".")
    set(${out_is_name_case_sensitive_var} ${is_name_case_sensitive} PARENT_SCOPE)
    math(EXPR num_out_vars ${num_out_vars}+1)
  endif()
  if (NOT "${out_is_back_and_forward_slash_separator_var}" STREQUAL "" AND NOT "${out_is_back_and_forward_slash_separator_var}" STREQUAL ".")
    set(${out_is_back_and_forward_slash_separator_var} ${is_back_and_forward_slash_separator} PARENT_SCOPE)
    math(EXPR num_out_vars ${num_out_vars}+1)
  endif()

  if (NOT num_out_vars GREATER 0)
    message(FATAL_ERROR "at least one variable must be returned")
  endif()
endfunction()

function(tkl_is_equal_paths out_var mode path0 path1 is_name_case_sensitive is_back_and_forward_slash_separator)
  if ("${is_name_case_sensitive}" STREQUAL "" OR "${is_name_case_sensitive}" STREQUAL ".")
    tkl_detect_file_system_paths_sensitivity(is_name_case_sensitive .)
  endif()

  if ("${is_back_and_forward_slash_separator}" STREQUAL "" OR "${is_back_and_forward_slash_separator}" STREQUAL ".")
    tkl_detect_file_system_paths_sensitivity(. is_back_and_forward_slash_separator)
  endif()

  if ("${mode}" STREQUAL "" OR "${mode}" STREQUAL ".")
    set(comp_path0 "${path0}")
    set(comp_path1 "${path1}")
  else()
    get_filename_component(comp_path0 "${path0}" ${mode})
    get_filename_component(comp_path1 "${path1}" ${mode})
  endif()

  if (NOT is_name_case_sensitive)
    string(TOLOWER "${comp_path0}" comp_path0)
    string(TOLOWER "${comp_path1}" comp_path1)
  endif()

  if (is_back_and_forward_slash_separator)
    string(REPLACE "\\" "/" comp_path0 "${comp_path0}")
    string(REPLACE "\\" "/" comp_path1 "${comp_path1}")
  endif()

  if ("${comp_path0}" STREQUAL "${comp_path1}")
    set(${out_var} 1 PARENT_SCOPE)
  else()
    set(${out_var} 0 PARENT_SCOPE)
  endif()
endfunction()

function(tkl_make_comparable_path out_var path mode is_name_case_sensitive is_back_and_forward_slash_separator)
  if ("${is_name_case_sensitive}" STREQUAL "" OR "${is_name_case_sensitive}" STREQUAL ".")
    tkl_detect_file_system_paths_sensitivity(is_name_case_sensitive .)
  endif()

  if ("${is_back_and_forward_slash_separator}" STREQUAL "" OR "${is_back_and_forward_slash_separator}" STREQUAL ".")
    tkl_detect_file_system_paths_sensitivity(. is_back_and_forward_slash_separator)
  endif()

  if ("${mode}" STREQUAL "" OR "${mode}" STREQUAL ".")
    set(comp_path "${path}")
  else()
    get_filename_component(comp_path "${path}" ${mode})
  endif()

  if (NOT is_name_case_sensitive)
    string(TOLOWER "${comp_path}" comp_path)
  endif()

  if (is_back_and_forward_slash_separator)
    string(REPLACE "\\" "/" comp_path "${comp_path}")
  endif()

  set(${out_var} "${comp_path}" PARENT_SCOPE)
endfunction()

# returns "." if paths are equal
function(tkl_subtract_absolute_paths from_path to_path out_var)
  string(TOLOWER "${from_path}" from_path_lower)
  string(TOLOWER "${to_path}" to_path_lower)

  if (NOT "${from_path_lower}" STREQUAL "")
    if ("${to_path_lower}" STREQUAL "${from_path_lower}")
      set(${out_var} "." PARENT_SCOPE)
      return()
    else()
      file(RELATIVE_PATH rel_path ${to_path_lower} ${from_path_lower})
      if (DEFINED rel_path)
        string(SUBSTRING "${rel_path}" 0 2 rel_path_first_component)
        if(NOT "${rel_path_first_component}" STREQUAL ".." AND NOT "${rel_path}" STREQUAL "${from_path_lower}")
          set(${out_var} ${rel_path} PARENT_SCOPE)
          return()
        endif()
      endif()
    endif()
  endif()

  set(${out_var} "" PARENT_SCOPE)
endfunction()

# Workaround for `file(REMOVE ...)` to bypass the command issues.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/19274 : `file(REMOVE_RECURSE "")` removes everything from current working directory`
#
function(tkl_file_remove)
  tkl_detect_file_system_paths_sensitivity(. is_back_and_forward_slash_separator)

  foreach(file_path IN LISTS ARGV)
    # protection from removing the current working directory or the root of the current drive (Windows) or the file system (Linux)
    if ("${file_path}" STREQUAL "")
      message(FATAL_ERROR "attemp to implicitly erase the current working directory")
    endif()
    if (is_back_and_forward_slash_separator)
      if ("${file_path}" STREQUAL "/" OR "${file_path}" STREQUAL "\\")
        message(FATAL_ERROR "attemp to erase the root of the current drive")
      endif()
    else()
      if ("${file_path}" STREQUAL "/")
        message(FATAL_ERROR "attemp to erase the root of the file system")
      endif()
    endif()

    # call to previous implementation
    #message("tkl_file_remove: `${file_path}`")
    _file(REMOVE "${file_path}")
  endforeach()
endfunction()

# Workaround for `file(REMOVE_RECURSE ...)` to bypass the command issues.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/19274 : `file(REMOVE_RECURSE "")` removes everything from current working directory`
#
function(tkl_file_remove_recurse)
  tkl_detect_file_system_paths_sensitivity(. is_back_and_forward_slash_separator)

  foreach(file_path IN LISTS ARGV)
    # protection from removing the current working directory or the root of the current drive (Windows) or the file system (Linux)
    if ("${file_path}" STREQUAL "")
      message(FATAL_ERROR "attemp to implicitly erase the current working directory")
    endif()
    if (is_back_and_forward_slash_separator)
      if ("${file_path}" STREQUAL "/" OR "${file_path}" STREQUAL "\\")
        message(FATAL_ERROR "attemp to erase the root of the current drive")
      endif()
    else()
      if ("${file_path}" STREQUAL "/")
        message(FATAL_ERROR "attemp to erase the root of the file system")
      endif()
    endif()

    # call to previous implementation
    #message("tkl_file_remove_recurse: `${file_path}`")
    _file(REMOVE_RECURSE "${file_path}")
  endforeach()
endfunction()

# Workaround for `file(STRINGS ...)` to bypass the command issues.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/19156 : `Not paired `]` or `[` characters breaks "file(STRINGS"`
#
# CAUTION:
#   The `file(STRINGS` and some other functions has deep sitting issues which prevents to write reliable and consistent parsers:
#   https://gitlab.kitware.com/cmake/cmake/issues/19156 : `Not paired `]` or `[` characters breaks "file(STRINGS"`
#   https://gitlab.kitware.com/cmake/cmake/issues/18946 : `;-escape list implicit unescaping`
#
#   1. To bypass the first issue we have to replace all `[` and `]` characters by a special sequence to enclose single standing characters
#      by respective opposite character in a pair.
#   2. To bypass the issue with line trailing `\` character, we have to replace all `\` characters to a placeholder.
#   3. Each placeholder should contain different characters on both endings to avoid accidental wrong replacement in the decode function.
#
function(tkl_file_encode_strings out_var file_path)
  # CAUTION:
  #   The `file(READ ...)` is instead of `file(STRINGS ...)`, because the first one is broken and
  #   CAN NOT properly handle a trailing `\` character before the line return!
  #
  _file(READ "${file_path}" file_content)

  # WORKAROUND: we have to replace because `file(STRINGS` does a break on not closed `]` or `[` characters
  string(REPLACE "?" "?0" file_content "${file_content}")
  string(REPLACE "[" "?1" file_content "${file_content}") # CAUTION: required for both `file(STRINGS ...)` and `file(READ ...)`
  string(REPLACE "]" "?2" file_content "${file_content}") # CAUTION: required for both `file(STRINGS ...)` and `file(READ ...)`
  string(REPLACE "\\" "?3" file_content "${file_content}")
  string(REPLACE ";" "\;" file_content "${file_content}")
  # to support EOL of all 3 systems: WIN, UNIX and MAC
  string(REPLACE "\n\r" ";" file_content "${file_content}") # WIN
  string(REPLACE "\n" ";" file_content "${file_content}")   # UNIX
  string(REPLACE "\r" ";" file_content "${file_content}")   # MAC

  set(${out_var} "${file_content}" PARENT_SCOPE)
endfunction()

function(tkl_file_decode_string out_var str)
  string(REPLACE "?0" "?" str "${str}")
  string(REPLACE "?1" "[" str "${str}")
  string(REPLACE "?2" "]" str "${str}")
  string(REPLACE "?3" "\\" str "${str}")

  set(${out_var} "${str}" PARENT_SCOPE)
endfunction()

# To avoid escaping for a `file` macro arguments is reimplemented at the end of this file.
#
function(tkl_file_append file_path str)
  _file(APPEND "${file_path}" "${str}" ${ARGN})
endfunction()

# To avoid escaping for a `file` macro arguments is reimplemented at the end of this file.
#
function(tkl_file_write file_path str)
  _file(WRITE "${file_path}" "${str}" ${ARGN})
endfunction()

# To avoid escaping for a `file` macro arguments is reimplemented at the end of this file.
#
function(tkl_file_read out_var file_path)
  _file(READ "${file_path}" file_content ${ARGN})
  set(${out_var} "${file_content}" PARENT_SCOPE)
endfunction()

# To avoid escaping for a `file` macro arguments is reimplemented at the end of this file.
#
function(tkl_file_append_from_file to_file_path from_file_path prefix_str suffix_str)
  tkl_file_read(file_content "${from_file_path}" OFFSET 0)
  if (NOT "${prefix_str}" STREQUAL "")
    _file(APPEND "${to_file_path}" "${prefix_str}")
  endif()
  _file(APPEND "${to_file_path}" "${file_content}")
  if (NOT "${suffix_str}" STREQUAL "")
    _file(APPEND "${to_file_path}" "${suffix_str}")
  endif()
endfunction()

# Workaround for `file(LOCK ...)` to avoid immediate cmake exit in case of usage in the script mode.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/19007
#
function(tkl_file_lock file_path scope_type)
  tkl_get_cmake_role(is_in_script_mode SCRIPT)
  if (NOT is_in_script_mode)
    file(LOCK "${file_path}" GUARD ${scope_type})
  else()
    file(LOCK "${file_path}")
  endif()
endfunction()

# CAUTION:
#   Function must be without arguments to:
#   1. support optional leading arguments like flags beginning by the `-` character
#
# Usage:
#   [<flags>] <out_file_path>
#
# flags:
#   --flock <flock_file>        - file lock to lock write into <out_file_path> file
#
# out_file_path:
#   File path to write in.
#
function(tkl_write_GENERATOR_IS_MULTI_CONFIG_into_file) # WITH OUT ARGUMENTS!
  tkl_make_var_from_ARGV_begin("${ARGN}" argn)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_var_from_ARGV_end(argn)

  list(LENGTH argn argn_len)
  set(argn_index 0)

  unset(flock_file_path)

  # parse flags until no flags
  tkl_parse_function_optional_flags_into_vars(
    argn_index
    argn
    ""
    ""
    ""
    "flock\;.\;flock_file_path")

  if (NOT argn_index LESS argn_len)
    message(FATAL_ERROR "write_GENERATOR_IS_MULTI_CONFIG_into_file function must be called at least with 1 not optional argument: argn_len=`${argn_len}` argn_index=`${argn_index}`")
  endif()

  if (DEFINED flock_file_path)
    get_filename_component(flock_file_path_abs "${flock_file_path}" ABSOLUTE)
    get_filename_component(flock_dir_path "${flock_file_path_abs}" DIRECTORY)
    if (NOT IS_DIRECTORY "${flock_dir_path}")
      message(FATAL_ERROR "--flock argument must be path to a file in existed directory: `${flock_file_path_abs}`")
    endif()
  endif()

  list(GET argn ${argn_index} out_file_path)
  math(EXPR argn_index "${argn_index}+1")

  get_property(GENERATOR_IS_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

  # create create/truncate output files and append values under flock
  if (DEFINED flock_file_path)
    tkl_file_lock("${flock_file_path}" FILE)
  endif()

  tkl_file_write("${out_file_path}" "${GENERATOR_IS_MULTI_CONFIG}")

  if (DEFINED flock_file_path)
    file(LOCK "${flock_file_path}" RELEASE)
    tkl_file_remove("${flock_file_path}")
  endif()
endfunction()

# CAUTION:
#   Should not be overriden before!
#   Exists to bypass issues has introduced here:
#     https://gitlab.kitware.com/cmake/cmake/issues/19274 : `file(REMOVE_RECURSE "")` removes everything from current working directory`
#     https://gitlab.kitware.com/cmake/cmake/issues/19156 : `Not paired `]` or `[` characters breaks "file(STRINGS"`
#   Has to be a function to avoid errors around strings with non standard escape sequences: `Invalid character escape '\0'.`.
#   For the details see the implementation throwed that error:
#     `share/cmake-3.14/Modules/CMakeDetermineCompilerId.cmake`, line:159; around the expression `file(WRITE ... "${ID_CONTENT_OUT}")`.
#
function(file cmd)
  # CAUTION:
  #   Disabled because has used from internals of the cmake:
  #   * REMOVE:         `.../share/cmake-3.14/Modules/Internal/FeatureTesting.cmake:6 (file)` (`file(REMOVE "${CMAKE_BINARY_DIR}/CMakeFiles/feature_tests.bin")`)
  #   * REMOVE_RECURSE: `.../share/cmake-3.14/Modules/CMakeDetermineCompilerId.cmake:167 (file)` (`file(REMOVE_RECURSE ${CMAKE_${lang}_COMPILER_ID_DIR})`)
  #   * STRINGS:        `.../share/cmake-3.14/Modules/CMakeDetermineCompilerId.cmake:575 (file)` (`file(STRINGS ${file}`)
  #

  #if ("${cmd}" STREQUAL "REMOVE")
  #  message(FATAL_ERROR "`file(REMOVE ...)` having issues with the removing, do use `tkl_file_remove` instead")
  #elseif ("${cmd}" STREQUAL "REMOVE_RECURSE")
  #  message(FATAL_ERROR "`file(REMOVE_RECURSE ...)` having issues with the removing, do use `tkl_file_remove_recurse` instead")
  #elseif ("${cmd}" STREQUAL "STRINGS")
  #  message(FATAL_ERROR "`file(STRINGS ...)` having issues with file strings reading, do use `tkl_file_encode_strings`/`tkl_file_decode_string` instead")
  #endif()

  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" . _FC336C71_argn)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_vars_from_ARGV_ARGN_end(. _FC336C71_argn)

  tkl_escape_list_expansion(_FC336C71_cmdline "${_FC336C71_argn}")

  tkl_track_vars_begin()

  # call to previous implementation
  _file(${cmd} ${_FC336C71_cmdline})

  tkl_forward_changed_vars_to_parent_scope()
  tkl_track_vars_end()
endfunction()

tkl_register_implementation(function file)

endif()
