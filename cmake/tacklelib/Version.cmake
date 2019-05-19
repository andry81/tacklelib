# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_VERSION_INCLUDE_DEFINED)
set(TACKELIB_VERSION_INCLUDE_DEFINED 1)

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
    string(SUBSTRING "${CMAKE_MATCH_0}" 2 2 minor_msc_version)
    string(REGEX REPLACE "0*([1-9][0-9]*)" "\\1" minor_msc_version "${minor_msc_version}")
    if (minor_msc_version STREQUAL "")
      set(minor_msc_version 0)
    endif()
    if (minor_msc_version GREATER_EQUAL 11)
      set(minor_version ${minor_msc_version})
    elseif (minor_msc_version)
      set(minor_version 1)
    else()
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
    message(FATAL_ERROR "MSVC version is not supported: `${MSVC_VERSION}`")
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
  if (minor_version STREQUAL "")
    set(minor_version 0)
  endif()

  set(var_major_out "${major_version}" PARENT_SCOPE)
  set(var_minor_out "${minor_version}" PARENT_SCOPE)
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
  if (minor_version STREQUAL "")
    set(minor_version 0)
  endif()

  set(var_major_out "${major_version}" PARENT_SCOPE)
  set(var_minor_out "${minor_version}" PARENT_SCOPE)
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

function(tkl_compare_compiler_tokens compiler_token compiler_token_to_filter var_out)
  string(TOUPPER "${compiler_token}" compiler_token_upper)
  string(TOUPPER "${compiler_token_to_filter}" compiler_token_to_filter_upper)

  if (NOT compiler_token_upper MATCHES "([_A-Z]+)([0-9]+)?\\.?([0-9]+)?")
    message(FATAL_ERROR "format of comiler token is unknown: `${compiler_token_upper}`")
  endif()

  set(compiler_token_name "${CMAKE_MATCH_1}")
  set(compiler_token_major_version "${CMAKE_MATCH_2}")
  set(compiler_token_minor_version "${CMAKE_MATCH_3}")

  if (NOT compiler_token_to_filter_upper MATCHES "([_A-Z]+)([0-9]+)?\\.?([0-9]+)?")
    message(FATAL_ERROR "format of compiler token to filter is unknown: `${compiler_token_to_filter_upper}`")
  endif()

  set(compiler_token_to_filter_name "${CMAKE_MATCH_1}")
  set(compiler_token_to_filter_major_version "${CMAKE_MATCH_2}")
  set(compiler_token_to_filter_minor_version "${CMAKE_MATCH_3}")

  if (compiler_token_name STREQUAL compiler_token_to_filter_name AND
      ((compiler_token_major_version STREQUAL "") OR (compiler_token_to_filter_major_version STREQUAL "") OR (compiler_token_major_version EQUAL compiler_token_to_filter_major_version)) AND
      ((compiler_token_minor_version STREQUAL "") OR (compiler_token_to_filter_minor_version STREQUAL "") OR (compiler_token_minor_version EQUAL compiler_token_to_filter_minor_version)))
    set(${var_out} 1 PARENT_SCOPE)
  else()
    set(${var_out} 0 PARENT_SCOPE)
  endif()
endfunction()

endif()
