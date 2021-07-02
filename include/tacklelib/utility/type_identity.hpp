#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_TYPE_IDENTITY_HPP
#define UTILITY_TYPE_IDENTITY_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/preprocessor.hpp>
#include <tacklelib/utility/platform.hpp>
//#include <tacklelib/utility/string_identity.hpp>
//#include <tacklelib/utility/crc.hpp>

#include <cstdint>
#include <type_traits>
#include <tuple>


// CAUTION:
//  Redundant parentheses are required here to bypass a tricky error in the GCC 5.4.x around expressions with `>` and `<` characters in case of usage inside another expressions with the same characters:
//      `error: wrong number of template arguments (1, should be at least 2)`
//      `error: macro "..." passed 2 arguments, but takes just 1`
//

// * to suppress warnings around compile time expressions or values
// * to guarantee compile-timeness of an expression
#define UTILITY_CONSTEXPR(exp)                          (::utility::constexpr_bool<(exp) ? true : false>::value)

// to force compiler evaluate constexpr at compile time even in the debug configuration with disabled optimizations
#define UTILITY_CONSTEXPR_VALUE(exp)                    (::utility::constexpr_value<decltype(exp), (exp)>::value)

// 1. available in GCC from version 4.3, for details see: https://stackoverflow.com/questions/1625105/how-to-write-is-complete-template/1956217#1956217
// 2. additionally using crc32 hashing to make an unique call instantiation in different translation units over the same type
//
#define UTILITY_IS_TYPE_COMPLETE(type)                  (::utility::is_type_complete<(type), \
    UTILITY_CONSTEXPR_VALUE((::utility::constexpr_crc(32, ::utility::g_crc32_04C11DB7, 0U, UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(__FILE__ ":" UTILITY_PP_STRINGIZE(__LINE__) ":" UTILITY_PP_STRINGIZE(__COUNTER__)), 0U, 0xFFFFFFFFU, 0xFFFFFFFFU, true, true))) \
    >::value)

// Checks expression on constexpr nature.
//
// Based on:
//  https://stackoverflow.com/questions/13299394/is-is-constexpr-possible-in-c11/13305072#13305072
//  https://www.reddit.com/r/cpp/comments/7c208c/is_constexpr_a_macro_that_check_if_an_expression/
//
// CAUTION:
//
//  Where it does work:
//  * This will work at least in C++11 compilers: GCC 5.4, MSVC 2015 Update 3 and clang 3.8.0.
//  * This will work on void returning functions with implementation.
//  * This will work on variables in any scope.
//
//  Where it does not work:
//  * This won't work on function declarations.
//  * This won't work on void returning functions without implementation (tip: all `constexpr` functions in C++11 must consist only from a single and not a void return statement).
//
#ifndef UTILITY_COMPILER_CXX_CLANG
#define UTILITY_IS_CONSTEXPR_VALUE(...)                 UTILITY_CONSTEXPR(noexcept(::utility::makeprval((__VA_ARGS__, 0))))
#else
#define UTILITY_IS_CONSTEXPR_VALUE(...)                 UTILITY_CONSTEXPR(__builtin_constant_p((__VA_ARGS__, 0)))   // can be used for the GCC too
#endif

#define UTILITY_DEPENDENT_TYPENAME_COMPILE_ERROR_BY_INCOMPLETE_TYPE(dependent_type_name) \
    using UTILITY_PP_CONCAT(dependent_typename_compiler_error_by_incomplete_type_t, UTILITY_PP_LINE) = typename ::utility::incomplete_dependent_type<dependent_type_name>::type

#define UTILITY_CONSTEXPR_ARRAY_SIZE(c_arr)             UTILITY_CONSTEXPR_VALUE(sizeof(c_arr) / sizeof((c_arr)[0]))
#define UTILITY_CONSTEXPR_STRING_LENGTH(c_str)          UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(c_str) - 1)

#define UTILITY_STATIC_SIZE(seq)                        (::utility::static_size(seq))
#define UTILITY_STATIC_LENGTH(seq)                      (::utility::static_size(seq) - 1)

#define UTILITY_CONSTEXPR_SIZE(seq)                     UTILITY_CONSTEXPR_VALUE(UTILITY_STATIC_SIZE(seq))
#define UTILITY_CONSTEXPR_LENGTH(seq)                   UTILITY_CONSTEXPR_VALUE(UTILITY_STATIC_LENGTH(seq))

