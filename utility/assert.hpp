#pragma once

#include "utility/preprocessor.hpp"
#include "utility/platform.hpp"
#include "utility/debug.hpp"

#ifdef GTEST_FAIL
#error <utility/assert.hpp> header must be included instead of the <gtest.h> header
#endif

#if defined(UNIT_TESTS) || defined(BENCH_TESTS)
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
#endif

#include <cassert>


#define UTILITY_ASSERT_GTEST_MESSAGE_(message, result_type) \
  GTEST_MESSAGE_AT_(file, line, message, result_type) // `file` and `line` must be external respective variables

#define UTILITY_ASSERT_GTEST_FATAL_FAILURE_(message) \
  UTILITY_ASSERT_GTEST_MESSAGE_(message, ::testing::TestPartResult::kFatalFailure)

#define UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_(message) \
  UTILITY_ASSERT_GTEST_MESSAGE_(message, ::testing::TestPartResult::kNonFatalFailure)

#define UTILITY_ASSERT_GTEST_SUCCESS_(message) \
  UTILITY_ASSERT_GTEST_MESSAGE_(message, ::testing::TestPartResult::kSuccess)

#define ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp, precondition) \
    if (!(precondition)); else if(!!(exp)); else DEBUG_BREAK(true)

#if defined(UNIT_TESTS) || defined(BENCH_TESTS) && defined(_DEBUG)

#ifdef _MSC_VER
    #if _MSC_VER < 1600 // < MSVC++ 10 (Visual Studio 2010)
        #error lambda is not supported
    #endif
#else
    #if __cplusplus < 201103L
        #error lambda is not supported
    #endif
#endif

// TIPS:
//  * all unnecessary lambdas replaced by explicit structure with parentheses operator with void return to avoid slow down around excessive lambdas usage in the debug.
//  * if debugger is attached but `::testing::GTEST_FLAG(break_on_failure)` has not been setted, then an assertion does a post break.

#ifdef USE_ASSERT_WITH_INPLACE_STRUCT_OPERATOR_INSTEAD_LAMBDAS

#define VERIFY_TRUE(exp) (( ::utility::AnsiAssertTrue(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(exp, UTILITY_PP_STRINGIZE(exp)) ))
#define ASSERT_TRUE(exp) {{ ::utility::AnsiAssertTrue(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(exp, UTILITY_PP_STRINGIZE(exp)); }} (void)0

////

#define VERIFY_FALSE(exp) (( ::utility::AnsiAssertFalse(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(exp, UTILITY_PP_STRINGIZE(!(exp))) ))
#define ASSERT_FALSE(exp) {{ ::utility::AnsiAssertFalse(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(exp, UTILITY_PP_STRINGIZE(!(exp))); }} (void)0

////

#define VERIFY_EQ(v1, v2) (( ::utility::AnsiAssertEQ(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)) ))
#define ASSERT_EQ(v1, v2) {{ ::utility::AnsiAssertEQ(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)); }} (void)0

////

#define VERIFY_NE(v1, v2) (( ::utility::AnsiAssertNE(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)) ))
#define ASSERT_NE(v1, v2) {{ ::utility::AnsiAssertNE(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)); }} (void)0

////

#define VERIFY_LE(v1, v2) (( ::utility::AnsiAssertLE(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)) ))
#define ASSERT_LE(v1, v2) {{ ::utility::AnsiAssertLE(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)); }} (void)0

////

#define VERIFY_LT(v1, v2) (( ::utility::AnsiAssertLT(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)) ))
#define ASSERT_LT(v1, v2) {{ ::utility::AnsiAssertLT(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)); }} (void)0

////

#define VERIFY_GE(v1, v2) (( ::utility::AnsiAssertGE(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)) ))
#define ASSERT_GE(v1, v2) {{ ::utility::AnsiAssertGE(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)); }} (void)0

////

#define VERIFY_GT(v1, v2) (( ::utility::AnsiAssertGT(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)) ))
#define ASSERT_GT(v1, v2) {{ ::utility::AnsiAssertGT(UTILITY_PP_FILE, UTILITY_PP_LINE).gtest_verify(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2)); }} (void)0

#else

