# NOTE:
#   These variables does duplicate those from the `cmake/config.system.vars` configuration file to be
#   able to invoke cmake directly out of call to `_build` scripts.
#

# NOTE:
#   Use the `CACHE` modificator to be able to edit them externally.
#

set(TACKLELIB_CMAKE_ROOT            ${CMAKE_CURRENT_SOURCE_DIR}/cmake                                           CACHE PATH      "Path to Tacklelib cmake library")
set(CMAKE_CONFIG_VARS_SYSTEM_FILE   ${CMAKE_CURRENT_SOURCE_DIR}/_out/config/tacklelib/cmake/config.system.vars  CACHE FILEPATH  "Path to cmake system configuration variables file")
set(CMAKE_CONFIG_VARS_USER_0_FILE   ${CMAKE_CURRENT_SOURCE_DIR}/_out/config/tacklelib/cmake/config.0.vars       CACHE FILEPATH  "Path to cmake user configuration variables file")

LIST(APPEND CMAKE_MODULE_PATH       "${TACKLELIB_CMAKE_ROOT};${TACKLELIB_CMAKE_ROOT}/tacklelib/_3dparty/modules")

# cmake extension variables, must be before the first include
#set(TACKLELIB_ENABLE_TARGETS_EXTENSION_FUNCTION_HANDLERS 1) # 0 - macro handlers, faster; 1 - function handlers, slower