#define UTILITY_CONSTEXPR_GET(value, constexpr_index)   (::utility::constexpr_get<constexpr_index>(value))

#define UTILITY_GET(value, constexpr_index)             (::utility::get<constexpr_index>(value))


// define a tag type using int_identity class (through the using keyword)
#define UTILITY_DEFINE_INT_IDENTITY_AS_USING_TYPE_TAG(tag_token, ...) \
    using tag_ ## tag_token ## _t = ::utility::int_identity<UTILITY_PP_IIF(UTILITY_PP_IS_EMPTY(__VA_ARGS__))(tag_token, (__VA_ARGS__))>

// define a tag type and a constant using int_identity class (through the using keyword)
#define UTILITY_DEFINE_INT_IDENTITY_AS_USING_TYPE_TAG_AND_CONSTEXPR_CONSTANT(tag_token, ...) \
    UTILITY_DEFINE_INT_IDENTITY_AS_USING_TYPE_TAG(tag_token, __VA_ARGS__); \
    const CONSTEXPR tag_ ## tag_token ## _t tag_ ## tag_token{}

// define a tag type using int_identity class (through a derived struct)
#define UTILITY_DEFINE_INT_IDENTITY_AS_DERIVED_STRUCT_TAG(tag_token, ...) \
    struct tag_ ## tag_token ## _t : ::utility::int_identity<UTILITY_PP_IIF(UTILITY_PP_IS_EMPTY(__VA_ARGS__))(tag_token, (__VA_ARGS__))> {}

// define a tag type and a constant using int_identity class (through a derived struct)
#define UTILITY_DEFINE_INT_IDENTITY_AS_DERIVED_STRUCT_TAG_AND_CONSTEXPR_CONSTANT(tag_token, ...) \
    UTILITY_DEFINE_INT_IDENTITY_AS_DERIVED_STRUCT_TAG(tag_token, __VA_ARGS__); \
    const CONSTEXPR tag_ ## tag_token ## _t tag_ ## tag_token{}


// Checks existence of member function.
// Based on: https://stackoverflow.com/questions/257288/is-it-possible-to-write-a-template-to-check-for-a-functions-existence/264088#264088
//

// detection of static or not static functions depended on FuncSignature template argument
#define DEFINE_UTILITY_MEMBER_FUNCTION_CHECKER_WITH_SIGNATURE(checker_name, func_name) \
    template<typename FuncScopeType, typename FuncSignature> \
    struct checker_name \
    { \
        static_assert(std::is_pointer<FuncSignature>::value || std::is_member_pointer<FuncSignature>::value, \
            "FuncSignature must be a pointer or pointer to member type"); \
        \
        using yes = char[1]; \
        using no  = char[2]; \
        \
        template <typename U_, U_> struct type_check_any; \
        template <typename T_>  static yes & check(type_check_any<FuncSignature, &T_::func_name> *); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<FuncScopeType>(nullptr)) == sizeof(yes)); \
    };

// detection of static only functions depended on FuncSignature template argument
#define DEFINE_UTILITY_STATIC_MEMBER_FUNCTION_CHECKER_WITH_SIGNATURE(checker_name, func_name) \
    template<typename FuncScopeType, typename FuncSignature> \
    struct checker_name \
    { \
        static_assert(!std::is_pointer<FuncSignature>::value && !std::is_member_pointer<FuncSignature>::value, \
            "FuncSignature must not be a pointer or pointer to member, use plain function type"); \
        \
        using yes = char[1]; \
        using no  = char[2]; \
        \
        template <typename U_, U_ *> struct type_check_free_pointer; \
        template <typename T_>  static yes & check(type_check_free_pointer<FuncSignature, &T_::func_name> *); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<FuncScopeType>(nullptr)) == sizeof(yes)); \
    };

// detection of not static only functions depended on FuncSignature template argument
#define DEFINE_UTILITY_NOTSTATIC_MEMBER_FUNCTION_CHECKER_WITH_SIGNATURE(checker_name, func_name) \
    template<typename FuncScopeType, typename FuncSignature> \
    struct checker_name \
    { \
        static_assert(std::is_member_pointer<FuncSignature>::value, "FuncSignature must be a pointer to member"); \
        \
        using yes = char[1]; \
        using no  = char[2]; \
        \
        template <FuncSignature> struct type_check_not_static_pointer {}; \
        template <typename T_>  static yes & check(type_check_not_static_pointer<&T_::func_name> *); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<FuncScopeType>(nullptr)) == sizeof(yes)); \
    };

