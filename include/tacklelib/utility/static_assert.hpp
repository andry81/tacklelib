#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_STATIC_ASSERT_HPP
#define UTILITY_STATIC_ASSERT_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/preprocessor.hpp>
#include <tacklelib/utility/type_identity.hpp>

#include <stdexcept>

// CAUTION:
//  Redundant parentheses are required here to bypass a tricky error in the GCC 5.4.x around expressions with `>` and `<` characters in case of usage inside another expressions with the same characters:
//      `error: wrong number of template arguments (1, should be at least 2)`
//      `error: macro "..." passed 2 arguments, but takes just 1`
//

// lookup compile time template typename value
#define UTILITY_CONSTEXPR_PARAM_LOOKUP_BY_ERROR(constexpr_param) \
    UTILITY_TYPENAME_LOOKUP_BY_ERROR(STATIC_ASSERT_PARAM(constexpr_param))

// generates compilation error and shows real type name (and place of declaration in some cases) in an error message, useful for debugging boost::mpl like recurrent types
#define UTILITY_TYPENAME_LOOKUP_BY_ERROR(type_name) \
    using _type_lookup_t = decltype((*(typename ::utility::type_lookup<type_name >::type*)0).operator ,(*(::utility::_not_overloadable_type *)0))

// the macro only for msvc compiler which has more useful error output if a scope class and a type are separated from each other
#if defined(UTILITY_COMPILER_CXX_MSC)

#define UTILITY_TYPENAME_LOOKUP_BY_ERROR_CLASS(class_name, type_name) \
    using _type_lookup_t = decltype((*(typename ::utility::type_lookup<class_name >::type_name*)0).operator ,(*(::utility::_not_overloadable_type *)0))

#else

#define UTILITY_TYPENAME_LOOKUP_BY_ERROR_CLASS(class_name, type_name) \
    UTILITY_TYPENAME_LOOKUP_BY_ERROR(class_name::type_name)

#endif

// lookup compile time size value
#define UTILITY_SIZE_LOOKUP_BY_ERROR(size)              char * __integral_lookup[size] = 1

// static asserts to use in an constexpr expression

#define STATIC_ASSERT_CONSTEXPR_TRUE(constexpr_exp, ...)            ((void)::utility::static_assert_constexpr<UTILITY_CONSTEXPR(constexpr_exp), ## __VA_ARGS__ >())
#define STATIC_ASSERT_CONSTEXPR_FALSE(constexpr_exp, ...)           ((void)::utility::static_assert_constexpr<!UTILITY_CONSTEXPR(constexpr_exp), ## __VA_ARGS__ >())

#define STATIC_ASSERT_CONSTEXPR_TRUE_ID(id, constexpr_exp, ...)     ((void)::utility::static_assert_constexpr_id<id, UTILITY_CONSTEXPR(constexpr_exp), ## __VA_ARGS__ >())
#define STATIC_ASSERT_CONSTEXPR_FALSE_ID(id, constexpr_exp, ...)    ((void)::utility::static_assert_constexpr_id<id, !UTILITY_CONSTEXPR(constexpr_exp), ## __VA_ARGS__ >())

// can examine non constexpr expression, throws error if false expression in a constexpr context
#define STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE(exp, ...)              ((void)((exp) ? true : ::utility::not_constexpr_context<-1, decltype(exp)>(__VA_ARGS__)))
#define STATIC_ASSERT_RELAXED_CONSTEXPR_FALSE(exp, ...)             ((void)(!(exp) ? true : ::utility::not_constexpr_context<-1, decltype(exp)>(__VA_ARGS__)))

#define STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE_ID(id, exp, ...)       ((void)((exp) ? true : ::utility::not_constexpr_context<id, decltype(exp)>(__VA_ARGS__)))
#define STATIC_ASSERT_RELAXED_CONSTEXPR_FALSE_ID(id, exp, ...)      ((void)(!(exp) ? true : ::utility::not_constexpr_context<id, decltype(exp)>(__VA_ARGS__)))

// NOTE:
//  The reason this exists is to enable print types of parameters inside an assert expression in a compiler errors output.
//  To do so we pass parameter values separately into template arguments to trigger a compiler to index them inside compile time error messages.
//
// Example:
//  STATIC_ASSERT_TRUE2(a != b, a, b, "my custom message"); // types of a and b will be printed in a compiler errors output in case if a == b
//

#define STATIC_ASSERT_PARAM(v1)                         ::utility::StaticAssertParam<decltype(v1), (v1)>
#define STATIC_ASSERT_VALUE(v1)                         (STATIC_ASSERT_PARAM(v1)::value)

