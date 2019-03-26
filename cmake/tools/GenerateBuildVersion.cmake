include(Std)

if (NOT INCLUDE_FILE)
  message(FATAL_ERROR "* INCLUDE_FILE variable must be defined!")
endif()

LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

include(GenerateVersion)

generate_build_version_variables()
generate_build_version_include_file(${INCLUDE_FILE})

unset_all(INCLUDE_FILE)
unset_all(BUILD_VERSION_DATE_TIME_STR)
unset_all(BUILD_VERSION_DATE_TIME_TOKEN)
