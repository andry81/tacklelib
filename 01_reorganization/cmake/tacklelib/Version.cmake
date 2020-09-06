# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_VERSION_INCLUDE_DEFINED)
set(TACKLELIB_VERSION_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.7)

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# https://en.wikipedia.org/wiki/Microsoft_Visual_C
#
# MSC    1.0   _MSC_VER == 100
# MSC    2.0   _MSC_VER == 200
# MSC    3.0   _MSC_VER == 300
# MSC    4.0   _MSC_VER == 400
# MSC    5.0   _MSC_VER == 500
# MSC    6.0   _MSC_VER == 600
# MSC    7.0   _MSC_VER == 700
# MSVC++ 1.0   _MSC_VER == 800
# MSVC++ 2.0   _MSC_VER == 900
# MSVC++ 4.0   _MSC_VER == 1000 (Developer Studio 4.0)
# MSVC++ 4.2   _MSC_VER == 1020 (Developer Studio 4.2)
# MSVC++ 5.0   _MSC_VER == 1100 (Visual Studio 97 version 5.0)
# MSVC++ 6.0   _MSC_VER == 1200 (Visual Studio 6.0 version 6.0)
# MSVC++ 7.0   _MSC_VER == 1300 (Visual Studio .NET 2002 version 7.0)
# MSVC++ 7.1   _MSC_VER == 1310 (Visual Studio .NET 2003 version 7.1)
# MSVC++ 8.0   _MSC_VER == 1400 (Visual Studio 2005 version 8.0)
# MSVC++ 9.0   _MSC_VER == 1500 (Visual Studio 2008 version 9.0)
# MSVC++ 10.0  _MSC_VER == 1600 (Visual Studio 2010 version 10.0)
# MSVC++ 11.0  _MSC_VER == 1700 (Visual Studio 2012 version 11.0)
# MSVC++ 12.0  _MSC_VER == 1800 (Visual Studio 2013 version 12.0)
# MSVC++ 14.0  _MSC_VER == 1900 (Visual Studio 2015 version 14.0)
# MSVC++ 14.1  _MSC_VER == 1910 (Visual Studio 2017 version 15.0)
# MSVC++ 14.11 _MSC_VER == 1911 (Visual Studio 2017 version 15.3)
# MSVC++ 14.12 _MSC_VER == 1912 (Visual Studio 2017 version 15.5)
# MSVC++ 14.13 _MSC_VER == 1913 (Visual Studio 2017 version 15.6)
# MSVC++ 14.14 _MSC_VER == 1914 (Visual Studio 2017 version 15.7)
# MSVC++ 14.15 _MSC_VER == 1915 (Visual Studio 2017 version 15.8)
# MSVC++ 14.16 _MSC_VER == 1916 (Visual Studio 2017 version 15.9)
# MSVC++ 14.2  _MSC_VER == 1920 (Visual Studio 2019 Version 16.0)
# MSVC++ 14.21 _MSC_VER == 1921 (Visual Studio 2019 Version 16.1)
# MSVC++ 14.22 _MSC_VER == 1922 (Visual Studio 2019 Version 16.2)
# MSVC++ 14.23 _MSC_VER == 1923 (Visual Studio 2019 Version 16.3)
# MSVC++ 14.24 _MSC_VER == 1924 (Visual Studio 2019 Version 16.4)
#
# https://cmake.org/cmake/help/latest/variable/MSVC_VERSION.html
#
# 1200      = VS  6.0
# 1300      = VS  7.0
# 1310      = VS  7.1
# 1400      = VS  8.0 (v80 toolset)
# 1500      = VS  9.0 (v90 toolset)
# 1600      = VS 10.0 (v100 toolset)
# 1700      = VS 11.0 (v110 toolset)
# 1800      = VS 12.0 (v120 toolset)
# 1900      = VS 14.0 (v140 toolset)
# 1910-1919 = VS 15.0 (v141 toolset)
# 1920-1929 = VS 16.0 (v142 toolset)

