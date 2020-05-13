cmake_minimum_required(VERSION 3.7)

# at least cmake 3.7 is required for:
# * to request source directory path from target:
#   `get_target_property(FOO_SOURCE_DIR Foo SOURCE_DIR)`
# * to request BUILDSYSTEM_TARGETS property from a directory.
#

# at least cmake 3.3 is required for:
# * to use IN_LIST in if command: (https://cmake.org/cmake/help/v3.3/command/if.html )
#   `if(<variable|string> IN_LIST <variable>)`
#

###############################################################################
## cmake policy change ########################################################
###############################################################################

#if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "X.Y.Z")
#  #  Policy CMP00NN is not set: ...
#  #
#  #  ...
#  cmake_policy(SET CMP00NN NEW) # cmake >= X.Y
#endif()

if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.12.0")
  #  Policy CMP0075 is not set: Include file check macros honor
  #  CMAKE_REQUIRED_LIBRARIES.  Run "cmake --help-policy CMP0075" for policy
  #  details.  Use the cmake_policy command to set the policy and suppress this
  #  warning.
  #
  #  CMAKE_REQUIRED_LIBRARIES is set to:
  #
  #    .../_3dparty/arc/xz/lib/Release/Win32/liblzma/liblzma.lib
  #
  #  For compatibility with CMake 3.11 and below this check is ignoring it.

  # use global override to avoid policy drop in case where a 3dparty cmake list declared cmake version requirement less than 3.12.0
  set(CMAKE_POLICY_DEFAULT_CMP0075 NEW)
  #cmake_policy(SET CMP0075 NEW) # cmake >= 3.12
endif()

# enable project folders
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

###############################################################################
## cmake builtin search paths and includes ####################################
###############################################################################

LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake;${CMAKE_CURRENT_LIST_DIR}/cmake/tacklelib/_3dparty/modules")

# cmake extension variables, must be before the first include
#set(TACKLELIB_ENABLE_TARGETS_EXTENSION_FUNCTION_HANDLERS 1) # 0 - macro handlers, faster; 1 - function handlers, slower

include(tacklelib/Project)
include(tacklelib/EnableTargetsExtension)
include(tacklelib/_3dparty/Qt)

###############################################################################
## builtin detection ##########################################################
###############################################################################

## CAUTION:
##   Must be called before the `project(...)` to workaround the error:
##   `CMake Error: CMake was unable to find a build program corresponding to "MinGW Makefiles".  CMAKE_MAKE_PROGRAM is not set.  You probably need to select a different build tool.`
##   by declare respective variable BEFORE the project main initialization.
##
#tkl_preload_variables(-S -s "${CMAKE_CURRENT_LIST_DIR}/_config/environment_system.vars" "CMAKE_MAKE_PROGRAM" "PATH;CMAKE_MAKE_PROGRAM")

project("tacklelib")

set(PROJECT_LIB_NAME tacklelib)

set(LIB_TARGET_NAME ${PROJECT_LIB_NAME})
set(TESTLIB_TARGET_NAME ${PROJECT_NAME}.testlib)

tkl_configure_environment("${CMAKE_CURRENT_LIST_DIR}/_config" "${TACKLELIB_LINK_TYPE}" "MSVC;GCC")

###############################################################################
## check environment variables ################################################
###############################################################################

tkl_check_var(REQUIRED . TACKLELIB_ADDRESS_MODEL)
tkl_check_var(REQUIRED . TACKLELIB_LINK_TYPE)
tkl_check_var(REQUIRED . TACKLELIB_DEP_LIBS)

tkl_check_var(REQUIRED PATH _3DPARTY_LOCAL_ROOT)

tkl_check_var(OPTIONAL PATH CMAKE_LIBRARY_PATH)
tkl_check_var(OPTIONAL PATH NSIS_INSTALL_ROOT)

# multi

tkl_check_var(REQUIRED PATH BOOST_ROOT)
tkl_check_var(REQUIRED . Boost_ARCHITECTURE) # required for boost 1.66 and higher: https://gitlab.kitware.com/cmake/cmake/merge_requests/2568
tkl_check_var(REQUIRED STRING BOOST_COMPONENTS)

# utility

tkl_check_var(REQUIRED PATH UTILITY_FMT_ROOT)
tkl_check_var(OPTIONAL PATH UTILITY_PYSTRING_ROOT)

# math

tkl_check_var(OPTIONAL PATH QD_ROOT)
tkl_check_var(OPTIONAL . ENABLE_QD_INTEGRATION)
tkl_check_var(OPTIONAL . ENABLE_QD_QD_INTEGRATION)
tkl_check_var(OPTIONAL . ENABLE_QD_DD_INTEGRATION)

# log

tkl_check_var(OPTIONAL PATH LOG_P7_CLIENT_ROOT)

# arc

tkl_check_var(OPTIONAL PATH ARC_LIBARCHIVE_ROOT)
tkl_check_var(OPTIONAL . ENABLE_LZMA)
tkl_check_var(OPTIONAL . ENABLE_TAR)
tkl_check_var(OPTIONAL . ENABLE_CPIO)
tkl_check_var(OPTIONAL . ENABLE_CAT)
tkl_check_var(OPTIONAL . ENABLE_TEST)
tkl_check_var(OPTIONAL . ENABLE_COVERAGE)
tkl_check_var(OPTIONAL . ENABLE_INSTALL)

tkl_check_var(OPTIONAL PATH ARC_XZ_UTILS_ROOT)
tkl_check_var(OPTIONAL PATH LIBLZMA_INCLUDE_DIR)
tkl_check_var(OPTIONAL PATH LIBLZMA_LIBRARY)
tkl_check_var(OPTIONAL . LIBLZMA_HAS_AUTO_DECODER)
tkl_check_var(OPTIONAL . LIBLZMA_HAS_EASY_ENCODER)
tkl_check_var(OPTIONAL . LIBLZMA_HAS_LZMA_PRESET)

#tkl_check_var(REQUIRED PATH ARC_7ZIP_ROOT)

# tests

