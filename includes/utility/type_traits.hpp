#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_TYPE_TRAITS_HPP
#define UTILITY_TYPE_TRAITS_HPP

#include <tacklelib.hpp>

#include <utility/preprocessor.hpp>
#include <utility/static_assert.hpp>
#include <utility/memory.hpp>

#include <type_traits>
#include <tuple>

#include <cstdint>
#include <cstring>


// to suppress warnings around compile time expression or values
#define UTILITY_CONST_EXPR(exp) ::utility::const_expr<(exp) ? true : false>::value

// generates compilation error and shows real type name (and place of declaration in some cases) in an error message, useful for debugging boost::mpl like recurrent types
#define UTILITY_TYPE_LOOKUP_BY_ERROR(type_name) \
    using _type_lookup_t = decltype((*(typename ::utility::type_lookup<type_name >::type*)0).operator ,(*(::utility::dummy*)0))

// the macro only for msvc compiler which has more useful error output if a scope class and a type are separated from each other
#ifdef _MSC_VER

#define UTILITY_TYPE_LOOKUP_BY_ERROR_CLASS(class_name, type_name) \
    using _type_lookup_t = decltype((*(typename ::utility::type_lookup<class_name >::type_name*)0).operator ,(*(::utility::dummy*)0))

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

#define UTILITY_STR_WITH_STATIC_SIZE_TUPLE(str) str, ::utility::static_size(str)


#ifdef UTILITY_PLATFORM_CXX_STANDARD_CPP14
// in case if not declared
namespace std
{
    template<size_t... _Vals>
    using index_sequence = integer_sequence<size_t, _Vals...>;
}
#endif

namespace utility
{
    // replacement for mpl::void_, useful to suppress excessive errors output in particular places
    struct void_ { typedef void_ type; };

    // to suppress `warning C4127: conditional expression is constant`
    template <bool B>
    struct const_expr
    {
        static const bool value = B;
    };

    struct dummy {};

    template <typename T>
    struct type_lookup
    {
        using type = T;
    };

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
        static constexpr const T value = v;
    };

    template <typename T, T v>
    constexpr const T value_identity<T, v>::value = v;

    template <int v>
    struct int_identity
    {
        using type = int;
        static constexpr const int value = v;
    };

    // std::size is supported from C++17
    template <typename T, size_t N>
    FORCE_INLINE constexpr size_t static_size(const T (&)[N]) noexcept
    {
        return N;
    }

    template <typename ...T>
    FORCE_INLINE constexpr size_t static_size(const std::tuple<T...> &)
    {
        return std::tuple_size<std::tuple<T...> >::value;
    }

    // Represents unconstructed decayed type value, to suppress compilation error on return types which default constructor has been deleted.
    //

    template<typename T>
    FORCE_INLINE typename std::decay<T>::type & unconstructed_value(utility::identity<T>)
    {
        using T_decay = typename std::decay<T>::type;

        static std::aligned_storage<sizeof(T_decay), boost::alignment_of<T_decay>::value>::type T_aligned_storage{};

        // CAUTION:
        //  After this point any usage of the return value is UB!
        //  The return value exists ONLY to remove requirement of the type default constructor existance, because underlaying
        //  storage of the type can be a late construction container.
        //

        return *utility::cast_addressof<T_decay *>(T_aligned_storage);
    }

    FORCE_INLINE void unconstructed_value(...)
    {
    }

    // `static if` implementation
    // Based on: https://stackoverflow.com/questions/37617677/implementing-a-compile-time-static-if-logic-for-different-string-types-in-a-co
    //

    template <typename T, typename F>
    FORCE_INLINE constexpr auto static_if(std::true_type, T t, F f)
    {
        return t;
    }

    template <typename T, typename F>
    FORCE_INLINE constexpr auto static_if(std::false_type, T t, F f)
    {
        return f;
    }

    template <bool B, typename T, typename F>
    FORCE_INLINE constexpr auto static_if(T t, F f)
    {
        return static_if(std::integral_constant<bool, B>{}, t, f);
    }

    template <bool B, typename T>
    FORCE_INLINE constexpr auto static_if(T t)
    {
        return static_if(std::integral_constant<bool, B>{}, t, [](auto&&...) {});
    }

    // Type qualification adaptor for a function parameter.
    // Based on `boost` library (https://www.boost.org)
    //

    namespace detail
    {
        template <typename T, bool small_>
        struct ct_imp
        {
           typedef const T & param_type;
        };

        template <typename T>
        struct ct_imp<T, true>
        {
           typedef const T param_type;
        };
    }

    template <typename T>
    struct call_traits
    {
       using value_type       = T;
       using reference        = T &;
       using const_reference  = const T &;
       using param_type       = typename detail::ct_imp<T, (sizeof(T) <= sizeof(void*))>::param_type;
    };

    template <typename T>
    struct call_traits<T &>
    {
       using value_type       = T &;
       using reference        = T &;
       using const_reference  = const T &;
       using param_type       = T &;
    };

    template <typename T, std::size_t N>
    struct call_traits<T[N]>
    {
    private:
       using array_type = T[N];
    public:
       using value_type       = const T *;
       using reference        = array_type &;
       using const_reference  = const array_type &;
       using param_type       = const T * const;
    };

    template <typename T, std::size_t N>
    struct call_traits<const T[N]>
    {
    private:
       using array_type       = const T[N];
    public:
       using value_type       = const T *;
       using reference        = array_type &;
       using const_reference  = const array_type &;
       using param_type       = const T * const;
    };

    template<typename Functor>
    inline void runtime_for_lt(Functor && function, size_t from, size_t to)
    {
        if (from < to) {
            function(from);
            runtime_for_lt(std::forward<Functor>(function), from + 1, to);
        }
    }
    
    // runtime `for` with template/value predicate
    //

    template <template <typename T_> class Functor, typename T>
    FORCE_INLINE void runtime_foreach(T & container)
    {
        runtime_for_lt(Functor<T>{ container }, 0, static_size(container));
    }

    template <typename Functor, typename T>
    FORCE_INLINE void runtime_foreach(T & container, Functor && functor)
    {
        runtime_for_lt(functor, 0, static_size(container));
    }

    // `constexpr for` implementation.
    // Based on: https://stackoverflow.com/questions/42005229/why-for-loop-isnt-a-compile-time-expression-and-extended-constexpr-allows-for-l
    //

    template <typename T>
    FORCE_INLINE void static_consume(std::initializer_list<T>) {}

