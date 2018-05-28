#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_TYPE_TRAITS_HPP
#define UTILITY_TYPE_TRAITS_HPP

#include <tacklelib.hpp>

#include <utility/preprocessor.hpp>
#include <utility/static_assert.hpp>

#include <type_traits>
#include <tuple>


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

#define UTILITY_SIZE_LOOKUP_BY_ERROR(size) \
    char * __integral_lookup[size] = 1


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

    template<typename Functor>
    inline void runtime_for_lt(Functor && function, size_t from, size_t to)
    {
        if (from < to) {
            function(from);
            runtime_for_lt(std::forward<Functor>(function), from + 1, to);
        }
    }

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
}

#endif