tkl_check_var(OPTIONAL PATH GTEST_ROOT)
tkl_check_var(OPTIONAL . TACKLELIB_SKIP_TESTLIB)
tkl_check_var(OPTIONAL . TACKLELIB_SKIP_TESTS)

# WORKAROUND:
#   The issue:
#   `CMakeLists.txt tries to override globally visible CMAKE_BUILD_TYPE through the cache` :
#   https://github.com/libarchive/libarchive/issues/1163
#
tkl_register_package_var_set(ARC_LIBARCHIVE_ROOT CMAKE_BUILD_TYPE Release 0)

###############################################################################
## projects description #######################################################
###############################################################################

set(UNIT_TESTS_MAXOPT_TARGET_NAME tacklelib.unit_tests)           # maximal compiler optimization, custom optimization
set(UNIT_TESTS_DEFOPT_TARGET_NAME tacklelib.unit_tests_defopt)    # default compiler optimization, no custom optimization

# maximal compiler optimization, custom optimization, referenced project statically linked as library instead as sources
# (even more faster runtime because without unit test asserts from library)
set(UNIT_TESTS_LIBLINKED_TARGET_NAME tacklelib.unit_tests_liblinked)

set(BENCH_TESTS_MAXOPT_TARGET_NAME tacklelib.bench_tests)         # maximal compiler optimization, custom optimization
set(BENCH_TESTS_DEFOPT_TARGET_NAME tacklelib.bench_tests_defopt)  # default compiler optimization, no custom optimization

set(TESTS_TARGET_NAMES
  ${UNIT_TESTS_LIBLINKED_TARGET_NAME};
  ${UNIT_TESTS_MAXOPT_TARGET_NAME};${BENCH_TESTS_MAXOPT_TARGET_NAME};
  ${UNIT_TESTS_DEFOPT_TARGET_NAME};${BENCH_TESTS_DEFOPT_TARGET_NAME})

# common optimization targets
set(COMMON_OPT_APP_TARGET_NAMES
  ${LIB_TARGET_NAME};${TESTLIB_TARGET_NAME};${TACKLELIB_DEP_LIBS})

set(TESTS_TARGETS_SRC_DIR
  unit;
  unit;bench;
  unit;bench)

#set(TESTS_TARGETS_PCH_SRC_DIR
#  unit/liblinked;
#  unit/maxopt;bench/maxopt;
#  unit/defopt;bench/defopt)

set(TESTS_TARGETS_DEFINITIONS
  "UNIT_TESTS\;MAXOPT\;LIBLINKED"
  "UNIT_TESTS\;MAXOPT" "BENCH_TESTS\;MAXOPT\;LIBLINKED" # all bench tests always liblinked
  "UNIT_TESTS\;DEFOPT" "BENCH_TESTS\;DEFOPT\;LIBLINKED")

# targets with maximal optimization
set(TESTS_MAXOPT_TARGETS
  ${UNIT_TESTS_LIBLINKED_TARGET_NAME};
  ${UNIT_TESTS_MAXOPT_TARGET_NAME};${BENCH_TESTS_MAXOPT_TARGET_NAME})

# targets with library project linkage
set(TESTS_TARGETS_LIBLINKED
  1;
  0;1
  0;1)

# enable c++ standard usage for all targets, basically to avoid the default `--std=gnu++11` parameter for the GCC compiler
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

###############################################################################
## file globbing ##############################################################
###############################################################################

# public headers ONLY