#ifdef UTILITY_PLATFORM_CXX_STANDARD_CPP14 // for `std::index_sequence`
    template<typename Functor, std::size_t... S>
    FORCE_INLINE constexpr void static_foreach_seq(Functor && function, std::index_sequence<S...>)
    {
        return static_consume({ (function(std::integral_constant<std::size_t, S>{}), 0)... });
    }

    template<std::size_t Size, typename Functor>
    FORCE_INLINE constexpr void static_foreach(Functor && functor)
    {
        return static_foreach_seq(std::forward<Functor>(functor), std::make_index_sequence<Size>());
    }
#else
    template<typename Functor>
    FORCE_INLINE constexpr void static_foreach_seq(Functor && function, ...)
    {
        // make static assert function template parameter dependent
        // (still ill-formed, see: https://stackoverflow.com/questions/30078818/static-assert-dependent-on-non-type-template-parameter-different-behavior-on-gc)
        STATIC_ASSERT_TRUE(sizeof(Functor) && false, "not implemented");
    }

    template<std::size_t Size, typename Functor>
    FORCE_INLINE constexpr void static_foreach(Functor && functor)
    {
        // make static assert function template parameter dependent
        // (still ill-formed, see: https://stackoverflow.com/questions/30078818/static-assert-dependent-on-non-type-template-parameter-different-behavior-on-gc)
        STATIC_ASSERT_TRUE(sizeof(Functor) && false, "not implemented");
    }