// Checks existence of data member depended on MemberType template argument
// Based on: https://stackoverflow.com/questions/257288/is-it-possible-to-write-a-template-to-check-for-a-functions-existence/264088#264088
//

// detection of static or not static functions depended on MemberType template argument
#define DEFINE_UTILITY_MEMBER_DATA_CHECKER_WITH_SIGNATURE(checker_name, member_name) \
    template<typename MemberScopeType, typename MemberType> \
    struct checker_name \
    { \
        using unqual_member_type = typename std::remove_reference<MemberType>::type; \
        \
        using yes = char[1]; \
        using no  = char[2]; \
        \
        template <typename U_, U_> struct type_check_any; \
        template <typename T_>  static yes & check(type_check_any<unqual_member_type, &T_::member_name> *); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<MemberScopeType>(nullptr)) == sizeof(yes)); \
    };

// detection of static only functions depended on MemberType template argument
#define DEFINE_UTILITY_STATIC_MEMBER_DATA_CHECKER_WITH_SIGNATURE(checker_name, member_name) \
    template<typename MemberScopeType, typename MemberType> \
    struct checker_name \
    { \
        using unqual_member_type = typename std::remove_reference<MemberType>::type; \
        \
        using yes = char[1]; \
        using no  = char[2]; \
        \
        template <typename U_, U_ *> struct type_check_free_pointer; \
        template <typename T_>  static yes & check(type_check_free_pointer<unqual_member_type, &T_::member_name> *); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<MemberScopeType>(nullptr)) == sizeof(yes)); \
    };

// detection of not static only functions depended on MemberType template argument
#define DEFINE_UTILITY_NOTSTATIC_MEMBER_DATA_CHECKER_WITH_SIGNATURE(checker_name, member_name) \
    template<typename MemberScopeType, typename MemberType> \
    struct checker_name \
    { \
        using unqual_member_type = typename std::remove_reference<MemberType>::type; \
        \
        using yes = char[1]; \
        using no  = char[2]; \
        \
        template <typename U_, typename T_, U_ T_::*> struct type_check_not_static_pointer {}; \
        template <typename T_>  static yes & check(type_check_not_static_pointer<unqual_member_type, T_, &T_::member_name> *); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<MemberScopeType>(nullptr)) == sizeof(yes)); \
    };


// Checks existence of data member.
// Based on: https://stackoverflow.com/questions/15232758/detecting-constexpr-with-sfinae/15236647#15236647 
//

// detects only static data members
#define DEFINE_UTILITY_STATIC_MEMBER_DATA_CHECKER(checker_name, member_name) \
    template<typename MemberScopeType> \
    struct checker_name \
    { \
        using no  = char[1]; \
        using yes = char[2]; \
        \
        template <typename U_, U_ *> struct yes_free_pointer { yes yes_; }; \
        template <typename T_>  static yes_free_pointer<decltype(T_::member_name), &T_::member_name> & check(int); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<MemberScopeType>(0)) == sizeof(yes)); \
    };

// detects only not static data members
#define DEFINE_UTILITY_NOTSTATIC_MEMBER_DATA_CHECKER(checker_name, member_name) \
    template<typename MemberScopeType> \
    struct checker_name \
    { \
        using no  = char[1]; \
        using yes = char[2]; \
        \
        template <typename U_, typename T_, U_ T_::*> struct yes_not_static_pointer { yes yes_;}; \
        template <typename T_>  static yes_not_static_pointer<decltype(T_::member_name), T_, &T_::member_name> & check(int); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<MemberScopeType>(0)) == sizeof(yes)); \
    };


// Checks existence of constexpr member function.
// Based on: https://stackoverflow.com/questions/15232758/detecting-constexpr-with-sfinae/15236647#15236647 
//

// detects only static constexpr functions
#define DEFINE_UTILITY_STATIC_CONSTEXPR_MEMBER_FUNCTION_CHECKER_WITH_ARGS(checker_name, func_name, ...) \
    template<typename FuncScopeType> \
    struct checker_name \
    { \
        using no  = char[1]; \
        using yes = char[2]; \
        \
        template<int> struct yes_static_constexpr { yes yes_; }; \
        template <typename T_>  static yes_static_constexpr<(T_::func_name(__VA_ARGS__), 0)> & check(int); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<FuncScopeType>(0)) == sizeof(yes)); \
    };

