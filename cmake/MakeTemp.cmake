cmake_minimum_required(VERSION 3.6)

# at least cmake 3.6 is required for:
#   * specific `%s` format specifier in the `string(TIMESTAMP ...)`: https://cmake.org/cmake/help/v3.6/command/string.html#timestamp
#

function(MakeTempDir dir_name_prefix dir_random_name_suffix_len out_var)
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

  #string(TIMESTAMP timestamp_utc "%s" UTC)
  string(RANDOM LENGTH ${dir_random_name_suffix_len} random_suffix)

  if (dir_name_prefix)
    set(temp_dir_name "${dir_name_prefix}${random_suffix}")
  else()
    set(temp_dir_name "CMake.${random_suffix}")
  endif()

  set(temp_dir_path "${temp_base_dir}/${temp_dir_name}")

  get_filename_component(temp_dir_path_abs "${temp_dir_path}" REALPATH)

  file(MAKE_DIRECTORY "${temp_dir_path_abs}")

  set(${out_var} "${temp_dir_path_abs}" PARENT_SCOPE)
endfunction()
