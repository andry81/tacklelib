cmake_minimum_required(VERSION 3.6)

# at least cmake 3.6 is required for:
#   * specific `%s` format specifier in the `string(TIMESTAMP ...)`: https://cmake.org/cmake/help/v3.6/command/string.html#timestamp
#

set(MAKETEMPDIR_LAST_TIMESTAMP "")
set(MAKETEMPDIR_LAST_TIMESTAMP_INDEX 0) # additional suffix to the time limited by resolution in seconds

function(MakeTempDir dir_name_prefix time_fmt proc_index dir_random_name_suffix_len out_var)
  set(temp_base_dir "")
  if (DEFINED ENV{TMP} AND IS_DIRECTORY "$ENV{TMP}")
    set(temp_base_dir "$ENV{TMP}")
  endif()
  if (NOT temp_base_dir AND DEFINED ENV{TMPDIR} AND IS_DIRECTORY "$ENV{TMPDIR}")
    set(temp_base_dir "$ENV{TMPDIR}")
  endif()
  if (NOT temp_base_dir AND DEFINED ENV{TEMP} AND IS_DIRECTORY "$ENV{TEMP}")
    set(temp_base_dir "$ENV{TEMP}")
  endif()

  if (NOT temp_base_dir)
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

  if (NOT temp_base_dir)
    message(FATAL_ERROR "temporary directory is nor reachable")
  endif()

  string(RANDOM LENGTH ${dir_random_name_suffix_len} random_suffix)

  if (time_fmt)
    string(TIMESTAMP timestamp_utc "${time_fmt}" UTC)
    if (MAKETEMPDIR_LAST_TIMESTAMP)
      if (MAKETEMPDIR_LAST_TIMESTAMP STREQUAL timestamp_utc)
        math(EXPR MAKETEMPDIR_LAST_TIMESTAMP_INDEX "${MAKETEMPDIR_LAST_TIMESTAMP_INDEX}+1")
      else()
        set(MAKETEMPDIR_LAST_TIMESTAMP_INDEX 0)
        set(MAKETEMPDIR_LAST_TIMESTAMP "${timestamp_utc}" PARENT_SCOPE)
      endif()
      set(MAKETEMPDIR_LAST_TIMESTAMP_INDEX "${MAKETEMPDIR_LAST_TIMESTAMP_INDEX}" PARENT_SCOPE)
    endif()
    set(MAKETEMPDIR_LAST_TIMESTAMP "${timestamp_utc}" PARENT_SCOPE)

    set(timestamp_index_token ${MAKETEMPDIR_LAST_TIMESTAMP_INDEX})
    string(LENGTH "${timestamp_index_token}" timestamp_index_token_len)
    if (timestamp_index_token_len EQUAL 1)
      set(timestamp_index_token "0${timestamp_index_token}")
    endif()
  else()
    set(timestamp_utc "")
  endif()

  if (timestamp_utc)
    if (NOT proc_index STREQUAL "")
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

  set(${out_var} "${temp_dir_path_abs}" PARENT_SCOPE)
endfunction()