#define VERIFY_TRUE_IMPL(exp) [&](const auto & exp_var, const char * exp_str, const char * file, unsigned int line) -> const auto & { \
        const bool is_success = !!(exp_var); \
        const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure); \
        if (break_on_failure) { \
            GTEST_TEST_BOOLEAN_(is_success, exp_str, false, true, UTILITY_ASSERT_GTEST_FATAL_FAILURE_); \
        } else { \
            GTEST_TEST_BOOLEAN_(is_success, exp_str, false, true, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_); \
        } \
        ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(is_success, !break_on_failure); \
        return exp_var; \
    }

#define VERIFY_TRUE(exp) (( VERIFY_TRUE_IMPL(exp)(exp, UTILITY_PP_STRINGIZE(exp), UTILITY_PP_FILE, UTILITY_PP_LINE) ))
#define ASSERT_TRUE(exp) {{ VERIFY_TRUE_IMPL(exp)(exp, UTILITY_PP_STRINGIZE(exp), UTILITY_PP_FILE, UTILITY_PP_LINE); }} (void)0

#define VERIFY_FALSE_IMPL(exp) [&](const auto & exp_var, const char * exp_str, const char * file, unsigned int line) -> const auto & { \
        const bool is_success = !(exp_var); \
        const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure); \
        if (break_on_failure) { \
            GTEST_TEST_BOOLEAN_(is_success, exp_str, true, false, UTILITY_ASSERT_GTEST_FATAL_FAILURE_); \
        } else { \
            GTEST_TEST_BOOLEAN_(is_success, exp_str, true, false, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_); \
        } \
        ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(is_success, !break_on_failure); \
        return exp_var; \
    }

#define VERIFY_FALSE(exp) (( VERIFY_FALSE_IMPL(exp)(exp, UTILITY_PP_STRINGIZE(exp), UTILITY_PP_FILE, UTILITY_PP_LINE) ))
#define ASSERT_FALSE(exp) {{ VERIFY_FALSE_IMPL(exp)(exp, UTILITY_PP_STRINGIZE(exp), UTILITY_PP_FILE, UTILITY_PP_LINE); }} (void)0

#define VERIFY_EQ_IMPL(v1, v2) [&](const auto & v_1, const auto & v_2, const char * v1_str, const char * v2_str, const char * file, unsigned int line) -> const auto & { \
        const ::testing::AssertionResult exp_value = ::testing::internal::EqHelper<GTEST_IS_NULL_LITERAL_(v_1)>::Compare(v1_str, v2_str, v_1, v_2); \
        const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure); \
        if (break_on_failure) { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_); \
        } else { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_); \
        } \
        ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure); \
        return v_1; \
    }

#define VERIFY_EQ(v1, v2) (( VERIFY_EQ_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE) ))
#define ASSERT_EQ(v1, v2) {{ VERIFY_EQ_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE); }} (void)0

////

#define VERIFY_NE_IMPL(v1, v2) [&](const auto & v_1, const auto & v_2, const char * v1_str, const char * v2_str, const char * file, unsigned int line) -> const auto & { \
        const ::testing::AssertionResult exp_value = ::testing::internal::CmpHelperNE(v1_str, v2_str, v_1, v_2); \
        const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure); \
        if (break_on_failure) { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_); \
        } else { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_); \
        } \
        ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure); \
        return v_1; \
    }

#define VERIFY_NE(v1, v2) (( VERIFY_NE_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE) ))
#define ASSERT_NE(v1, v2) {{ VERIFY_NE_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE); }} (void)0

////

#define VERIFY_LE_IMPL(v1, v2) [&](const auto & v_1, const auto & v_2, const char * v1_str, const char * v2_str, const char * file, unsigned int line) -> const auto & { \
        const ::testing::AssertionResult exp_value = ::testing::internal::CmpHelperLE(v1_str, v2_str, v_1, v_2); \
        const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure); \
        if (break_on_failure) { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_); \
        } else { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_); \
        } \
        ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure); \
        return v_1; \
    }

#define VERIFY_LE(v1, v2) (( VERIFY_LE_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE) ))
#define ASSERT_LE(v1, v2) {{ VERIFY_LE_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE); }} (void)0

////

