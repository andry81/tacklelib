#include "tacklelib_private.hpp"

#undef LIBRARY_API_NAMESPACE
#define LIBRARY_API_NAMESPACE TACKLELIB
#include <tacklelib/utility/library_api_define.hpp>


#if defined(BUILD_VERSION_DATE_TIME_TOKEN)
  // to make the unique link with a library headers
  LIBRARY_API_IMPLEMENT_LIB_GLOBAL_BUILD_VERSION_DATE_TIME_TOKEN(tacklelib)
#endif()
