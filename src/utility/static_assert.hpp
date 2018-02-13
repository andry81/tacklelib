#pragma once

#include <tacklelib.hpp>

#include <utility/preprocessor.hpp>


#define STATIC_ASSERT_TRUE(exp, msg)    static_assert(::utility::StaticAssertTrue<decltype(exp), (exp)>::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_TRUE1(exp, v1, msg) \
    static_assert(::utility::StaticAssertTrue<decltype(exp), (exp), \
                  ::utility::StaticAssertParam<decltype(v1), (v1)> >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_TRUE2(exp, v1, v2, msg) \
    static_assert(::utility::StaticAssertTrue<decltype(exp), (exp), \
                  ::utility::StaticAssertParam<decltype(v1), (v1)>, \
                  ::utility::StaticAssertParam<decltype(v2), (v2)> >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_TRUE3(exp, v1, v2, v3, msg) \
    static_assert(::utility::StaticAssertTrue<decltype(exp), (exp), \
                  ::utility::StaticAssertParam<decltype(v1), (v1)>, \
                  ::utility::StaticAssertParam<decltype(v2), (v2)>, \
                  ::utility::StaticAssertParam<decltype(v3), (v3)> >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_TRUE4(exp, v1, v2, v3, v4, msg) \
    static_assert(::utility::StaticAssertTrue<decltype(exp), (exp), \
                  ::utility::StaticAssertParam<decltype(v1), (v1)>, \
                  ::utility::StaticAssertParam<decltype(v2), (v2)>, \
                  ::utility::StaticAssertParam<decltype(v3), (v3)>, \
                  ::utility::StaticAssertParam<decltype(v4), (v4)> >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)

#define STATIC_ASSERT_FALSE(exp, msg)   static_assert(::utility::StaticAssertFalse<decltype(exp), (exp)>::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_FALSE1(exp, v1, msg) \
    static_assert(::utility::StaticAssertFalse<decltype(exp), (exp), \
                  ::utility::StaticAssertParam<decltype(v1), (v1)> >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_FALSE2(exp, v1, v2, msg) \
    static_assert(::utility::StaticAssertFalse<decltype(exp), (exp), \
                  ::utility::StaticAssertParam<decltype(v1), (v1)>, \
                  ::utility::StaticAssertParam<decltype(v2), (v2)> >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_FALSE3(exp, v1, v2, v3, msg) \
    static_assert(::utility::StaticAssertFalse<decltype(exp), (exp), \
                  ::utility::StaticAssertParam<decltype(v1), (v1)>, \
                  ::utility::StaticAssertParam<decltype(v2), (v2)>, \
                  ::utility::StaticAssertParam<decltype(v3), (v3)> >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_FALSE4(exp, v1, v2, v3, v4, msg) \
    static_assert(::utility::StaticAssertFalse<decltype(exp), (exp), \
                  ::utility::StaticAssertParam<decltype(v1), (v1)>, \
                  ::utility::StaticAssertParam<decltype(v2), (v2)>, \
                  ::utility::StaticAssertParam<decltype(v3), (v3)>, \
                  ::utility::StaticAssertParam<decltype(v4), (v4)> >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)

#define STATIC_ASSERT_EQ(v1, v2, msg)   static_assert(::utility::StaticAssertEQ<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " == " UTILITY_PP_STRINGIZE(v2) "\": " msg)
#define STATIC_ASSERT_NE(v1, v2, msg)   static_assert(::utility::StaticAssertNE<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " != " UTILITY_PP_STRINGIZE(v2) "\": " msg)
#define STATIC_ASSERT_LE(v1, v2, msg)   static_assert(::utility::StaticAssertLE<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " <= " UTILITY_PP_STRINGIZE(v2) "\": " msg)
#define STATIC_ASSERT_LT(v1, v2, msg)   static_assert(::utility::StaticAssertLT<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " < "  UTILITY_PP_STRINGIZE(v2) "\": " msg)
#define STATIC_ASSERT_GE(v1, v2, msg)   static_assert(::utility::StaticAssertGE<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " >= " UTILITY_PP_STRINGIZE(v2) "\": " msg)
#define STATIC_ASSERT_GT(v1, v2, msg)   static_assert(::utility::StaticAssertGT<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " > "  UTILITY_PP_STRINGIZE(v2) "\": " msg)


namespace utility
{
    template <typename T, T v>
    struct StaticAssertParam
    {
    };

    template <typename T, T v, typename ...Params>
    struct StaticAssertTrue;

    template <typename T, T v>
    struct StaticAssertTrue<T, v>
    {
        static const bool value = (v ? true : false);
    };

    template <typename T, T v, typename ...Params>
    struct StaticAssertTrue
    {
        static const bool value = (v ? true : false);
        static_assert(v ? true : false, "StaticAssertTrue with parameters failed.");
    };

    template <typename T, T v, typename ...Params>
    struct StaticAssertFalse;

    template <typename T, T v>
    struct StaticAssertFalse<T, v>
    {
        static const bool value = (v ? false : true);
    };

    template <typename T, T v, typename ...Params>
    struct StaticAssertFalse
    {
        static const bool value = (v ? false : true);
        static_assert(v ? false : true, "StaticAssertFalse with parameters failed.");
    };

    template <typename U, typename V, U u, V v>
    struct StaticAssertEQ
    {
        static const bool value = (u == v);
        static_assert(u == v, "StaticAssertEQ failed.");
    };

    template <typename U, typename V, U u, V v>
    struct StaticAssertNE
    {
        static const bool value = (u != v);
        static_assert(u != v, "StaticAssertNE failed.");
    };

    template <typename U, typename V, U u, V v>
    struct StaticAssertLE
    {
        static const bool value = (u <= v);
        static_assert(u <= v, "StaticAssertLE failed.");
    };

    template <typename U, typename V, U u, V v>
    struct StaticAssertLT
    {
        static const bool value = (u < v);
        static_assert(u < v, "StaticAssertLT failed.");
    };

    template <typename U, typename V, U u, V v>
    struct StaticAssertGE
    {
        static const bool value = (u >= v);
        static_assert(u >= v, "StaticAssertGE failed.");
    };

    template <typename U, typename V, U u, V v>
    struct StaticAssertGT
    {
        static const bool value = (u > v);
        static_assert(u > v, "StaticAssertGT failed.");
    };
}
