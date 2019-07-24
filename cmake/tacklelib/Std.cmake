# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_STD_INCLUDE_DEFINED)
set(TACKLELIB_STD_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.14)

# at least cmake 3.14 is required for:
#   * CMAKE_ROLE property: https://cmake.org/cmake/help/latest/prop_gbl/CMAKE_ROLE.html#prop_gbl:CMAKE_ROLE
#

# at least cmake 3.9 is required for:
#   * Multiconfig generator detection support: https://cmake.org/cmake/help/v3.9/prop_gbl/GENERATOR_IS_MULTI_CONFIG.html
#

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# at least cmake 3.3 is required for:
# * to use IN_LIST in if command: (https://cmake.org/cmake/help/v3.3/command/if.html )
#   `if(<variable|string> IN_LIST <variable>)`
#

include(tacklelib/List)
include(tacklelib/Math)
include(tacklelib/File)
include(tacklelib/Props)
include(tacklelib/Reimpl)
include(tacklelib/Time)
include(tacklelib/Utility)

macro(tkl_include_and_echo path)
  message(STATUS "(*) Include: \"${path}\"")
  include(${path})
endmacro()

macro(tkl_unset_all var)
  unset(${var})
  unset(${var} CACHE)
endmacro()

endif()
