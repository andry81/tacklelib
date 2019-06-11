# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_CHECKS_INCLUDE_DEFINED)
set(TACKLELIB_CHECKS_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.9)

# at least cmake 3.9 is required for:
#   * Multiconfig generator detection support: see the `GENERATOR_IS_MULTI_CONFIG` global property
#     (https://cmake.org/cmake/help/v3.9/prop_gbl/GENERATOR_IS_MULTI_CONFIG.html )
#

function(tkl_check_CMAKE_CONFIGURATION_TYPES_vs_multiconfig)
  get_property(GENERATOR_IS_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
  if(NOT DEFINED GENERATOR_IS_MULTI_CONFIG)
    message(FATAL_ERROR "GENERATOR_IS_MULTI_CONFIG must be defined")
  endif()
  # WORKAROUND:
  #   `CMAKE_CONFIGURATION_TYPES is not empty when empty`: https://gitlab.kitware.com/cmake/cmake/issues/19057
  #
  if((NOT GENERATOR_IS_MULTI_CONFIG AND NOT "${CMAKE_CONFIGURATION_TYPES}" STREQUAL "") OR
     (GENERATOR_IS_MULTI_CONFIG AND "${CMAKE_CONFIGURATION_TYPES}" STREQUAL ""))
    message(FATAL_ERROR "CMAKE_CONFIGURATION_TYPES variable must contain configuration names in case of a multiconfig generator presence and must be empty if not: GENERATOR_IS_MULTI_CONFIG=`${GENERATOR_IS_MULTI_CONFIG}` CMAKE_CONFIGURATION_TYPES=`${CMAKE_CONFIGURATION_TYPES}`")
  endif()
endfunction()

function(tkl_check_CMAKE_BUILD_TYPE_vs_multiconfig)
  get_property(GENERATOR_IS_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
  if(NOT DEFINED GENERATOR_IS_MULTI_CONFIG)
    message(FATAL_ERROR "GENERATOR_IS_MULTI_CONFIG must be defined")
  endif()
  if((NOT GENERATOR_IS_MULTI_CONFIG AND NOT CMAKE_BUILD_TYPE) OR
     (GENERATOR_IS_MULTI_CONFIG AND CMAKE_BUILD_TYPE))
      message(FATAL_ERROR "CMAKE_BUILD_TYPE variable must not be set in case of a multiconfig generator presence and must be set if not: GENERATOR_IS_MULTI_CONFIG=`${GENERATOR_IS_MULTI_CONFIG}` CMAKE_BUILD_TYPE=`${CMAKE_BUILD_TYPE}`")
  endif()
endfunction()

function(tkl_check_global_vars_consistency)
  # CMAKE_CONFIGURATION_TYPES consistency check
  tkl_check_CMAKE_CONFIGURATION_TYPES_vs_multiconfig()

  # CMAKE_BUILD_TYPE consistency check
  tkl_check_CMAKE_BUILD_TYPE_vs_multiconfig()
endfunction()

function(tkl_check_existence_of_system_vars)
  # these must always exist at any stage
  if (NOT EXISTS "${CMAKE_OUTPUT_ROOT}")
    message(FATAL_ERROR "CMAKE_OUTPUT_ROOT directory must be existed: `${CMAKE_OUTPUT_ROOT}`")
  endif()
  if (NOT EXISTS "${CMAKE_BUILD_ROOT}")
    message(FATAL_ERROR "CMAKE_BUILD_ROOT directory must be existed: `${CMAKE_BUILD_ROOT}`")
  endif()
  if (NOT EXISTS "${CMAKE_BIN_ROOT}")
    message(FATAL_ERROR "CMAKE_BIN_ROOT directory must be existed: `${CMAKE_BIN_ROOT}`")
  endif()
  if (NOT EXISTS "${CMAKE_LIB_ROOT}")
    message(FATAL_ERROR "CMAKE_LIB_ROOT directory must be existed: `${CMAKE_LIB_ROOT}`")
  endif()
  if (NOT EXISTS "${CMAKE_INSTALL_ROOT}")
    message(FATAL_ERROR "CMAKE_INSTALL_ROOT directory must be existed: `${CMAKE_INSTALL_ROOT}`")
  endif()
  if (NOT EXISTS "${CMAKE_CPACK_ROOT}")
    message(FATAL_ERROR "CMAKE_CPACK_ROOT directory must be existed: `${CMAKE_CPACK_ROOT}`")
  endif()

  if (NOT EXISTS "${CMAKE_BUILD_DIR}")
    message(FATAL_ERROR "CMAKE_BUILD_DIR directory does not exist `${CMAKE_BUILD_DIR}`")
  endif()
  if (NOT EXISTS "${CMAKE_BIN_DIR}")
    message(FATAL_ERROR "CMAKE_BIN_DIR directory does not exist `${CMAKE_BIN_DIR}`")
  endif()
  if (NOT EXISTS "${CMAKE_LIB_DIR}")
    message(FATAL_ERROR "CMAKE_LIB_DIR directory does not exist `${CMAKE_LIB_DIR}`")
  endif()
  if (NOT EXISTS "${CMAKE_INSTALL_ROOT}")
    message(FATAL_ERROR "CMAKE_INSTALL_ROOT directory does not exist `${CMAKE_INSTALL_ROOT}`")
  endif()
  if (NOT EXISTS "${CMAKE_CPACK_DIR}")
    message(FATAL_ERROR "CMAKE_CPACK_DIR directory does not exist `${CMAKE_CPACK_DIR}`")
  endif()

  if(NOT PROJECT_NAME)
    message(FATAL_ERROR "PROJECT_NAME must be defined")
  endif()
  if(NOT EXISTS "${PROJECT_ROOT}")
    message(FATAL_ERROR "PROJECT_ROOT directory must be existed: `${PROJECT_ROOT}`")
  endif()

  if(NOT CMAKE_CONFIG_TYPES)
    message(FATAL_ERROR "CMAKE_CONFIG_TYPES must be defined")
  endif()
  if(NOT CMAKE_GENERATOR)
    message(FATAL_ERROR "CMAKE_GENERATOR must be defined")
  endif()
endfunction()

macro(tkl_check_existence_of_required_vars)
  tkl_check_existence_of_system_vars()

  if(NOT DEFINED GENERATOR_IS_MULTI_CONFIG)
    message(FATAL_ERROR "GENERATOR_IS_MULTI_CONFIG must be defined")
  endif()

  if (GENERATOR_IS_MULTI_CONFIG)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BIN_ROOT}")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIB_ROOT}")
  else()
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BIN_ROOT}/${CMAKE_BUILD_TYPE}")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIB_ROOT}/${CMAKE_BUILD_TYPE}")
  endif()

  if (NOT EXISTS "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
    message(FATAL_ERROR "CMAKE_RUNTIME_OUTPUT_DIRECTORY directory must be existed: `${CMAKE_RUNTIME_OUTPUT_DIRECTORY}`")
  endif()
  if (NOT EXISTS "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
    message(FATAL_ERROR "CMAKE_LIBRARY_OUTPUT_DIRECTORY directory must be existed: `${CMAKE_LIBRARY_OUTPUT_DIRECTORY}`")
  endif()
endmacro()

function(tkl_check_var var_opt var_type var_name)
  if (var_opt STREQUAL "")
    message(FATAL_ERROR "var_opt must be set to a variable optionality attribute")
  endif()
  if (var_type STREQUAL "")
    message(FATAL_ERROR "var_type must be set to a variable type")
  endif()
  if (var_name STREQUAL "")
    message(FATAL_ERROR "var_name must be set to a variable name")
  endif()

  if ((var_opt STREQUAL "REQUIRED") OR (var_opt STREQUAL "DEFINED"))
    if (NOT DEFINED ${var_name})
      message(FATAL_ERROR "a variable must be defined: `${var_name}`")
    endif()
  endif()

  if (var_type STREQUAL "PATH")
    if ((var_opt STREQUAL "REQUIRED") OR (var_opt STREQUAL "OPTIONAL" AND DEFINED ${var_name}))
      if (NOT EXISTS "${${var_name}}")
        message(FATAL_ERROR "a path variable must issue an existed path: ${var_name}=`${${var_name}}`")
      endif()
    endif()
  endif()
endfunction()

endif()
