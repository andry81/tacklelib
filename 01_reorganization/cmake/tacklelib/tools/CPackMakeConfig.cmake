include(tacklelib/Std)

if (NOT CPACK_BUNDLE_TEMPLATE_CONFIG_FILE)
  message(FATAL_ERROR "* CPACK_BUNDLE_TEMPLATE_CONFIG_FILE variable must be defined!")
endif()
if (NOT CPACK_BUNDLE_OUTPUT_CONFIG_FILE)
  message(FATAL_ERROR "* CPACK_BUNDLE_OUTPUT_CONFIG_FILE variable must be defined!")
endif()

configure_file("${CPACK_BUNDLE_TEMPLATE_CONFIG_FILE}" "${CPACK_BUNDLE_OUTPUT_CONFIG_FILE}")

tkl_unset_all(CPACK_BUNDLE_TEMPLATE_CONFIG_FILE)
tkl_unset_all(CPACK_BUNDLE_OUTPUT_CONFIG_FILE)
