# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_MAKE_TEMP_INCLUDE_DEFINED)
set(TACKLELIB_MAKE_TEMP_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.6)

include(tacklelib/Props)

# at least cmake 3.6 is required for:
#   * specific `%s` format specifier in the `string(TIMESTAMP ...)`: https://cmake.org/cmake/help/v3.6/command/string.html#timestamp
#

function(tkl_make_temp_dir out_var dir_name_prefix time_fmt proc_index dir_random_name_suffix_len)
  set(temp_base_dir "")
  if (DEFINED ENV{TMP} AND IS_DIRECTORY "$ENV{TMP}")
    set(temp_base_dir "$ENV{TMP}")
  elseif (DEFINED ENV{TMPDIR} AND IS_DIRECTORY "$ENV{TMPDIR}")
    set(temp_base_dir "$ENV{TMPDIR}")
  elseif (DEFINED ENV{TEMP} AND IS_DIRECTORY "$ENV{TEMP}")
    set(temp_base_dir "$ENV{TEMP}")
  endif()

  if ("${temp_base_dir}" STREQUAL "")
    if (WIN32)
      if (DEFINED ENV{LOCALAPPDATA} AND IS_DIRECTORY "$ENV{LOCALAPPDATA}/Temp")
        set(temp_base_dir "$ENV{LOCALAPPDATA}/Temp")
      endif()
    elseif (UNIX)
      if (IS_DIRECTORY "/tmp")
        set(temp_base_dir "/tmp")
      endif()
    endif()
  endif()

  if ("${temp_base_dir}" STREQUAL "")
    message(FATAL_ERROR "temporary directory is not reachable")
  endif()

  string(RANDOM LENGTH ${dir_random_name_suffix_len} random_suffix)

  if (time_fmt)
    tkl_get_global_prop(TACKLELIB_TEMP_DIR_LAST_TIMESTAMP "tkl::temp_dir::last_timestamp" 1)
    tkl_get_global_prop(TACKLELIB_TEMP_DIR_LAST_TIMESTAMP_INDEX "tkl::temp_dir::last_timestamp_index" 1)

    string(TIMESTAMP timestamp_utc "${time_fmt}" UTC)
    if ("${TACKLELIB_TEMP_DIR_LAST_TIMESTAMP}" STREQUAL "${timestamp_utc}")
      math(EXPR TACKLELIB_TEMP_DIR_LAST_TIMESTAMP_INDEX ${TACKLELIB_TEMP_DIR_LAST_TIMESTAMP_INDEX}+1)
    else()
      set(TACKLELIB_TEMP_DIR_LAST_TIMESTAMP "${timestamp_utc}")
      set(TACKLELIB_TEMP_DIR_LAST_TIMESTAMP_INDEX 0)
    endif()

    set_property(GLOBAL PROPERTY "tkl::temp_dir::last_timestamp" "${TACKLELIB_TEMP_DIR_LAST_TIMESTAMP}")
    set_property(GLOBAL PROPERTY "tkl::temp_dir::last_timestamp_index" "${TACKLELIB_TEMP_DIR_LAST_TIMESTAMP_INDEX}")

    set(timestamp_index_token ${TACKLELIB_TEMP_DIR_LAST_TIMESTAMP_INDEX})
    string(LENGTH "${timestamp_index_token}" timestamp_index_token_len)
    if (timestamp_index_token_len EQUAL 1)
      set(timestamp_index_token "0${timestamp_index_token}")
    endif()
  else()
    set(timestamp_utc "")
  endif()

  if (timestamp_utc)
    if (NOT "${proc_index}" STREQUAL "")
      # MakeTempDir calls in multiple cmake processes
      set(proc_index_token "${proc_index}")
      string(LENGTH "${proc_index_token}" proc_index_token_len)
      if (proc_index_token_len EQUAL 1)
        set(proc_index_token "0${proc_index_token}")
      endif()
      set(dir_name_suffix "${timestamp_utc}''${proc_index_token}''${timestamp_index_token}.${random_suffix}")
    else()
      set(dir_name_suffix "${timestamp_utc}''${timestamp_index_token}.${random_suffix}")
    endif()
  else()
    set(dir_name_suffix "${random_suffix}")
  endif()

  if (dir_name_prefix)
    set(temp_dir_name "${dir_name_prefix}${dir_name_suffix}")
  else()
    set(temp_dir_name "CMake.${dir_name_suffix}")
  endif()

  set(temp_dir_path "${temp_base_dir}/${temp_dir_name}")

  get_filename_component(temp_dir_path_abs "${temp_dir_path}" REALPATH)

  file(MAKE_DIRECTORY "${temp_dir_path_abs}")
  #message("tkl_make_temp_dir: `${temp_dir_path_abs}`")

  set(${out_var} "${temp_dir_path_abs}" PARENT_SCOPE)
endfunction()

function(tkl_make_basic_timestamp_temp_dir out_var dir_name_prefix dir_random_name_suffix_len)
  # first time the call handler generation from a function
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTPROC_INDEX "tkl::testlib::testproc::index" 1)

  if (NOT "${TACKLELIB_TESTLIB_TESTPROC_INDEX}" STREQUAL "")
    # running under TestLib, the macro can call under different cmake processe when the inner timestamp is not yet changed (timestamp has seconds resolution)
    tkl_make_temp_dir(temp_dir_path "${dir_name_prefix}." "%Y'%m'%d''%H'%M'%SZ" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}" ${dir_random_name_suffix_len})
  else()
    tkl_make_temp_dir(temp_dir_path "${dir_name_prefix}." "%Y'%m'%d''%H'%M'%SZ" "" ${dir_random_name_suffix_len})
  endif()

  set(${out_var} "${temp_dir_path}" PARENT_SCOPE)
endfunction()

endif()
