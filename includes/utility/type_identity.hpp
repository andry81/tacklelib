#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_TYPE_IDENTITY_HPP
#define UTILITY_TYPE_IDENTITY_HPP

#include <tacklelib.hpp>

#include <utility/preprocessor.hpp>
#include <utility/platform.hpp>
#include <utility/static_assert.hpp> // required here only for UTILITY_PARAM_LOOKUP_BY_ERROR macro

#include <type_traits>


// to suppress warnings around compile time expression or values
#define UTILITY_CONST_EXPR(exp) ::utility::const_expr<(exp) ? true : false>::value

// generates compilation error and shows real type name (and place of declaration in some cases) in an error message, useful for debugging boost::mpl like recurrent types
#define UTILITY_TYPE_LOOKUP_BY_ERROR(type_name) \
    using _type_lookup_t = decltype((*(typename ::utility::type_lookup<type_name >::type*)0).operator ,(*(::utility::_not_overloadable_type *)0))

// the macro only for msvc compiler which has more useful error output if a scope class and a type are separated from each other
#if defined(UTILITY_COMPILER_CXX_MSC)

#define UTILITY_TYPE_LOOKUP_BY_ERROR_CLASS(class_name, type_name) \
    using _type_lookup_t = decltype((*(typename ::utility::type_lookup<class_name >::type_name*)0).operator ,(*(::utility::_not_overloadable_type *)0))

#else

#define UTILITY_TYPE_LOOKUP_BY_ERROR_CLASS(class_name, type_name) \
    UTILITY_TYPE_LOOKUP_BY_ERROR(class_name::type_name)

#endif

// lookup compile time template typename value
#define UTILITY_PARAM_LOOKUP_BY_ERROR(static_param) \
    UTILITY_TYPE_LOOKUP_BY_ERROR(STATIC_ASSERT_PARAM(static_param))

// lookup compile time size value
#define UTILITY_SIZE_LOOKUP_BY_ERROR(size) \
    char * __integral_lookup[size] = 1

// available in GCC from version 4.3, for details see: https://stackoverflow.com/questions/1625105/how-to-write-is-complete-template/1956217#1956217
#define UTILITY_IS_TYPE_COMPLETE(type) ::utility::is_type_complete<type, __COUNTER__>::value


namespace utility
{
    // replacement for mpl::void_, useful to suppress excessive errors output in particular places
    struct void_ { typedef void_ type; };

    // to suppress `warning C4127: conditional expression is constant`
    template <bool B>
    struct const_expr
    {
        static CONSTEXPR const bool value = B;
    };

namespace {

    struct _not_overloadable_type {};

}

    template <typename T>
    struct type_lookup
    {
        using type = T;
    };

    namespace
    {
        template<class T, int discriminator>
        struct is_type_complete {
            static T & getT();
            static char(&pass(T))[2];
            static char pass(...);
            static CONSTEXPR const bool value = sizeof(pass(getT())) == 2;
        };
    }

    // std::identity is depricated in msvc2017

    template <typename T>
    struct identity
    {
        using type = T;
    };

    // type-by-value identity

    template <typename T, T v>
    struct value_identity
    {
        using type = T;
        static CONSTEXPR const T value = v;
    };

    template <typename T, T v>
    CONSTEXPR const T value_identity<T, v>::value;

    template <bool b>
    struct bool_identity
    {
        using type = bool;
        static CONSTEXPR const bool value = b;
    };

    template <int v>
    struct int_identity
    {
        using type = int;
        static CONSTEXPR const int value = v;
    };

    // for explicit partial specialization of type_index_identity_base

    template <typename T, int Index>
    struct type_index_identity
    {
        using type = T;
        static constexpr const int index = Index;
    };

    template <typename T, int Index>
    struct type_index_identity_base; // : type_index_identity<T, Index> {};

    // The `dependent_*` classes to provoke compiler to instantiate a template by a dependent template argument to evaluate the value only after template instantiation.
    // This is useful in contexts where a static_assert could be evaluated inside a class template before it's instantiation.
    // For details, see: https://stackoverflow.com/questions/5246049/c11-static-assert-and-template-instantiation/5246686#5246686
    //

    template <typename T>
    struct dependent_type
    {
        using type = T;
        static CONSTEXPR const bool false_value = !std::is_same<type, type>::value;
    };

    template <typename T, T v>
    struct dependent_value
    {
        using type = T;
        static CONSTEXPR const bool false_value = !std::is_same<value_identity<type, v>, value_identity<type, v> >::value;
    };

    template <bool B>
    struct dependent_bool
    {
        static CONSTEXPR const bool false_value = !std::is_same<bool_identity<B>, bool_identity<B> >::value;
    };

    template <int N>
    struct dependent_int
    {
        static CONSTEXPR const bool false_value = !std::is_same<int_identity<N>, int_identity<N> >::value;
    };

}

#endif
