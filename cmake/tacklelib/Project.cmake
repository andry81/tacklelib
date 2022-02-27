# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_PROJECT_INCLUDE_DEFINED)
set(TACKLELIB_PROJECT_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.9)

# at least cmake 3.9 is required for:
#   * Multiconfig generator detection support: see the `GENERATOR_IS_MULTI_CONFIG` global property
#       https://cmake.org/cmake/help/v3.9/prop_gbl/GENERATOR_IS_MULTI_CONFIG.html
#   * `CMAKE_MATCH_<n>` string regex expression support:
#       https://cmake.org/cmake/help/v3.9/variable/CMAKE_MATCH_n.html
#       https://cmake.org/cmake/help/latest/command/string.html
#

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command:
#     https://cmake.org/cmake/help/v3.7/command/if.html
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# CAUTION:
# 1. Be careful with the `set(... CACHE ...)` because it unsets the original
#    variable!
#    From documation:
#     "Finally, whenever a cache variable is added or modified by a command,
#     CMake also removes the normal variable of the same name from the current
#     scope so that an immediately following evaluation of it will expose the
#     newly cached value."
# 2. Be careful with the `set(... CACHE ... FORCE)` because it not just resets
#    the cache and unsets the original variable. Additionally to previously
#    mentioned behaviour it overrides a value passed by the `-D` cmake command
#    line parameter!
# 3. Be careful with the usual `set(<var> <value>)` when the cache value has
#    been already exist, because it actually does not change the cache value but
#    changes state of the ${<var>} value. In another words if you try later to
#    unset the cache variable by the `unset(<var> CACHE)`, then the not cached
#    value will be revealed and might be different when after the very first
#    set!
#

include(tacklelib/Std)
include(tacklelib/Checks)
include(tacklelib/ForwardVariables)
include(tacklelib/SetVarsFromFiles)
include(tacklelib/_3dparty/Global3dparty)

function(tkl_cache_or_discover_var var cache_type desc)
  if(NOT DEFINED ${var} AND DEFINED ENV{${var}})
    set(${var} $ENV{${var}} CACHE ${cache_type} ${desc}) # before the normal set, otherwise it will remove the normal variable!
    set(${var} $ENV{${var}} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_discover_env_var_to flag_var out_var var_name cache_type desc)
  if((NOT out_var) OR (NOT var_name))
    message(FATAL_ERROR "out_var and var_name variables must be not empty: out_var=`${out_var}` var_name=`${var_name}`")
  endif()

  tkl_get_var(uncached_var cached_var ${var_name})

  if ("${desc}" STREQUAL ".")
    # reuse default description
    get_property(desc CACHE "${var_name}" PROPERTY HELPSTRING)
  endif()

  if (DEFINED ENV{${var_name}})
    set(env_var_defined 1)
  else()
    set(env_var_defined 0)
  endif()

  if (DEFINED cached_var)
    set(cached_var_defined 1)
  else()
    set(cached_var_defined 0)
  endif()

  if (DEFINED uncached_var)
    set(uncached_var_defined 1)
  else()
    set(uncached_var_defined 0)
  endif()

  # always set both cache and not cache values into the same value unconditionally
  if(env_var_defined)
    if (cached_var_defined)
      set(${out_var} $ENV{${var_name}} CACHE ${cache_type} ${desc} FORCE) # before the normal set, otherwise it will remove the normal variable!
    endif()
    set(${out_var} $ENV{${var_name}} PARENT_SCOPE)
    set(${flag_var} 1 PARENT_SCOPE)
    return()
  #elseif (cached_var_defined)
  #  if ("${cached_var}" STREQUAL "" AND NOT "${uncached_var}" STREQUAL "")
  #    message(WARNING "not empty not cache variable was rewrited by empty cache variable: ${var_name}=`${uncached_var}` -> ``")
  #  endif()
  #  set(${out_var} ${cached_var} CACHE ${cache_type} ${desc} FORCE) # before the normal set, otherwise it will remove the normal variable!
  #  set(${out_var} ${cached_var} PARENT_SCOPE)
  #  set(${flag_var} 2 PARENT_SCOPE)
  #  return()
  #elseif (uncached_var_defined)
  #  set(${out_var} ${uncached_var} PARENT_SCOPE)
  #  set(${flag_var} 3 PARENT_SCOPE)
  #  return()
  endif()

  set(${flag_var} 0 PARENT_SCOPE)
endfunction()

function(tkl_discover_env_var var_name cache_type desc)
  tkl_discover_env_var_to(is_discovered ${var_name} ${var_name} ${cache_type} ${desc})
  if(is_discovered)
    message(STATUS "(*) discovered environment variable: ${var_name}=`${${var_name}}`")
  endif()
endfunction()

function(tkl_discover_builtin_env_vars prefix_list cache_type desc)
  if(ARGN)
    foreach(prefix IN LISTS prefix_list)
      foreach(suffix IN LISTS ARGN)
        string(TOUPPER "${suffix}" suffix_upper)
        set(var ${prefix}_${suffix_upper})

        # unique variable because in the cache scope
        tkl_discover_env_var_to(is_discovered _F862E761_new_${var} ${var} ${cache_type} .)
        if (is_discovered)
          message(STATUS "(*) discovered environment variable: (builtin) ${var}=`${${var}}`")

          # update cache with FORCE only if alreaady exists
          get_property(var_cache_value_is_set CACHE "${var}" PROPERTY VALUE SET)
          if (var_cache_value_is_set)
            if ("${desc}" STREQUAL ".")
              # reuse default description
              get_property(var_cache_desc CACHE "${var}" PROPERTY HELPSTRING)
            else()
              set(var_cache_desc "${desc}")
            endif()

            set(${var} "${_F862E761_new_${var}}" CACHE ${cache_type} ${var_cache_desc} FORCE)
          endif()

          set(${var} "${_F862E761_new_${var}}" PARENT_SCOPE)
          tkl_unset_all(_F862E761_new_${var})
        endif()
      endforeach()
    endforeach()
  else()
    foreach(prefix IN LISTS prefix_list)
      set(var ${prefix})

      # unique variable because in the cache scope
      tkl_discover_env_var_to(is_discovered _F862E761_new_${var} ${var} ${cache_type} .)
      if (is_discovered)
        message(STATUS "(*) discovered environment variable: (builtin) ${var}=`${${var}}`")

        # update cache with FORCE only if alreaady exists
        get_property(var_cache_value_is_set CACHE "${var}" PROPERTY VALUE SET)
        if (var_cache_value_is_set)
          if ("${desc}" STREQUAL ".")
            # reuse default description
            get_property(var_cache_desc CACHE "${var}" PROPERTY HELPSTRING)
          else()
            set(var_cache_desc "${desc}")
          endif()

          set(${var} "${_F862E761_new_${var}}" CACHE ${cache_type} ${var_cache_desc} FORCE)
        endif()

        set(${var} "${_F862E761_new_${var}}" PARENT_SCOPE)
        tkl_unset_all(_F862E761_new_${var})
      endif()
    endforeach()
  endif()
endfunction()

function(tkl_generate_regex_replace_expression out_regex_match_var out_regex_replace_var in_regex_match_var in_replace_to)
  if((${in_regex_match_var} MATCHES "[^\\\\]\\(|^\\(") OR ("${in_replace_to}" MATCHES "\\\\0|\\\\1|\\\\2|\\\\3|\\\\4|\\\\5|\\\\6|\\\\7|\\\\8|\\\\9"))
    message(FATAL_ERROR "input regex match expression does not support groups capture: in_regex_match_var=`${${in_regex_match_var}}`; in_replace_to=`${in_replace_to}`")
  endif()

  string(REPLACE "\\" "\\\\" in_replace_to_escaped "${in_replace_to}")
  set(${out_regex_match_var} "([${TACKLELIB_CMAKE_NOTFLAG_REGEX_CHARS}]*)${${in_regex_match_var}}([${TACKLELIB_CMAKE_NOTFLAG_REGEX_CHARS}]*)" PARENT_SCOPE)
  set(${out_regex_replace_var} "\\1${in_replace_to_escaped}\\2" PARENT_SCOPE)
endfunction()

macro(tkl_unset_empty_builtin_vars)
  if (DEFINED OSTYPE AND "${OSTYPE}" STREQUAL "")
    tkl_unset_all(OSTYPE)
  endif()

  if (DEFINED CMAKE_BUILD_TYPE AND "${CMAKE_BUILD_TYPE}" STREQUAL "")
    tkl_unset_all(CMAKE_BUILD_TYPE)
  endif()
  if (DEFINED CMAKE_GENERATOR AND "${CMAKE_GENERATOR}" STREQUAL "")
    tkl_unset_all(CMAKE_GENERATOR)
  endif()
  if (DEFINED CMAKE_GENERATOR_INSTANCE AND "${CMAKE_GENERATOR_INSTANCE}" STREQUAL "")
    tkl_unset_all(CMAKE_GENERATOR_INSTANCE)
  endif()
  if (DEFINED CMAKE_GENERATOR_TOOLSET AND "${CMAKE_GENERATOR_TOOLSET}" STREQUAL "")
    tkl_unset_all(CMAKE_GENERATOR_TOOLSET)
  endif()
  if (DEFINED CMAKE_GENERATOR_PLATFORM AND "${CMAKE_GENERATOR_PLATFORM}" STREQUAL "")
    tkl_unset_all(CMAKE_GENERATOR_PLATFORM)
  endif()
endmacro()