function(tkl_get_msvc_version_year major_ver minor_ver var_year_out)
  if (major_ver EQUAL 14)
    if (minor_ver GREATER_EQUAL 20 OR minor_ver EQUAL 2)
      set(${var_year_out} 2019 PARENT_SCOPE)
    elif (minor_ver GREATER_EQUAL 10 OR minor_ver EQUAL 1)
      set(${var_year_out} 2017 PARENT_SCOPE)
    elif (minor_ver EQUAL 0)
      set(${var_year_out} 2015 PARENT_SCOPE)
    else()
      message(FATAL_ERROR "MSVC version is unknown: `${major_ver}.${minor_ver}`")
    endif()
  elseif (major_ver EQUAL 13)
    set(${var_year_out} 2014 PARENT_SCOPE)
  elseif (major_ver EQUAL 12)
    set(${var_year_out} 2013 PARENT_SCOPE)
  elseif (major_ver EQUAL 11)
    set(${var_year_out} 2012 PARENT_SCOPE)
  elseif (major_ver EQUAL 10)
    set(${var_year_out} 2010 PARENT_SCOPE)
  elseif (major_ver EQUAL 9)
    set(${var_year_out} 2008 PARENT_SCOPE)
  elseif (major_ver EQUAL 8)
    set(${var_year_out} 2005 PARENT_SCOPE)
  else()
    message(FATAL_ERROR "MSVC version is deprecated: `${major_ver}.${minor_ver}`")
  endif()
endfunction()

function(tkl_get_msvc_version var_major_out var_minor_out)
  if (NOT MSVC)
    message(FATAL_ERROR "MSVC compiler is not detected to request a version")
  endif()

  if (NOT MSVC_VERSION MATCHES "([0-9]+)")
    message(FATAL_ERROR "MSVC_VERSION format is unknown: `${MSVC_VERSION}`")
  endif()

  string(SUBSTRING "${CMAKE_MATCH_1}" 0 2 major_msc_version)
  if (major_msc_version GREATER 19)
    message(FATAL_ERROR "MSVC version is not supported: `${MSVC_VERSION}`")
  elseif (major_msc_version EQUAL 19)
    set(major_version 14)
    string(SUBSTRING "${CMAKE_MATCH_0}" 2 2 minor_version)
    string(REGEX REPLACE "0*([1-9][0-9]*)" "\\1" minor_version "${minor_version}")
    if ("${minor_version}" STREQUAL "")
      set(minor_version 0)
    endif()
  elseif (major_msc_version EQUAL 18)
    set(major_version 12)
    set(minor_version 0)
  elseif (major_msc_version EQUAL 17)
    set(major_version 11)
    set(minor_version 0)
  elseif (major_msc_version EQUAL 16)
    set(major_version 10)
    set(minor_version 0)
  elseif (major_msc_version EQUAL 15)
    set(major_version 9)
    set(minor_version 0)
  elseif (major_msc_version EQUAL 14)
    set(major_version 8)
    set(minor_version 0)
  else()
    message(FATAL_ERROR "MSVC version is deprecated: `${MSVC_VERSION}`")
  endif()

  set(${var_major_out} "${major_version}" PARENT_SCOPE)
  set(${var_minor_out} "${minor_version}" PARENT_SCOPE)
endfunction()

function(tkl_get_gcc_version var_major_out var_minor_out)
  if (NOT GCC)
    message(FATAL_ERROR "GCC compiler is not detected to request a version")
  endif()

  if (NOT CMAKE_CXX_COMPILER_VERSION MATCHES "([0-9]+)\\.?([0-9]+)?" AND
      NOT CMAKE_C_COMPILER_VERSION MATCHES "([0-9]+)\\.?([0-9]+)?")
    message(FATAL_ERROR "CMAKE_CXX_COMPILER_VERSION/CMAKE_C_COMPILER_VERSION format(s) is unknown: `${CMAKE_CXX_COMPILER_VERSION}`/`${CMAKE_C_COMPILER_VERSION}`")
  endif()

  set(major_version "${CMAKE_MATCH_1}")

  string(STRIP "${CMAKE_MATCH_2}" minor_version)
  string(REGEX REPLACE "0*([1-9][0-9]*)" "\\1" minor_version "${minor_version}")
  if ("${minor_version}" STREQUAL "")
    set(minor_version 0)
  endif()

  set(${var_major_out} "${major_version}" PARENT_SCOPE)
  set(${var_minor_out} "${minor_version}" PARENT_SCOPE)
