# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_CHECKS_INCLUDE_DEFINED)
set(TACKLELIB_CHECKS_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.9)

# at least cmake 3.9 is required for:
#   * Multiconfig generator detection support: see the `GENERATOR_IS_MULTI_CONFIG` global property
#     (https://cmake.org/cmake/help/v3.9/prop_gbl/GENERATOR_IS_MULTI_CONFIG.html )
#

include(tacklelib/ForwardVariables)
include(tacklelib/Eval)
include(tacklelib/Props)

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
  if(NOT GENERATOR_IS_MULTI_CONFIG AND NOT CMAKE_BUILD_TYPE)
      message(FATAL_ERROR "CMAKE_BUILD_TYPE variable must be set for not multiconfig generator: GENERATOR_IS_MULTI_CONFIG=`${GENERATOR_IS_MULTI_CONFIG}` CMAKE_BUILD_TYPE=`${CMAKE_BUILD_TYPE}`")
  endif()
endfunction()

function(tkl_check_global_vars_consistency)
  # CMAKE_CONFIGURATION_TYPES consistency check
  tkl_check_CMAKE_CONFIGURATION_TYPES_vs_multiconfig()

  # CMAKE_BUILD_TYPE consistency check, can be checked ONLY if not a registered context variable (explicit user override)
  get_property(global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR")

  if (NOT "${global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}" STREQUAL "")
    tkl_has_context_vars(has_CMAKE_BUILD_TYPE "tkl_register_package_var" "${global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}" CMAKE_BUILD_TYPE)
    if (NOT has_CMAKE_BUILD_TYPE)
      tkl_check_CMAKE_BUILD_TYPE_vs_multiconfig()
    endif()
  endif()
endfunction()

function(tkl_check_existence_of_preloaded_system_vars)
  # these must exist after a very first variable's preload
  if (NOT DEFINED CMAKE_OUTPUT_ROOT)
    message(FATAL_ERROR "CMAKE_OUTPUT_ROOT variable must be defined")
  endif()
  if (NOT DEFINED CMAKE_BUILD_ROOT)
    message(FATAL_ERROR "CMAKE_BUILD_ROOT variable must be defined")
  endif()
endfunction()

function(tkl_check_existence_of_loaded_system_vars)
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
  if (NOT EXISTS "${CMAKE_PACK_ROOT}")
    message(FATAL_ERROR "CMAKE_PACK_ROOT directory must be existed: `${CMAKE_PACK_ROOT}`")
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
  if (NOT EXISTS "${CMAKE_PACK_DIR}")
    message(FATAL_ERROR "CMAKE_PACK_DIR directory does not exist `${CMAKE_PACK_DIR}`")
  endif()

  if(NOT PROJECT_NAME)
    message(FATAL_ERROR "PROJECT_NAME must be defined")
  endif()

  if(NOT CMAKE_CONFIG_TYPES)
    message(FATAL_ERROR "CMAKE_CONFIG_TYPES must be defined")
  endif()
  if(NOT CMAKE_GENERATOR)
    message(FATAL_ERROR "CMAKE_GENERATOR must be defined")
  endif()
endfunction()

macro(tkl_check_existence_of_required_vars)
  tkl_check_existence_of_loaded_system_vars()

  if(NOT DEFINED GENERATOR_IS_MULTI_CONFIG)
    message(FATAL_ERROR "GENERATOR_IS_MULTI_CONFIG must be defined")
  endif()

  if (NOT EXISTS "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
    message(FATAL_ERROR "CMAKE_RUNTIME_OUTPUT_DIRECTORY directory must be existed: `${CMAKE_RUNTIME_OUTPUT_DIRECTORY}`")
  endif()
  if (NOT EXISTS "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
    message(FATAL_ERROR "CMAKE_LIBRARY_OUTPUT_DIRECTORY directory must be existed: `${CMAKE_LIBRARY_OUTPUT_DIRECTORY}`")
  endif()
  if (NOT EXISTS "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}")
    message(FATAL_ERROR "CMAKE_ARCHIVE_OUTPUT_DIRECTORY directory must be existed: `${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}`")
  endif()
endmacro()

function(tkl_check_build_root_tags build_type is_multi_config)
  # check if multiconfig.tag is already created
  if (EXISTS "${CMAKE_BUILD_ROOT}/singleconfig.tag")
    if ("${build_type}" STREQUAL "")
      message(FATAL_ERROR "single config cmake cache already has been created, but variable CMAKE_BUILT_TYPE is not set: CMAKE_GENERATOR=`${CMAKE_GENERATOR}`")
    endif()
  endif()

  if (EXISTS "${CMAKE_BUILD_ROOT}/multiconfig.tag")
    if (NOT "${build_type}" STREQUAL "")
      message(FATAL_ERROR "multi config cmake cache already has been created, but variable CMAKE_BUILD_TYPE is set: CMAKE_GENERATOR=`${CMAKE_GENERATOR}` CMAKE_BUILD_TYPE=`${CMAKE_BUILD_TYPE}`")
    endif()
    if (NOT is_multi_config)
      message(FATAL_ERROR "multi config cmake cache already has been created, but cmake was not run under a multiconfig generator: CMAKE_GENERATOR=`${CMAKE_GENERATOR}` CMAKE_BUILD_TYPE=`${CMAKE_BUILD_TYPE}`")
    endif()
  endif()
endfunction()

function(tkl_check_var var_opt var_type var_name)
  if ("${var_opt}" STREQUAL "")
    message(FATAL_ERROR "var_opt must be set to a variable optionality attribute")
  endif()
  if ("${var_type}" STREQUAL "")
    message(FATAL_ERROR "var_type must be set to a variable type")
  endif()
  if ("${var_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be set to a variable name")
  endif()

  if (("${var_opt}" STREQUAL "REQUIRED") OR ("${var_opt}" STREQUAL "DEFINED"))
    if (NOT DEFINED ${var_name})
      message(FATAL_ERROR "tkl_check_var: `${var_name}`: a variable must be defined; type: `${var_type}`")
    endif()
  elseif ("${var_opt}" STREQUAL "OPTIONAL")
    message(WARNING "tkl_check_var: OPTIONAL argument is deprecated, use `path optional` attribute sequence directly in a path variable declaration")
  # check `var_opt` as a user variable or if-expression
  elseif (DEFINED ${var_opt} AND ${var_opt})
    if (NOT DEFINED ${var_name})
      message(FATAL_ERROR "tkl_check_var: `${var_name}`: a variable must be defined; requireness: ${var_opt}=`${${var_opt}}`")
    endif()
    message("tkl_check_var: `${var_name}`: ${var_opt}=`${${var_opt}}`; type: `${var_type}`")
  endif()

  if ("${var_type}" STREQUAL "PATH")
    if ("${var_opt}" STREQUAL "REQUIRED")
      if (NOT EXISTS "${${var_name}}")
        message(FATAL_ERROR "tkl_check_var: `${var_name}`: a path variable must issue an existed path: `${${var_name}}`; type: `${var_type}`")
      endif()
    endif()
  endif()
endfunction()

function(tkl_check_var_eval var_opt_exp var_type var_name)
  if ("${var_opt_exp}" STREQUAL "")
    message(FATAL_ERROR "var_opt_exp must be set to an if-expression")
  endif()
  if ("${var_type}" STREQUAL "")
    message(FATAL_ERROR "var_type must be set to a variable type")
  endif()
  if ("${var_name}" STREQUAL "")
    message(FATAL_ERROR "var_name must be set to a variable name")
  endif()

  tkl_eval_begin("tkl_check_var_eval.cmake" "")

  tkl_eval_append("tkl_check_var_eval.cmake" "\
if (${var_opt_exp})
  set_property(GLOBAL PROPERTY \"tkl::checkvar::exp\" 1)
else()
  set_property(GLOBAL PROPERTY \"tkl::checkvar::exp\" 0)
endif()
")

  # evaluating...
  tkl_eval_end("tkl_check_var_eval.cmake" .)

  tkl_get_global_prop(check_var_exp_result "tkl::checkvar::exp" 1)

  message("tkl_check_var_eval: `${var_name}`: if-expression: `${var_opt_exp}` -> `${check_var_exp_result}`; type: `${var_type}`")

  if ("${var_type}" STREQUAL "PATH")
    if (("${var_opt}" STREQUAL "REQUIRED") OR ("${var_opt}" STREQUAL "OPTIONAL" AND DEFINED ${var_name}))
      if (NOT EXISTS "${${var_name}}")
        message(FATAL_ERROR "tkl_check_var: `${var_name}`: a path variable must issue an existed path: `${${var_name}}`; type: `${var_type}`")
      endif()
    endif()
  endif()
endfunction()

endif()