// detects only static constexpr functions
#define DEFINE_UTILITY_STATIC_CONSTEXPR_MEMBER_FUNCTION_CHECKER(checker_name, func_call) \
    template<typename FuncScopeType> \
    struct checker_name \
    { \
        using no  = char[1]; \
        using yes = char[2]; \
        \
        template<int> struct yes_static_constexpr { yes yes_; }; \
        template <typename T_>  static yes_static_constexpr<(T_::func_call, 0)> & check(int); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<FuncScopeType>(0)) == sizeof(yes)); \
    };

// detects static constexpr or not static constexpr functions
#define DEFINE_UTILITY_CONSTEXPR_MEMBER_FUNCTION_CHECKER_WITH_ARGS(checker_name, func_name, ...) \
    template<typename FuncScopeType> \
    struct checker_name \
    { \
        using no  = char[1]; \
        using yes = char[2]; \
        \
        template<int> struct yes_any_constexpr { yes yes_; }; \
        template <typename T_>  static yes_any_constexpr<(static_cast<T_ *>(nullptr)->func_name(__VA_ARGS__), 0)> & check(int); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<FuncScopeType>(0)) == sizeof(yes)); \
    };

// detects static constexpr or not static constexpr functions
#define DEFINE_UTILITY_CONSTEXPR_MEMBER_FUNCTION_CHECKER(checker_name, func_call) \
    template<typename FuncScopeType> \
    struct checker_name \
    { \
        using no  = char[1]; \
        using yes = char[2]; \
        \
        template<int> struct yes_any_constexpr { yes yes_; }; \
        template <typename T_>  static yes_any_constexpr<(static_cast<T_ *>(nullptr)->func_call, 0)> & check(int); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<FuncScopeType>(0)) == sizeof(yes)); \
    };

// Checks existence of constexpr data member.
// Based on: https://stackoverflow.com/questions/15232758/detecting-constexpr-with-sfinae/15236647#15236647 
//

// incomplete
/*
// detects only static constexpr data members
#define DEFINE_UTILITY_STATIC_CONSTEXPR_MEMBER_CHECKER(checker_name, member_name) \
    template<typename MemberScopeType> \
    struct checker_name \
    { \
        using no  = char[1]; \
        using yes = char[2]; \
        \
        template<int> struct yes_any_constexpr { yes yes_; }; \
        template <typename U_, U_ *> struct free_pointer {}; \
        template <typename T_>  static yes_any_constexpr<(free_pointer<decltype(T_::member_name), &T_::member_name>{}, 0)> & check(int); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<MemberScopeType>(0)) == sizeof(yes)); \
    };

// detects static constexpr or not static constexpr data members
#define DEFINE_UTILITY_CONSTEXPR_MEMBER_CHECKER(checker_name, member_name, ...) \
    template<typename MemberScopeType> \
    struct checker_name \
    { \
        using no  = char[1]; \
        using yes = char[2]; \
        \
        template<int> struct yes_any_constexpr { yes yes_; }; \
        template <typename U_, typename T_, U_ T_::*> struct not_static_pointer { yes yes_;}; \
        template <typename T_>  static yes_any_constexpr<(not_static_pointer<decltype(T_::member_name), T_, &T_::member_name>{}, 0)> & check(int); \
        template <typename>     static no & check(...); \
        \
        static CONSTEXPR const bool value = (sizeof(check<MemberScopeType>(0)) == sizeof(yes)); \
    };*/

namespace utility
{
    //// containers

    // replacement for mpl::void_, useful to suppress excessive errors output in particular places
    struct void_ { using type = void_; };

    // to suppress `warning C4127: conditional expression is constant`
    template <bool B, typename...>
    struct constexpr_bool
    {
        static CONSTEXPR const bool value = B;
    };

    template <bool B, typename... types>
    const bool constexpr_bool<B, types...>::value;

    // to force compiler evaluate constexpr at compile time even in the debug configuration with disabled optimizations
    template <typename T, T v, typename...>
    struct constexpr_value
    {
        static CONSTEXPR const T value = v;
    };