endfunction()

function(tkl_get_clang_version var_major_out var_minor_out)
  if (NOT CLANG)
    message(FATAL_ERROR "CLANG compiler is not detected to request a version")
  endif()

  if (NOT CMAKE_CXX_COMPILER_VERSION MATCHES "([0-9]+)\\.?([0-9]+)?" AND
      NOT CMAKE_C_COMPILER_VERSION MATCHES "([0-9]+)\\.?([0-9]+)?")
    message(FATAL_ERROR "CMAKE_CXX_COMPILER_VERSION/CMAKE_C_COMPILER_VERSION format(s) is unknown: `${CMAKE_CXX_COMPILER_VERSION}`/`${CMAKE_C_COMPILER_VERSION}`")
  endif()

  set(major_version "${CMAKE_MATCH_1}")

  string(STRIP "${CMAKE_MATCH_2}" minor_version)
  string(REGEX REPLACE "0*([1-9][0-9]*)" "\\1" minor_version "${minor_version}")
  if ("${minor_version}" STREQUAL "")
    set(minor_version 0)
  endif()

  set(${var_major_out} "${major_version}" PARENT_SCOPE)
  set(${var_minor_out} "${minor_version}" PARENT_SCOPE)
endfunction()

function(tkl_get_msvc_version_token var_token_out)
  tkl_get_msvc_version(msvc_major_ver msvc_minor_ver)
  set(${var_token_out} "MSVC${msvc_major_ver}.${msvc_minor_ver}" PARENT_SCOPE)
endfunction()

function(tkl_get_gcc_version_token var_token_out)
  tkl_get_gcc_version(msvc_major_ver msvc_minor_ver)
  set(${var_token_out} "GCC${msvc_major_ver}.${msvc_minor_ver}" PARENT_SCOPE)
endfunction()

function(tkl_get_clang_version_token var_token_out)
  tkl_get_clang_version(msvc_major_ver msvc_minor_ver)
  set(${var_token_out} "CLANG${msvc_major_ver}.${msvc_minor_ver}" PARENT_SCOPE)
endfunction()

