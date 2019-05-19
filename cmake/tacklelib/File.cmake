# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_FILE_INCLUDE_DEFINED)
set(TACKLELIB_FILE_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.7)

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# at least cmake 3.3 is required for:
# * to use IN_LIST in if command: (https://cmake.org/cmake/help/v3.3/command/if.html )
#   `if(<variable|string> IN_LIST <variable>)`
#

# returns "." if paths are equal
function(tkl_subtract_absolute_paths from_path to_path var_out)
  string(TOLOWER "${from_path}" from_path_lower)
  string(TOLOWER "${to_path}" to_path_lower)

  if (NOT from_path_lower STREQUAL "")
    if (${to_path_lower} STREQUAL ${from_path_lower})
      set(${var_out} "." PARENT_SCOPE)
      return()
    else()
      file(RELATIVE_PATH rel_path ${to_path_lower} ${from_path_lower})
      if (DEFINED rel_path)
        string(SUBSTRING "${rel_path}" 0 2 rel_path_first_component)
        if(NOT rel_path_first_component STREQUAL ".." AND NOT rel_path STREQUAL from_path_lower)
          set(${var_out} ${rel_path} PARENT_SCOPE)
          return()
        endif()
      endif()
    endif()
  endif()

  set(${var_out} "" PARENT_SCOPE)
endfunction()

# Workaround for `file(LOCK ...)` to avoid immediate cmake exit in case of usage in the script mode.
# For details: https://gitlab.kitware.com/cmake/cmake/issues/19007
#
function(tkl_file_lock file_path scope_type)
  tkl_get_cmake_role(SCRIPT is_in_script_mode)
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
function(write_GENERATOR_IS_MULTI_CONFIG_into_file) # WITH OUT ARGUMENTS!
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" "" argn)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_vars_from_ARGV_ARGN_end("" argn)

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
    message(FATAL_ERROR "write_GENERATOR_IS_MULTI_CONFIG_into_file function must be called at least with 1 not optional argument: argn_len=${argn_len} argn_index=${argn_index}")
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

  file(WRITE "${out_file_path}" "${GENERATOR_IS_MULTI_CONFIG}")

  if (DEFINED flock_file_path)
    file(LOCK "${flock_file_path}" RELEASE)
    file(REMOVE "${flock_file_path}")
  endif()
endfunction()

endif()