#define VERIFY_LT_IMPL(v1, v2) [&](const auto & v_1, const auto & v_2, const char * v1_str, const char * v2_str, const char * file, unsigned int line) -> const auto & { \
        const ::testing::AssertionResult exp_value = ::testing::internal::CmpHelperLT(v1_str, v2_str, v_1, v_2); \
        const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure); \
        if (break_on_failure) { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_); \
        } else { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_); \
        } \
        ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure); \
        return v_1; \
    }

#define VERIFY_LT(v1, v2) (( VERIFY_LT_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE) ))
#define ASSERT_LT(v1, v2) {{ VERIFY_LT_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE); }} (void)0

////

#define VERIFY_GE_IMPL(v1, v2) [&](const auto & v_1, const auto & v_2, const char * v1_str, const char * v2_str, const char * file, unsigned int line) -> const auto & { \
        const ::testing::AssertionResult exp_value = ::testing::internal::CmpHelperGE(v1_str, v2_str, v_1, v_2); \
        const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure); \
        if (break_on_failure) { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_); \
        } else { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_); \
        } \
        ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure); \
        return v_1; \
    }

#define VERIFY_GE(v1, v2) (( VERIFY_GE_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE) ))
#define ASSERT_GE(v1, v2) {{ VERIFY_GE_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE); }} (void)0

////

#define VERIFY_GT_IMPL(v1, v2) [&](const auto & v_1, const auto & v_2, const char * v1_str, const char * v2_str, const char * file, unsigned int line) -> const auto & { \
        const ::testing::AssertionResult exp_value = ::testing::internal::CmpHelperGT(v1_str, v2_str, v_1, v_2); \
        const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure); \
        if (break_on_failure) { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_); \
        } else { \
            GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_); \
        } \
        ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure); \
        return v_1; \
    }

#define VERIFY_GT(v1, v2) (( VERIFY_GT_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE) ))
#define ASSERT_GT(v1, v2) {{ VERIFY_GT_IMPL(v1, v2)(v1, v2, UTILITY_PP_STRINGIZE(v1), UTILITY_PP_STRINGIZE(v2), UTILITY_PP_FILE, UTILITY_PP_LINE); }} (void)0

#endif

#define VERIFY(x) VERIFY_TRUE(x)
#define ASSERT(x) ASSERT_TRUE(x)

#define ASSERT_VERIFY_ENABLED 1

#else

#ifdef _DEBUG

#define VERIFY_TRUE(exp)    (( ::utility::WideAssertTrue(UTILITY_PP_FILE_WIDE, UTILITY_PP_LINE).verify(exp, UTILITY_PP_STRINGIZE_WIDE(exp)) ))
#define VERIFY_FALSE(exp)   (( ::utility::WideAssertFalse(UTILITY_PP_FILE_WIDE, UTILITY_PP_LINE).verify(exp, UTILITY_PP_STRINGIZE_WIDE(!(exp))) ))

#define VERIFY_EQ(v1, v2)   (( ::utility::WideAssertEQ(UTILITY_PP_FILE_WIDE, UTILITY_PP_LINE).verify(v1, v2, UTILITY_PP_STRINGIZE_WIDE((v1) == (v2))) ))
#define VERIFY_NE(v1, v2)   (( ::utility::WideAssertNE(UTILITY_PP_FILE_WIDE, UTILITY_PP_LINE).verify(v1, v2, UTILITY_PP_STRINGIZE_WIDE((v1) != (v2))) ))
#define VERIFY_LE(v1, v2)   (( ::utility::WideAssertLE(UTILITY_PP_FILE_WIDE, UTILITY_PP_LINE).verify(v1, v2, UTILITY_PP_STRINGIZE_WIDE((v1) <= (v2))) ))
#define VERIFY_LT(v1, v2)   (( ::utility::WideAssertLT(UTILITY_PP_FILE_WIDE, UTILITY_PP_LINE).verify(v1, v2, UTILITY_PP_STRINGIZE_WIDE((v1) < (v2))) ))
#define VERIFY_GE(v1, v2)   (( ::utility::WideAssertGE(UTILITY_PP_FILE_WIDE, UTILITY_PP_LINE).verify(v1, v2, UTILITY_PP_STRINGIZE_WIDE((v1) >= (v2))) ))
#define VERIFY_GT(v1, v2)   (( ::utility::WideAssertGT(UTILITY_PP_FILE_WIDE, UTILITY_PP_LINE).verify(v1, v2, UTILITY_PP_STRINGIZE_WIDE((v1) > (v2))) ))