# DESCRIPTION:
#   `14.1*` equals to `14.1` or `14.16`, but not to `14.2`
#   `14.1+` equals to `14.1` and higher like `14.999` or `15.0`
#
function(tkl_compare_compiler_tokens compiler_token op compiler_token_to_filter out_var)
  string(TOUPPER "${compiler_token}" compiler_token_upper)
  string(TOUPPER "${compiler_token_to_filter}" compiler_token_to_filter_upper)

  #message("  ${compiler_token_upper} ${op} ${compiler_token_to_filter_upper}")

  if (NOT compiler_token_upper MATCHES "([_A-Z]+)(0*)([1-9][0-9]*)?\\.?(0*)([1-9][0-9]*)?")
    message(FATAL_ERROR "format of comiler token is unknown: `${compiler_token_upper}`")
  endif()

  #message("  = ${CMAKE_MATCH_1} ${CMAKE_MATCH_2} ${CMAKE_MATCH_3} ${CMAKE_MATCH_4} ${CMAKE_MATCH_5}")

  set(compiler_token_name "${CMAKE_MATCH_1}")
  set(compiler_token_major_version "${CMAKE_MATCH_3}")
  if ("${compiler_token_major_version}" STREQUAL "" AND NOT "${CMAKE_MATCH_2}" STREQUAL "")
    set(compiler_token_major_version 0)
  endif()
  set(compiler_token_minor_version "${CMAKE_MATCH_5}")
  if ("${compiler_token_minor_version}" STREQUAL "" AND NOT "${CMAKE_MATCH_4}" STREQUAL "")
    set(compiler_token_minor_version 0)
  endif()

  if ("${compiler_token_major_version}" STREQUAL "" AND NOT "${compiler_token_minor_version}" STREQUAL "")
    message(FATAL_ERROR "the major version must be not empty if the minor version is not empty: `${compiler_token_upper}`")
  endif()

  if (NOT compiler_token_to_filter_upper MATCHES "([_A-Z]+)(0*)([1-9][0-9]*[*+]?)?\\.?(0*)([1-9][0-9]*[*+]?)?")
    message(FATAL_ERROR "format of compiler token to filter is unknown: `${compiler_token_to_filter_upper}`")
  endif()

  #message("  = ${CMAKE_MATCH_1} ${CMAKE_MATCH_2} ${CMAKE_MATCH_3} ${CMAKE_MATCH_4} ${CMAKE_MATCH_5}")

  set(compiler_token_to_filter_name "${CMAKE_MATCH_1}")
  set(compiler_token_to_filter_major_version "${CMAKE_MATCH_3}")
  if ("${compiler_token_to_filter_major_version}" STREQUAL "" AND NOT "${CMAKE_MATCH_2}" STREQUAL "")
    set(compiler_token_to_filter_major_version 0)
  endif()
  set(compiler_token_to_filter_minor_version "${CMAKE_MATCH_5}")
  if ("${compiler_token_to_filter_minor_version}" STREQUAL "" AND NOT "${CMAKE_MATCH_4}" STREQUAL "")
    set(compiler_token_to_filter_minor_version 0)
  endif()

  if ("${compiler_token_to_filter_major_version}" STREQUAL "" AND NOT "${compiler_token_to_filter_minor_version}" STREQUAL "")
    message(FATAL_ERROR "the major version must be not empty if the minor version is not empty: `${compiler_token_to_filter_upper}`")
  endif()

  # specific cases
  if (compiler_token_major_version MATCHES "([^*+]+)[*+]")
    message(FATAL_ERROR "only the second argument can contain the pattern matching characters: `${compiler_token_upper}`")
  endif()
  if (compiler_token_minor_version MATCHES "([^*+]+)[*+]")
    message(FATAL_ERROR "only the second argument can contain the pattern matching characters: `${compiler_token_upper}`")
  endif()
  if ("${compiler_token_to_filter_major_version}" STREQUAL "" AND NOT "${compiler_token_to_filter_minor_version}" STREQUAL "")
    message(FATAL_ERROR "the major version filter must not be empty if the minor version filter is not empty: `${compiler_token_to_filter}`")
  endif()

  if (compiler_token_to_filter_major_version MATCHES "([^*+]+)([*+])")
    set (compiler_token_to_filter_major_version "${CMAKE_MATCH_1}")

    # uses additionally as `not empty` flags
    set (compiler_token_to_filter_major_version_and_higher 1)
    set (compiler_token_to_filter_minor_version_and_higher 0)

    if (NOT "${compiler_token_to_filter_minor_version}" STREQUAL "")
      message(FATAL_ERROR "the minor version filter must be empty if the major version filter is using the pattern matching: `${compiler_token_to_filter}`")
    endif()

    if ("${CMAKE_MATCH_2}" STREQUAL "+")
      set (compiler_token_to_filter_major_version_greater_or_equal 1) # the `>=` operator should be used instead of the `=`
    else()
      set (compiler_token_to_filter_major_version_greater_or_equal 0)
    endif()
  else()
    # uses additionally as `not empty` flag
    set (compiler_token_to_filter_major_version_and_higher 0)

    if (compiler_token_to_filter_minor_version MATCHES "([^*+]+)([*+])")
      set (compiler_token_to_filter_minor_version "${CMAKE_MATCH_1}")
      set (compiler_token_to_filter_minor_version_and_higher 1) # uses additionally as `not empty` flag
      if ("${CMAKE_MATCH_2}" STREQUAL "+")
        set (compiler_token_to_filter_minor_version_greater_or_equal 1) # the `>=` operator should be used instead of the `=`
      else()
        set (compiler_token_to_filter_minor_version_greater_or_equal 0)
        if ("${CMAKE_MATCH_2}" STREQUAL "*")
          if (compiler_token_to_filter_minor_version EQUAL 0)
            message(FATAL_ERROR "the minor version filter must be greater than 0 if uses partial pattern matching: `${compiler_token_to_filter}`")
          endif()
        endif()
      endif()
    else()
      set (compiler_token_to_filter_minor_version_and_higher 0)
    endif()
  endif()

  if ("${compiler_token_name}" STREQUAL "${compiler_token_to_filter_name}")
    if (("${compiler_token_major_version}" STREQUAL "" AND NOT "${compiler_token_to_filter_major_version}" STREQUAL "") OR
        ("${compiler_token_minor_version}" STREQUAL "" AND NOT "${compiler_token_to_filter_minor_version}" STREQUAL ""))
      set(${out_var} 0 PARENT_SCOPE)
    else()
      # specific cases
      if (NOT "${compiler_token_major_version}" STREQUAL "" AND NOT "${compiler_token_minor_version}" STREQUAL "")
        if (compiler_token_major_version EQUAL 14)
          if (compiler_token_minor_version GREATER 0 AND compiler_token_minor_version LESS 10)
            set(compiler_token_minor_version ${compiler_token_minor_version}0)
          endif()
        endif()
      endif()
      if (NOT compiler_token_to_filter_major_version_and_higher AND NOT compiler_token_to_filter_minor_version_and_higher)
        if (NOT "${compiler_token_to_filter_major_version}" STREQUAL "" AND NOT "${compiler_token_to_filter_minor_version}" STREQUAL "")
          if (compiler_token_to_filter_major_version EQUAL 14)
            if (compiler_token_to_filter_minor_version GREATER 0 AND compiler_token_to_filter_minor_version LESS 10)
              set(compiler_token_to_filter_minor_version ${compiler_token_to_filter_minor_version}0)
            endif()
          endif()
        endif()
      endif()

      # Change the `=` operator to the `>=` operator instead in case of the `+` version suffix.
      # The `*` suffix still must check on string prefix (limited range) instead of the `+` which stands for the true `equal or higher` operator.
      if ("${op}" STREQUAL "=")
        if (compiler_token_to_filter_major_version_greater_or_equal OR compiler_token_to_filter_minor_version_greater_or_equal)
          set(op ">=")
        endif()
      endif()

      #message("    ${compiler_token_name} ${compiler_token_major_version} ${compiler_token_minor_version}  ${op}")
      #message("      ${compiler_token_to_filter_name} ${compiler_token_to_filter_major_version} ${compiler_token_to_filter_minor_version} ${compiler_token_to_filter_major_version_and_higher} ${compiler_token_to_filter_minor_version_and_higher}")

      if ("${op}" STREQUAL "=")
        if (NOT compiler_token_to_filter_major_version_and_higher AND NOT compiler_token_to_filter_minor_version_and_higher)
          if ((("${compiler_token_major_version}" STREQUAL "") OR ("${compiler_token_to_filter_major_version}" STREQUAL "") OR (compiler_token_major_version EQUAL compiler_token_to_filter_major_version)) AND
              (("${compiler_token_minor_version}" STREQUAL "") OR ("${compiler_token_to_filter_minor_version}" STREQUAL "") OR (compiler_token_minor_version EQUAL compiler_token_to_filter_minor_version)))
            set(${out_var} 1 PARENT_SCOPE)
          else()
            set(${out_var} 0 PARENT_SCOPE)
          endif()
        else()
          set (is_filter_str_prefix 0)
          if (compiler_token_to_filter_major_version_and_higher)
            tkl_string_begins_with("${compiler_token_major_version}" "${compiler_token_to_filter_major_version}" is_filter_str_prefix)
          else()
            if (("${compiler_token_major_version}" STREQUAL "") OR ("${compiler_token_to_filter_major_version}" STREQUAL "") OR (compiler_token_major_version EQUAL compiler_token_to_filter_major_version))
              tkl_string_begins_with("${compiler_token_minor_version}" "${compiler_token_to_filter_minor_version}" is_filter_str_prefix)
            endif()
          endif()
          set(${out_var} ${is_filter_str_prefix} PARENT_SCOPE)
        endif()
      elseif ("${op}" STREQUAL ">=")
        if (NOT compiler_token_to_filter_major_version_and_higher AND NOT compiler_token_to_filter_minor_version_and_higher)
          if ((("${compiler_token_major_version}" STREQUAL "") OR ("${compiler_token_to_filter_major_version}" STREQUAL "") OR (compiler_token_major_version GREATER compiler_token_to_filter_major_version)) OR
              ((("${compiler_token_major_version}" STREQUAL "") OR ("${compiler_token_to_filter_major_version}" STREQUAL "") OR (compiler_token_major_version EQUAL compiler_token_to_filter_major_version)) AND
              (("${compiler_token_minor_version}" STREQUAL "") OR ("${compiler_token_to_filter_minor_version}" STREQUAL "") OR (compiler_token_minor_version GREATER_EQUAL compiler_token_to_filter_minor_version))))
            set(${out_var} 1 PARENT_SCOPE)
          else()
            set(${out_var} 0 PARENT_SCOPE)
          endif()
        else()
          set (is_filter_str_prefix 0)
          if (compiler_token_to_filter_major_version_and_higher)
            tkl_string_begins_with("${compiler_token_major_version}" "${compiler_token_to_filter_major_version}" is_filter_str_prefix)
          else()
            if (("${compiler_token_major_version}" STREQUAL "") OR ("${compiler_token_to_filter_major_version}" STREQUAL "") OR (compiler_token_major_version GREATER compiler_token_to_filter_major_version))
              set (is_filter_str_prefix 1)
            elseif (("${compiler_token_major_version}" STREQUAL "") OR ("${compiler_token_to_filter_major_version}" STREQUAL "") OR (compiler_token_major_version EQUAL compiler_token_to_filter_major_version))
              tkl_string_begins_with("${compiler_token_minor_version}" "${compiler_token_to_filter_minor_version}" is_filter_str_prefix)
            endif()
          endif()
          set(${out_var} ${is_filter_str_prefix} PARENT_SCOPE)
        endif()
      elseif ("${op}" STREQUAL "<")
        if (NOT compiler_token_to_filter_major_version_and_higher AND NOT compiler_token_to_filter_minor_version_and_higher)
          if ((("${compiler_token_major_version}" STREQUAL "") OR ("${compiler_token_to_filter_major_version}" STREQUAL "") OR (compiler_token_major_version LESS compiler_token_to_filter_major_version)) OR
              ((("${compiler_token_major_version}" STREQUAL "") OR ("${compiler_token_to_filter_major_version}" STREQUAL "") OR (compiler_token_major_version EQUAL compiler_token_to_filter_major_version)) AND
            (("${compiler_token_minor_version}" STREQUAL "") OR ("${compiler_token_to_filter_minor_version}" STREQUAL "") OR (compiler_token_minor_version LESS compiler_token_to_filter_minor_version))))
            set(${out_var} 1 PARENT_SCOPE)
          else()
            set(${out_var} 0 PARENT_SCOPE)
          endif()
        else()
          set (is_filter_str_prefix 0)
          if (compiler_token_to_filter_major_version_and_higher)
            tkl_string_begins_with("${compiler_token_major_version}" "${compiler_token_to_filter_major_version}" is_filter_str_prefix)
          else()
            if (("${compiler_token_major_version}" STREQUAL "") OR ("${compiler_token_to_filter_major_version}" STREQUAL "") OR (compiler_token_major_version LESS compiler_token_to_filter_major_version))
              set (is_filter_str_prefix 1)
            elseif (("${compiler_token_major_version}" STREQUAL "") OR ("${compiler_token_to_filter_major_version}" STREQUAL "") OR (compiler_token_major_version EQUAL compiler_token_to_filter_major_version))
              tkl_string_begins_with("${compiler_token_minor_version}" "${compiler_token_to_filter_minor_version}" is_filter_str_prefix)
            endif()
          endif()
          # invert
          if (is_filter_str_prefix)
            set(${out_var} 0 PARENT_SCOPE)
          else()
            set(${out_var} 1 PARENT_SCOPE)
          endif()
        endif()
      else()
        message(FATAL_ERROR "only lminited set of operators is supported: `=`, `>=`, `<`: `${op}`")
      endif()
    endif()
  else()
    set(${out_var} 0 PARENT_SCOPE)
  endif()
endfunction()

endif()