file(GLOB_RECURSE public_headers
  ${CMAKE_CURRENT_LIST_DIR}/include/*.h*
)

# library

file(GLOB_RECURSE lib_headers
  ${CMAKE_CURRENT_LIST_DIR}/src/*.h*
)
file(GLOB_RECURSE lib_sources
  ${CMAKE_CURRENT_LIST_DIR}/src/*.c*
)

# testlib

file(GLOB_RECURSE testlib_headers
  ${CMAKE_CURRENT_LIST_DIR}/src/testlib/*.h*
)
file(GLOB_RECURSE testlib_sources
  ${CMAKE_CURRENT_LIST_DIR}/src/testlib/*.c*
)

# tests

file(GLOB tests_sources_common
  ${CMAKE_CURRENT_LIST_DIR}/src/tests/*.c*
)
file(GLOB tests_headers_common
  ${CMAKE_CURRENT_LIST_DIR}/src/tests/*.h*
)

# exclude tests
tkl_exclude_paths_from_path_list(. lib_sources "${lib_sources}" "/tests" 0)
tkl_exclude_paths_from_path_list(. lib_headers "${lib_headers}" "/tests" 0)

# exclude testlib
tkl_exclude_paths_from_path_list(. lib_sources "${lib_sources}" "/testlib" 0)
tkl_exclude_paths_from_path_list(. lib_headers "${lib_headers}" "/testlib" 0)

set(target_index 0)
foreach(target IN LISTS TESTS_TARGET_NAMES)
  list(GET TESTS_TARGETS_SRC_DIR ${target_index} target_src_dir)

  file(GLOB_RECURSE tests_sources_${target}
    ${CMAKE_CURRENT_LIST_DIR}/src/tests/${target_src_dir}/*.c*)
  file(GLOB_RECURSE tests_headers_${target}
    ${CMAKE_CURRENT_LIST_DIR}/src/tests/${target_src_dir}/*.h*)

  # exclude marked as "out of project" (/~) files/directories by pattern
  tkl_exclude_paths_from_path_list(. tests_sources_${target} "${tests_sources_${target}}" "/~" 0)
  tkl_exclude_paths_from_path_list(. tests_headers_${target} "${tests_headers_${target}}" "/~" 0)

  MATH(EXPR target_index "${target_index}+1")
endforeach()

###############################################################################
## find_package dependencies #######################################################
###############################################################################

# boost

if (TACKLELIB_LINK_TYPE STREQUAL "dynamic")
  set(Boost_USE_STATIC_LIBS OFF)
  set(Boost_USE_STATIC_RUNTIME OFF)
  set(Boost_USE_MULTITHREADED ON)
elseif (TACKLELIB_LINK_TYPE STREQUAL "static")
  set(Boost_USE_STATIC_LIBS ON)
  set(Boost_USE_STATIC_RUNTIME ON)
  set(Boost_USE_MULTITHREADED ON)
endif()

find_package(BOOST_ROOT Boost REQUIRED COMPONENTS ${BOOST_COMPONENTS})

if (Boost_FOUND)
  message(STATUS "(*) Found `Boost`: `${Boost_VERSION}` Location: \"${BOOST_ROOT}\" Libs: [${Boost_LIBRARIES}]")
else()
  message(WARNING "(*) Boost is not found")
endif()

# liblzma

if (LIBLZMA_LIBRARY)
  find_package(LIBLZMA_LIBRARY LibLZMA)

  if (LIBLZMA_FOUND)
    message(STATUS "(*) Found `LibLZMA`: `${LIBLZMA_VERSION_STRING}` IncludeDirs: [${LIBLZMA_INCLUDE_DIRS}] Libs: [${LIBLZMA_LIBRARIES}]")
  else()
    message(WARNING "(*) LibLZMA is not found")
  endif()
endif()

###############################################################################
## add_subdirectory dependencies ##############################################
###############################################################################

# test

set(TESTLIB_ENABLED 0)
set(TESTS_ENABLED 0)
if (GTEST_ROOT AND NOT (TACKLELIB_SKIP_TESTLIB AND TACKLELIB_SKIP_TESTS))
  if (MSVC)
    if (TACKLELIB_LINK_TYPE STREQUAL "dynamic")
      set(GTEST_MSVC_SEARCH "MD") # if by `find_package`
      set(BUILD_SHARED_LIBS ON)   # if by `add_subdirectory`
    elseif (TACKLELIB_LINK_TYPE STREQUAL "static")
      set(GTEST_MSVC_SEARCH "MT") # if by `find_package`
      set(BUILD_SHARED_LIBS OFF)  # if by `add_subdirectory`
    endif()
  elseif (GCC)
    # nothing is required
  endif()

  #find_package(GTest)

  #if (GTEST_FOUND AND NOT TACKLELIB_SKIP_TESTLIB)
  if (NOT TACKLELIB_SKIP_TESTLIB)
    set(TESTLIB_ENABLED 1)
  endif()

  # automatic tests enable by specific source file
  #if (GTEST_FOUND AND NOT TACKLELIB_SKIP_TESTS)
  if (NOT TACKLELIB_SKIP_TESTS)
    set(tests_sources_common_filtered ${tests_sources_common})
    if (tests_sources_common_filtered)
      list(FILTER tests_sources_common_filtered EXCLUDE REGEX "(.*)/test_main.cpp")
      if (NOT "${tests_sources_common_filtered}" EQUAL "${tests_sources_common}")
        tkl_add_target_subdirectory(GTEST_ROOT gtest ${CMAKE_BUILD_ROOT}/_3dparty/test/googletest)
        set(TESTS_ENABLED 1)
      endif()
    endif()
  endif()
endif()

# fmt

tkl_add_target_subdirectory(UTILITY_FMT_ROOT fmt ${CMAKE_BUILD_ROOT}/_3dparty/utility/fmt)

# fmt has it's own cmake list, so we have to call it from here
tkl_initialize_library_target_defaults(fmt "${TACKLELIB_ADDRESS_MODEL}bit")

# pystring

tkl_add_target_subdirectory(UTILITY_PYSTRING_ROOT pystring ${CMAKE_BUILD_ROOT}/_3dparty/utility/pystring)

# p7 logger

tkl_add_target_subdirectory(LOG_P7_CLIENT_ROOT p7client ${CMAKE_BUILD_ROOT}/_3dparty/log/p7client)

if (TARGET p7client)
  get_target_property(INCLUDE_DIRS_p7client p7client INCLUDE_DIRECTORIES)
  get_target_property(LIBRARIES_p7client p7client LINK_LIBRARIES)
endif()

# 7zip

tkl_add_target_subdirectory(ARC_7ZIP_ROOT 7zip ${CMAKE_BUILD_ROOT}/_3dparty/arc/7zip)

if (TARGET 7zip)
  get_target_property(INCLUDE_DIRS_7zip 7zip INCLUDE_DIRECTORIES)
  get_target_property(LIBRARIES_7zip 7zip LINK_LIBRARIES)
endif()

# libarchive

tkl_add_target_subdirectory(ARC_LIBARCHIVE_ROOT libarchive ${CMAKE_BUILD_ROOT}/_3dparty/arc/libarchive)

tkl_set_target_property(ARC_LIBARCHIVE_ROOT * * "^archive$$|^archive_static$$" *  . EXCLUDE_FROM_DEFAULT_BUILD ON) # all except output libraries
tkl_set_target_property(ARC_LIBARCHIVE_ROOT * * "^archive$$|^archive_static$$" *  . EXCLUDE_FROM_ALL ON) # all except output libraries

if (TARGET archive)
  tkl_set_target_property(ARC_LIBARCHIVE_ROOT * "^archive$$" . *  . EXCLUDE_FROM_DEFAULT_BUILD ON) # all except output libraries
  tkl_set_target_property(ARC_LIBARCHIVE_ROOT * "^archive$$" . *  . EXCLUDE_FROM_ALL ON) # all except output libraries

  # libarchive has it's own cmake list, so we have to call it from here
  if (TACKLELIB_ADDRESS_MODEL)
    tkl_initialize_library_target_defaults(archive "${TACKLELIB_ADDRESS_MODEL}bit")
  else()
    tkl_initialize_library_target_defaults(archive "")
  endif()
endif()
if (TARGET archive_static)
  # libarchive has it's own cmake list, so we have to call it from here
  if (TACKLELIB_ADDRESS_MODEL)
    tkl_initialize_library_target_defaults(archive_static "${TACKLELIB_ADDRESS_MODEL}bit")
  else()
    tkl_initialize_library_target_defaults(archive_static "")
  endif()
endif()

###############################################################################
## target definitions #########################################################
###############################################################################

# library

add_library(${LIB_TARGET_NAME} STATIC
  ${lib_sources};${lib_headers};${public_headers}
)

tkl_initialize_library_target_defaults(${LIB_TARGET_NAME} "${TACKLELIB_ADDRESS_MODEL}bit")

tkl_source_groups_from_dir_list("Header Files (interface)" FILES ${CMAKE_CURRENT_LIST_DIR}/include *.h*)
tkl_source_groups_from_dir_list("Header Files" FILES ${CMAKE_CURRENT_LIST_DIR}/src *.h*)
tkl_source_groups_from_dir_list("Source Files" FILES ${CMAKE_CURRENT_LIST_DIR}/src *.c*)

target_include_directories(${LIB_TARGET_NAME}
  PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/include
  PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}
)

if (UTILITY_FMT_ROOT)
  target_include_directories(${LIB_TARGET_NAME}
    PUBLIC
      ${UTILITY_FMT_ROOT}/include
  )
endif()

if (UTILITY_PYSTRING_ROOT)
  target_include_directories(${LIB_TARGET_NAME}
    PUBLIC
      ${UTILITY_PYSTRING_ROOT}
  )
endif()

if (Boost_INCLUDE_DIRS)
  target_include_directories(${LIB_TARGET_NAME}
    PRIVATE
      ${Boost_INCLUDE_DIRS}
  )
endif()

if (INCLUDE_DIRS_p7client)
  target_include_directories(${LIB_TARGET_NAME}
    PUBLIC
      ${INCLUDE_DIRS_p7client}
  )
endif()

if (INCLUDE_DIRS_7zip)
  target_include_directories(${LIB_TARGET_NAME}
    PUBLIC
      ${INCLUDE_DIRS_7zip}
  )
endif()

if (ARC_LIBARCHIVE_ROOT)
  target_include_directories(${LIB_TARGET_NAME}
    PUBLIC
      ${ARC_LIBARCHIVE_ROOT}
  )
endif()

if (LIBLZMA_FOUND)
  target_include_directories(${LIB_TARGET_NAME}
    PRIVATE
      ${LIBLZMA_INCLUDE_DIRS}
  )
endif()

# to calculate relative path to source files in log output
tkl_add_target_compile_definitions(${LIB_TARGET_NAME} *
  PRIVATE
    LOG_SRC_ROOT="${LOG_SRC_ROOT}"
)

# to declare export/import from source files
tkl_add_target_compile_definitions(${LIB_TARGET_NAME} *
  PRIVATE
    LIBRARY_API
    LIBRARY_API_EXPORTS_TACKLELIB
)

if (MINGW)
  tkl_add_target_compile_definitions(${LIB_TARGET_NAME} *
    PRIVATE
      MINGW
  )
endif()

# we need the same Boost definitions here to maintain the link with the same libraries
if (Boost_FOUND)
  tkl_add_target_compile_definitions(${LIB_TARGET_NAME} *
    PRIVATE
      BOOST_ALL_NO_LIB                    # Disable auto-linking
      BOOST_SCOPE_EXIT_CONFIG_USE_LAMBDAS # Force to use C++11 lambda functions to implement scope exits.
  )

  if (TACKLELIB_LINK_TYPE STREQUAL "dynamic")
    tkl_add_target_compile_definitions(${LIB_TARGET_NAME} *
      PRIVATE
        BOOST_ALL_DYN_LINK
    )
  endif()
endif()

if (ARC_LIBARCHIVE_ROOT)
  tkl_add_target_compile_definitions(${LIB_TARGET_NAME} *
    PRIVATE
      LIBARCHIVE_STATIC
  )
endif()

if (LIBLZMA_FOUND)
  tkl_add_target_compile_definitions(${LIB_TARGET_NAME} *
    PRIVATE
      LZMA_API_STATIC
  )
endif()

if (WIN32)
  tkl_add_target_compile_definitions(${LIB_TARGET_NAME} *
    PRIVATE
      _X86_ # in case of dynamic library linkage which is required from Windows SDK: `fatal error C1189: #error:  "No Target Architecture"`
  )
endif()

if (Boost_LIBRARY_DIRS)
    tkl_add_target_link_directories(${LIB_TARGET_NAME} *
      PRIVATE
        ${Boost_LIBRARY_DIRS}
    )
endif()

if (UTILITY_FMT_ROOT)
  target_link_libraries(${LIB_TARGET_NAME}
    PUBLIC
      fmt
  )
endif()

if (UTILITY_PYSTRING_ROOT)
  target_link_libraries(${LIB_TARGET_NAME}
    PUBLIC
      pystring
  )
endif()

if (Boost_FOUND)
  target_link_libraries(${LIB_TARGET_NAME}
    PRIVATE
      ${Boost_LIBRARIES}
  )
endif()

if (TARGET p7client)
  target_link_libraries(${LIB_TARGET_NAME}
    PUBLIC
      p7client
  )
endif()

if (TARGET 7zip)
  target_link_libraries(${LIB_TARGET_NAME}
    PUBLIC
      7zip
  )
endif()

if (TARGET archive_static)
  target_link_libraries(${LIB_TARGET_NAME}
    PUBLIC
      archive_static
  )
endif()

if (LIBLZMA_FOUND)
  target_link_libraries(${LIB_TARGET_NAME}
    PRIVATE
      ${LIBLZMA_LIBRARIES}
  )
endif()

if (WIN32)
  target_link_libraries(${LIB_TARGET_NAME}
    PRIVATE
      Mpr
      Netapi32
  )
elseif (UNIX AND NOT APPLE)
  target_link_libraries(${LIB_TARGET_NAME}
    PRIVATE
      ${CMAKE_DL_LIBS}
  )
endif()

# testlib

if (TESTLIB_ENABLED)
  add_library(${TESTLIB_TARGET_NAME} STATIC
    ${testlib_sources};${testlib_headers};${public_headers}
  )

  tkl_initialize_library_target_defaults(${TESTLIB_TARGET_NAME} "${TACKLELIB_ADDRESS_MODEL}bit")

  tkl_source_groups_from_dir_list("Header Files (interface)" FILES ${CMAKE_CURRENT_LIST_DIR}/include *.h*)
  tkl_source_groups_from_dir_list("Header Files" FILES ${CMAKE_CURRENT_LIST_DIR}/src *.h*)
  tkl_source_groups_from_dir_list("Source Files" FILES ${CMAKE_CURRENT_LIST_DIR}/src *.c*)

  target_include_directories(${TESTLIB_TARGET_NAME}
    PRIVATE
      ${CMAKE_CURRENT_LIST_DIR}
    PUBLIC
      ${CMAKE_CURRENT_LIST_DIR}/include
  )

  if (UTILITY_FMT_ROOT)
    target_include_directories(${TESTLIB_TARGET_NAME}
      PUBLIC
        ${UTILITY_FMT_ROOT}/include
    )
  endif()

  if (UTILITY_PYSTRING_ROOT)
    target_include_directories(${TESTLIB_TARGET_NAME}
      PUBLIC
        ${UTILITY_PYSTRING_ROOT}
    )
  endif()

  if (Boost_INCLUDE_DIRS)
    target_include_directories(${TESTLIB_TARGET_NAME}
      PRIVATE
        ${Boost_INCLUDE_DIRS}
    )
  endif()

#  if (GTEST_INCLUDE_DIRS)
#    target_include_directories(${TESTLIB_TARGET_NAME}
#      PUBLIC
#        ${GTEST_INCLUDE_DIRS}
#    )
#  endif()

  tkl_add_target_compile_definitions(${TESTLIB_TARGET_NAME} *
    PUBLIC
      TACKLE_TESTLIB
      GTEST_LINKED_AS_SHARED_LIBRARY=1 # gtest links as dynamic by default
  )

  if (MINGW)
    tkl_add_target_compile_definitions(${TESTLIB_TARGET_NAME} *
      PRIVATE
        MINGW
    )
  endif()

  # we need the same Boost definitions here to maintain the link with the same libraries
  if (Boost_FOUND)
    tkl_add_target_compile_definitions(${TESTLIB_TARGET_NAME} *
      PRIVATE
        BOOST_ALL_NO_LIB                    # Disable auto-linking
        BOOST_SCOPE_EXIT_CONFIG_USE_LAMBDAS # Force to use C++11 lambda functions to implement scope exits.
    )

    if (TACKLELIB_LINK_TYPE STREQUAL "dynamic")
      tkl_add_target_compile_definitions(${TESTLIB_TARGET_NAME} *
        PRIVATE
          BOOST_ALL_DYN_LINK
      )
    endif()
  endif()

  if (WIN32)
    tkl_add_target_compile_definitions(${TESTLIB_TARGET_NAME} *
      PRIVATE
        _X86_ # in case of dynamic library linkage which is required from Windows SDK: `fatal error C1189: #error:  "No Target Architecture"`
    )
  endif()

  if (Boost_LIBRARY_DIRS)
    tkl_add_target_link_directories(${TESTLIB_TARGET_NAME} *
      PRIVATE
        ${Boost_LIBRARY_DIRS}
    )
  endif()

#  if (GTEST_ROOT)
#    tkl_add_target_link_directories(${TESTLIB_TARGET_NAME} *
#      PRIVATE
#        ${GTEST_ROOT}/${_gtest_libpath_suffixes}
#    )
#  endif()

  target_link_libraries(${TESTLIB_TARGET_NAME}
    PRIVATE
      ${LIB_TARGET_NAME}
  )

#  if (GTEST_LIBRARIES)
#    target_link_libraries(${TESTLIB_TARGET_NAME}
#      PRIVATE
#        ${GTEST_LIBRARIES}
#    )
#  endif()

  if (TARGET gtest)
    target_link_libraries(${TESTLIB_TARGET_NAME}
      PRIVATE
        gtest
    )
  endif()
else()
  list(REMOVE_ITEM COMMON_OPT_APP_TARGET_NAMES ${TESTLIB_TARGET_NAME})
endif()

###############################################################################
## target optimization ########################################################
###############################################################################

# local optimization per target basis
if (MSVC)
  tkl_add_target_compile_properties("${COMMON_OPT_APP_TARGET_NAMES}" RELEASE
    /Ox     # Full Optimization
    /Ob2    # Inline Function Expansion: Any Suitable
    #/Oi     # Enable Intrinsic Functions
    /Ot     # Enable Intrinsic Functions
    /GL     # Whole Program Optimization
  )
  tkl_add_target_compile_properties("${COMMON_OPT_APP_TARGET_NAMES}" *
    /MP
  )

  tkl_add_target_link_properties("${COMMON_OPT_APP_TARGET_NAMES}" * RELEASE
    /LTCG   # Use Link Time Code Generation
  )
elseif (GCC)
  tkl_add_target_compile_properties("${COMMON_OPT_APP_TARGET_NAMES}" RELEASE
    -O3     # Full Optimization
    #/usr/bin/ranlib: .cpp.o: plugin needed to handle lto object
    #-flto   # Use Link Time Code Generation
  )
  tkl_add_target_compile_properties("${COMMON_OPT_APP_TARGET_NAMES}" *
    -pipe       # Use pipes rather than temporary files for communication between the various stages of compilation.
  )

  #/usr/bin/ranlib: .cpp.o: plugin needed to handle lto object
  #tkl_add_target_link_properties("${COMMON_OPT_APP_TARGET_NAMES}" NOTSTATIC RELEASE
  #  -flto   # Use Link Time Code Generation
  #)
  tkl_add_target_link_properties("${COMMON_OPT_APP_TARGET_NAMES}" NOTSTATIC *
    -pipe   # Use pipes rather than temporary files for communication between the various stages of compilation.
  )
endif()

###############################################################################
## tests ######################################################################
###############################################################################

if (TESTS_ENABLED)
  message(STATUS "(*) Tests build: ${TESTS_TARGET_NAMES} (test_main.cpp).")

  # inherit dependency include directories and libraries
  get_target_property(INTERFACE_COMPILE_DEFINITIONS_${LIB_TARGET_NAME} ${LIB_TARGET_NAME} INTERFACE_COMPILE_DEFINITIONS)
  get_target_property(INCLUDE_DIRS_${LIB_TARGET_NAME} ${LIB_TARGET_NAME} INCLUDE_DIRECTORIES)
  tkl_get_target_link_libraries_recursively(LIBRARIES_${LIB_TARGET_NAME} ${LIB_TARGET_NAME})

  set(target_index 0)
  foreach(target IN LISTS TESTS_TARGET_NAMES)
    list(GET TESTS_TARGET_NAMES ${target_index} target)
    list(GET TESTS_TARGETS_SRC_DIR ${target_index} target_src_dir)
    list(GET TESTS_TARGETS_DEFINITIONS ${target_index} target_definitions)
    list(GET TESTS_TARGETS_LIBLINKED ${target_index} target_is_liblinked)

    set(target_sources_common
      ${tests_sources_common};${tests_headers_common};
      ${tests_sources_${target}};${tests_headers_${target}};
      ${public_headers};${testlib_headers}
    )
    if (target_is_liblinked)
      set(target_sources ${target_sources_common})
    else()
      set(target_sources ${target_sources_common};${lib_sources};${testlib_sources})
    endif()

    #tkl_add_pch_header(
    #  "test_common.hpp" "src/tests/${target_src_dir}/pch.cpp" "pch/${target}/$<CONFIG>/test_common.pch" # create
    #  "test_common.hpp" "src/tests/test_common.hpp" # use + force include
    #  "${tests_sources_${target}}" 0) # input + output

    add_executable(${target}
      ${target_sources}
    )

    tkl_initialize_executable_target_defaults(${target} "${TACKLELIB_ADDRESS_MODEL}bit;console")

    # exclude test_common.cpp from compilation to avoid symbols duplications from pch.cpp
    #set_source_files_properties(src/tests/test_common.cpp PROPERTIES
    #  HEADER_FILE_ONLY TRUE)
    set_source_files_properties(src/tests/unit/pch.cpp PROPERTIES
      HEADER_FILE_ONLY TRUE)
    set_source_files_properties(src/tests/bench/pch.cpp PROPERTIES
      HEADER_FILE_ONLY TRUE)

    tkl_source_groups_from_dir_list("Header Files (interface)" FILES ${CMAKE_CURRENT_LIST_DIR}/include *.h*)
    tkl_source_groups_from_dir_list("Header Files" FILES ${CMAKE_CURRENT_LIST_DIR}/src *.h*)
    tkl_source_groups_from_dir_list("Source Files" FILES ${CMAKE_CURRENT_LIST_DIR}/src *.c*)
    tkl_source_groups_from_dir_list("tests" FILES ${CMAKE_CURRENT_LIST_DIR}/src/tests *)

    target_include_directories(${target}
      PUBLIC
        ${CMAKE_CURRENT_LIST_DIR}/src/tests/${target}
        ${CMAKE_CURRENT_LIST_DIR}/src/tests
    )

    target_include_directories(${target}
      PUBLIC
        ${CMAKE_CURRENT_LIST_DIR}
        ${CMAKE_CURRENT_LIST_DIR}/include
    )

    if (UTILITY_FMT_ROOT)
      target_include_directories(${target}
        PUBLIC
          ${UTILITY_FMT_ROOT}/include
      )
    endif()

    if (UTILITY_PYSTRING_ROOT)
      target_include_directories(${target}
        PUBLIC
          ${UTILITY_PYSTRING_ROOT}
      )
    endif()

    if (Boost_INCLUDE_DIRS)
      target_include_directories(${target}
        PRIVATE
          ${Boost_INCLUDE_DIRS}
      )
    endif()

    if (INCLUDE_DIRS_p7client)
      target_include_directories(${target}
        PUBLIC
          ${INCLUDE_DIRS_p7client}
      )
    endif()

    if (INCLUDE_DIRS_7zip)
      target_include_directories(${target}
        PUBLIC
          ${INCLUDE_DIRS_7zip}
      )
    endif()

    if (ARC_LIBARCHIVE_ROOT)
      target_include_directories(${target}
        PRIVATE
          ${ARC_LIBARCHIVE_ROOT}
      )
    endif()

    if (LIBLZMA_FOUND)
      target_include_directories(${target}
        PRIVATE
          ${LIBLZMA_INCLUDE_DIRS}
      )
    endif()

#    if (GTEST_INCLUDE_DIRS)
#      target_include_directories(${target}
#        PRIVATE
#          ${GTEST_INCLUDE_DIRS}
#      )
#    endif()

    tkl_add_target_compile_definitions(${target} *
      PRIVATE
        ${target_definitions}
    )

    # to calculate relative path to source files in log output
    tkl_add_target_compile_definitions(${target} *
      PRIVATE
        LOG_SRC_ROOT="${LOG_SRC_ROOT}"
    )

    if (MINGW)
      tkl_add_target_compile_definitions(${target} *
        PRIVATE
          MINGW
      )
    endif()

    if (NOT target_is_liblinked)
      # we must include these definitions to link dependency appropriately
      if (ARC_LIBARCHIVE_ROOT)
        tkl_add_target_compile_definitions(${target} *
          PRIVATE
            LIBARCHIVE_STATIC
        )
      endif()

      if (LIBLZMA_FOUND)
        tkl_add_target_compile_definitions(${target} *
          PRIVATE
            LZMA_API_STATIC
        )
      endif()

      if (INTERFACE_COMPILE_DEFINITIONS_${LIB_TARGET_NAME})
        tkl_add_target_compile_definitions(${target} *
          PRIVATE
            ${INTERFACE_COMPILE_DEFINITIONS_${LIB_TARGET_NAME}}
        )
      endif()
    endif()

    # we need the same Boost definitions here to maintain the link with the same libraries
    if (Boost_FOUND)
      tkl_add_target_compile_definitions(${target} *
        PRIVATE
          BOOST_ALL_NO_LIB                    # Disable auto-linking
          BOOST_SCOPE_EXIT_CONFIG_USE_LAMBDAS # Force to use C++11 lambda functions to implement scope exits.
      )

      if (TACKLELIB_LINK_TYPE STREQUAL "dynamic")
        tkl_add_target_compile_definitions(${target} *
          PRIVATE
            BOOST_ALL_DYN_LINK
        )
      endif()
    endif()

    if (WIN32)
      tkl_add_target_compile_definitions(${target} *
        PRIVATE
          _X86_ # in case of dynamic library linkage which is required from Windows SDK: `fatal error C1189: #error:  "No Target Architecture"`
      )
    endif()

    # local optimization per target basis
    if (${target} IN_LIST TESTS_MAXOPT_TARGETS)
      if (MSVC)
        tkl_add_target_compile_properties(${target} RELEASE
          /Ox     # Full Optimization
          /Ob2    # Inline Function Expansion: Any Suitable
          #/Oi     # Enable Intrinsic Functions
          /Ot     # Enable Intrinsic Functions
          /GL     # Whole Program Optimization
        )
        tkl_add_target_compile_properties(${target} *
          /MP
        )

        tkl_add_target_link_properties(${target} * RELEASE
          /LTCG   # Use Link Time Code Generation
        )
      elseif (GCC)
        tkl_add_target_compile_properties(${target} RELEASE
          -O3     # Full Optimization
          #/usr/bin/ranlib: .cpp.o: plugin needed to handle lto object
          #-flto   # Use Link Time Code Generation
        )
        tkl_add_target_compile_properties(${target} *
          -pipe   # Use pipes rather than temporary files for communication between the various stages of compilation.
        )

        #/usr/bin/ranlib: .cpp.o: plugin needed to handle lto object
        #tkl_add_target_link_properties(${target} NOTSTATIC RELEASE
        #  -flto   # Use Link Time Code Generation
        #)
        tkl_add_target_link_properties(${target} NOTSTATIC *
          -pipe   # Use pipes rather than temporary files for communication between the various stages of compilation.
        )
      endif()
    else()
      if (MSVC)
        tkl_add_target_compile_properties(${target} RELEASE
          /O2     # Maximize Speed
        )
        tkl_add_target_compile_properties(${target} *
          /MP
        )
      elseif (GCC)
        tkl_add_target_compile_properties(${target} RELEASE
          -O2     # More Stable Optimization
        )
        tkl_add_target_compile_properties(${target} *
          -pipe   # Use pipes rather than temporary files for communication between the various stages of compilation.
        )

        tkl_add_target_link_properties(${target} NOTSTATIC *
          -pipe   # Use pipes rather than temporary files for communication between the various stages of compilation.
        )
      endif()
    endif()

    tkl_get_target_compile_property(COMPILE_OPTIONS_${target} ${target} .)
    tkl_get_target_link_property(LINK_FLAGS_${target} ${target} .)
    tkl_get_target_link_property(LINK_FLAGS_${target}_DEBUG ${target} DEBUG)
    tkl_get_target_link_property(LINK_FLAGS_${target}_RELEASE ${target} RELEASE)
    tkl_get_target_link_property(LINK_FLAGS_${target}_MINSIZEREL ${target} MINSIZEREL)
    tkl_get_target_link_property(LINK_FLAGS_${target}_RELWITHDEBINFO ${target} RELWITHDEBINFO)

    tkl_print_flags(
      COMPILE_OPTIONS_${target}
      LINK_FLAGS_${target}
      LINK_FLAGS_${target}_DEBUG
      LINK_FLAGS_${target}_RELEASE
      LINK_FLAGS_${target}_MINSIZEREL
      LINK_FLAGS_${target}_RELWITHDEBINFO
    )

    if (Boost_LIBRARY_DIRS)
      tkl_add_target_link_directories(${target} *
        PRIVATE
          ${Boost_LIBRARY_DIRS}
      )
    endif()

#    if (GTEST_ROOT)
#      tkl_add_target_link_directories(${target} *
#        PRIVATE
#          ${GTEST_ROOT}/${_gtest_libpath_suffixes}
#      )
#    endif()

    # libraries must be different in case of the library linkage or direct library sources usage
    if (target_is_liblinked)
      target_link_libraries(${target}
        PRIVATE
          ${LIB_TARGET_NAME}
      )
    else()
      # TODO:
      #   replace target_link_libraries by a custom implementation with arbitrary exclusion of specific libraries
      #
      target_link_libraries(${target}
        PRIVATE
          ${LIBRARIES_${LIB_TARGET_NAME}}
      )
    endif()

    target_link_libraries(${target}
      PRIVATE
        ${TESTLIB_TARGET_NAME}
    )

    if (Boost_LIBRARIES)
      target_link_libraries(${target}
        PRIVATE
          ${Boost_LIBRARIES}
      )
    endif()

#    if (GTEST_LIBRARIES)
#      target_link_libraries(${target}
#        PRIVATE
#          ${GTEST_LIBRARIES}
#      )
#    endif()

    if (TARGET gtest)
      target_link_libraries(${target}
        PRIVATE
          gtest
      )
    endif()

    MATH(EXPR target_index "${target_index}+1")
  endforeach()
else()
  message(STATUS "(*) Tests build skipped.")
endif()

###############################################################################
## packaging ##################################################################
###############################################################################

# All install commands get the same destination. this allows us to use paths
# relative to the executable.
install(TARGETS ${LIB_TARGET_NAME} DESTINATION $<CONFIGURATION>)
if (TARGET TESTLIB_TARGET_NAME)
  install(TARGETS ${TESTLIB_TARGET_NAME} DESTINATION $<CONFIGURATION>)
endif()

## must be after all `install` commands!
##
#install(CODE "
#  include(BundleUtilities)
#  fixup_bundle(\"\${CMAKE_INSTALL_PREFIX}/\${CMAKE_INSTALL_CONFIG_NAME}/${EXE_TARGET_NAME}${CMAKE_EXECUTABLE_SUFFIX}\" \"\" \"${Boost_LIBRARY_DIRS}\")
#  " COMPONENT ${LIB_TARGET_NAME} ${QT_LIBRARIES})

#if (${TESTS_ENABLED})
#  set(target_index 0)
#  foreach(target IN LISTS TESTS_TARGET_NAMES)
#    list(GET TESTS_TARGET_NAMES ${target_index} target)
#
#    install(TARGETS ${target} DESTINATION $<CONFIGURATION>)
#
#    #install(CODE "
#    #  include(BundleUtilities)
#    #  fixup_bundle(\"\${CMAKE_INSTALL_PREFIX}/\${CMAKE_INSTALL_CONFIG_NAME}/${target}${CMAKE_EXECUTABLE_SUFFIX}\" \"\" \"${Boost_LIBRARY_DIRS}\")
#    #  " COMPONENT ${target})
#
#    MATH(EXPR target_index "${target_index}+1")
#  endforeach()
#endif()

## Now comes everything we need, to create a package
## there are a lot more variables you can set, and some
## you need to set for some package types, but we want to
## be minimal here.
#set(CPACK_PACKAGE_VERSION "1.0.0.0")
#
##set(CPACK_PACKAGE_FILE_NAME "${PROJECT_LIB_NAME}-${CPACK_PACKAGE_VERSION}-win32-$<CONFIGURATION>")
##set(CPACK_PACKAGE_NAME "${LIB_TARGET_NAME}")
#
## We don't want to split our program up into several incomplete pieces.
#set(CPACK_MONOLITHIC_INSTALL 1)
#
#set(CPACK_OUTPUT_CONFIG_FILE "${CMAKE_BINARY_DIR}/BundleConfig.cmake")
#
#include(CPack)
#
#set(CPACK_BUNDLE_TEMPLATE_CONFIG_FILE "${CMAKE_BINARY_DIR}/CPackConfig.cmake.in")
#set(CPACK_BUNDLE_OUTPUT_CONFIG_FILE "${CMAKE_BINARY_DIR}/CPackProperties.cmake")
#
## make cpack configuration template for later replacements with the expression generator support
#file(WRITE "${CPACK_BUNDLE_TEMPLATE_CONFIG_FILE}" "")
#file(APPEND "${CPACK_BUNDLE_TEMPLATE_CONFIG_FILE}" "set(CPACK_PACKAGE_FILE_NAME \"\${CPACK_PACKAGE_FILE_NAME}\")\n")
#
#add_custom_target(bundle
#  COMMAND ${CMAKE_COMMAND}
#    # this one must be written as is, DO NOT put the `$<CONFIGURATION>` inside a variable!
#    -D "CPACK_PACKAGE_FILE_NAME=${PROJECT_LIB_NAME}-${CPACK_PACKAGE_VERSION}-win32-$<CONFIGURATION>"
#    -D "CPACK_BUNDLE_TEMPLATE_CONFIG_FILE=${CPACK_BUNDLE_TEMPLATE_CONFIG_FILE}"
#    -D "CPACK_BUNDLE_OUTPUT_CONFIG_FILE=${CPACK_BUNDLE_OUTPUT_CONFIG_FILE}"
#    # this one must be after all `-D`s
#    -P "${CMAKE_CURRENT_LIST_DIR}/cmake/tacklelib/tools/CPackMakeConfig.cmake"
#  COMMAND "${CMAKE_CPACK_COMMAND}" 
#    -G "NSIS"
#    -C "$<CONFIGURATION>"
#    --config "${CPACK_OUTPUT_CONFIG_FILE}")

###############################################################################
## project folders ############################################################
###############################################################################

## projects

tkl_set_target_folder(CMAKE_CURRENT_LIST_DIR . * .       UTILITY     . util)
tkl_set_target_folder(CMAKE_CURRENT_LIST_DIR . * "tests" EXECUTABLE  . exe)
tkl_set_target_folder(CMAKE_CURRENT_LIST_DIR . * .       "SHARED_LIBRARY;STATIC_LIBRARY" . lib)

## 3dparty

# utility

tkl_set_target_folder(BOOST_ROOT * * . * . _3dparty/utility/boost)

tkl_set_target_folder(UTILITY_FMT_ROOT * * . * . _3dparty/utility/fmt)
tkl_set_target_folder(UTILITY_PYSTRING_ROOT * * . * . _3dparty/utility/pystring)

# math

tkl_set_target_folder(QD_ROOT * * . * . _3dparty/math/qd)

# log

tkl_set_target_folder(LOG_P7_CLIENT_ROOT * * . * . _3dparty/log/p7client)

# arc

tkl_set_target_folder(ARC_LIBARCHIVE_ROOT * * . UTILITY     . _3dparty/arc/libarchive/util)
tkl_set_target_folder(ARC_LIBARCHIVE_ROOT * * . EXECUTABLE  . _3dparty/arc/libarchive/exe)
tkl_set_target_folder(ARC_LIBARCHIVE_ROOT * * . "SHARED_LIBRARY;STATIC_LIBRARY" . _3dparty/arc/libarchive/lib)
tkl_set_target_folder(ARC_LIBARCHIVE_ROOT * * . * "UTILITY;EXECUTABLE;SHARED_LIBRARY;STATIC_LIBRARY" _3dparty/arc/libarchive)
tkl_set_target_folder(ARC_XZ_UTILS_ROOT   * * . * . _3dparty/arc/xz)
tkl_set_target_folder(ARC_7ZIP_ROOT       * * . * . _3dparty/arc/7zip)

# tests

tkl_set_target_folder(GTEST_ROOT * * . * . _3dparty/test/googletest)
tkl_set_target_folder(CMAKE_CURRENT_LIST_DIR . "tests" . * . tests)
tkl_set_target_folder(CMAKE_CURRENT_LIST_DIR . "build_check" . * . tests)

###############################################################################
## updated global flags and post process target properties ####################
###############################################################################

# to avoid cmake autogen specific warnings
if (generated_headers)
  set_property(SOURCE ${generated_headers}
    PROPERTY SKIP_AUTOGEN ON
    PROPERTY GENERATED ON
  )

  # to avoid cmake errors generation on source file absence
  set_source_files_properties(${generated_headers}
    PROPERTIES
      SKIP_AUTOGEN ON
      GENERATED ON
  )
endif()