#define ASSERT_TRUE(exp)    {{ assert(exp); }} (void)0
#define ASSERT_FALSE(exp)   {{ assert(!(exp)); }} (void)0

#define ASSERT_EQ(v1, v2)   {{ assert((v1) == (v2)); }} (void)0
#define ASSERT_NE(v1, v2)   {{ assert((v1) != (v2)); }} (void)0
#define ASSERT_LE(v1, v2)   {{ assert((v1) <= (v2)); }} (void)0
#define ASSERT_LT(v1, v2)   {{ assert((v1) < (v2)); }} (void)0
#define ASSERT_GE(v1, v2)   {{ assert((v1) >= (v2)); }} (void)0
#define ASSERT_GT(v1, v2)   {{ assert((v1) > (v2)); }} (void)0

#define ASSERT_VERIFY_ENABLED 1

#else

// additionally checks on respective operators existance

#define VERIFY_TRUE(exp)    (( ::utility::unused_true(exp) ))
#define VERIFY_FALSE(exp)   (( ::utility::unused_false(exp) ))

#define VERIFY_EQ(v1, v2)   (( ::utility::unused_equal(v1, v2) ))
#define VERIFY_NE(v1, v2)   (( ::utility::unused_not_equal(v1, v2) ))
#define VERIFY_LE(v1, v2)   (( ::utility::unused_less_or_equal(v1, v2) ))
#define VERIFY_LT(v1, v2)   (( ::utility::unused_less(v1, v2) ))
#define VERIFY_GE(v1, v2)   (( ::utility::unused_greater_or_equal(v1, v2) ))
#define VERIFY_GT(v1, v2)   (( ::utility::unused_greater(v1, v2) ))

#define ASSERT_TRUE(exp)    {{ UTILITY_UNUSED_STATEMENT(!!(exp)); }} (void)0
#define ASSERT_FALSE(exp)   {{ UTILITY_UNUSED_STATEMENT(!(exp)); }} (void)0

#define ASSERT_EQ(v1, v2)   {{ UTILITY_UNUSED_STATEMENT2(v1, v2); UTILITY_UNUSED_STATEMENT((v1) == (v2)); }} (void)0
#define ASSERT_NE(v1, v2)   {{ UTILITY_UNUSED_STATEMENT2(v1, v2); UTILITY_UNUSED_STATEMENT((v1) != (v2)); }} (void)0
#define ASSERT_LE(v1, v2)   {{ UTILITY_UNUSED_STATEMENT2(v1, v2); UTILITY_UNUSED_STATEMENT((v1) <= (v2)); }} (void)0
#define ASSERT_LT(v1, v2)   {{ UTILITY_UNUSED_STATEMENT2(v1, v2); UTILITY_UNUSED_STATEMENT((v1) < (v2)); }} (void)0
#define ASSERT_GE(v1, v2)   {{ UTILITY_UNUSED_STATEMENT2(v1, v2); UTILITY_UNUSED_STATEMENT((v1) >= (v2)); }} (void)0
#define ASSERT_GT(v1, v2)   {{ UTILITY_UNUSED_STATEMENT2(v1, v2); UTILITY_UNUSED_STATEMENT((v1) > (v2)); }} (void)0

#define ASSERT_VERIFY_ENABLED 0

#endif

#define VERIFY(exp)         VERIFY_TRUE(exp)
#define ASSERT(exp)         ASSERT_TRUE(exp)

#endif


namespace utility
{
    // TIPS:
    // * to capture parameters by reference in macro definitions for single evaluation
    // * to suppress `unused variable` warnings like: `warning C4101: '...': unreferenced local variable`
    template<typename T>
    FORCE_INLINE const T & unused_true(const T & exp_var)
    {
        return !!exp_var ? exp_var : exp_var; // to avoid warnings of truncation to bool
    }

    template<typename T>
    FORCE_INLINE const T & unused_false(const T & exp_var)
    {
        return !exp_var ? exp_var : exp_var; // to avoid warnings of truncation to bool
    }