#define STATIC_ASSERT_TRUE(exp, msg) \
    static_assert(::utility::StaticAssertTrue<decltype(exp), (exp)>::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)

#define STATIC_ASSERT_TRUE1(exp, v1, msg) \
    static_assert(::utility::StaticAssertTrue<decltype(exp), (exp), \
                  STATIC_ASSERT_PARAM(v1) >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_TRUE2(exp, v1, v2, msg) \
    static_assert(::utility::StaticAssertTrue<decltype(exp), (exp), \
                  STATIC_ASSERT_PARAM(v1), \
                  STATIC_ASSERT_PARAM(v2) >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_TRUE3(exp, v1, v2, v3, msg) \
    static_assert(::utility::StaticAssertTrue<decltype(exp), (exp), \
                  STATIC_ASSERT_PARAM(v1), \
                  STATIC_ASSERT_PARAM(v2), \
                  STATIC_ASSERT_PARAM(v3) >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_TRUE4(exp, v1, v2, v3, v4, msg) \
    static_assert(::utility::StaticAssertTrue<decltype(exp), (exp), \
                  STATIC_ASSERT_PARAM(v1), \
                  STATIC_ASSERT_PARAM(v2), \
                  STATIC_ASSERT_PARAM(v3), \
                  STATIC_ASSERT_PARAM(v4) >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)

#define STATIC_ASSERT_FALSE(exp, msg) \
    static_assert(::utility::StaticAssertFalse<decltype(exp), (exp)>::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)

#define STATIC_ASSERT_FALSE1(exp, v1, msg) \
    static_assert(::utility::StaticAssertFalse<decltype(exp), (exp), \
                  STATIC_ASSERT_PARAM(v1) >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_FALSE2(exp, v1, v2, msg) \
    static_assert(::utility::StaticAssertFalse<decltype(exp), (exp), \
                  STATIC_ASSERT_PARAM(v1), \
                  STATIC_ASSERT_PARAM(v2) >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_FALSE3(exp, v1, v2, v3, msg) \
    static_assert(::utility::StaticAssertFalse<decltype(exp), (exp), \
                  STATIC_ASSERT_PARAM(v1), \
                  STATIC_ASSERT_PARAM(v2), \
                  STATIC_ASSERT_PARAM(v3) >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)
#define STATIC_ASSERT_FALSE4(exp, v1, v2, v3, v4, msg) \
    static_assert(::utility::StaticAssertFalse<decltype(exp), (exp), \
                  STATIC_ASSERT_PARAM(v1), \
                  STATIC_ASSERT_PARAM(v2), \
                  STATIC_ASSERT_PARAM(v3), \
                  STATIC_ASSERT_PARAM(v4) >::value, "expression: \"" UTILITY_PP_STRINGIZE(exp) "\": " msg)

#define STATIC_ASSERT_EQ(v1, v2, msg)   static_assert(::utility::StaticAssertEQ<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " == " UTILITY_PP_STRINGIZE(v2) "\": " msg)
#define STATIC_ASSERT_NE(v1, v2, msg)   static_assert(::utility::StaticAssertNE<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " != " UTILITY_PP_STRINGIZE(v2) "\": " msg)
#define STATIC_ASSERT_LE(v1, v2, msg)   static_assert(::utility::StaticAssertLE<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " <= " UTILITY_PP_STRINGIZE(v2) "\": " msg)
#define STATIC_ASSERT_LT(v1, v2, msg)   static_assert(::utility::StaticAssertLT<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " < "  UTILITY_PP_STRINGIZE(v2) "\": " msg)
#define STATIC_ASSERT_GE(v1, v2, msg)   static_assert(::utility::StaticAssertGE<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " >= " UTILITY_PP_STRINGIZE(v2) "\": " msg)
#define STATIC_ASSERT_GT(v1, v2, msg)   static_assert(::utility::StaticAssertGT<decltype(v1), decltype(v2), (v1), (v2)>::value, "expression: \"" UTILITY_PP_STRINGIZE(v1) " > "  UTILITY_PP_STRINGIZE(v2) "\": " msg)


namespace utility
{
    // to generate an error upon a call in runtime
    template <int id, typename T, typename... Args>
    T not_constexpr_context(Args &&... args)
    {
        // exception in a constexpr context is not acceptable
        throw std::domain_error("must not be instantiated in constexpr context");
        return T();
    }

    // static assert to use in an constexpr expression

    template <bool v, typename...>
    CONSTEXPR_FUNC bool static_assert_constexpr()
    {
        static_assert(v, "static_assert_true failed.");
        return v;
    }

    template <int id, bool v, typename...>
    CONSTEXPR_FUNC bool static_assert_constexpr_id()
    {
        static_assert(v, "static_assert_true failed.");
        return v;
    }

    // static asserts to use in an statement

    template <typename T, T v>
    struct StaticAssertParam
    {
    };

    template <typename T, T v, typename... Params>
    struct StaticAssertTrue;

    template <typename T, T v>
    struct StaticAssertTrue<T, v>
    {
        static CONSTEXPR const bool value = (v ? true : false);
        // duplicate the error, to provoke compiler include complete error stack from here
        static_assert(v ? true : false, "StaticAssertTrue failed.");
    };

    template <typename T, T v>
    const bool StaticAssertTrue<T, v>::value;

    template <typename T, T v, typename... Params>
    struct StaticAssertTrue
    {
        static CONSTEXPR const bool value = (v ? true : false);
        // duplicate the error, to provoke compiler include complete error stack from here
        static_assert(v ? true : false, "StaticAssertTrue with parameters failed.");
    };

    template <typename T, T v, typename... Params>
    const bool StaticAssertTrue<T, v, Params...>::value;

    template <typename T, T v, typename... Params>
    struct StaticAssertFalse;

    template <typename T, T v>
    struct StaticAssertFalse<T, v>
    {
        static CONSTEXPR const bool value = (v ? false : true);
        // duplicate the error, to provoke compiler include complete error stack from here
        static_assert(v ? false : true, "StaticAssertFalse failed.");
    };

    template <typename T, T v>
    const bool StaticAssertFalse<T, v>::value;

    template <typename T, T v, typename... Params>
    struct StaticAssertFalse
    {
        static CONSTEXPR const bool value = ((void)StaticAssertFalse<T, v>{ "StaticAssertFalse with parameters failed." }, v ? false : true);
        // duplicate the error, to provoke compiler include complete error stack from here
        static_assert(v ? false : true, "StaticAssertFalse with parameters failed.");
    };

    template <typename T, T v, typename... Params>
    const bool StaticAssertFalse<T, v, Params...>::value;

    template <typename U, typename V, U u, V v>
    struct StaticAssertEQ
    {
        static CONSTEXPR const bool value = (u == v);
        // duplicate the error, to provoke compiler include complete error stack from here
        static_assert(u == v, "StaticAssertEQ failed.");
    };

    template <typename U, typename V, U u, V v>
    const bool StaticAssertEQ<U, V, u, v>::value;

    template <typename U, typename V, U u, V v>
    struct StaticAssertNE
    {
        static CONSTEXPR const bool value = (u != v);
        // duplicate the error, to provoke compiler include complete error stack from here
        static_assert(u != v, "StaticAssertNE failed.");
    };

    template <typename U, typename V, U u, V v>
    const bool StaticAssertNE<U, V, u, v>::value;

    template <typename U, typename V, U u, V v>
    struct StaticAssertLE
    {
        static CONSTEXPR const bool value = (u <= v);
        // duplicate the error, to provoke compiler include complete error stack from here
        static_assert(u <= v, "StaticAssertLE failed.");
    };

    template <typename U, typename V, U u, V v>
    const bool StaticAssertLE<U, V, u, v>::value;

    template <typename U, typename V, U u, V v>
    struct StaticAssertLT
    {
        static CONSTEXPR const bool value = (u < v);
        // duplicate the error, to provoke compiler include complete error stack from here
        static_assert(u < v, "StaticAssertLT failed.");
    };

    template <typename U, typename V, U u, V v>
    const bool StaticAssertLT<U, V, u, v>::value;

    template <typename U, typename V, U u, V v>
    struct StaticAssertGE
    {
        static CONSTEXPR const bool value = (u >= v);
        // duplicate the error, to provoke compiler include complete error stack from here
        static_assert(u >= v, "StaticAssertGE failed.");
    };

    template <typename U, typename V, U u, V v>
    const bool StaticAssertGE<U, V, u, v>::value;

    template <typename U, typename V, U u, V v>
    struct StaticAssertGT
    {
        static CONSTEXPR const bool value = (u > v);
        // duplicate the error, to provoke compiler include complete error stack from here
        static_assert(u > v, "StaticAssertGT failed.");
    };

    template <typename U, typename V, U u, V v>
    const bool StaticAssertGT<U, V, u, v>::value;
}

#endif