#endif

    // `is_callable` implementation.
    // Based on: https://stackoverflow.com/questions/15393938/find-out-if-a-c-object-is-callable
    //

    template<typename T, typename U = void>
    struct is_callable
    {
        static bool const constexpr value = std::conditional<
            std::is_class<typename std::remove_reference<T>::type>::value,
            is_callable<typename std::remove_reference<T>::type, int>, std::false_type>::type::value;
    };

    // function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...), U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const, U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)volatile, U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const volatile, U> : std::true_type {};

    // pointer-to-function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(*)(Args...), U> : std::true_type {};

    // reference-to-function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(&)(Args...), U> : std::true_type {};

    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)&, U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const&, U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)volatile&, U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const volatile&, U> : std::true_type {};

    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...) && , U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const&&, U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)volatile&&, U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const volatile&&, U> : std::true_type {};

    // variadic-function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...), U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const, U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)volatile, U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const volatile, U> : std::true_type {};

    // pointer-to-variadic-function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(*)(Args..., ...), U> : std::true_type {};

    // reference-to-variadic-function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(&)(Args..., ...), U> : std::true_type {};

    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)&, U> : std::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const&, U> : std::true_type{};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)volatile&, U> : std::true_type{};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const volatile&, U> : std::true_type{};

    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)&&, U> : std::true_type{};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const&&, U> : std::true_type{};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)volatile&&, U> : std::true_type{};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const volatile&&, U> : std::true_type{};

    template<typename T>
    struct is_callable<T, int>
    {
    private:
        using yes_t = char(&)[1];
        using no_t = char(&)[2];

        struct Fallback { void operator()(); };

        struct Derived : T, Fallback {};

        template<typename U, U>
        struct Check;

        template<typename C> static no_t Test(Check<void (Fallback::*)(), &C::operator()>*);
        template<typename> static yes_t Test(...);

    public:
        static bool const constexpr value = sizeof(Test<Derived>(0)) == sizeof(yes_t);
    };

    // Simple `has_regular_parenthesis_operator` based on SFINAE, does detect ONLY regular `operator()`, does NOT detect templated `operator()`.
    // Based on: https://stackoverflow.com/questions/42480669/how-to-use-sfinae-to-check-whether-type-has-operator
    //

    template <typename T>
    class has_regular_parenthesis_operator
    {
        using yes_t = char(&)[1];
        using no_t = char(&)[2];

        template <typename C> static yes_t test(decltype(&C::operator()));
        template <typename C> static no_t test(...);

        using unref_type = typename std::remove_reference<T>::type;

    public:
        static const bool value = (sizeof(test<unref_type>(0)) == sizeof(yes_t));
    };

    //

    template <typename>
    struct is_template : std::false_type
    {
    };

    template <template <typename...> class Tmpl, typename ...Args>
    struct is_template<Tmpl<Args...> > : std::true_type
    {
    };

    //

    template <typename T>
    struct is_function_traits_extractable;

    // Simple function traits applicable to all callable types including generic lambdas
    // Based on: https://stackoverflow.com/questions/7943525/is-it-possible-to-figure-out-the-parameter-type-and-return-type-of-a-lambda
    //

    template <typename... Args>
    struct has_variadic_args : std::true_type
    {
    };

    template <>
    struct has_variadic_args<> : std::false_type
    {
    };

    template <typename T>
    struct function_traits;

    namespace lambda_detail
    {
        template<typename R, typename C, typename IsConst, typename IsVolatile, typename IsVariadic, typename... Args>
        struct types
        {
            static const size_t arity = sizeof...(Args);

            using return_type = R;
            using class_type = C;
            using is_const = IsConst;
            using is_volatile = IsVolatile;
            using is_variadic = IsVariadic;

            template <size_t i>
            struct arg
            {
                static_assert(has_variadic_args<Args...>::value, "functor does not declare any arguments");

                using type = typename std::conditional<has_variadic_args<Args...>::value, std::tuple_element<i, std::tuple<Args...> >, void_>::type::type;
            };
        };
    }

    //// function_traits

    // function
    template <typename R, typename... Args>
    struct function_traits<R(Args...)> : lambda_detail::types<R, void, std::false_type, std::false_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...) const> : lambda_detail::types<R, void, std::true_type, std::false_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...) volatile> : lambda_detail::types<R, void, std::false_type, std::true_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...) const volatile> : lambda_detail::types<R, void, std::true_type, std::true_type, std::false_type, Args...>
    {
    };

    // pointer-to-function
    template <typename R, typename... Args>
    struct function_traits<R(*)(Args...)> : lambda_detail::types<R, void, std::false_type, std::false_type, std::false_type, Args...>
    {
    };

    // reference-to-function
    template <typename R, typename... Args>
    struct function_traits<R(&)(Args...)> : lambda_detail::types<R, void, std::false_type, std::false_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)&> : lambda_detail::types<R, void, std::false_type, std::false_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)const&> : lambda_detail::types<R, void, std::true_type, std::false_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)volatile&> : lambda_detail::types<R, void, std::false_type, std::true_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)const volatile&> : lambda_detail::types<R, void, std::true_type, std::true_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)&&> : lambda_detail::types<R, void, std::false_type, std::false_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)const&&> : lambda_detail::types<R, void, std::true_type, std::false_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)volatile&&> : lambda_detail::types<R, void, std::false_type, std::true_type, std::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)const volatile&&> : lambda_detail::types<R, void, std::true_type, std::true_type, std::false_type, Args...>
    {
    };

    // variadic-function
    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)> : lambda_detail::types<R, void, std::false_type, std::false_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const> : lambda_detail::types<R, void, std::true_type, std::false_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)volatile> : lambda_detail::types<R, void, std::false_type, std::true_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const volatile> : lambda_detail::types<R, void, std::true_type, std::true_type, std::true_type, Args...>
    {
    };

    // pointer-to-variadic-function
    template <typename R, typename... Args>
    struct function_traits<R(*)(Args..., ...)> : lambda_detail::types<R, void, std::false_type, std::false_type, std::true_type, Args...>
    {
    };

    // reference-to-variadic-function
    template <typename R, typename... Args>
    struct function_traits<R(&)(Args..., ...)> : lambda_detail::types<R, void, std::false_type, std::false_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)&> : lambda_detail::types<R, void, std::false_type, std::false_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const&> : lambda_detail::types<R, void, std::true_type, std::false_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)volatile&> : lambda_detail::types<R, void, std::false_type, std::true_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const volatile&> : lambda_detail::types<R, void, std::true_type, std::true_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)&&> : lambda_detail::types<R, void, std::false_type, std::false_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const&&> : lambda_detail::types<R, void, std::true_type, std::false_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)volatile&&> : lambda_detail::types<R, void, std::false_type, std::true_type, std::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const volatile&&> : lambda_detail::types<R, void, std::true_type, std::true_type, std::true_type, Args...>
    {
    };

    // pointer-to-class-function
    template <typename C, typename R, typename... Args>
    struct function_traits<R (C::*)(Args...)> : lambda_detail::types<R, C, std::false_type, std::false_type, std::false_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args...)const> : lambda_detail::types<R, C, std::true_type, std::false_type, std::false_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args...)volatile> : lambda_detail::types<R, C, std::false_type, std::true_type, std::false_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args...)const volatile> : lambda_detail::types<R, C, std::true_type, std::true_type, std::false_type, Args...>
    {
    };

    // pointer-to-class-variadic-function
    template <typename C, typename R, typename... Args>
    struct function_traits<R (C::*)(Args..., ...)> : lambda_detail::types<R, C, std::false_type, std::false_type, std::true_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args..., ...)const> : lambda_detail::types<R, C, std::true_type, std::false_type, std::true_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args..., ...)volatile> : lambda_detail::types<R, C, std::false_type, std::true_type, std::true_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args..., ...)const volatile> : lambda_detail::types<R, C, std::true_type, std::true_type, std::true_type, Args...>
    {
    };

    //// function_traits_extractable

    template<typename T, bool IsExtractable>
    struct function_traits_extractable : function_traits<decltype(&T::operator())>
    {
    };

    template<typename T>
    struct function_traits_extractable<T, false>
    {
        using unref_type = typename std::remove_reference<T>::type;
        STATIC_ASSERT_TRUE2(std::is_function<unref_type>::value || std::is_class<unref_type>::value,
            std::is_function<unref_type>::value, std::is_class<unref_type>::value,
            "type must be at least a function/class type");
        static_assert(is_callable<unref_type>::value, "type is not callable");
        STATIC_ASSERT_TRUE2(std::is_function<unref_type>::value || has_regular_parenthesis_operator<unref_type>::value,
            std::is_function<unref_type>::value, has_regular_parenthesis_operator<unref_type>::value,
            "type is not a function and does not contain regular operator()");

        // to reduce excessive compiler errors output
        template <size_t i>
        struct arg
        {
            using type = void_;
        };
    };

    //// function_traits

    template<typename T>
    struct function_traits : function_traits_extractable<typename std::remove_reference<T>::type, is_function_traits_extractable<T>::value>
    {
    };

    //// is_function_traits_extractable

    template <typename T>
    struct is_function_traits_extractable
    {
        using unref_type = typename std::remove_reference<T>::type;
        static const bool value = (std::is_function<unref_type>::value || std::is_class<unref_type>::value) && is_callable<unref_type>::value && (std::is_function<unref_type>::value || has_regular_parenthesis_operator<unref_type>::value);
    };

    //// construct_if_constructible

    template <typename Type, bool Constructible>
    struct construct_if_constructible
    {
        static FORCE_INLINE bool construct_default(void * storage_ptr, const char * func, const char * error_msg_fmt)
        {
            UTILITY_UNUSED_STATEMENT2(func, error_msg_fmt);

            ::new (storage_ptr) Type();

            return true;
        }
    };

    template <typename Type>
    struct construct_if_constructible<Type, false>
    {
        static FORCE_INLINE bool construct_default(void * storage_ptr, const char * func, const char * error_msg_fmt)
        {
            throw std::runtime_error(
                (boost::format(error_msg_fmt) % func % typeid(Type).name()).str()
            );

            return false;
        }
    };

    //// construct_if_convertible

    template <typename Type, bool Convertable>
    struct construct_if_convertible
    {
        template <typename Ref>
        static FORCE_INLINE bool construct(void * storage_ptr, Ref & r, const char * func, const char * error_msg_fmt)
        {
            UTILITY_UNUSED_STATEMENT2(func, error_msg_fmt);

            ::new (storage_ptr) Type(r);

            return true;
        }
    };

    template <typename Type>
    struct construct_if_convertible<Type, false>
    {
        template <typename Ref>
        static FORCE_INLINE bool construct(void * storage_ptr, Ref & r, const char * func, const char * error_msg_fmt)
        {
            throw std::runtime_error(
                (boost::format(error_msg_fmt) % func % typeid(Type).name() % typeid(Ref).name()).str()
            );

            return false;
        }
    };

    //// construct_dispatcher

    template <int TypeIndex, typename Type, bool IsEnabled>
    struct construct_dispatcher
    {
        template <typename Ref>
        static FORCE_INLINE bool construct(void * storage_ptr, Ref & r, const char * func, const char * error_msg_fmt)
        {
            return construct_if_convertible<Type, std::is_convertible<Ref, Type>::value>::construct(storage_ptr, r, func, error_msg_fmt);
        }

        static FORCE_INLINE bool construct_default(void * storage_ptr, const char * func, const char * error_msg_fmt)
        {
            return construct_if_constructible<Type, std::is_constructible<Type>::value>::construct_default(storage_ptr, func, error_msg_fmt);
        }
    };

    template <int TypeIndex, typename Type>
    struct construct_dispatcher<TypeIndex, Type, false>
    {
        template <typename Ref>
        static FORCE_INLINE bool construct(void * storage_ptr, Ref & r, const char * func, const char * error_msg_fmt)
        {
            UTILITY_UNUSED_STATEMENT4(storage_ptr, r, func, error_msg_fmt);
            return false;
        }

        static FORCE_INLINE bool construct_default(void * storage_ptr, const char * func, const char * error_msg_fmt)
        {
            UTILITY_UNUSED_STATEMENT3(storage_ptr, func, error_msg_fmt);
            return false;
        }
    };

    //// invoke_if_convertible

    template <typename Ret, typename From, typename To, bool Convertable>
    struct invoke_if_convertible
    {
        template <typename F, typename Ref>
        static FORCE_INLINE Ret call(F & f, Ref & r, const char * func, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
        {
            UTILITY_UNUSED_STATEMENT3(func, error_msg_fmt, throw_exceptions_on_type_error);
            return f(r);
        }
    };

    template <typename Ret, typename From, typename To>
    struct invoke_if_convertible<Ret, From, To, false>
    {
        template <typename F, typename Ref>
        static FORCE_INLINE Ret call(F & f, Ref & r, const char * func, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
        {
            if(throw_exceptions_on_type_error) {
                char buf[1024];
                buf[0] = '\0';
                snprintf(UTILITY_STR_WITH_STATIC_SIZE_TUPLE(buf), error_msg_fmt, func, typeid(From).name(), typeid(To).name(), typeid(Ret).name());
                throw std::runtime_error(buf);
            }

            // CAUTION:
            //  After this point any usage of the return value is UB!
            //  The return value exists ONLY to remove requirement of the type default constructor existance, because underlaying
            //  storage of the type can be a late construction container.
            //

            return utility::unconstructed_value(utility::identity<Ret>());
        }
    };

    // invoke_dispatcher

    template <int TypeIndex, typename Ret, typename TypeList, template <typename, typename> typename TypeFind, typename EndIt, bool IsEnabled, bool IsExtractable>
    struct invoke_dispatcher
    {
        template <typename F, typename Ref>
        static FORCE_INLINE Ret call(F & f, Ref & r, const char * func, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
        {
            using return_type = typename std::remove_cv<typename std::remove_reference<typename utility::function_traits<F>::return_type>::type>::type;
            using unqual_arg0_type = typename std::remove_cv<typename std::remove_reference<typename utility::function_traits<F>::TEMPLATE_SCOPE arg<0>::type>::type>::type;
            using found_it_t = typename TypeFind<TypeList, unqual_arg0_type>::type;

            static_assert(!std::is_same<found_it_t, EndIt>::value,
                "functor first unqualified parameter type is not declared by storage types list");

            return invoke_if_convertible<Ret, Ref, unqual_arg0_type,
                std::is_convertible<Ref, unqual_arg0_type>::value && std::is_convertible<return_type, Ret>::value>::
                call(f, r, func, error_msg_fmt, throw_exceptions_on_type_error);
        }
    };

    template <int TypeIndex, typename Ret, typename TypeList, template <typename, typename> typename TypeFind, typename EndIt>
    struct invoke_dispatcher<TypeIndex, Ret, TypeList, TypeFind, EndIt, true, false>
    {
        template <typename F, typename Ref>
        static FORCE_INLINE Ret call(F & f, Ref & r, const char * func, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
        {
            UTILITY_UNUSED_STATEMENT3(func, error_msg_fmt, throw_exceptions_on_type_error);
            return f(r); // call as generic or cast
        }
    };

    template <int TypeIndex, typename Ret, typename TypeList, template <typename, typename> typename TypeFind, typename EndIt, bool IsExtractable>
    struct invoke_dispatcher<TypeIndex, Ret, TypeList, TypeFind, EndIt, false, IsExtractable>
    {
        template <typename F, typename Ref>
        static FORCE_INLINE Ret call(F & f, Ref & r, const char * func, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
        {
            return invoke_if_convertible<Ret, Ref, Ret, false>::
                call(f, r, func, error_msg_fmt, throw_exceptions_on_type_error);
        }
    };

    // invoke_if_returnable_dispatcher

    template <int TypeIndex, typename Ret, typename TypeList, template <typename, typename> typename TypeFind, typename EndIt, bool IsEnabled>
    struct invoke_if_returnable_dispatcher : invoke_dispatcher<TypeIndex, Ret, TypeList, TypeFind, EndIt, IsEnabled, true>
    {
    };

    //// assign_if_convertible

    template <bool Convertable>
    struct assign_if_convertible
    {
        template <typename From, typename To>
        static FORCE_INLINE To & call(To & to, const From & from, const char * func, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
        {
            UTILITY_UNUSED_STATEMENT3(func, error_msg_fmt, throw_exceptions_on_type_error);
            return to = from;
        }
    };

    template <>
    struct assign_if_convertible<false>
    {
        template <typename From, typename To>
        static FORCE_INLINE To & call(To & to, From & from, const char * func, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
        {
            if (throw_exceptions_on_type_error) {
                char buf[1024];
                buf[0] = '\0';
                snprintf(UTILITY_STR_WITH_STATIC_SIZE_TUPLE(buf), error_msg_fmt, func, typeid(From).name(), typeid(To).name());
                throw std::runtime_error(buf);
            }

            return to;
        }
    };

    //// assign_dispatcher

    template <typename From, typename To, bool IsEnabled>
    struct assign_dispatcher
    {
        template <bool IsEnabled_>
        struct assign_if_enabled
        {
            template <typename From, typename To>
            static FORCE_INLINE To & call(To & to, const From & from, const char * func, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
            {
                return assign_if_convertible<std::is_convertible<From, To>::value>::
                    call(to, from, func, error_msg_fmt, throw_exceptions_on_type_error);
            }
        };

        template <>
        struct assign_if_enabled<false>
        {
            template <typename From, typename To>
            static FORCE_INLINE To & call(To & to, const From & from, const char * func, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
            {
                UTILITY_UNUSED_STATEMENT5(to, from, func, error_msg_fmt, throw_exceptions_on_type_error);
                return to;
            }
        };

        template <typename From, typename To>
        static FORCE_INLINE To & call(To & to, const From & from, const char * func, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
        {
            return assign_if_enabled<IsEnabled>::
                call(to, from, func, error_msg_fmt, throw_exceptions_on_type_error);
        }
    };
}

#endif