    template<typename T1, typename T2>
    FORCE_INLINE const T1 & unused_equal(const T1 & v1, const T2 & v2)
    {
        return v1 == v2 ? v1 : v1;
    }

    template<typename T1, typename T2>
    FORCE_INLINE const T1 & unused_not_equal(const T1 & v1, const T2 & v2)
    {
        return v1 != v2 ? v1 : v1;
    }

    template<typename T1, typename T2>
    FORCE_INLINE const T1 & unused_less_or_equal(const T1 & v1, const T2 & v2)
    {
        return v1 <= v2 ? v1 : v1;
    }

    template<typename T1, typename T2>
    FORCE_INLINE const T1 & unused_less(const T1 & v1, const T2 & v2)
    {
        return v1 < v2 ? v1 : v1;
    }

    template<typename T1, typename T2>
    FORCE_INLINE const T1 & unused_greater_or_equal(const T1 & v1, const T2 & v2)
    {
        return v1 >= v2 ? v1 : v1;
    }

    template<typename T1, typename T2>
    FORCE_INLINE const T1 & unused_greater(const T1 & v1, const T2 & v2)
    {
        return v1 > v2 ? v1 : v1;
    }

    struct BasicAnsiAssert
    {
        FORCE_INLINE BasicAnsiAssert(const char * file_, unsigned int line_) :
            file(file_), line(line_)
        {
        }

        const char *    file;
        unsigned int    line;
    };

    struct BasicWideAssert
    {
        FORCE_INLINE BasicWideAssert(const wchar_t * file_, unsigned int line_) :
            file(file_), line(line_)
        {
        }

        const wchar_t * file;
        unsigned int    line;
    };

    struct AnsiAssertTrue : BasicAnsiAssert {
        FORCE_INLINE AnsiAssertTrue(const char * file, unsigned int line) :
            BasicAnsiAssert(file, line)
        {
        }

        template <typename T>
        FORCE_INLINE const T & gtest_verify(const T & exp_var, const char * exp_str) const {
            const bool is_success = !!(exp_var); // to avoid `warning C4800: forcing value to bool 'true' or 'false' (performance warning)`
            const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure);
            if (break_on_failure) {
                GTEST_TEST_BOOLEAN_(is_success, exp_str, false, true, UTILITY_ASSERT_GTEST_FATAL_FAILURE_);
            } else {
                GTEST_TEST_BOOLEAN_(is_success, exp_str, false, true, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_);
            }
            ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(is_success, !break_on_failure);

