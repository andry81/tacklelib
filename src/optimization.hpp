#pragma once


#define ENABLE_FORCE_INLINE         // defines FORCE_INLINE in to builtin instruction to force entity to inline
#define ENABLE_FORCE_NO_INLINE      // defines FORCE_NO_INLINE in to builtin instruction to force entity to not inline
#define ENABLE_INTRINSIC            // use builtin implementation (intrinsic) instead externally linked
#define ENABLE_POF2_DEFINITIONS     // enables optimized version of the power-of-2 macroses instead of straight implementation

// Do NOT use macro inline instead of function/lambda call for the UNIT_ASSERT_* macroses ONLY.
//#define DONT_USE_UNIT_ASSERT_CALL_THROUGH_MACRO_INLINE

// WARNING:
//  1. You must define DONT_USE_UNIT_ASSERT_CALL_THROUGH_MACRO_INLINE to fully switch the implementation.
//  2. Compilation or linkage times has noticable slow down about 2x times.
//#define USE_UNIT_ASSERT_CALL_THROUGH_TEMPLATE_FUNCTION_INSTEAD_LAMBDAS

// use basic verify/assert implementation instead unit test implementation (just to measure time spent in unit tests)
//#define USE_BASIC_ASSERT_INSTEAD_UNIT_ASSERT
