#pragma once

#include "common.hpp"

// commons exclicitly for tests ONLY
#include "testlib/testlib.hpp"
#include "testlib/gtest_ext.hpp"

#include <spacetracker.hpp>
#include <tle_manager.hpp>

#include <utility/math.hpp>

#include <tackle/date_time.hpp>

#include <chrono>
#include <boost/filesystem.hpp>
#include <boost/regex.hpp>
#include <boost/range/combine.hpp>
#include <boost/iostreams/stream.hpp>
#include <boost/iostreams/device/file_descriptor.hpp>

#include <cstdint>
#include <cstdlib>
#include <iostream>


namespace boost
{
    namespace fs = filesystem;
    namespace ios = boost::iostreams;
}

// special value type to skip a specific test parameter check
struct Skip
{
};

const Skip skip = Skip{};