    template <typename T, T v, typename... types>
    const T constexpr_value<T, v, types...>::value;

    namespace
    {
        struct _not_overloadable_type {};
    }

    template <typename T, typename...>
    struct type_lookup
    {
        using type = T;
    };

    template <typename T>
    struct incomplete_dependent_type;

    namespace
    {
        template<class T, int discriminator>
        struct is_type_complete
        {
            static T & getT();
            static char (& pass(T))[2];
            static char pass(...);
            static CONSTEXPR const bool value = (sizeof(pass(getT())) == 2);
        };
    }

    // std::identity is depricated in msvc2017

    template <typename T>
    struct identity
    {
        using type = T;
    };

    // tuple identities

    template <typename... Type>
    struct tuple_identities
    {
        using tuple_type = std::tuple<Type...>;
    };

    // value identity / identities

    template <typename T, T v>
    struct value_identity
    {
        using type = T;
        static CONSTEXPR const T value = v;
    };

    template <typename T, T v>
    CONSTEXPR const T value_identity<T, v>::value;

    template <typename T, T... v>
    struct value_identities
    {
        using type = T;
        static CONSTEXPR const T values[] = { v... };
    };

    // bool identity / identities

    template <bool b>
    struct bool_identity
    {
        using type = bool;
        static CONSTEXPR const bool value = b;
    };

    template <bool b>
    CONSTEXPR const bool bool_identity<b>::value;

    template <bool... b>
    struct bool_identities
    {
        using type = bool;
        static CONSTEXPR const bool values[] = { b... };
    };

    // int identity / identities

    template <int v>
    struct int_identity
    {
        using type = int;
        static CONSTEXPR const type value = v;
    };

    template <int v>
    CONSTEXPR const int int_identity<v>::value;

    template <int... v>
    struct int_identities
    {
        using type = int;
        static CONSTEXPR const type values[] = { v... };
    };

    // size identity / identities

    template <size_t v>
    struct size_identity
    {
        using type = size_t;
        static CONSTEXPR const type value = v;
    };

    template <size_t v>
    CONSTEXPR const size_t size_identity<v>::value;

    template <size_t... v>
    struct size_identities
    {
        using type = size_t;
        static CONSTEXPR const type values[] = { v... };
    };

    // int8_t identity / identities

    template <int8_t v>
    struct int8_identity
    {
        using type = int8_t;
        static CONSTEXPR const type value = v;
    };

    template <int8_t v>
    CONSTEXPR const int8_t int8_identity<v>::value;

    template <int8_t... v>
    struct int8_identities
    {
        using type = int8_t;
        static CONSTEXPR const type values[] = { v... };
    };

    // uint8_t identity / identities

    template <uint8_t v>
    struct uint8_identity
    {
        using type = uint8_t;
        static CONSTEXPR const type value = v;
    };

    template <uint8_t v>
    CONSTEXPR const uint8_t uint8_identity<v>::value;

    template <uint8_t... v>
    struct uint8_identities
    {
        using type = uint8_t;
        static CONSTEXPR const type values[] = { v... };
    };

    // int16_t identity / identities

    template <int16_t v>
    struct int16_identity
    {
        using type = int16_t;
        static CONSTEXPR const type value = v;
    };

    template <int16_t v>
    CONSTEXPR const int16_t int16_identity<v>::value;

    template <int16_t... v>
    struct int16_identities
    {
        using type = int16_t;
        static CONSTEXPR const type values[] = { v... };
    };

    // uint16_t identity / identities

    template <uint16_t v>
    struct uint16_identity
    {
        using type = uint16_t;
        static CONSTEXPR const type value = v;
    };

    template <uint16_t v>
    CONSTEXPR const uint16_t uint16_identity<v>::value;

    template <uint16_t... v>
    struct uint16_identities
    {
        using type = uint16_t;
        static CONSTEXPR const type values[] = { v... };
    };

    // int32_t identity / identities

    template <int32_t v>
    struct int32_identity
    {
        using type = int32_t;
        static CONSTEXPR const type value = v;
    };

    template <int32_t v>
    CONSTEXPR const int32_t int32_identity<v>::value;

    template <int32_t... v>
    struct int32_identities
    {
        using type = int32_t;
        static CONSTEXPR const type values[] = { v... };
    };

    // uint32_t identity / identities

