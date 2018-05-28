#pragma once

#include <tacklelib.hpp>

#ifdef GTEST_FAIL
#error <utility/assert.hpp> header must be included instead of the <gtest.h> header
#endif

// the gtest is always required in tests, even if only the public headers are available (liblinked)
#if (defined(UNIT_TESTS) || defined(BENCH_TESTS)) && defined(LIBLINKED)
#define GTEST_DONT_DEFINE_ASSERT_TRUE 1
#define GTEST_DONT_DEFINE_ASSERT_FALSE 1
#define GTEST_DONT_DEFINE_ASSERT_EQ 1
#define GTEST_DONT_DEFINE_ASSERT_NE 1
#define GTEST_DONT_DEFINE_ASSERT_LE 1
#define GTEST_DONT_DEFINE_ASSERT_LT 1
#define GTEST_DONT_DEFINE_ASSERT_GE 1
#define GTEST_DONT_DEFINE_ASSERT_GT 1

#include <gtest/gtest.h>

// back compatability
#undef ASSERT_TRUE
#undef ASSERT_FALSE
#undef ASSERT_EQ
#undef ASSERT_NE
#undef ASSERT_LE
#undef ASSERT_LT
#undef ASSERT_GE
#undef ASSERT_GT

#define GTEST_INCLUDE_FROM_TESTS
#endif

#include <utility/platform.hpp>
#include <utility/utility.hpp>
#include <utility/static_assert.hpp>
#include <utility/type_traits.hpp>
#include <utility/assert.hpp>
#include <utility/math.hpp>
#include <utility/algorithm.hpp>

#include <boost/preprocessor/cat.hpp>
#include <boost/utility.hpp>
#include <boost/format.hpp>

#include <boost/shared_ptr.hpp>

#include <string>

#include <stdio.h>
#include <stdlib.h>

#include <limits>


// project particular commons here...
