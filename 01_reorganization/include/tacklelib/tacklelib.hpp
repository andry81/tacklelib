#pragma once

#include <tacklelib/setup.hpp>          // setup symbols
#include <tacklelib/debug.hpp>          // debug symbols
#include <tacklelib/optimization.hpp>   // optimization symbols

#include <tacklelib/utility/platform.hpp>

#undef LIBRARY_API_NAMESPACE
#define LIBRARY_API_NAMESPACE TACKLELIB
#include <tacklelib/utility/library_api_define.hpp>

#if defined(BUILD_VERSION_DATE_TIME_TOKEN)
    // to make the unique link with a library implementation
    LIBRARY_API_DECLARE_HEADER_LIB_BUILD_VERSION_DATE_TIME_TOKEN(tacklelib, lib);
#endif