macro(tkl_declare_primary_builtin_vars)
  tkl_get_global_prop(TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL "tkl::CMAKE_CURRENT_PACKAGE_NEST_LVL" 0)
  if (DEFINED TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
    math(EXPR TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL "${TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL}+1")
  else()
    set(TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL 0)
  endif()
  set_property(GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_NEST_LVL" "${TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL}")

  if (TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL LESS 10)
    set(TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX "0${TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL}")
  else()
    set(TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX "${TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL}")
  endif()

  set(TACKLELIB_CMAKE_CURRENT_PACKAGE_NAME "${PROJECT_NAME}")
  set(TACKLELIB_CMAKE_CURRENT_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}")

  # top level project root
  if (NOT TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
    if ((DEFINED TACKLELIB_CMAKE_TOP_PACKAGE_NAME) OR (DEFINED TACKLELIB_CMAKE_TOP_PACKAGE_SOURCE_DIR))
      message(FATAL_ERROR "TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL may have has an incorrect value, the top package variables has been already defined")
    endif()
    set(TACKLELIB_CMAKE_TOP_PACKAGE_NAME "${TACKLELIB_CMAKE_CURRENT_PACKAGE_NAME}")
    set(TACKLELIB_CMAKE_TOP_PACKAGE_SOURCE_DIR "${TACKLELIB_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
  endif()

  # configuration values with partial defined state check
  if (DEFINED ENV{OSTYPE})
    set(_8B902B3E_rvalue_of_OSTYPE "`$ENV{OSTYPE}`")
  else()
    set(_8B902B3E_rvalue_of_OSTYPE "<undefined>")
  endif()

  message(STATUS "(*) PROJECT_NAME/TACKLELIB_CMAKE_CURRENT_PACKAGE_NAME=`${PROJECT_NAME}` TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL=`${TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL}` TACKLELIB_CMAKE_CURRENT_PACKAGE_SOURCE_DIR=`${TACKLELIB_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}`")

  message(STATUS "(*) CMAKE_VERSION=`${CMAKE_VERSION}`")
  message(STATUS "(*) CMAKE_MODULE_PATH=`${CMAKE_MODULE_PATH}`")
  message(STATUS "(*) CMAKE_C_COMPILER_ID=`${CMAKE_C_COMPILER_ID}` CMAKE_CXX_COMPILER_ID=`${CMAKE_CXX_COMPILER_ID}` OSTYPE=${_8B902B3E_rvalue_of_OSTYPE}")
  message(STATUS "(*) CMAKE_C_COMPILER_VERSION=`${CMAKE_C_COMPILER_VERSION}` CMAKE_CXX_COMPILER_VERSION=`${CMAKE_CXX_COMPILER_VERSION}`")
  message(STATUS "(*) CMAKE_C_COMPILER_ARCHITECTURE_ID=`${CMAKE_C_COMPILER_ARCHITECTURE_ID}` CMAKE_CXX_COMPILER_ARCHITECTURE_ID=`${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}`")

  # check if generator is multiconfig
  get_property(GENERATOR_IS_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
  message(STATUS "(*) GENERATOR_IS_MULTI_CONFIG=`${GENERATOR_IS_MULTI_CONFIG}` CMAKE_CONFIGURATION_TYPES=`${CMAKE_CONFIGURATION_TYPES}` (default)")

  # basic input values with defined state check
  if (DEFINED CMAKE_BUILD_TYPE)
    set(_8B902B3E_rvalue_of_CMAKE_BUILD_TYPE "`${CMAKE_BUILD_TYPE}`")
  else()
    set(_8B902B3E_rvalue_of_CMAKE_BUILD_TYPE "<undefined>")
  endif()
  if (DEFINED CMAKE_GENERATOR)
    set(_8B902B3E_rvalue_of_CMAKE_GENERATOR "`${CMAKE_GENERATOR}`")
  else()
    set(_8B902B3E_rvalue_of_CMAKE_GENERATOR "<undefined>")
  endif()
  if (DEFINED CMAKE_GENERATOR_INSTANCE)
    set(_8B902B3E_rvalue_of_CMAKE_GENERATOR_INSTANCE "`${CMAKE_GENERATOR_INSTANCE}`")
  else()
    set(_8B902B3E_rvalue_of_CMAKE_GENERATOR_INSTANCE "<undefined>")
  endif()
  if (DEFINED CMAKE_GENERATOR_TOOLSET)
    set(_8B902B3E_rvalue_of_CMAKE_GENERATOR_TOOLSET "`${CMAKE_GENERATOR_TOOLSET}`")
  else()
    set(_8B902B3E_rvalue_of_CMAKE_GENERATOR_TOOLSET "<undefined>")
  endif()
  if (DEFINED CMAKE_GENERATOR_PLATFORM)
    set(_8B902B3E_rvalue_of_CMAKE_GENERATOR_PLATFORM "`${CMAKE_GENERATOR_PLATFORM}`")
  else()
    set(_8B902B3E_rvalue_of_CMAKE_GENERATOR_PLATFORM "<undefined>")
  endif()

  if (DEFINED CMAKE_BUILD_ROOT)
    set(_8B902B3E_rvalue_of_CMAKE_BUILD_ROOT "`${CMAKE_BUILD_ROOT}`")
  else()
    set(_8B902B3E_rvalue_of_CMAKE_BUILD_ROOT "<undefined>")
  endif()

  message(STATUS
    "(*) CMAKE_BUILD_TYPE=${_8B902B3E_rvalue_of_CMAKE_BUILD_TYPE} "
    "CMAKE_GENERATOR=${_8B902B3E_rvalue_of_CMAKE_GENERATOR} "
    "CMAKE_GENERATOR_TOOLSET=${_8B902B3E_rvalue_of_CMAKE_GENERATOR_TOOLSET} "
    "CMAKE_GENERATOR_PLATFORM=${_8B902B3E_rvalue_of_CMAKE_GENERATOR_PLATFORM}")
  message(STATUS
    "(*) CMAKE_GENERATOR_INSTANCE=${_8B902B3E_rvalue_of_CMAKE_GENERATOR_INSTANCE}")
  message(STATUS
    "(*) CMAKE_BUILD_ROOT=${_8B902B3E_rvalue_of_CMAKE_BUILD_ROOT}")

  tkl_check_global_vars_consistency()

  # https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_COMPILER_ID.html
  #
  # Absoft = Absoft Fortran (absoft.com)
  # ADSP = Analog VisualDSP++ (analog.com)
  # AppleClang = Apple Clang (apple.com)
  # ARMCC = ARM Compiler (arm.com)
  # Bruce = Bruce C Compiler
  # CCur = Concurrent Fortran (ccur.com)
  # Clang = LLVM Clang (clang.llvm.org)
  # Cray = Cray Compiler (cray.com)
  # Embarcadero, Borland = Embarcadero (embarcadero.com)
  # Flang = Flang LLVM Fortran Compiler
  # G95 = G95 Fortran (g95.org)
  # GNU = GNU Compiler Collection (gcc.gnu.org)
  # GHS = Green Hills Software (www.ghs.com)
  # HP = Hewlett-Packard Compiler (hp.com)
  # IAR = IAR Systems (iar.com)
  # Intel = Intel Compiler (intel.com)
  # MIPSpro = SGI MIPSpro (sgi.com)
  # MSVC = Microsoft Visual Studio (microsoft.com)
  # NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  # OpenWatcom = Open Watcom (openwatcom.org)
  # PGI = The Portland Group (pgroup.com)
  # PathScale = PathScale (pathscale.com)
  # SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  # SunPro = Oracle Solaris Studio (oracle.com)
  # TI = Texas Instruments (ti.com)
  # TinyCC = Tiny C Compiler (tinycc.org)
  # XL, VisualAge, zOS = IBM XL (ibm.com)

  # declare some not yet builtin variables
  if (NOT DEFINED GCC)
    if(("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU") OR ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU"))
      set(GCC 1)
    endif()
  endif()

  if (NOT DEFINED CLANG)
    if (("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang") OR ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang"))
      set(CLANG 1)
    endif()
  endif()

  set(TACKLELIB_CMAKE_NOTPRINTABLE_MATCH_CHARS " \t")
  set(TACKLELIB_CMAKE_NOTFLAG_MATCH_CHARS "${TACKLELIB_CMAKE_NOTPRINTABLE_REGEX_CHARS}\"")
  set(TACKLELIB_CMAKE_QUOTABLE_MATCH_CHARS ";,${TACKLELIB_CMAKE_NOTPRINTABLE_REGEX_CHARS}")

  set(TACKLELIB_CMAKE_NOTPRINTABLE_REGEX_CHARS " \\t")
  set(TACKLELIB_CMAKE_NOTFLAG_REGEX_CHARS "${TACKLELIB_CMAKE_NOTPRINTABLE_REGEX_CHARS}\"")
  set(TACKLELIB_CMAKE_QUOTABLE_REGEX_CHARS ";,${TACKLELIB_CMAKE_NOTPRINTABLE_REGEX_CHARS}")
endmacro()

macro(tkl_declare_secondary_builtin_vars)
  tkl_discover_env_var(MSYS         STRING "msys environment flag")
  tkl_discover_env_var(MINGW        STRING "mingw environment flag")
  tkl_discover_env_var(CYGWIN       STRING "cygwin environment flag")

  tkl_detect_file_system_paths_sensitivity(TACKLELIB_FILE_SYSTEM_NAME_CASE_SENSITIVE TACKLELIB_FILE_SYSTEM_BACK_AND_FORWARD_SLASH_SEPARATOR)
endmacro()

macro(tkl_declare_ternary_builtin_vars)
  if (NOT DEFINED TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
    message(FATAL_ERROR "TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL is not defined")
  endif()

  if (NOT "${CMAKE_BUILD_TYPE}" STREQUAL "")
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BIN_ROOT}/${CMAKE_BUILD_TYPE}")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIB_ROOT}/${CMAKE_BUILD_TYPE}")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_LIB_ROOT}/${CMAKE_BUILD_TYPE}") # `*.lib` files on Windows and `*.a` files on Linux
  else()
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BIN_ROOT}")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIB_ROOT}")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_LIB_ROOT}")  # `*.lib` files on Windows and `*.a` files on Linux
  endif()

  # only top level project can discovery or change global cmake flags
  if (NOT TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
    tkl_discover_builtin_env_vars(CMAKE_INSTALL_PREFIX        PATH .)

    tkl_discover_builtin_env_vars(CMAKE_CXX_FLAGS             STRING .)
    tkl_discover_builtin_env_vars(CMAKE_EXE_LINKER_FLAGS      STRING .)
    tkl_discover_builtin_env_vars(CMAKE_MODULE_LINKER_FLAGS   STRING .)
    tkl_discover_builtin_env_vars(CMAKE_STATIC_LINKER_FLAGS   STRING .)
    tkl_discover_builtin_env_vars(CMAKE_SHARED_LINKER_FLAGS   STRING .)

    # all other variables
    if (NOT "${CMAKE_BUILD_TYPE}" STREQUAL "")
      tkl_discover_builtin_env_vars("CMAKE_CXX_FLAGS;CMAKE_EXE_LINKER_FLAGS;CMAKE_MODULE_LINKER_FLAGS;CMAKE_STATIC_LINKER_FLAGS;CMAKE_SHARED_LINKER_FLAGS"
          STRING . "${CMAKE_BUILD_TYPE}")
    else()
      tkl_discover_builtin_env_vars("CMAKE_CXX_FLAGS;CMAKE_EXE_LINKER_FLAGS;CMAKE_MODULE_LINKER_FLAGS;CMAKE_STATIC_LINKER_FLAGS;CMAKE_SHARED_LINKER_FLAGS"
          STRING . "${CMAKE_CONFIGURATION_TYPES}")
    endif()
  endif()
endmacro()

macro(tkl_detect_environment)
  # detection of msys/mingw/cygwin environments
  if ("$ENV{OSTYPE}" MATCHES "msys.*")
    set(MSYS ON)
    set(MINGW ON)
  elseif ("$ENV{OSTYPE}" MATCHES "mingw.*")
    set(MINGW ON)
  elseif ("$ENV{OSTYPE}" MATCHES "cygwin.*")
    set(CYGWIN ON)
  endif()

  # WARNING: is not needed anymore as long as the Qt Creator is not uniformally or portibly detectable from cmake under any OS
  ## CAUTION:
  ##   We have to detect the executor to ignore a build directory change under particular executors.
  ##
  #if (COMMAND detect_qt_creator)
  #  detect_qt_creator()
  #endif()
endmacro()

# CAUTION:
#   Function must be without arguments to:
#   1. support optional leading arguments like flags beginning by the `-` character
#
# Usage:
#   [<flags>] <env_var_files_list> <external_vars_list> <preload_only_vars_list>
#
# flags:
#   -S                          - script mode
#   -s                          - silent mode
#
macro(tkl_preload_variables) # WITH OUT ARGUMENTS!
  if (NOT ${ARGC} GREATER_EQUAL 3)
    message(FATAL_ERROR "function must be called at least with 3 not optional arguments: `${ARGC}`")
  endif()

  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" . _DDDE2B35_argn)
  # in case of in a macro call we must pass all ARGV arguments explicitly
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGVn()
  tkl_make_vars_from_ARGV_ARGN_end(. _DDDE2B35_argn)
  tkl_pop_ARGVn_from_stack()

  set(_DDDE2B35_argn_index 0)

  set(_DDDE2B35_script_mode 0)
  set(_DDDE2B35_silent_mode 0)

  # parse flags until no flags
  tkl_parse_function_optional_flags_into_vars(
    _DDDE2B35_argn_index
    _DDDE2B35_argn
    "S;s"
    ""
    "S\;_DDDE2B35_script_mode;s\;_DDDE2B35_silent_mode"
    ""
  )

  list(LENGTH _DDDE2B35_argn _DDDE2B35_argn_len)
  math(EXPR _DDDE2B35_argn_len ${_DDDE2B35_argn_len}-${_DDDE2B35_argn_index})

  if (NOT ${_DDDE2B35_argn_len} GREATER_EQUAL 3)
    message(FATAL_ERROR "function must be called at least with 3 not optional arguments: `${_DDDE2B35_argn_len}`")
  endif()

  list(GET _DDDE2B35_argn ${_DDDE2B35_argn_index} _DDDE2B35_env_var_files_list) # discardes ;-escaping
  math(EXPR _DDDE2B35_argn_index ${_DDDE2B35_argn_index}+1)

  list(GET _DDDE2B35_argn ${_DDDE2B35_argn_index} _DDDE2B35_external_vars_list) # discardes ;-escaping
  math(EXPR _DDDE2B35_argn_index ${_DDDE2B35_argn_index}+1)

  list(GET _DDDE2B35_argn ${_DDDE2B35_argn_index} _DDDE2B35_preload_only_vars_list) # discardes ;-escaping
  math(EXPR _DDDE2B35_argn_index ${_DDDE2B35_argn_index}+1)

  if (_DDDE2B35_script_mode)
    set(_DDDE2B35_script_flag "-S")
  else()
    set(_DDDE2B35_script_flag "")
  endif()
  if (_DDDE2B35_silent_mode)
    set(_DDDE2B35_silent_flag "-s")
    set(_DDDE2B35_print_vars_flag "")
  else()
    set(_DDDE2B35_silent_flag "")
    set(_DDDE2B35_print_vars_flag "-p")
  endif()

  set(_DDDE2B35_default_external_vars "CMAKE_INSTALL_PREFIX;CMAKE_GENERATOR;CMAKE_GENERATOR_TOOLSET;CMAKE_GENERATOR_PLATFORM")
  set(_DDDE2B35_external_vars "${_DDDE2B35_default_external_vars}")
  if (NOT "${_DDDE2B35_external_vars_list}" STREQUAL "" AND NOT "${_DDDE2B35_external_vars_list}" STREQUAL ".")
    tkl_set_append(_DDDE2B35_external_vars "${_DDDE2B35_external_vars_list}" ";")
  endif()

  if (NOT "${_DDDE2B35_preload_only_vars_list}" STREQUAL "" AND NOT "${_DDDE2B35_preload_only_vars_list}" STREQUAL ".")
    function(tkl_load_vars_from_files_lambda_C71CE541)
      tkl_load_vars_from_files(${_DDDE2B35_print_vars_flag} ${_DDDE2B35_script_flag} ${_DDDE2B35_silent_flag}
        --grant_external_vars_for_assign "${_DDDE2B35_external_vars}"
        #--grant_assign_on_vars_change "TACKLELIB_CMAKE_CURRENT_PACKAGE_NAME"
        --load_state_from_cmake_global_properties "_4BA54FD8_"
        #--save_state_into_cmake_global_properties "_4BA54FD8_" # preload does not save the state
        "${_DDDE2B35_env_var_files_list}")

      # drop all variables except these
      foreach(var_name IN LISTS _DDDE2B35_preload_only_vars_list)
        if (DEFINED ${var_name})
          set(${var_name} "${${var_name}}" PARENT_SCOPE)
        endif()
      endforeach()
    endfunction()

    tkl_load_vars_from_files_lambda_C71CE541()
  else()
    tkl_load_vars_from_files(${_DDDE2B35_print_vars_flag} ${_DDDE2B35_script_flag} ${_DDDE2B35_silent_flag}
      --grant_external_vars_for_assign "${_DDDE2B35_external_vars}"
      #--grant_assign_on_vars_change "TACKLELIB_CMAKE_CURRENT_PACKAGE_NAME"
      --load_state_from_cmake_global_properties "_4BA54FD8_"
      #--save_state_into_cmake_global_properties "_4BA54FD8_" # preload does not save the state
      "${_DDDE2B35_env_var_files_list}")
  endif()

  unset(_DDDE2B35_argn)
  unset(_DDDE2B35_argn_len)
  unset(_DDDE2B35_argn_index)
  unset(_DDDE2B35_script_mode)
  unset(_DDDE2B35_silent_mode)
  unset(_DDDE2B35_env_var_files_list)
  unset(_DDDE2B35_external_vars_list)
  unset(_DDDE2B35_default_external_vars)
  unset(_DDDE2B35_external_vars)
  unset(_DDDE2B35_script_flag)
  unset(_DDDE2B35_silent_flag)
  unset(_DDDE2B35_print_vars_flag)
endmacro()

macro(tkl_configure_environment runtime_linkage_type_var supported_compilers)
  if (NOT DEFINED PROJECT_NAME)
    message(FATAL_ERROR "The PROJECT_NAME variable is not defined. The `tkl_configure_environment` function must be called after the `project(...)` cmake function.")
  endif()
  if (NOT DEFINED CMAKE_CONFIG_VARS_SYSTEM_FILE)
    message(FATAL_ERROR "CMAKE_CONFIG_VARS_SYSTEM_FILE must be defined as path to system variables file.")
  endif()
  if (NOT DEFINED CMAKE_CONFIG_VARS_USER_0_FILE)
    message(FATAL_ERROR "CMAKE_CONFIG_VARS_USER_0_FILE must be defined as path to user variables file.")
  endif()

  # WARNING:
  #
  #   It is required to unset a set of builtin variables if were defined empty to avoid triggering the `SetVarsFromFiles.cmake` module
  #   on a variable value change while loading from a configuration file.
  #
  tkl_unset_empty_builtin_vars()

  tkl_declare_primary_builtin_vars()

  set(has_supported_compiler 0)
  foreach(compiler ${supported_compilers})
    if(${compiler})
      set(has_supported_compiler 1)
    endif()
  endforeach()

  if(NOT has_supported_compiler)
    message(FATAL_ERROR "platform is not implemented, supported compilers: `${supported_compilers}`")
  endif()

  tkl_declare_secondary_builtin_vars()

  tkl_detect_environment()

  # CAUTION:
  #   From now and on a predefined set of configuration files must always exist before a cmake run!
  #
  if (NOT EXISTS "${CMAKE_CONFIG_VARS_SYSTEM_FILE}")
    message(FATAL_ERROR "(*) The `${CMAKE_CONFIG_VARS_SYSTEM_FILE}` is not properly generated, use the `*_generate_config` script to generage the file and then edit values manually if required!")
  endif()
  if (NOT EXISTS "${CMAKE_CONFIG_VARS_USER_0_FILE}")
    message(FATAL_ERROR "(*) The `${CMAKE_CONFIG_VARS_USER_0_FILE}` is not properly generated, use the `*_generate_config` script to generage the file and then edit values manually if required!")
  endif()

  # CAUTION:
  #   Never reconfigure configuration files from here, because they can have different versions which must be compared and merged externally!
  #

  # CAUTION:
  #   An IDE like the QtCreator uses the `CMakeLists.txt.user` file to store and load cached
  #   values of the cmake variables (may be already obsoleted in new versions).
  #   But it's change in the cmake may won't promote respective change in the IDE.
  #   To make it changed you have to CLOSE IDE AND DELETE FILE WITH THE CACHED VARIABLES - `CMakeLists.txt.user`!

  # The predefined set of builtin local configuration files for load.
  set(sys_env_var_file_path_load_list "${CMAKE_CONFIG_VARS_SYSTEM_FILE}")
  set(user_env_var_file_path_load_list "${CMAKE_CONFIG_VARS_USER_0_FILE}")

  # detect and load all the rest user local configuration files until not found
  set(next_user_env_var_file_index 1)
  string(REGEX REPLACE "/([^.]*).0." "/\\1.${next_user_env_var_file_index}." next_user_env_var_file ${CMAKE_CONFIG_VARS_USER_0_FILE})
  while (EXISTS "${next_user_env_var_file}" AND NOT IS_DIRECTORY "${next_user_env_var_file}")
    list(APPEND user_env_var_file_path_load_list "${next_user_env_var_file}")

    math(EXPR next_user_env_var_file_index "${next_user_env_var_file_index}+1")
    string(REGEX REPLACE "/([^.]*).0." "/\\1.${next_user_env_var_file_index}." next_user_env_var_file ${CMAKE_CONFIG_VARS_USER_0_FILE})
  endwhile()

  # Preload local configuration files to set only predefined set of variables.
  tkl_preload_variables("${sys_env_var_file_path_load_list}" . .)

  # some variables must exist after a preload
  tkl_check_existence_of_preloaded_system_vars()

  # build output directory variables
  tkl_make_build_output_dir_vars("${CMAKE_BUILD_TYPE}" ${GENERATOR_IS_MULTI_CONFIG})

  # if CMAKE_BUILD_ROOT directory already was created externally and contains some predefined tags, then it already must be in a consistent state
  tkl_check_build_root_tags("${CMAKE_BUILD_TYPE}" ${GENERATOR_IS_MULTI_CONFIG})

  # must always create predefined set of output directories because the camke can be called directly and/or from a nested project out of an external script
  tkl_make_build_output_dirs("${CMAKE_BUILD_TYPE}" ${GENERATOR_IS_MULTI_CONFIG})

  # WARNING: is not needed anymore as long as the Qt Creator is not uniformally or portibly detectable from cmake under any OS
  #if (DEFINED CMAKE_CACHEFILE_DIR AND NOT IS_EXECUTED_BY_QT_CREATOR)
  #  tkl_is_equal_paths(_BA96124E_cmake_cachefile_dir_is_build_dir REALPATH "${CMAKE_CACHEFILE_DIR}" "${CMAKE_BUILD_DIR}" . .)
  #  if (NOT _BA96124E_cmake_cachefile_dir_is_build_dir)
  #    message(FATAL_ERROR "Cmake cache files directory is not the cmake build root directory which might means cmake was previously configured out of the build directory. "
  #                        "To continue do remove manually the external cache file:\n CMAKE_BUILD_DIR=`${CMAKE_BUILD_DIR}`\n CMAKE_CACHEFILE_DIR=`${CMAKE_CACHEFILE_DIR}`")
  #  endif()
  #  unset(_BA96124E_cmake_cachefile_dir_is_build_dir)
  #endif()

  # Find environment variable files through the `_3DPARTY_GLOBAL_ROOTS_LIST` and `_3DPARTY_GLOBAL_ROOTS_FILE_LIST` variables
  # to load them before the local environment variable files.
  # Basically these environment files contain a global environment prepend a local environment.
  #
  find_global_3dparty_environments(global_vars_file_path_list)

  # Prepend a global list over a local list, because a local list must always override a global list.
  set(env_var_file_path_load_list "${sys_env_var_file_path_load_list};${user_env_var_file_path_load_list}")
  if (global_vars_file_path_list)
    set(env_var_file_path_load_list "${global_vars_file_path_list};${env_var_file_path_load_list}")
  else()
    # check construction at least one valid file path
    if (DEFINED _3DPARTY_GLOBAL_ROOTS_LIST AND DEFINED _3DPARTY_GLOBAL_ROOTS_FILE_LIST)
      message(FATAL_ERROR
        "_3DPARTY_GLOBAL_ROOTS_LIST and _3DPARTY_GLOBAL_ROOTS_FILE_LIST does not construct at least one valid file path: "
        "_3DPARTY_GLOBAL_ROOTS_LIST=`${_3DPARTY_GLOBAL_ROOTS_LIST}` "
        "_3DPARTY_GLOBAL_ROOTS_FILE_LIST=`${_3DPARTY_GLOBAL_ROOTS_FILE_LIST}`")
    endif()
  endif()

  # Load all configuration files to ordered set of all variables except variables from the preload section.
  tkl_load_vars_from_files(-p
    --grant_external_vars_assign_in_files "${global_vars_file_path_list}"
    #--grant_assign_on_vars_change "TACKLELIB_CMAKE_CURRENT_PACKAGE_NAME"
    --load_state_from_cmake_global_properties "_4BA54FD8_"
    --save_state_into_cmake_global_properties "_4BA54FD8_"
    "${env_var_file_path_load_list}")

  tkl_update_CMAKE_CONFIGURATION_TYPES_from("${CMAKE_CONFIG_TYPES}" 0)

  tkl_declare_ternary_builtin_vars()

  tkl_check_existence_of_required_vars()

  ### global flag variables reconfiguration

  # set runtime linkage type (dynamic/static)
  tkl_set_runtime_link_type_var("${runtime_linkage_type_var}" 0)

  # remove optimization parameters from global flags, do control it explicitly per source file or target basis
  tkl_remove_global_optimization_flags(*)

  # fix invalid cmake suggestions
  tkl_fix_global_flags(*)

  # print reconfigured global flag variables
  tkl_print_global_flags(*)
endmacro()

function(tkl_configure_file_impl tmpl_file_path out_file_path do_recofigure)
  if(NOT EXISTS "${tmpl_file_path}")
    message(FATAL_ERROR "template input file does not exist: `${tmpl_file_path}`")
  endif()

  get_filename_component(out_file_dir ${out_file_path} DIRECTORY)
  if(NOT EXISTS "${out_file_dir}")
    message(FATAL_ERROR "output file directory does not exist: `${out_file_dir}`")
  endif()

  # override current environment variables by locally stored
  if(do_recofigure OR (NOT EXISTS "${out_file_path}"))
    message(STATUS "(*) Generating file: `${tmpl_file_path}` -> `${out_file_path}`")
    set(CONFIGURE_IN_FILE "${tmpl_file_path}")
    set(CONFIGURE_OUT_FILE "${out_file_path}")
    include(tacklelib/tools/ConfigureFile)
  endif()
endfunction()

function(tkl_configure_file_and_include_impl tmpl_file_path out_file_path do_recofigure)
  tkl_configure_file_impl("${tmpl_file_path}" "${out_file_path}" ${do_recofigure})
  tkl_include_and_echo("${out_file_path}")
endfunction()

function(tkl_configure_file_if_not_exist_and_include tmpl_file_path out_file_path)
  tkl_configure_file_and_include_impl(${tmpl_file_path} ${out_file_path} 0)
endfunction()

function(tkl_reconfigure_file_and_include tmpl_file_path out_file_path)
  tkl_configure_file_and_include_impl(${tmpl_file_path} ${out_file_path} 1)
endfunction()

function(tkl_configure_file_and_load_impl tmpl_file_path out_file_path do_recofigure do_print_vars_set)
  tkl_configure_file_impl("${tmpl_file_path}" "${out_file_path}" ${do_recofigure})
  if (do_print_vars_set)
    tkl_load_vars_from_files(-p "${out_file_path}")
  else()
    tkl_load_vars_from_files("${out_file_path}")
  endif()
endfunction()

function(tkl_configure_file_if_not_exist_and_load tmpl_file_path out_file_path do_print_vars_set)
  tkl_configure_file_and_load_impl(${tmpl_file_path} ${out_file_path} 0 ${do_print_vars_set})
endfunction()

function(tkl_reconfigure_file_and_load tmpl_file_path out_file_path)
  tkl_configure_file_and_load_impl(${tmpl_file_path} ${out_file_path} 1 ${do_print_vars_set})
endfunction()

function(tkl_exclude_paths_from_path_list exclude_list_var include_list_var path_list exclude_path_list verbose_flag)
  if(verbose_flag)
    message(STATUS "(**) tkl_exclude_paths_from_path_list: exclude list: `${exclude_path_list}`")
  endif()

  if(NOT "${include_list_var}" STREQUAL "" AND NOT "${include_list_var}" STREQUAL ".")
    set(include_list_var_defined 1)
  endif()
  if(NOT "${exclude_list_var}" STREQUAL "" AND NOT "${exclude_list_var}" STREQUAL ".")
    set(exclude_list_var_defined 1)
  endif()

  if(NOT include_list_var_defined AND NOT exclude_list_var_defined)
    message(FATAL_ERROR "at least one output list variable must be defined")
  endif()

  set(include_list "")
  set(exclude_list "")

  foreach(path IN LISTS path_list)
    set(_excluded 0)
    foreach(exclude_path IN LISTS exclude_path_list)
      if("${path}" MATCHES "${exclude_path}")
        if(verbose_flag)
          message(STATUS "(**) tkl_exclude_paths_from_path_list: excluded: `${path}`")
        endif()
        set(_excluded 1)
        break()
      endif()
    endforeach()
    if(NOT _excluded)
      list(APPEND include_list "${path}")
    else()
      list(APPEND exclude_list "${path}")
    endif()
  endforeach()

  if(verbose_flag)
    message(STATUS "(**) tkl_exclude_paths_from_path_list: include list: `${include_list}`")
  endif()

  if (include_list_var_defined)
    set(${include_list_var} ${include_list} PARENT_SCOPE)
  endif()
  if (exclude_list_var_defined)
    set(${exclude_list_var} ${exclude_list} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_exclude_file_paths_from_path_list exclude_list_var include_list_var path_list exclude_file_path_list verbose_flag)
  if(verbose_flag)
    message(STATUS "(**) tkl_exclude_file_paths_from_path_list: exclude list: `${exclude_file_path_list}`")
  endif()

  if(NOT "${include_list_var}" STREQUAL "" AND NOT "${include_list_var}" STREQUAL ".")
    set(include_list_var_defined 1)
  endif()
  if(NOT "${exclude_list_var}" STREQUAL "" AND NOT "${exclude_list_var}" STREQUAL ".")
    set(exclude_list_var_defined 1)
  endif()

  if(NOT include_list_var_defined AND NOT exclude_list_var_defined)
    message(FATAL_ERROR "at least one output list variable must be defined")
  endif()

  set(include_list "")
  set(exclude_list "")

  foreach(path IN LISTS path_list)
    set(_excluded 0)
    foreach(exclude_file_path IN LISTS exclude_file_path_list)
      if("${path}|" MATCHES "${exclude_file_path}\\|")
        if(verbose_flag)
          message(STATUS "(**) tkl_exclude_file_paths_from_path_list: excluded: `${path}`")
        endif()
        set(_excluded 1)
        break()
      endif()
    endforeach()
    if(NOT _excluded)
      list(APPEND include_list "${path}")
    else()
      list(APPEND exclude_list "${path}")
    endif()
  endforeach()

  if(verbose_flag)
    message(STATUS "(**) tkl_exclude_file_paths_from_path_list: include list: `${include_list}`")
  endif()

  if (include_list_var_defined)
    set(${include_list_var} ${include_list} PARENT_SCOPE)
  endif()
  if (exclude_list_var_defined)
    set(${exclude_list_var} ${exclude_list} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_include_paths_from_path_list include_list_var path_list include_path_list verbose_flag)
  if(verbose_flag)
    message(STATUS "(**) tkl_include_paths_from_path_list: include list: `${include_path_list}`")
  endif()

  set(include_list "")

  foreach(path IN LISTS path_list)
    foreach(include_path IN LISTS include_path_list)
      if("${path}" MATCHES "${include_path}")
        if(verbose_flag)
          message(STATUS "(**) tkl_include_paths_from_path_list: included: `${path}`")
        endif()
        list(APPEND include_list "${path}")
      endif()
    endforeach()
  endforeach()

  set(${include_list_var} ${include_list} PARENT_SCOPE)
endfunction()

function(tkl_include_file_paths_from_path_list include_list_var path_list include_file_path_list verbose_flag)
  if(verbose_flag)
    message(STATUS "(**) tkl_include_file_paths_from_path_list: include list: `${include_file_path_list}`")
  endif()

  set(include_list "")

  foreach(path IN LISTS path_list)
    foreach(include_file_path IN LISTS include_file_path_list)
      if("${path}|" MATCHES "${include_file_path}\\|")
        if(verbose_flag)
          message(STATUS "(**) tkl_include_file_paths_from_path_list: included: `${path}`")
        endif()
        list(APPEND include_list "${path}")
      endif()
    endforeach()
  endforeach()

  set(${include_list_var} ${include_list} PARENT_SCOPE)
endfunction()

function(tkl_source_group_by_path_list group_path type path_list include_path_list verbose_flag)
  set(include_list "")

  foreach(path IN LISTS path_list)
    foreach(include_path IN LISTS include_path_list)
      if("${path}" MATCHES "${include_path}")
        if(verbose_flag)
          message(STATUS "(**) tkl_source_group_by_path_list: `${group_path}` -> (${type}) `${path}`")
        endif()
        list(APPEND include_list ${path})
      endif()
    endforeach()
  endforeach()

  if(include_list)
    source_group("${group_path}" ${type} ${include_list})
  endif()
endfunction()

function(tkl_source_group_by_file_path_list group_path type path_list include_file_path_list verbose_flag)
  set(include_list "")

  foreach(path IN LISTS path_list)
    foreach(include_file_path IN LISTS include_file_path_list)
      if("${path}|" MATCHES "${include_file_path}\\|")
        if(verbose_flag)
          message(STATUS "(**) tkl_source_group_by_file_path_list: `${group_path}` -> (${type}) `${path}`")
        endif()
        list(APPEND include_list ${path})
      endif()
    endforeach()
  endforeach()

  if(include_list)
    source_group("${group_path}" ${type} ${include_list})
  endif()
endfunction()

function(tkl_source_groups_from_dir_list source_group_root type path_dir_list path_glob_suffix_list)
  string(REPLACE "/" "\\" source_group_root "${source_group_root}")

  #message("  tkl_source_groups_from_dir_list: path_dir_list=`${path_dir_list}`")

  foreach(path_dir IN LISTS path_dir_list)
    #message("  tkl_source_groups_from_dir_list: path_dir=`${path_dir}`")
    if(NOT IS_DIRECTORY "${path_dir}")
      continue()
    endif()

    set(children_list "")
    set(children_per_prefix_list "")

    foreach(path_glob_suffix IN LISTS path_glob_suffix_list)
      file(GLOB_RECURSE children_per_prefix_list RELATIVE ${path_dir} "${path_dir}/${path_glob_suffix}")
      #message("  tkl_source_groups_from_dir_list: ${path_glob_suffix}: children_list=`${children_per_prefix_list}`")

      if (NOT "${children_per_prefix_list}" STREQUAL "")
        list(APPEND children_list "${children_per_prefix_list}")
      endif()
    endforeach()

    set(group_path_dir_list "")

    get_filename_component(abs_path_dir ${path_dir} ABSOLUTE)

    foreach(child_path IN LISTS children_list)
      get_filename_component(abs_child_path ${path_dir}/${child_path} ABSOLUTE)

      file(RELATIVE_PATH child_rel_path ${abs_path_dir} ${abs_child_path})
      if (child_rel_path)
        get_filename_component(child_rel_dir ${child_rel_path} DIRECTORY)

        string(REPLACE "/" "\\" source_group_dir "${child_rel_dir}")
        if(source_group_root)
          if (source_group_dir)
            #message(STATUS "tkl_source_groups_from_dir_list: `${source_group_root}\\${source_group_dir}` -> `${child_rel_path}`")
            source_group("${source_group_root}\\${source_group_dir}" ${type} "${path_dir}/${child_path}")
          else()
            #message(STATUS "tkl_source_groups_from_dir_list: `${source_group_root}` -> `${child_rel_path}`")
            source_group("${source_group_root}" ${type} "${path_dir}/${child_path}")
          endif()
        else()
          #message(STATUS "tkl_source_groups_from_dir_list: `${source_group_dir}` -> `${child_rel_path}`")
          source_group("${source_group_dir}" ${type} "${path_dir}/${child_path}")
        endif()
      endif()
    endforeach()
  endforeach()
endfunction()

function(tkl_declare_target_builtin_properties target)
  # ignore all aliases because of read only
  get_target_property(target_origin ${target} ALIASED_TARGET)
  if (target_origin)
    return()
  endif()

  get_target_property(target_type ${target} TYPE)

  # avoid error: INTERFACE_LIBRARY targets may only have whitelisted properties.
  if(NOT "${target_type}" STREQUAL "INTERFACE_LIBRARY")
    set_property(GLOBAL APPEND PROPERTY "tkl::GLOBAL_TARGET_LIST" ${target})

    get_property(is_global_CMAKE_CURRENT_PACKAGE_NAME_set GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_NAME" SET)
    get_property(is_global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR_set GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR" SET)

    get_property(is_target_PACKAGE_NAME_set TARGET ${target} PROPERTY PACKAGE_NAME SET)
    get_property(is_target_PACKAGE_SOURCE_DIR_set TARGET ${target} PROPERTY PACKAGE_SOURCE_DIR SET)

    # back compatability, just in case
    get_property(is_target_property_SOURCE_DIR_set TARGET ${target} PROPERTY SOURCE_DIR SET)
    if (NOT is_target_property_SOURCE_DIR_set)
      set_target_properties(${target} PROPERTIES SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()

    if (NOT is_target_PACKAGE_NAME_set)
      if (is_global_CMAKE_CURRENT_PACKAGE_NAME_set)
        get_property(global_CMAKE_CURRENT_PACKAGE_NAME GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_NAME")
        set_target_properties(${target} PROPERTIES PACKAGE_NAME "${global_CMAKE_CURRENT_PACKAGE_NAME}")
      else()
        # CAUTION: project name instead, but that still is not a package name!
        set_target_properties(${target} PROPERTIES PACKAGE_NAME "${PROJECT_NAME}")
      endif()
    endif()

    if (NOT is_target_PACKAGE_SOURCE_DIR_set)
      if (is_global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR_set)
        get_property(global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR")
        set_target_properties(${target} PROPERTIES PACKAGE_SOURCE_DIR "${global_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
      else()
        # CAUTION: cmake list directory instead, but that still is not a package directory!
        set_target_properties(${target} PROPERTIES PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}")
      endif()
    endif()

    # in case if cmake list directory would require too
    get_property(is_target_property_LIST_DIR_set TARGET ${target} PROPERTY LIST_DIR SET)
    if (NOT is_target_property_LIST_DIR_set)
      set_target_properties(${target} PROPERTIES LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")
    endif()
  endif()
endfunction()

function(tkl_get_target_alias_from_command_line target_alias_var)
  # search for ALIAS name
  set(target_alias "")
  set(arg_index 0)
  set(arg_alias_index -1)
  foreach(arg IN LISTS ARGN)
    if(arg_alias_index EQUAL -1)
      if("${arg}" STREQUAL "ALIAS")
        set(arg_alias_index ${arg_index})
      endif()
    else()
      set(${target_alias_var} ${arg} PARENT_SCOPE)
      return()
    endif()

    math(EXPR arg_index "${arg_index}+1")
  endforeach()

  set(${target_alias_var} "" PARENT_SCOPE)
endfunction()

function(tkl_get_global_targets_list var)
  get_property(${var} GLOBAL PROPERTY "tkl::GLOBAL_TARGET_LIST")
  set(${var} ${${var}} PARENT_SCOPE)
endfunction()

function(tkl_set_global_targets_list)
  set_property(GLOBAL PROPERTY "tkl::GLOBAL_TARGET_LIST" ${ARGN})
endfunction()

function(tkl_add_library_begin target)
  tkl_get_target_alias_from_command_line(target_alias ${ARGN})
  tkl_add_library_target_begin_message(${target} "${target_alias}" ${ARGN})
endfunction()

function(tkl_add_library_end target)
  tkl_register_target(${target})
endfunction()

function(tkl_add_library_target_begin_message target target_alias)
  get_property(current_package_name GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_NAME")

  if (NOT target_alias)
    message("adding library target: package=`${current_package_name}`; target=`${target}`...")
  else()
    message("adding library target: package=`${current_package_name}`; target=`${target}`; alias=`${target_alias}`...")
  endif()
endfunction()

function(tkl_add_executable_begin target)
  tkl_get_target_alias_from_command_line(target_alias ${ARGN})
  tkl_add_executable_target_begin_message(${target} "${target_alias}" ${ARGN})
endfunction()

function(tkl_add_executable_end target)
  tkl_register_target(${target})
endfunction()

function(tkl_add_executable_target_begin_message target target_alias)
  get_property(current_package_name GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_NAME")

  if (NOT target_alias)
    message("adding executable target: package=`${current_package_name}`; target=`${target}`...")
  else()
    message("adding executable target: package=`${current_package_name}`; target=`${target}`; alias=`${target_alias}`...")
  endif()
endfunction()

function(tkl_add_custom_target_begin target)
  tkl_get_target_alias_from_command_line(target_alias ${ARGN})
  tkl_add_custom_target_begin_message(${target} "${target_alias}" ${ARGN})
endfunction()

function(tkl_add_custom_target_end target)
  tkl_register_target(${target})
endfunction()

function(tkl_add_custom_target_begin_message target target_alias)
  get_property(current_package_name GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_NAME")

  if (NOT target_alias)
    message("adding custom target: package=`${current_package_name}`; target=`${target}`...")
  else()
    message("adding custom target: package=`${current_package_name}`; target=`${target}`;  alias=`${target_alias}`...")
  endif()
endfunction()

function(tkl_register_target target)
  tkl_declare_target_builtin_properties(${target})
endfunction()

function(tkl_unregister_directory_scope_targets)
  tkl_get_global_targets_list(targets_list)

  if (NOT targets_list)
    return()
  endif()

  set(targets_to_remove "")

  foreach(target IN LISTS targets_list)
    get_target_property(is_target_imported ${target} IMPORTED)
    get_target_property(is_target_imported_global ${target} IMPORTED_GLOBAL)
    if (is_target_imported AND NOT is_target_imported_global)
      list(APPEND targets_to_remove ${target})
    endif()
  endforeach()

  if (targets_to_remove)
    list(REMOVE_ITEM targets_list ${targets_to_remove})
  endif()

  tkl_set_global_targets_list(${targets_list})
endfunction()

function(tkl_project_begin project_name)
  message("entering project: `${project_name}`...")

  # use project name as package name
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_NAME" "tkl::package" "${project_name}")

  # use current cmake list directory as package source directory
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR" "tkl::package" "${CMAKE_CURRENT_LIST_DIR}")

  # use additional stack to detect pop
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::CMAKE_CURRENT_PROJECT_SOURCE_DIR" "tkl::package" "${CMAKE_CURRENT_LIST_DIR}")

  if (DEFINED TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
    math(EXPR TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL "${TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL}+1")
  else()
    set(TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL 1 PARENT_SCOPE)
  endif()

  get_property(global_prev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR")

  if (NOT "${global_prev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}" STREQUAL "")
    # reset not inheritable context variables
    tkl_pushreset_not_inheritable_context_vars_macro("tkl_register_package_var" "${global_prev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
  endif()

  tkl_pushset_prop_to_stack(. GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR" "tkl::package" ${CMAKE_CURRENT_LIST_DIR})

  get_property(global_next_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR")

  # push all context variables
  tkl_push_all_context_vars_macro("tkl_register_package_var" "${global_next_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
endfunction()

function(tkl_project_end)
  tkl_unregister_directory_scope_targets()

  get_property(global_next_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR")

  # pop all context variables
  tkl_pop_all_context_vars_macro("tkl_register_package_var" "${global_next_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")

  tkl_pop_prop_from_stack(global_prev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR" "tkl::package")

  if (NOT "${global_prev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}" STREQUAL "")
    # restore not inheritable context variables
    tkl_poprestore_not_inheritable_context_vars_macro("tkl_register_package_var" "${global_prev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
  endif()

  # use project name as package name
  get_property(project_name GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_NAME")
  tkl_pop_prop_from_stack(. GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_NAME" "tkl::package")

  # package source directory
  tkl_pop_prop_from_stack(. GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR" "tkl::package")

  # use additional stack to detect pop
  tkl_pop_prop_from_stack(. GLOBAL "tkl::CMAKE_CURRENT_PROJECT_SOURCE_DIR" "tkl::package")

  message("leaving project: `${project_name}`...")
endfunction()

function(tkl_add_subdirectory_begin target_src_dir)
  if (NOT DEFINED TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
    message(FATAL_ERROR "cmake project is not properly initialized, you must call `tkl_configure_environment` before add any package")
  endif()

  if ("${target_src_dir}" STREQUAL "")
    message(FATAL_ERROR "Target source directory is empty")
  endif()

  # must be always canonical and absolute
  get_filename_component(target_src_dir_abs ${target_src_dir} ABSOLUTE)

  tkl_add_subdirectory_begin_message("${target_src_dir}" ${ARGN})
endfunction()

function(tkl_add_subdirectory_end target_src_dir)
  # must be always canonical and absolute
  get_filename_component(target_src_dir_abs ${target_src_dir} ABSOLUTE)

  get_property(global_CMAKE_CURRENT_PROJECT_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PROJECT_SOURCE_DIR")

  if ("${target_src_dir_abs}" STREQUAL "${global_CMAKE_CURRENT_PROJECT_SOURCE_DIR}")
    tkl_project_end()
  endif()

  tkl_add_subdirectory_end_message(${target_src_dir} ${ARGN})

  math(EXPR TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL "${TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL}-1")
endfunction()

macro(tkl_add_subdirectory_prepare_message)
  set(target_bin_dir "")
  set(arg_index 0)
  foreach(arg IN LISTS ARGN)
    if(arg_index EQUAL 0)
      if(NOT "${arg}" STREQUAL "EXCLUDE_FROM_ALL")
        set(target_bin_dir ${arg})
      endif()
    endif()
    math(EXPR arg_index "${arg_index}+1")
  endforeach()

  # get relative path to the source/binary directory from cmake top level directory - PROJECT_SOURCE_DIR
  #message(PROJECT_SOURCE_DIR=`${PROJECT_SOURCE_DIR}`)
  #message(target_src_dir_abs=`${target_src_dir_abs}`)
  file(RELATIVE_PATH target_src_dir_path ${PROJECT_SOURCE_DIR} ${target_src_dir_abs})
  if(("${target_src_dir_path}" STREQUAL ".") OR ("${target_src_dir_path}" STREQUAL ""))
    set(target_src_dir_path ${target_src_dir})
  endif()

  set(target_bin_dir_msg_line "")
  if(target_bin_dir)
    get_filename_component(target_bin_dir_abs ${target_bin_dir} ABSOLUTE)
    file(RELATIVE_PATH target_bin_dir_path ${PROJECT_SOURCE_DIR} ${target_bin_dir_abs})
    if(("${target_bin_dir_path}" STREQUAL ".") OR ("${target_src_dir_path}" STREQUAL ""))
      set(target_bin_dir_path "${target_bin_dir}")
    endif()

    set(target_bin_dir_msg_line "; bin_dir=`${target_bin_dir_path}`")
  endif()
endmacro()

function(tkl_add_subdirectory_begin_message target_src_dir)
  tkl_add_subdirectory_prepare_message(${ARGV})
  get_property(current_package_name GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_NAME")
  message("entering subdirectory: package=`${current_package_name}`; src_dir=`${target_src_dir_path}`${target_bin_dir_msg_line}...")
endfunction()

function(tkl_add_subdirectory_end_message target_src_dir)
  tkl_add_subdirectory_prepare_message(${ARGV})
  get_property(current_package_name GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_NAME")
  message("leaving subdirectory: package=`${current_package_name}`; src_dir=`${target_src_dir_path}`${target_bin_dir_msg_line}")
endfunction()

function(tkl_find_package_begin package_root_dir_var package)
  if (NOT DEFINED TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
    message(FATAL_ERROR "cmake project is not properly initialized, you must call `tkl_configure_environment` before add any package")
  endif()

  math(EXPR TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL "${TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL}+1")

  tkl_find_package_begin_message(${package_root_dir_var} ${package} ${ARGN})

  get_property(global_prev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR")

  if (NOT "${global_prev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}" STREQUAL "")
    # reset not inheritable context variables
    tkl_pushreset_not_inheritable_context_vars_macro("tkl_register_package_var" "${global_prev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
  endif()

  tkl_pushset_prop_to_stack(. GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_NAME" "tkl::package" ${package})

  if (NOT "${package_root_dir_var}" STREQUAL "" AND NOT "${package_root_dir_var}" STREQUAL ".")
    set(package_root_dir "${${package_root_dir_var}}")
    if ("${package_root_dir}" STREQUAL "")
      message(FATAL_ERROR "Package root diretory path is empty: package_root_dir_var=`${package_root_dir_var}`")
    endif()

    # must be always canonical and absolute
    get_filename_component(package_root_dir_abs ${package_root_dir} ABSOLUTE)

    tkl_pushset_prop_to_stack(. GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR" "tkl::package" "${package_root_dir_abs}")

    get_property(global_next_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR")

    # push all context variables
    tkl_push_all_context_vars_macro("tkl_register_package_var" "${global_next_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
  else()
    tkl_pushunset_prop_to_stack(. GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR" "tkl::package")
  endif()
endfunction()

function(tkl_find_package_end package_root_dir_var package)
  if (NOT DEFINED TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
    message(FATAL_ERROR "cmake project is not properly initialized, you must call `tkl_configure_environment` before add any package")
  endif()

  if (NOT "${package_root_dir_var}" STREQUAL "" AND NOT "${package_root_dir_var}" STREQUAL ".")
    get_property(global_next_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL PROPERTY "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR")

    # pop all context variables
    tkl_pop_all_context_vars_macro("tkl_register_package_var" "${global_next_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
  endif()

  tkl_unregister_directory_scope_targets()

  tkl_pop_prop_from_stack(global_rev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_SOURCE_DIR" "tkl::package")
  tkl_pop_prop_from_stack(. GLOBAL "tkl::CMAKE_CURRENT_PACKAGE_NAME" "tkl::package")

  if (NOT "${global_prev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}" STREQUAL "")
    # restore not inheritable context variables
    tkl_poprestore_not_inheritable_context_vars_macro("tkl_register_package_var" "${global_rev_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
  endif()

  tkl_find_package_end_message(${package_root_dir_var} ${package} ${ARGN})

  math(EXPR TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL "${TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL}-1")
endfunction()

function(tkl_find_package_begin_message package_root_dir_var package)
  if (NOT "${package_root_dir_var}" STREQUAL "" AND NOT "${package_root_dir_var}" STREQUAL ".")
    message("entering package: `${package}`: ${package_root_dir_var}=`${${package_root_dir_var}}`...")
  else()
    message("entering package: `${package}`...")
  endif()
endfunction()

function(tkl_find_package_end_message package_root_dir_var package)
  if (NOT "${package_root_dir_var}" STREQUAL "" AND NOT "${package_root_dir_var}" STREQUAL ".")
    message("leaving package: `${package}`: ${package_root_dir_var}=`${${package_root_dir_var}}`")
  else()
    message("leaving package: `${package}`")
  endif()
endfunction()

function(tkl_add_pch_header create_pch_header from_pch_src to_pch_bin use_pch_header include_pch_header sources sources_out_var)
  # MSVC arguments can be mixed, canonicalize all
  set(create_pch_header_fixed ${create_pch_header})
  set(from_pch_src_fixed ${from_pch_src})
  set(to_pch_bin_fixed ${to_pch_bin})
  set(use_pch_header_fixed ${use_pch_header})
  set(include_pch_header_fixed ${include_pch_header})
  set(sources_fixed "")

  string(REPLACE "\\" "/" create_pch_header_fixed ${create_pch_header_fixed})
  string(REPLACE "\\" "/" from_pch_src_fixed ${from_pch_src_fixed})
  string(REPLACE "\\" "/" to_pch_bin_fixed ${to_pch_bin_fixed})
  string(REPLACE "\\" "/" use_pch_header_fixed ${use_pch_header_fixed})
  string(REPLACE "\\" "/" include_pch_header_fixed ${include_pch_header_fixed})
  foreach(src IN LISTS sources)
    string(REPLACE "\\" "/" src_fixed ${src})
    list(APPEND sources_fixed ${src_fixed})
  endforeach()

  set(pch_bin_file "${CMAKE_CURRENT_BINARY_DIR}/${to_pch_bin_fixed}")

  tkl_exclude_file_paths_from_path_list(. sources_filtered "${sources_fixed}" "/.*\\.h.*" 0)

  string(REPLACE "." "\\." from_pch_src_regex ${from_pch_src})
  tkl_exclude_file_paths_from_path_list(. sources_filtered "${sources_filtered}" "/${from_pch_src_regex}" 0)

  set(use_and_include_pch_header "/Yu\"${use_pch_header_fixed}\"")
  if(include_pch_header)
    set(use_and_include_pch_header "${use_and_include_pch_header} /FI\"${include_pch_header_fixed}\"")
  endif()

  set_source_files_properties(${sources_filtered}
                              PROPERTIES COMPILE_FLAGS "${use_and_include_pch_header} /Fp\"${pch_bin_file}\""
                                         OBJECT_DEPENDS "${pch_bin_file}")  

  # at the last to reset the properties in case if `from_pch_src` is a part of `sources`
  set_source_files_properties(${from_pch_src_fixed}
                              PROPERTIES COMPILE_FLAGS "/Yc\"${create_pch_header_fixed}\" /Fp\"${pch_bin_file}\""
                                         OBJECT_OUTPUTS "${pch_bin_file}")

  if(sources_out_var)
    list(APPEND ${sources_out_var} ${pch_src})
    set(${sources_out_var} ${${sources_out_var}} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_parse_config_names_list_var config_names out_config_types_var out_has_all_config_types_var out_has_default_config_type_var)
  set(config_types "")
  set(has_all_config_types 0)
  set(has_default_config_type 0)

  tkl_check_global_vars_consistency()

  if (NOT "${CMAKE_BUILD_TYPE}" STREQUAL "")
    set(cmake_config_types "${CMAKE_BUILD_TYPE}")
  else()
    if (NOT GENERATOR_IS_MULTI_CONFIG)
      message(FATAL_ERROR "CMAKE_BUILD_TYPE must be set for not multiconfig generator")
    endif()
    set(cmake_config_types "${CMAKE_CONFIGURATION_TYPES}")
  endif()

  if(config_names)
    foreach(config_name IN LISTS config_names)
      if("${config_name}" STREQUAL "*")
        set(has_all_config_types 1)

        foreach(config_type IN LISTS cmake_config_types)
          list(APPEND config_types "${config_type}")
        endforeach()
      else()
        list(APPEND config_types "${config_name}")
      endif()

      if("${config_name}" STREQUAL ".")
        set(has_default_config_type 1)
      endif()
    endforeach()
  endif()

  set(${out_config_types_var} "${config_types}" PARENT_SCOPE)
  set(${out_has_all_config_types_var} "${has_all_config_types}" PARENT_SCOPE)
  set(${out_has_default_config_type_var} "${has_default_config_type}" PARENT_SCOPE)
endfunction()

function(tkl_remove_global_optimization_flags)
  tkl_parse_config_names_list_var(".;${ARGN}" config_types has_all_config_types has_default_config_type)

  if(MSVC)
    set(cmake_compiler_flags_to_remove /O[1-9]+ /GL /GT)
    set(cmake_linker_flags_to_remove /LTCG[^${TACKLELIB_CMAKE_NOTPRINTABLE_REGEX_CHARS}]*)
  elseif(GCC)
    set(cmake_compiler_flags_to_remove -O[1-9]+) #-flto(-[^-]+)? -fwhopr(-[^-]+)?)
    set(cmake_linker_flags_to_remove "")
  else()
    message(FATAL_ERROR "platform is not implemented")
  endif()

  foreach(config_type IN LISTS config_types)
    if("${config_type}" STREQUAL ".")
      set(config_type_suffix "")
    else()
      string(TOUPPER "_${config_type}" config_type_suffix)
    endif()

    if(cmake_compiler_flags_to_remove)
      foreach(flag_var
        CMAKE_CXX_FLAGS)
        foreach(flag IN LISTS cmake_compiler_flags_to_remove)
          if(${flag_var}${config_type_suffix})
            tkl_generate_regex_replace_expression(flag_match_expr flag_replace_expr flag "")
            string(REGEX REPLACE "${flag_match_expr}" "${flag_replace_expr}" ${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}})
            set(${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}} PARENT_SCOPE)
          endif()
        endforeach()
      endforeach()
    endif()

    if(cmake_linker_flags_to_remove)
      foreach(flag_var
        CMAKE_EXE_LINKER_FLAGS CMAKE_MODULE_LINKER_FLAGS CMAKE_STATIC_LINKER_FLAGS CMAKE_SHARED_LINKER_FLAGS)
        foreach(flag IN LISTS cmake_linker_flags_to_remove)
          if(${flag_var}${config_type_suffix})
            tkl_generate_regex_replace_expression(flag_match_expr flag_replace_expr flag "")
            string(REGEX REPLACE "${flag_match_expr}" "${flag_replace_expr}" ${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}})
            set(${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}} PARENT_SCOPE)
          endif()
        endforeach()
      endforeach()
    endif()
  endforeach()
endfunction()

function(tkl_fix_global_flags)
  tkl_parse_config_names_list_var(".;${ARGN}" config_types has_all_config_types has_default_config_type)

  # invalid case flags
  if(MSVC)
    set(_compiler_flags_to_upcase "")
    set(_linker_flags_to_upcase /machine:X86)
  elseif(GCC)
    set(_compiler_flags_to_upcase "")
    set(_linker_flags_to_upcase "")
  else()
    message(FATAL_ERROR "platform is not implemented")
  endif()

  foreach(config_type IN LISTS config_types)
    if("${config_type}" STREQUAL ".")
      set(config_type_suffix "")
    else()
      string(TOUPPER "_${config_type}" config_type_suffix)
    endif()

    if(_compiler_flags_to_upcase)
      foreach(flag_var
        CMAKE_CXX_FLAGS)
        foreach(flag IN LISTS _compiler_flags_to_upcase)
          if(${flag_var}${config_type_suffix})
            string(TOUPPER "${flag}" flag_uppercase)
            tkl_generate_regex_replace_expression(flag_match_expr flag_replace_expr flag "${flag_uppercase}")
            string(REGEX REPLACE "${flag_match_expr}" "${flag_replace_expr}" ${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}})
            set(${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}} PARENT_SCOPE)
          endif()
        endforeach()
      endforeach()
    endif()

    if(_linker_flags_to_upcase)
      foreach(flag_var
        CMAKE_EXE_LINKER_FLAGS CMAKE_MODULE_LINKER_FLAGS CMAKE_STATIC_LINKER_FLAGS CMAKE_SHARED_LINKER_FLAGS)
        foreach(flag IN LISTS _linker_flags_to_upcase)
          if(${flag_var}${config_type_suffix})
            string(TOUPPER "${flag}" flag_uppercase)
            tkl_generate_regex_replace_expression(flag_match_expr flag_replace_expr flag "${flag_uppercase}")
            string(REGEX REPLACE "${flag_match_expr}" "${flag_replace_expr}" ${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}})
            set(${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}} PARENT_SCOPE)
          endif()
        endforeach()
      endforeach()
    endif()
  endforeach()
endfunction()

function(tkl_set_runtime_link_type_var link_type_var do_advance_out_vars)
  if (NOT DEFINED "${link_type_var}")
    message(FATAL_ERROR "runtime link type variable is not defined: `${link_type_var}`")
  endif()

  set(link_type "${${link_type_var}}")

  tkl_check_global_vars_consistency()

  if (NOT "${CMAKE_BUILD_TYPE}" STREQUAL "")
    set(is_single_config_type 1)
    set(cmake_config_types "${CMAKE_BUILD_TYPE}")
  else()
    if (NOT GENERATOR_IS_MULTI_CONFIG)
      message(FATAL_ERROR "CMAKE_BUILD_TYPE must be set for not multiconfig generator")
    endif()
    set(is_single_config_type 0)
    set(cmake_config_types "${CMAKE_CONFIGURATION_TYPES}")
  endif()

  tkl_parse_config_names_list_var(".;${cmake_config_types}" config_types has_all_config_types has_default_config_type)

  # all flags variables here must be list representable (index queriable)
  if(MSVC)
    # https://cmake.org/cmake/help/v3.15/release/3.15.html#variables :
    # The CMAKE_MSVC_RUNTIME_LIBRARY variable and MSVC_RUNTIME_LIBRARY target property
    # (https://cmake.org/cmake/help/v3.15/variable/CMAKE_MSVC_RUNTIME_LIBRARY.html )
    # were introduced to select the runtime library used by compilers targeting the MSVC ABI.
    # See policy CMP0091:
    #   https://cmake.org/cmake/help/v3.15/policy/CMP0091.html#policy:CMP0091
    # Note:
    #   The OLD behavior for this policy is to place MSVC runtime library flags in the default CMAKE_<LANG>_FLAGS_<CONFIG>
    #   cache entries and ignore the CMAKE_MSVC_RUNTIME_LIBRARY abstraction. The NEW behavior for this policy is to not
    #   place MSVC runtime library flags in the default cache entries and use the abstraction instead.
    #
    #   This policy was introduced in CMake version 3.15. Use the cmake_policy() command to set it to OLD or NEW explicitly.
    #   Unlike many policies, CMake version 3.15.7 does not warn when this policy is not set and simply uses OLD behavior.
    #

    if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.15.0" AND "${CMAKE_POLICY_DEFAULT_CMP0091}" STREQUAL "NEW")
      if("${link_type}" STREQUAL "dynamic")
        set(msvc_runtime_link_var_suffix "DLL")
      elseif("${link_type}" STREQUAL "static")
        set(msvc_runtime_link_var_suffix "")
      else()
        message(FATAL_ERROR "unknown runtime link type variable value: link_type=`${link_type}`")
      endif()

      set(is_debug_config_type 0)
      if (NOT is_single_config_type)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "")
      endif()

      foreach(config_type IN LISTS config_types)
        if (config_type IN_LIST CMAKE_CONFIG_DEBUG_TYPES)
          set(is_debug_config_type 1)
        endif()

        if (NOT is_debug_config_type)
          string(FIND "${config_type}" "Debug" config_type_debug_str_pos)
          if (NOT config_type_debug_str_pos EQUAL -1)
            set(is_debug_config_type 1)
          endif()
        endif()

        if (NOT is_debug_config_type)
          string(FIND "${config_type}" "DebInfo" config_type_debug_str_pos)
          if (NOT config_type_debug_str_pos EQUAL -1)
            set(is_debug_config_type 1)
          endif()
        endif()

        if (is_single_config_type)
          if (is_debug_config_type)
            set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDebug${msvc_runtime_link_var_suffix}" PARENT_SCOPE)
          else()
            set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded${msvc_runtime_link_var_suffix}" PARENT_SCOPE)
          endif()

          break()
        else()
          if (is_debug_config_type)
            list(APPEND CMAKE_MSVC_RUNTIME_LIBRARY "$<$<CONFIG:${config_type}>:MultiThreadedDebug${msvc_runtime_link_var_suffix}>")
          else()
            list(APPEND CMAKE_MSVC_RUNTIME_LIBRARY "$<$<CONFIG:${config_type}>:MultiThreaded${msvc_runtime_link_var_suffix}>")
          endif()
        endif()
      endforeach()

      if (NOT is_single_config_type)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "${CMAKE_MSVC_RUNTIME_LIBRARY}" PARENT_SCOPE)
      endif()

      if (do_advance_out_vars)
        mark_as_advanced(CMAKE_MSVC_RUNTIME_LIBRARY)
      endif()

      return()
    else()
      if("${link_type}" STREQUAL "dynamic")
        set(cmake_compiler_flags_to_replace /MT /MTd)
        set(cmake_compiler_flags_to_replace_by /MD /MDd)
        set(cmake_linker_flags_to_replace "")
        set(cmake_linker_flags_to_replace_by "")
      elseif("${link_type}" STREQUAL "static")
        set(cmake_compiler_flags_to_replace /MD /MDd)
        set(cmake_compiler_flags_to_replace_by /MT /MTd)
        set(cmake_linker_flags_to_replace "")
        set(cmake_linker_flags_to_replace_by "")
      else()
        message(FATAL_ERROR "unknown runtime link type variable value: link_type=`${link_type}`")
      endif()
    endif()
  elseif(GCC)
    set(cmake_compiler_flags_to_replace "")
    set(cmake_compiler_flags_to_replace_by "")
    set(cmake_linker_flags_to_replace "")
    set(cmake_linker_flags_to_replace_by "")

    if("${link_type}" STREQUAL "dynamic")
      set(CMAKE_SHARED_LIBS ON PARENT_SCOPE)

      if (do_advance_out_vars)
        mark_as_advanced(CMAKE_SHARED_LIBS)
      endif()

      return()
    elseif("${link_type}" STREQUAL "static")
      set(CMAKE_SHARED_LIBS OFF PARENT_SCOPE)

      if (do_advance_out_vars)
        mark_as_advanced(CMAKE_SHARED_LIBS)
      endif()

      return()
    else()
      message(FATAL_ERROR "unknown runtime link type variable value: link_type=`${link_type}`")
    endif()
  else()
    message(FATAL_ERROR "platform is not implemented")
  endif()

  foreach(config_type IN LISTS config_types)
    if("${config_type}" STREQUAL ".")
      set(config_type_suffix "")
    else()
      string(TOUPPER "_${config_type}" config_type_suffix)
    endif()

    if(cmake_compiler_flags_to_replace)
      foreach(flag_var
        CMAKE_CXX_FLAGS)
        set(flag_index 0)
        foreach(flag IN LISTS cmake_compiler_flags_to_replace)
          if(${flag_var}${config_type_suffix})
            list(GET cmake_compiler_flags_to_replace_by ${flag_index} flag_to_replace_by)
            tkl_generate_regex_replace_expression(flag_match_expr flag_replace_expr flag "${flag_to_replace_by}")
            string(REGEX REPLACE "${flag_match_expr}" "${flag_replace_expr}" ${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}})
            set(${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}} PARENT_SCOPE)

            if (do_advance_out_vars)
              mark_as_advanced(${flag_var}${config_type_suffix})
            endif()
          endif()

          MATH(EXPR flag_index "${flag_index}+1")
        endforeach()
      endforeach()
    endif()

    if(cmake_linker_flags_to_replace)
      foreach(flag_var
        CMAKE_EXE_LINKER_FLAGS CMAKE_MODULE_LINKER_FLAGS CMAKE_STATIC_LINKER_FLAGS CMAKE_SHARED_LINKER_FLAGS)
        set(flag_index 0)
        foreach(flag IN LISTS cmake_linker_flags_to_replace)
          if(${flag_var}${config_type_suffix})
            list(GET cmake_linker_flags_to_replace_by ${flag_index} flag_to_replace_by)
            tkl_generate_regex_replace_expression(flag_match_expr flag_replace_expr flag "${flag_to_replace_by}")
            string(REGEX REPLACE "${flag_match_expr}" "${flag_replace_expr}" ${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}})
            set(${flag_var}${config_type_suffix} ${${flag_var}${config_type_suffix}} PARENT_SCOPE)

            if (do_advance_out_vars)
              mark_as_advanced(${flag_var}${config_type_suffix})
            endif()
          endif()

          MATH(EXPR flag_index "${flag_index}+1")
        endforeach()
      endforeach()
    endif()
  endforeach()
endfunction()

# create basic set of preprocessor definitions, compiler and linker flags for all configurations
# flags_list:
#   - console     - console application
#   - gui         - GUI application
#   - 32bit       - 32-bit linkage on non 32-bit subsystem
function(tkl_initialize_executable_target_defaults target flags_list)
  tkl_initialize_target_defaults_impl(${target} ${flags_list})
endfunction()

# create basic set of preprocessor definitions, compiler and linker flags for all configurations
# flags_list:
#   - 32bit       - 32-bit linkage on non 32-bit subsystem
function(tkl_initialize_library_target_defaults target flags_list)
  tkl_initialize_target_defaults_impl(${target} ${flags_list})
endfunction()

function(tkl_initialize_target_defaults_impl target flags_list)
  message(STATUS "Initializing target: `${target}`...")

  tkl_check_global_vars_consistency()

  if (NOT "${CMAKE_BUILD_TYPE}" STREQUAL "")
    set(cmake_config_types "${CMAKE_BUILD_TYPE}")
  else()
    if (NOT GENERATOR_IS_MULTI_CONFIG)
      message(FATAL_ERROR "CMAKE_BUILD_TYPE must be set for not multiconfig generator")
    endif()
    set(cmake_config_types "${CMAKE_CONFIGURATION_TYPES}")
  endif()

  if(TARGET ${target})
    get_target_property(target_type ${target} TYPE)

    foreach(config_type IN LISTS cmake_config_types)
      string(TOUPPER "${config_type}" config_type_upper)

      # definitions
      if("${config_type_upper}" STREQUAL "DEBUG")
        tkl_add_target_compile_definitions(${target} ${config_type_upper}
          PUBLIC
            _DEBUG
        )
      elseif(("${config_type_upper}" STREQUAL "RELEASE") OR
             ("${config_type_upper}" STREQUAL "MINSIZEREL") OR
             ("${config_type_upper}" STREQUAL "RELWITHDEBINFO"))
        tkl_add_target_compile_definitions(${target} ${config_type_upper}
          PUBLIC
            NDEBUG
        )
      endif()

      # compilation flags
      if(MSVC)
        if(("${target_type}" STREQUAL "EXECUTABLE") OR
           ("${target_type}" STREQUAL "STATIC_LIBRARY") OR
           ("${target_type}" STREQUAL "SHARED_LIBRARY") OR
           ("${target_type}" STREQUAL "MODULE_LIBRARY"))
          if("${config_type_upper}" STREQUAL "DEBUG")
            tkl_add_target_compile_properties(${target} ${config_type_upper}
              /Od     # always drop optimization in debug
            )
          endif()
        endif()
      elseif(GCC)
        if(("${target_type}" STREQUAL "EXECUTABLE") OR
           ("${target_type}" STREQUAL "STATIC_LIBRARY") OR
           ("${target_type}" STREQUAL "SHARED_LIBRARY") OR
           ("${target_type}" STREQUAL "MODULE_LIBRARY"))
          if("${config_type_upper}" STREQUAL "DEBUG")
            tkl_add_target_compile_properties(${target} ${config_type_upper}
              -O0     # always drop optimization in debug
            )
          endif()
          if(("${config_type_upper}" STREQUAL "DEBUG") OR ("${config_type_upper}" STREQUAL "RELWITHDEBINFO"))
            tkl_add_target_compile_properties(${target} ${config_type_upper}
              -g
            )
          endif()
        endif()
      endif()
    endforeach()

    foreach(flag IN LISTS flags_list)
      # indifferent to Windows or Linux, has meaning to console/GUI linkage.
      if("${flag}" STREQUAL "console")
        if(("${target_type}" STREQUAL "EXECUTABLE") OR
           ("${target_type}" STREQUAL "SHARED_LIBRARY") OR
           ("${target_type}" STREQUAL "MODULE_LIBRARY"))
          tkl_add_target_compile_definitions(${target} *
            PUBLIC
              _CONSOLE
          )

          if(MSVC)
            tkl_add_target_link_properties(${target} NOTSTATIC *
              /SUBSYSTEM:CONSOLE
            )
          endif()
        endif()

      elseif("${flag}" STREQUAL "gui")
        if(("${target_type}" STREQUAL "EXECUTABLE") OR
           ("${target_type}" STREQUAL "SHARED_LIBRARY") OR
           ("${target_type}" STREQUAL "MODULE_LIBRARY"))
          tkl_add_target_compile_definitions(${target} *
            PUBLIC
              _WINDOWS
          )

          if(MSVC)
            tkl_add_target_link_properties(${target} NOTSTATIC *
              /SUBSYSTEM:WINDOWS
            )
          endif()
        endif()

      elseif("${flag}" STREQUAL "32bit")
        if(GCC)
          tkl_add_target_compile_properties(${target} *
            -m32        # compile 32 bit target
          )

          tkl_add_target_link_properties(${target} NOTSTATIC *
            -m32        # link 32 bit target
          )
        endif()

      elseif("${flag}" STREQUAL "64bit")
        if(GCC)
          tkl_add_target_compile_properties(${target} *
            -m64        # compile 64 bit target
          )

          tkl_add_target_link_properties(${target} NOTSTATIC *
            -m64        # link 64 bit target
          )
        endif()

      elseif("${flag}" STREQUAL "anybit")
      else()
        message(FATAL_ERROR "unknown flag: `${flag}`")
      endif()
    endforeach()
  endif()
endfunction()

function(tkl_add_target_compile_definitions targets config_names inheritance_type)
  if(ARGN)
    tkl_parse_config_names_list_var("${config_names}" config_types has_all_config_types has_default_config_type)

    if(has_all_config_types OR has_default_config_type)
      foreach(target IN LISTS targets)
        foreach(arg IN LISTS ARGN)
          if (("${arg}" STREQUAL "PRIVATE") OR ("${arg}" STREQUAL "INTERFACE") OR ("${arg}" STREQUAL "PUBLIC"))
            message(FATAL_ERROR "PRIVATE/INTERFACE/PUBLIC types should not be in the list of targets, use another function call to declare different visibility targets")
          endif()
          # arg must be a string here
          target_compile_definitions(${target} ${inheritance_type} "${arg}")
        endforeach()
      endforeach()
    else()
      foreach(config_type IN LISTS config_types)
        foreach(target IN LISTS targets)
          foreach(arg IN LISTS ARGN)
            if (("${arg}" STREQUAL "PRIVATE") OR ("${arg}" STREQUAL "INTERFACE") OR ("${arg}" STREQUAL "PUBLIC"))
              message(FATAL_ERROR "PRIVATE/INTERFACE/PUBLIC types should not be in the list of targets, use another function call to declare different visibility targets")
            endif()
            # arg must be a string here
            target_compile_definitions(${target} ${inheritance_type} "\$<\$<CONFIG:${config_type}>:${arg}>")
          endforeach()
        endforeach()
      endforeach()
    endif()
  else()
    message(FATAL_ERROR "no arguments found")
  endif()
endfunction()

function(tkl_add_target_compile_properties targets config_names)
  tkl_parse_config_names_list_var("${config_names}" config_types has_all_config_types has_default_config_type)

  foreach(target IN LISTS targets)
    # get previous properties
    get_target_property(PROP_LIST_${target} ${target} COMPILE_OPTIONS)

    # PROP_LIST can be list here
    set(PROP_LIST "")

    # convert string to list
    if(PROP_LIST_${target})
      foreach(arg IN LISTS PROP_LIST_${target})
        list(APPEND PROP_LIST ${arg})
      endforeach()
    endif()

    if(ARGN)
      if(has_all_config_types OR has_default_config_type)
        foreach(arg IN LISTS ARGN)
          list(APPEND PROP_LIST ${arg})
        endforeach()
      else()
        foreach(config_type IN LISTS config_types)
          foreach(arg IN LISTS ARGN)
            list(APPEND PROP_LIST "\$<\$<CONFIG:${config_type}>:${arg}>")
          endforeach()
        endforeach()
      endif()
    else()
      message(FATAL_ERROR "no arguments found")
    endif()

    if(PROP_LIST)
      set_target_properties(${target} PROPERTIES
        COMPILE_OPTIONS "${PROP_LIST}"
      )
    endif()
  endforeach()
endfunction()

function(tkl_add_target_link_directories targets config_names inheritance_type)
  if(ARGN)
    tkl_parse_config_names_list_var("${config_names}" config_types has_all_config_types has_default_config_type)

    if(has_all_config_types OR has_default_config_type)
      foreach(target IN LISTS targets)
        foreach(arg IN LISTS ARGN)
          if (("${arg}" STREQUAL "PRIVATE") OR ("${arg}" STREQUAL "INTERFACE") OR ("${arg}" STREQUAL "PUBLIC"))
            message(FATAL_ERROR "PRIVATE/INTERFACE/PUBLIC types should not be in the list of targets, use another function call to declare different visibility targets")
          endif()
          # arg must be a string here
          if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.13.0")
            target_link_directories(${target} ${inheritance_type} "${arg}")
          else()
            link_directories("${arg}")
          endif()
        endforeach()
      endforeach()
    else()
      foreach(config_type IN LISTS config_types)
        foreach(target IN LISTS targets)
          foreach(arg IN LISTS ARGN)
            if (("${arg}" STREQUAL "PRIVATE") OR ("${arg}" STREQUAL "INTERFACE") OR ("${arg}" STREQUAL "PUBLIC"))
              message(FATAL_ERROR "PRIVATE/INTERFACE/PUBLIC types should not be in the list of targets, use another function call to declare different visibility targets")
            endif()
            # arg must be a string here
            if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.13.0")
              target_link_directories(${target} ${inheritance_type} "\$<\$<CONFIG:${config_type}>:${arg}>")
            else()
              link_directories("${arg}")
            endif()
          endforeach()
        endforeach()
      endforeach()
    endif()
  else()
    message(FATAL_ERROR "no arguments found")
  endif()
endfunction()

function(tkl_add_target_link_properties targets linker_type config_names)
  tkl_parse_config_names_list_var("${config_names}" config_types has_all_config_types has_default_config_type)

  set(ignore_notstatic 0)
  set(ignore_static 0)

  if (("${linker_type}" STREQUAL "*") OR ("${linker_type}" STREQUAL "."))
    # use in all linker types
  elseif ("${linker_type}" STREQUAL "STATIC")
    set(ignore_notstatic 1)
  elseif ("${linker_type}" STREQUAL "NOTSTATIC")
    set(ignore_static 1)
  else()
    message(FATAL_ERROR "Unrecognized linker type: `${linker_type}`")
  endif()

  foreach(target IN LISTS targets)
    # static libraries has special flag variables for the linkage
    get_target_property(target_type ${target} TYPE)
    if("${target_type}" STREQUAL "STATIC_LIBRARY")
      if (ignore_static)
        continue()
      endif()
      set(link_flags_name STATIC_LIBRARY_FLAGS)
    else()
      if (ignore_notstatic)
        continue()
      endif()
      set(link_flags_name LINK_FLAGS)
    endif()

    foreach(config_type IN LISTS config_types)
      if("${config_type}" STREQUAL ".")
        set(config_type_suffix "")
      else()
        string(TOUPPER "_${config_type}" config_type_suffix)
      endif()

      get_target_property(PROP_LIST_${target} ${target} ${link_flags_name}${config_type_suffix})

      # PROP_LIST must be a string here
      set(PROP_LIST "")
      if(PROP_LIST_${target})
        foreach(arg IN LISTS PROP_LIST_${target})
          if(PROP_LIST)
            set(PROP_LIST "${PROP_LIST} ${arg}")
          else()
            set(PROP_LIST "${arg}")
          endif()
        endforeach()
      endif()

      if(ARGN)
        foreach(arg IN LISTS ARGN)
          if(PROP_LIST)
            if(NOT arg MATCHES "[${TACKLELIB_CMAKE_QUOTABLE_MATCH_CHARS}]")
              set(PROP_LIST "${PROP_LIST} ${arg}")
            else()
              set(PROP_LIST "${PROP_LIST} \"${arg}\"")
            endif()
          else()
            if(NOT arg MATCHES "[${TACKLELIB_CMAKE_QUOTABLE_MATCH_CHARS}]")
              set(PROP_LIST "${arg}")
            else()
              set(PROP_LIST "\"${arg}\"")
            endif()
          endif()
        endforeach()
      else()
        message(FATAL_ERROR "no arguments found")
      endif()

      if(PROP_LIST)
        set_target_properties(${target} PROPERTIES
          ${link_flags_name}${config_type_suffix} "${PROP_LIST}"
        )
      endif()
    endforeach()
  endforeach()
endfunction()

function(tkl_get_target_compile_property out_var_name target config_type)
  get_target_property(target_type ${target} TYPE)
  if("${config_type}" STREQUAL ".")
    set(config_type_suffix "")
  else()
    string(TOUPPER "_${config_type}" config_type_suffix)
  endif()

  get_target_property(${out_var_name} ${target} COMPILE_OPTIONS${config_type_suffix})

  set(${out_var_name} ${${out_var_name}} PARENT_SCOPE)
endfunction()

function(tkl_get_target_link_property out_var_name target config_type)
  get_target_property(target_type ${target} TYPE)
  if("${config_type}" STREQUAL ".")
    set(config_type_suffix "")
  else()
    string(TOUPPER "_${config_type}" config_type_suffix)
  endif()

  if("${target_type}" STREQUAL "STATIC_LIBRARY")
    get_target_property(${out_var_name} ${target} STATIC_LIBRARY_FLAGS${config_type_suffix})
  else()
    get_target_property(${out_var_name} ${target} LINK_FLAGS${config_type_suffix})
  endif()

  set(${out_var_name} ${${out_var_name}} PARENT_SCOPE)
endfunction()

function(tkl_get_target_link_libraries_recursively out_var_name target)
  set(link_libs "")
  tkl_get_target_link_libraries_recursively_impl(0 link_libs ${target} ${ARGN})
  #message(FATAL_ERROR "  target=`${target}`; all=`${link_libs}`")

  set(${out_var_name} ${link_libs} PARENT_SCOPE)
endfunction()

function(tkl_get_target_link_libraries_recursively_impl nest_counter out_var_name target)
  math(EXPR next_nest_counter "${nest_counter}+1")

  get_target_property(link_libs ${target} LINK_LIBRARIES)

  #message("  target=`${target}`; nest_counter=`${nest_counter}`; link_libs=`${link_libs}`")

  if (link_libs)
    set(link_libs_more "")
    set(link_libs_recur "")

    foreach(link_lib IN LISTS link_libs)
      if (TARGET ${link_lib})
        tkl_get_target_link_libraries_recursively_impl(${next_nest_counter} link_libs_recur ${link_lib})
        if (link_libs_recur)
          list(APPEND link_libs_more ${link_libs_recur})
          list(REMOVE_DUPLICATES link_libs_more)
        endif()
        #message("    target=`${link_lib}`; nest_counter=`${nest_counter}`; link_libs_recur=`${link_libs_recur}`")
      endif()
    endforeach()

    list(APPEND link_libs ${link_libs_more})
    list(REMOVE_DUPLICATES link_libs)

    set(${out_var_name} ${link_libs} PARENT_SCOPE)
  else()
    set(${out_var_name} "" PARENT_SCOPE)
  endif()

  #message("    target=`${target}`; nest_counter=`${nest_counter}`; link_libs_more=`${link_libs_more}`")
endfunction()

function(tkl_add_target_subdirectory target_root_dir_var target target_binary_root)
  tkl_is_var(is_target_root_dir_var ${target_root_dir_var})
  if (NOT is_target_root_dir_var)
    #message(FATAL_ERROR "`${target_root_dir_var}` must be a variable")
    return()
  endif()

  if (TARGET ${target})
    # TODO:
    #   `${target_root_dir_var}` must be the same path where the target located, otherwise this can be not the same target and we must throw an error!
    #
    return() # ignore if already added from common ancestor subdirectory
  endif()

  # Now ARGx built-in variables would be related to the function parameters
  # list instead of the upper caller context which might have has
  # different/shifted parameters list, so now we have to propagate all
  # changed variables (except the builtins) into upper context by ourselves!
  tkl_track_vars_begin()

  tkl_add_target_subdirectory_invoker("${${target_root_dir_var}}" "${target_binary_root}")

  tkl_forward_changed_vars_to_parent_scope()
  tkl_track_vars_end()
endfunction()

function(tkl_print_flags)
  if(ARGN)
    foreach(flag_var IN LISTS ARGN)
      if(${flag_var})
        message(STATUS "* ${flag_var}=`${${flag_var}}`")
      else()
        message(STATUS "* ${flag_var}=``")
      endif()
    endforeach()
  else()
    message(FATAL_ERROR "ARGN must be defined and not empty")
  endif()
endfunction()

function(tkl_print_global_flags)
  tkl_parse_config_names_list_var(".;${ARGN}" config_types has_all_config_types has_default_config_type)

  foreach(flag_var
          CMAKE_CXX_FLAGS CMAKE_EXE_LINKER_FLAGS CMAKE_MODULE_LINKER_FLAGS
          CMAKE_STATIC_LINKER_FLAGS CMAKE_SHARED_LINKER_FLAGS)
    foreach(config_type IN LISTS config_types)
      if("${config_type}" STREQUAL ".")
        set(config_type_suffix "")
      else()
        string(TOUPPER "_${config_type}" config_type_suffix)
      endif()

      tkl_print_flags(${flag_var}${config_type_suffix})
    endforeach()
  endforeach()
endfunction()

function(tkl_set_target_folder target_root_dir_var package_target_rel_path_pattern
         target_pattern_include_list target_pattern_exclude_list
         target_type_include_list target_type_exclude_list folder_path)
  tkl_set_target_property("${target_root_dir_var}" "${package_target_rel_path_pattern}"
    ${target_pattern_include_list} ${target_pattern_exclude_list}
    "${target_type_include_list}" "${target_type_exclude_list}"
    FOLDER "${folder_path}")
endfunction()

function(tkl_set_target_property target_root_dir_var package_target_rel_path_pattern
         target_pattern_include_list target_pattern_exclude_list
         target_type_include_list target_type_exclude_list
         property_type property_value)
  tkl_is_var(is_target_root_dir_var ${target_root_dir_var})
  if (NOT is_target_root_dir_var)
    #message(FATAL_ERROR "`${target_root_dir_var}` must be a variable")
    return()
  endif()

  set(target_root_dir ${${target_root_dir_var}})

  if (NOT IS_DIRECTORY "${target_root_dir}")
    message(FATAL_ERROR "`${target_root_dir_var}` must be existing directory path variable: ${target_root_dir_var}=`${target_root_dir}`")
  endif()

  if("${package_target_rel_path_pattern}" STREQUAL "")
    message(FATAL_ERROR "package target relative path pattern must not be empty")
  endif()

  get_filename_component(target_root_dir_abs ${target_root_dir} ABSOLUTE)

  string(TOLOWER "${target_root_dir_abs}" target_root_dir_path_abs_lower)

  tkl_get_global_targets_list(targets_list)

  foreach(target IN LISTS targets_list)
    # ignore all aliases because of read only
    get_target_property(target_origin ${target} ALIASED_TARGET)
    if (target_origin)
      continue()
    endif()

    set(is_target_applied 1)

    # target exclude by pattern
    foreach (target_to_exclude IN LISTS target_pattern_exclude_list)
      if (NOT "${target_to_exclude}" STREQUAL "" AND NOT "${target_to_exclude}" STREQUAL "." AND
          ${target} MATCHES ${target_to_exclude})
        set(is_target_applied 0)
        break()
      endif()
    endforeach()

    if (NOT is_target_applied)
      continue()
    endif()

    # target include by pattern
    set(is_target_applied 0)
    foreach (target_to_include IN LISTS target_pattern_include_list)
      # check on invalid include sequences at first
      if ("${target_to_include}" STREQUAL ".")
        message(FATAL_ERROR "target include pattern should not contain sequences related ONLY to the exclude patterns: target_to_include=`${target_to_include}`")
      endif()

      if ("${target_to_include}" STREQUAL "*")
        set(is_target_applied 1)
        break()
      elseif(${target} MATCHES ${target_to_include}) # should not be linked by OR with previous condition, otherwise compilation error
        set(is_target_applied 1)
        break()
      endif()
    endforeach()

    if (NOT is_target_applied)
      continue()
    endif()

    get_target_property(target_type ${target} TYPE)

    #message("** TYPE: `${target_type}` TARGET: `${target}`")

    # avoid error: INTERFACE_LIBRARY targets may only have whitelisted properties.
    if("${target_type}" STREQUAL "INTERFACE_LIBRARY")
      continue()
    endif()

    set(is_target_type_applied 0)

    foreach (target_type_to_include IN LISTS target_type_include_list)
      # check on invalid include sequences at first
      if ("${target_type_to_include}" STREQUAL ".")
        message(FATAL_ERROR "target type include pattern should not contain sequences related ONLY to the exclude patterns: target_type_to_include=`${target_type_to_include}`")
      endif()

      if (("${target_type_to_include}" STREQUAL "*") OR ("${target_type_to_include}" STREQUAL "${target_type}"))
        set(is_target_type_applied 1)
        foreach (target_type_to_exclude IN LISTS target_type_exclude_list)
          if (NOT "${target_type_to_exclude}" STREQUAL "" AND NOT "${target_type_to_exclude}" STREQUAL "." AND
              "${target_type_to_exclude}" STREQUAL "${target_type}")
            set(is_target_type_applied 0)
            break()
          endif()
        endforeach()
        if (is_target_type_applied)
          break()
        endif()
      endif()
    endforeach()

    if (NOT is_target_type_applied)
      continue()
    endif()

    get_target_property(package_root_dir ${target} PACKAGE_SOURCE_DIR)
    if (package_root_dir)
      string(TOLOWER "${package_root_dir}" package_root_dir_lower)

      tkl_subtract_absolute_paths(${package_root_dir_lower} ${target_root_dir_path_abs_lower} package_target_rel_path_dir)
      #message("  target=`${target}`\n   package_root_dir_lower=`${package_root_dir_lower}`\n   target_root_dir_path_abs_lower=`${target_root_dir_path_abs_lower}`\n   package_target_rel_path_dir=`${package_target_rel_path_dir}`\n   package_target_rel_path_pattern=`${package_target_rel_path_pattern}`\n")

      if (NOT "${package_target_rel_path_dir}" STREQUAL "")
        if("${package_target_rel_path_pattern}" STREQUAL ".") # special pattern means "equal to package source directory" or "not recursively from package source directory"
          if("${package_target_rel_path_dir}" STREQUAL "${package_target_rel_path_pattern}")
            set_target_properties(${target} PROPERTIES ${property_type} ${property_value})
            #message("  set_target_properties(${target} PROPERTIES ${property_type} ${property_value})\n")
          endif()
        elseif("${package_target_rel_path_pattern}" STREQUAL "*") # special pattern means "any"
          set_target_properties(${target} PROPERTIES ${property_type} ${property_value})
          #message("  set_target_properties(${target} PROPERTIES ${property_type} ${property_value})\n")
        elseif(package_target_rel_path_dir MATCHES ${package_target_rel_path_pattern})
          set_target_properties(${target} PROPERTIES ${property_type} ${property_value})
          #message("  set_target_properties(${target} PROPERTIES ${property_type} ${property_value})\n")
        endif()
      endif()
    endif()
  endforeach()
endfunction()

function(tkl_make_build_output_dir_vars build_type is_multi_config)
  if (NOT "${build_type}" STREQUAL "")
    set(CMAKE_BUILD_DIR "${CMAKE_BUILD_ROOT}/${build_type}" PARENT_SCOPE)
    set(CMAKE_BIN_DIR "${CMAKE_BIN_ROOT}/${build_type}" PARENT_SCOPE)
    set(CMAKE_LIB_DIR "${CMAKE_LIB_ROOT}/${build_type}" PARENT_SCOPE)
    set(CMAKE_PACK_DIR "${CMAKE_PACK_ROOT}/${build_type}" PARENT_SCOPE)
  else()
    if (NOT is_multi_config)
      message(FATAL_ERROR "CMAKE_BUILD_TYPE must be set for not multiconfig generator")
    endif()
    set(CMAKE_BUILD_DIR "${CMAKE_BUILD_ROOT}" PARENT_SCOPE)
    set(CMAKE_BIN_DIR "${CMAKE_BIN_ROOT}" PARENT_SCOPE)
    set(CMAKE_LIB_DIR "${CMAKE_LIB_ROOT}" PARENT_SCOPE)
    set(CMAKE_PACK_DIR "${CMAKE_PACK_ROOT}" PARENT_SCOPE)
  endif()
endfunction()

function(tkl_make_build_output_dirs build_type is_multi_config)
  get_filename_component(CMAKE_OUTPUT_ROOT_DIR ${CMAKE_OUTPUT_ROOT} DIRECTORY)
  if (NOT EXISTS "${CMAKE_OUTPUT_ROOT_DIR}")
    message(FATAL_ERROR "parent directory of the CMAKE_OUTPUT_ROOT does not exist `${CMAKE_OUTPUT_ROOT}`")
  endif()

  file(MAKE_DIRECTORY "${CMAKE_OUTPUT_ROOT}")

  if (DEFINED CMAKE_OUTPUT_GENERATOR_DIR)
    get_filename_component(CMAKE_OUTPUT_PARENT_DIR ${CMAKE_OUTPUT_GENERATOR_DIR} DIRECTORY)
    if (NOT EXISTS "${CMAKE_OUTPUT_PARENT_DIR}")
      message(FATAL_ERROR "parent directory of the CMAKE_OUTPUT_GENERATOR_DIR does not exist `${CMAKE_OUTPUT_GENERATOR_DIR}`")
    endif()

    file(MAKE_DIRECTORY "${CMAKE_OUTPUT_GENERATOR_DIR}")
  endif()

  get_filename_component(CMAKE_OUTPUT_PARENT_DIR ${CMAKE_OUTPUT_DIR} DIRECTORY)
  if (NOT EXISTS "${CMAKE_OUTPUT_PARENT_DIR}")
    message(FATAL_ERROR "parent directory of the CMAKE_OUTPUT_DIR does not exist `${CMAKE_OUTPUT_DIR}`")
  endif()

  file(MAKE_DIRECTORY "${CMAKE_OUTPUT_DIR}")

  file(MAKE_DIRECTORY "${CMAKE_BUILD_ROOT}")
  file(MAKE_DIRECTORY "${CMAKE_BIN_ROOT}")
  file(MAKE_DIRECTORY "${CMAKE_LIB_ROOT}")
  file(MAKE_DIRECTORY "${CMAKE_INSTALL_ROOT}")
  file(MAKE_DIRECTORY "${CMAKE_PACK_ROOT}")

  get_filename_component(CMAKE_BUILD_PARENT_DIR ${CMAKE_BUILD_DIR} DIRECTORY)
  if (NOT EXISTS "${CMAKE_BUILD_PARENT_DIR}")
    message(FATAL_ERROR "parent directory of the CMAKE_BUILD_DIR does not exist `${CMAKE_BUILD_DIR}`")
  endif()

  get_filename_component(CMAKE_BIN_PARENT_DIR ${CMAKE_BIN_DIR} DIRECTORY)
  if (NOT EXISTS "${CMAKE_BIN_PARENT_DIR}")
    message(FATAL_ERROR "parent directory of the CMAKE_BIN_DIR does not exist `${CMAKE_BIN_DIR}`")
  endif()

  get_filename_component(CMAKE_LIB_PARENT_DIR ${CMAKE_LIB_DIR} DIRECTORY)
  if (NOT EXISTS "${CMAKE_LIB_PARENT_DIR}")
    message(FATAL_ERROR "parent directory of the CMAKE_LIB_DIR does not exist `${CMAKE_LIB_DIR}`")
  endif()

  get_filename_component(CMAKE_INSTALL_ROOT_DIR ${CMAKE_INSTALL_ROOT} DIRECTORY)
  if (NOT EXISTS "${CMAKE_INSTALL_ROOT_DIR}")
    message(FATAL_ERROR "parent directory of the CMAKE_INSTALL_ROOT does not exist `${CMAKE_INSTALL_ROOT}`")
  endif()

  get_filename_component(CMAKE_PACK_PARENT_DIR ${CMAKE_PACK_DIR} DIRECTORY)
  if (NOT EXISTS "${CMAKE_PACK_PARENT_DIR}")
    message(FATAL_ERROR "parent directory of the CMAKE_PACK_DIR does not exist `${CMAKE_PACK_DIR}`")
  endif()

  file(MAKE_DIRECTORY "${CMAKE_BUILD_DIR}")
  file(MAKE_DIRECTORY "${CMAKE_BIN_DIR}")
  file(MAKE_DIRECTORY "${CMAKE_LIB_DIR}")
  file(MAKE_DIRECTORY "${CMAKE_PACK_DIR}")

  if (NOT "${build_type}" STREQUAL "")
    file(WRITE "${CMAKE_BUILD_ROOT}/singleconfig.tag" "")
  elseif (is_multi_config)
    file(WRITE "${CMAKE_BUILD_ROOT}/multiconfig.tag" "")
  endif()
endfunction()

function(tkl_update_CMAKE_CONFIGURATION_TYPES_from config_types do_advance_out_vars)
  if ("${config_types}" STREQUAL "")
    message(FATAL_ERROR "config_types must not be empty")
  endif()

  if (NOT DEFINED TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
    message(FATAL_ERROR "TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL is not defined")
  endif()
  if (NOT DEFINED GENERATOR_IS_MULTI_CONFIG)
    message(FATAL_ERROR "GENERATOR_IS_MULTI_CONFIG is not set")
  endif()
  if (NOT CMAKE_CONFIG_TYPES)
    message(FATAL_ERROR "CMAKE_CONFIG_TYPES is not set")
  endif()

  if (GENERATOR_IS_MULTI_CONFIG)
    # reuse default description
    get_property(desc CACHE "CMAKE_CONFIGURATION_TYPES" PROPERTY HELPSTRING)

    if (NOT TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
      if (NOT "${CMAKE_CONFIG_TYPES}" STREQUAL "${CMAKE_CONFIGURATION_TYPES}")
        # override CMAKE_CONFIGURATION_TYPES
        set(CMAKE_CONFIGURATION_TYPES_OLD "${CMAKE_CONFIGURATION_TYPES}")

        set(CMAKE_CONFIGURATION_TYPES_TO_ADVANCE "${CMAKE_CONFIG_TYPES}")
        list(REMOVE_ITEM CMAKE_CONFIGURATION_TYPES_TO_ADVANCE ${CMAKE_CONFIGURATION_TYPES})

        # double set with CACHE FORCE is required to update the change properly
        set(CMAKE_CONFIGURATION_TYPES "${CMAKE_CONFIG_TYPES}" CACHE STRING "${desc}" FORCE)
        set(CMAKE_CONFIGURATION_TYPES "${CMAKE_CONFIG_TYPES}" PARENT_SCOPE)
        set(CMAKE_CONFIGURATION_TYPES "${CMAKE_CONFIG_TYPES}")

        # advance ONLY is has non standard configurations
        if (do_advance_out_vars OR CMAKE_CONFIGURATION_TYPES_TO_ADVANCE)
          mark_as_advanced(CMAKE_CONFIGURATION_TYPES)
        endif()

        if (CMAKE_CONFIGURATION_TYPES_TO_ADVANCE)
          message(STATUS "(*) variable update: CMAKE_CONFIGURATION_TYPES: `${CMAKE_CONFIGURATION_TYPES_OLD}` -> `${CMAKE_CONFIGURATION_TYPES}` (advanced: +`${CMAKE_CONFIGURATION_TYPES_TO_ADVANCE}`)")
        else()
          message(STATUS "(*) variable update: CMAKE_CONFIGURATION_TYPES: `${CMAKE_CONFIGURATION_TYPES_OLD}` -> `${CMAKE_CONFIGURATION_TYPES}` (overriden)")
        endif()
      endif()
    else()
      if (NOT "${CMAKE_CONFIG_TYPES}" STREQUAL "${CMAKE_CONFIGURATION_TYPES}")
        message(FATAL_ERROR "Only a top level project can change project configuration list: CMAKE_CONFIGURATION_TYPES=`${CMAKE_CONFIGURATION_TYPES}` CMAKE_CONFIG_TYPES=`${CMAKE_CONFIG_TYPES}`")
      endif()
    endif()
  endif()
endfunction()

function(tkl_register_package_var_set package_root_dir_var var_name var_value inheritable_var)
  tkl_is_var(is_package_root_dir_var ${package_root_dir_var})
  if (NOT is_package_root_dir_var)
    #message(FATAL_ERROR "$`{package_root_dir_var}` must be a variable")
    return()
  endif()

  set(package_root_dir "${${package_root_dir_var}}")
  if (NOT IS_DIRECTORY "${package_root_dir}")
    message(FATAL_ERROR "Package root diretory path does not exist: package_root_dir_var=`${package_root_dir_var}` package_root_dir=`${package_root_dir}`")
  endif()

  get_filename_component(package_root_dir ${package_root_dir} ABSOLUTE)

  tkl_register_context_var_set("tkl_register_package_var" "${package_root_dir}" "${var_name}" "${var_value}" "${inheritable_var}")
endfunction()

function(tkl_unregister_package_var package_root_dir_var var_name var_value)
  tkl_is_var(is_package_root_dir_var ${package_root_dir_var})
  if (NOT is_package_root_dir_var)
    #message(FATAL_ERROR "`${package_root_dir_var}` must be a variable")
    return()
  endif()

  set(package_root_dir "${${package_root_dir_var}}")
  if (NOT IS_DIRECTORY "${package_root_dir}")
    message(FATAL_ERROR "Package root diretory path does not exist: package_root_dir_var=`${package_root_dir_var}` package_root_dir=`${package_root_dir}`")
  endif()

  get_filename_component(package_root_dir ${package_root_dir} ABSOLUTE)

  tkl_unregister_context_var("tkl_register_package_var" "${package_root_dir}" "${var_name}")
endfunction()

endif()