            return exp_var;
        }
    };

    struct WideAssertTrue : BasicWideAssert {
        FORCE_INLINE WideAssertTrue(const wchar_t * file, unsigned int line) :
            BasicWideAssert(file, line)
        {
        }

        // TIPS:
        // * to capture parameters by reference in macro definitions for single evaluation
        // * to suppress `unused variable` warnings like: `warning C4101: '...': unreferenced local variable`
        template<typename T>
        FORCE_INLINE const T & verify(const T & exp_var, const wchar_t * exp_str)
        {
            if (exp_var);
            else {
                _wassert(exp_str, file, line);
            }

            return exp_var;
        }
    };

    struct AnsiAssertFalse : BasicAnsiAssert {
        FORCE_INLINE AnsiAssertFalse(const char * file, unsigned int line) :
            BasicAnsiAssert(file, line)
        {
        }

        template <typename T>
        FORCE_INLINE const T & gtest_verify(const T & exp_var, const char * exp_str) const {
            const bool is_success = !(exp_var); // to avoid `warning C4800: forcing value to bool 'true' or 'false' (performance warning)`
            const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure);
            if (break_on_failure) {
                GTEST_TEST_BOOLEAN_(is_success, exp_str, false, true, UTILITY_ASSERT_GTEST_FATAL_FAILURE_);
            }
            else {
                GTEST_TEST_BOOLEAN_(is_success, exp_str, false, true, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_);
            }
            ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(is_success, !break_on_failure);

            return exp_var;
        }
    };

    struct WideAssertFalse : BasicWideAssert {
        FORCE_INLINE WideAssertFalse(const wchar_t * file, unsigned int line) :
            BasicWideAssert(file, line)
        {
        }

        // TIPS:
        // * to capture parameters by reference in macro definitions for single evaluation
        // * to suppress `unused variable` warnings like: `warning C4101: '...': unreferenced local variable`
        template<typename T>
        FORCE_INLINE const T & verify(const T & exp_var, const wchar_t * exp_str)
        {
            if (exp_var) {
                _wassert(exp_str, file, line);
            }

            return exp_var;
        }
    };

    struct AnsiAssertEQ : BasicAnsiAssert {
        FORCE_INLINE AnsiAssertEQ(const char * file, unsigned int line) :
            BasicAnsiAssert(file, line)
        {
        }

        template <typename T1, typename T2>
        FORCE_INLINE const T1 & gtest_verify(const T1 & v1, const T2 & v2, const char * v1_str, const char * v2_str) const {
            const ::testing::AssertionResult exp_value = ::testing::internal::EqHelper<GTEST_IS_NULL_LITERAL_(v1)>::Compare(v1_str, v2_str, v1, v2);
            const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure);
            if (break_on_failure) {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_);
            }
            else {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_);
            }
            ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure);

            return v1;
        }
    };

    struct WideAssertEQ : BasicWideAssert {
        FORCE_INLINE WideAssertEQ(const wchar_t * file, unsigned int line) :
            BasicWideAssert(file, line)
        {
        }

        // TIPS:
        // * to capture parameters by reference in macro definitions for single evaluation
        // * to suppress `unused variable` warnings like: `warning C4101: '...': unreferenced local variable`
        template<typename T1, typename T2>
        FORCE_INLINE const T1 & verify(const T1 & v1, const T2 & v2, const wchar_t * exp_str)
        {
            if (v1 == v2);
            else {
                _wassert(exp_str, file, line);
            }

            return v1;
        }
    };

    struct AnsiAssertNE : BasicAnsiAssert {
        FORCE_INLINE AnsiAssertNE(const char * file, unsigned int line) :
            BasicAnsiAssert(file, line)
        {
        }

        template <typename T1, typename T2>
        FORCE_INLINE const T1 & gtest_verify(const T1 & v1, const T2 & v2, const char * v1_str, const char * v2_str) const {
            const ::testing::AssertionResult exp_value = ::testing::internal::CmpHelperNE(v1_str, v2_str, v1, v2);
            const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure);
            if (break_on_failure) {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_);
            } else {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_);
            }
            ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure);

            return v1;
        }
    };

    struct WideAssertNE : BasicWideAssert {
        FORCE_INLINE WideAssertNE(const wchar_t * file, unsigned int line) :
            BasicWideAssert(file, line)
        {
        }

        // TIPS:
        // * to capture parameters by reference in macro definitions for single evaluation
        // * to suppress `unused variable` warnings like: `warning C4101: '...': unreferenced local variable`
        template<typename T1, typename T2>
        FORCE_INLINE const T1 & verify(const T1 & v1, const T2 & v2, const wchar_t * exp_str)
        {
            if (v1 != v2);
            else {
                _wassert(exp_str, file, line);
            }

            return v1;
        }
    };

    struct AnsiAssertLE : BasicAnsiAssert {
        FORCE_INLINE AnsiAssertLE(const char * file, unsigned int line) :
            BasicAnsiAssert(file, line)
        {
        }

        template <typename T1, typename T2>
        FORCE_INLINE const T1 & gtest_verify(const T1 & v1, const T2 & v2, const char * v1_str, const char * v2_str) const {
            const ::testing::AssertionResult exp_value = ::testing::internal::CmpHelperLE(v1_str, v2_str, v1, v2);
            const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure);
            if (break_on_failure) {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_);
            }
            else {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_);
            }
            ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure);

            return v1;
        }
    };

    struct WideAssertLE : BasicWideAssert {
        FORCE_INLINE WideAssertLE(const wchar_t * file, unsigned int line) :
            BasicWideAssert(file, line)
        {
        }

        // TIPS:
        // * to capture parameters by reference in macro definitions for single evaluation
        // * to suppress `unused variable` warnings like: `warning C4101: '...': unreferenced local variable`
        template<typename T1, typename T2>
        FORCE_INLINE const T1 & verify(const T1 & v1, const T2 & v2, const wchar_t * exp_str)
        {
            if (v1 <= v2);
            else {
                _wassert(exp_str, file, line);
            }

            return v1;
        }
    };

    struct AnsiAssertLT : BasicAnsiAssert {
        FORCE_INLINE AnsiAssertLT(const char * file, unsigned int line) :
            BasicAnsiAssert(file, line)
        {
        }

        template <typename T1, typename T2>
        FORCE_INLINE const T1 & gtest_verify(const T1 & v1, const T2 & v2, const char * v1_str, const char * v2_str) const {
            const ::testing::AssertionResult exp_value = ::testing::internal::CmpHelperLT(v1_str, v2_str, v1, v2);
            const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure);
            if (break_on_failure) {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_);
            }
            else {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_);
            }
            ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure);

            return v1;
        }
    };

    struct WideAssertLT : BasicWideAssert {
        FORCE_INLINE WideAssertLT(const wchar_t * file, unsigned int line) :
            BasicWideAssert(file, line)
        {
        }

        // TIPS:
        // * to capture parameters by reference in macro definitions for single evaluation
        // * to suppress `unused variable` warnings like: `warning C4101: '...': unreferenced local variable`
        template<typename T1, typename T2>
        FORCE_INLINE const T1 & verify(const T1 & v1, const T2 & v2, const wchar_t * exp_str)
        {
            if (v1 < v2);
            else {
                _wassert(exp_str, file, line);
            }

            return v1;
        }
    };

    struct AnsiAssertGE : BasicAnsiAssert {
        FORCE_INLINE AnsiAssertGE(const char * file, unsigned int line) :
            BasicAnsiAssert(file, line)
        {
        }

        template <typename T1, typename T2>
        FORCE_INLINE const T1 & gtest_verify(const T1 & v1, const T2 & v2, const char * v1_str, const char * v2_str) const {
            const ::testing::AssertionResult exp_value = ::testing::internal::CmpHelperGE(v1_str, v2_str, v1, v2);
            const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure);
            if (break_on_failure) {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_);
            }
            else {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_);
            }
            ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure);

            return v1;
        }
    };

    struct WideAssertGE : BasicWideAssert {
        FORCE_INLINE WideAssertGE(const wchar_t * file, unsigned int line) :
            BasicWideAssert(file, line)
        {
        }

        // TIPS:
        // * to capture parameters by reference in macro definitions for single evaluation
        // * to suppress `unused variable` warnings like: `warning C4101: '...': unreferenced local variable`
        template<typename T1, typename T2>
        FORCE_INLINE const T1 & verify(const T1 & v1, const T2 & v2, const wchar_t * exp_str)
        {
            if (v1 >= v2);
            else {
                _wassert(exp_str, file, line);
            }

            return v1;
        }
    };

    struct AnsiAssertGT : BasicAnsiAssert {
        FORCE_INLINE AnsiAssertGT(const char * file, unsigned int line) :
            BasicAnsiAssert(file, line)
        {
        }

        template <typename T1, typename T2>
        FORCE_INLINE const T1 & gtest_verify(const T1 & v1, const T2 & v2, const char * v1_str, const char * v2_str) const {
            const ::testing::AssertionResult exp_value = ::testing::internal::CmpHelperGT(v1_str, v2_str, v1, v2);
            const bool break_on_failure = ::testing::GTEST_FLAG(break_on_failure);
            if (break_on_failure) {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_FATAL_FAILURE_);
            }
            else {
                GTEST_ASSERT_(exp_value, UTILITY_ASSERT_GTEST_NONFATAL_FAILURE_);
            }
            ASSERT_FAIL_BREAK_ON_ATTACHED_DEBUGGER(exp_value, !break_on_failure);

            return v1;
        }
    };

    struct WideAssertGT : BasicWideAssert {
        FORCE_INLINE WideAssertGT(const wchar_t * file, unsigned int line) :
            BasicWideAssert(file, line)
        {
        }

        // TIPS:
        // * to capture parameters by reference in macro definitions for single evaluation
        // * to suppress `unused variable` warnings like: `warning C4101: '...': unreferenced local variable`
        template<typename T1, typename T2>
        FORCE_INLINE const T1 & verify(const T1 & v1, const T2 & v2, const wchar_t * exp_str)
        {
            if (v1 > v2);
            else {
                _wassert(exp_str, file, line);
            }

            return v1;
        }
    };
}
