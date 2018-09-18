#pragma once

#if !defined(TACKLE_TESTLIB) && !defined(UNIT_TESTS) && !defined(BENCH_TESTS)
#error This header must be used explicitly in a test declared environment. Use respective definitions to declare a test environment.
#endif

#include <gtest/gtest.h>


#define EXPECT_TRUE_PRED(v1, fail_pred) \
    EXPECT_PRED1( \
        [&](auto x) { \
            if (x ? true : false) return true; \
            { fail_pred; } \
            return false; \
        }, \
        v1)

#define EXPECT_FALSE_PRED(v1, fail_pred) \
    EXPECT_PRED1( \
        [&](auto x) { \
            if (x ? false : true) return true; \
            { fail_pred; } \
            return false; \
        }, \
        v1)

#define EXPECT_EQ_PRED(v1, v2, fail_pred) \
    EXPECT_PRED2( \
        [&](auto x, auto y) { \
            if (x == y) return true; \
            { fail_pred; } \
            return false; \
        }, \
        v1, v2)

#define EXPECT_NE_PRED(v1, v2, fail_pred) \
    EXPECT_PRED2( \
        [&](auto x, auto y) { \
            if (x != y) return true; \
            { fail_pred; } \
            return false; \
        }, \
        v1, v2)

#define EXPECT_LE_PRED(v1, v2, fail_pred) \
    EXPECT_PRED2( \
        [&](auto x, auto y) { \
            if (x <= y) return true; \
            { fail_pred; } \
            return false; \
        }, \
        v1, v2)

#define EXPECT_LT_PRED(v1, v2, fail_pred) \
    EXPECT_PRED2( \
        [&](auto x, auto y) { \
            if (x < y) return true; \
            { fail_pred; } \
            return false; \
        }, \
        v1, v2)

#define EXPECT_GE_PRED(v1, v2, fail_pred) \
    EXPECT_PRED2( \
        [&](auto x, auto y) { \
            if (x >= y) return true; \
            { fail_pred; } \
            return false; \
        }, \
        v1, v2)

#define EXPECT_GT_PRED(v1, v2, fail_pred) \
    EXPECT_PRED2( \
        [&](auto x, auto y) { \
            if (x > y) return true; \
            { fail_pred; } \
            return false; \
        }, \
        v1, v2)