    template <uint32_t v>
    struct uint32_identity
    {
        using type = uint32_t;
        static CONSTEXPR const type value = v;
    };

    template <uint32_t v>
    CONSTEXPR const uint32_t uint32_identity<v>::value;

    template <uint32_t... v>
    struct uint32_identities
    {
        using type = uint32_t;
        static CONSTEXPR const type values[] = { v... };
    };

    // int64_t identity / identities

    template <int64_t v>
    struct int64_identity
    {
        using type = int64_t;
        static CONSTEXPR const type value = v;
    };

    template <int64_t v>
    CONSTEXPR const int64_t int64_identity<v>::value;

    template <int64_t... v>
    struct int64_identities
    {
        using type = int64_t;
        static CONSTEXPR const type values[] = { v... };
    };

    // uint64_t identity / identities

    template <uint64_t v>
    struct uint64_identity
    {
        using type = uint64_t;
        static CONSTEXPR const type value = v;
    };

    template <uint64_t v>
    CONSTEXPR const uint64_t uint64_identity<v>::value;

    template <uint64_t... v>
    struct uint64_identities
    {
        using type = uint64_t;
        static CONSTEXPR const type values[] = { v... };
    };

    // for explicit partial specialization of type_index_identity_base

    template <typename T, int Index>
    struct type_index_identity
    {
        using type = T;
        static CONSTEXPR const int index = Index;
    };

    template <typename T, int Index>
    CONSTEXPR const int type_index_identity<T, Index>::index;

    template <typename T, int... Index>
    struct type_index_identities
    {
        using type = T;
        static CONSTEXPR const int indexes[] = { Index... };
    };

    template <typename T, int Index>
    struct type_index_identity_base; // : type_index_identity<T, Index> {};

    // The `dependent_*` classes to provoke compiler to instantiate a template by a dependent template argument to evaluate the value only after template instantiation.
    // This is useful in contexts where a static_assert could be evaluated inside a class template before it's instantiation.
    // For details, see: https://stackoverflow.com/questions/5246049/c11-static-assert-and-template-instantiation/5246686#5246686
    //

    template <typename T, typename U = void>
    struct dependent_type
    {
        using type      = T;
        using user_type = U;
        static CONSTEXPR const bool false_value = !std::is_same<type, type>::value;
    };

    template <typename T, T v>
    struct dependent_value
    {
        using type      = T;
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

    template <size_t S>
    struct dependent_size
    {
        static CONSTEXPR const bool false_value = !std::is_same<size_identity<S>, size_identity<S> >::value;
    };

    // custom more convenient `enable_if` implementation.
    // Based on: https://www.reddit.com/r/cpp_questions/comments/3zn1n9/why_is_this_use_of_enable_if_invalid/
    //

    template <bool B, class Type, typename... Dependencies>
    struct dependent_enable_if
    {
    };

    template<class Type, typename... Dependencies>
    struct dependent_enable_if<true, Type, Dependencies...>
    {
        using type = Type;
    };

    template <bool B, class Type, typename... Dependencies>
    struct dependent_disable_if
    {
    };

    template<class Type, typename... Dependencies>
    struct dependent_disable_if<false, Type, Dependencies...>
    {
        using type = Type;
    };

    // remove_reference + remove_cv
    template <typename T>
    struct remove_cvref
    {
        using type = typename std::remove_cv<typename std::remove_reference<T>::type>::type;
    };

    // remove_pointer + remove_cv
    template <typename T>
    struct remove_cvptr
    {
        using type = typename std::remove_cv<typename std::remove_pointer<T>::type>::type;
    };

    // remove_reference + remove_cv + remove_pointer + remove_cv
    template <typename T>
    struct remove_cvref_cvptr
    {
        using type = typename remove_cvptr<typename remove_cvref<T>::type>::type;
    };

    // remove_reference + remove_cv + remove_pointer + remove_cv + remove_extent
    template <typename T>
    struct remove_cvref_cvptr_extent
    {
        using type = typename std::remove_extent<typename remove_cvref_cvptr<T>::type>::type;
    };

    // CAUTION:
    //  Return values in the `makeprval` are required to avoid breakage in the `Visual Studio 2015 Update 3` compiler.
    //
    template <typename T>
    CONSTEXPR_FUNC typename remove_cvref<T>::type makeprval(T && v)
    {
        return v;
    }

    // static array type must be overloaded separately, otherwise will be an error: `error: function returning an array`
    template <typename T>
    CONSTEXPR_FUNC const typename remove_cvref<T>::type & makeprval(const T & v)
    {
        return v;
    }

    // integer_sequence/index_sequence implementation for C++11
    // Based on: https://stackoverflow.com/questions/49669958/details-of-stdmake-index-sequence-and-stdindex-sequence/49672613#49672613
    //

    template<typename T, T... I>
    struct integer_sequence
    {
        static_assert(std::is_integral<T>::value, "T must be integral type.");

        using type          = integer_sequence<T, I...>;
        using value_type    = T;

        static CONSTEXPR_FUNC size_t size()
        {
            return sizeof...(I);
        }
    };

    template<size_t... Indexes>
    using index_sequence = integer_sequence<size_t, Indexes...>;

    namespace detail
    {
        template <std::size_t N, size_t... NextIndexes>
        struct _index_sequence : public _index_sequence<N - 1U, N - 1U, NextIndexes...>
        {
        };

        template <std::size_t... NextIndexes>
        struct _index_sequence<0U, NextIndexes...>
        {
            using type = index_sequence<NextIndexes...>;
        };
    }

    template <std::size_t N>
    struct make_index_sequence : detail::_index_sequence<N>::type
    {
    };

    template <typename T, size_t S>
    using array_type = T[S];

    //// functions

    // must be overloaded explicitly
    template <size_t index>
    FORCE_INLINE CONSTEXPR_FUNC void_ get(...)
    {
        return void_{};
    }

    template <size_t index>
    FORCE_INLINE CONSTEXPR_FUNC void_ constexpr_get(...)
    {
        return void_{};
    }

    // std::size is supported from C++17
    template <typename T, size_t N>
    FORCE_INLINE CONSTEXPR size_t static_size(const T (&)[N]) noexcept
    {
        return N;
    }

    template <typename... T>
    FORCE_INLINE CONSTEXPR size_t static_size(const std::tuple<T...> &)
    {
        return std::tuple_size<std::tuple<T...> >::value;
    }

    // for parameter pack usage inside a static_assert

    template <typename T0>
    FORCE_INLINE CONSTEXPR_FUNC bool is_all_true(T0 && v0)
    {
        return std::forward<T0>(v0) ? true : false;
    }

    template <typename T0, typename... Args>
    FORCE_INLINE CONSTEXPR_FUNC bool is_all_true(T0 && v0, Args &&... args)
    {
        return (std::forward<T0>(v0) ? true : false) && is_all_true(std::forward<Args>(args)...);
    }

    template <typename T0>
    FORCE_INLINE CONSTEXPR_FUNC bool is_all_false(T0 && v0)
    {
        return std::forward<T0>(v0) ? false : true;
    }

    template <typename T0, typename... Args>
    FORCE_INLINE CONSTEXPR_FUNC bool is_all_false(T0 && v0, Args &&... args)
    {
        return (std::forward<T0>(v0) ? false : true) && is_all_false(std::forward<Args>(args)...);
    }

    template <typename T0>
    FORCE_INLINE CONSTEXPR_FUNC bool is_any_true(T0 && v0)
    {
        return std::forward<T0>(v0) ? true : false;
    }

    template <typename T0, typename... Args>
    FORCE_INLINE CONSTEXPR_FUNC bool is_any_true(T0 && v0, Args &&... args)
    {
        return (std::forward<T0>(v0) ? true : false) || is_any_true(std::forward<Args>(args)...);
    }

    template <typename T0>
    FORCE_INLINE CONSTEXPR_FUNC bool is_any_false(T0 && v0)
    {
        return std::forward<T0>(v0) ? false : true;
    }

    template <typename T0, typename... Args>
    FORCE_INLINE CONSTEXPR_FUNC bool is_any_false(T0 && v0, Args &&... args)
    {
        return (std::forward<T0>(v0) ? false : true) || is_any_false(std::forward<Args>(args)...);
    }

    // move if movable, otherwise return a lvalue reference

    template <typename T>
    FORCE_INLINE CONSTEXPR_FUNC typename remove_cvref<T>::type && move_if_movable(T && v)
    {
        return std::forward<T>(v);
    }

    template <typename T>
    FORCE_INLINE CONSTEXPR_FUNC T & move_if_movable(T & v)
    {
        return v;
    }
}

#endif
