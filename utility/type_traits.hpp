#pragma once

#include <utility/preprocessor.hpp>

#include <boost/preprocessor/cat.hpp>
#include <boost/type_traits/integral_constant.hpp>
#include <boost/type_traits/is_function.hpp>
#include <boost/type_traits/is_class.hpp>
#include <boost/type_traits/remove_reference.hpp>
#include <boost/type_traits/conditional.hpp>
#include <boost/mpl/if.hpp>
#include <boost/mpl/void.hpp>

#include <tuple>


#define UTILITY_CONST_EXPR(exp) ::utility::const_expr<!!(exp)>::value

// generates compilation error and shows real type name (and place of declaration in some cases) in an error message, useful for debugging boost::mpl recurrent types
#define UTILITY_TYPE_LOOKUP_BY_ERROR(type_name) \
    typedef decltype((*(typename ::utility::type_lookup<type_name >::type*)0).operator ,(*(::utility::dummy*)0)) _type_lookup_t

// the macro only for msvc compiler which has more useful error output if a scope class and a type are separated from each other
#ifdef _MSC_VER

#define UTILITY_TYPE_LOOKUP_BY_ERROR_CLASS(class_name, type_name) \
    typedef decltype((*(typename ::utility::type_lookup<class_name >::type_name*)0).operator ,(*(::utility::dummy*)0)) _type_lookup_t

#else

#define UTILITY_TYPE_LOOKUP_BY_ERROR_CLASS(class_name, type_name) \
    UTILITY_TYPE_LOOKUP_BY_ERROR(class_name::type_name)

#endif


namespace utility
{
    namespace mpl = boost::mpl;

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
        typedef T type;
    };

    // `is_callable` implementation.
    // Based on: https://stackoverflow.com/questions/15393938/find-out-if-a-c-object-is-callable
    //

    template<typename T, typename U = void>
    struct is_callable
    {
        static bool const constexpr value = boost::conditional<
            boost::is_class<typename boost::remove_reference<T>::type>::value,
            is_callable<typename boost::remove_reference<T>::type, int>, boost::false_type>::type::value;
    };

    // function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...), U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const, U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)volatile, U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const volatile, U> : boost::true_type {};

    // pointer-to-function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(*)(Args...), U> : boost::true_type {};

    // reference-to-function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(&)(Args...), U> : boost::true_type {};

    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)&, U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const&, U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)volatile&, U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const volatile&, U> : boost::true_type {};

    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...) && , U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const&&, U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)volatile&&, U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args...)const volatile&&, U> : boost::true_type {};

    // variadic-function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...), U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const, U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)volatile, U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const volatile, U> : boost::true_type {};

    // pointer-to-variadic-function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(*)(Args..., ...), U> : boost::true_type {};

    // reference-to-variadic-function
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(&)(Args..., ...), U> : boost::true_type {};

    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)&, U> : boost::true_type {};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const&, U> : boost::true_type{};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)volatile&, U> : boost::true_type{};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const volatile&, U> : boost::true_type{};

    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)&&, U> : boost::true_type{};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const&&, U> : boost::true_type{};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)volatile&&, U> : boost::true_type{};
    template<typename T, typename U, typename ...Args>
    struct is_callable<T(Args..., ...)const volatile&&, U> : boost::true_type{};

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

        typedef typename boost::remove_reference<T>::type unref_type;

    public:
        static const bool value = (sizeof(test<unref_type>(0)) == sizeof(yes_t));
    };

    //

    template <typename>
    struct is_template : boost::false_type
    {
    };

    template <template <typename...> class Tmpl, typename ...Args>
    struct is_template<Tmpl<Args...> > : boost::true_type
    {
    };

    //

    template <typename T>
    struct is_function_traits_extractable;

    // Simple function traits applicable to all callable types including generic lambdas
    // Based on: https://stackoverflow.com/questions/7943525/is-it-possible-to-figure-out-the-parameter-type-and-return-type-of-a-lambda
    //

    template <typename... Args>
    struct has_variadic_args : boost::true_type
    {
    };

    template <>
    struct has_variadic_args<> : boost::false_type
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

                typedef typename mpl::if_<has_variadic_args<Args...>, std::tuple_element<i, std::tuple<Args...> >, mpl::void_>::type::type type;
            };
        };
    }

    // function
    template <typename R, typename... Args>
    struct function_traits<R(Args...)> : lambda_detail::types<R, void, boost::false_type, boost::false_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...) const> : lambda_detail::types<R, void, boost::true_type, boost::false_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...) volatile> : lambda_detail::types<R, void, boost::false_type, boost::true_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...) const volatile> : lambda_detail::types<R, void, boost::true_type, boost::true_type, boost::false_type, Args...>
    {
    };

    // pointer-to-function
    template <typename R, typename... Args>
    struct function_traits<R(*)(Args...)> : lambda_detail::types<R, void, boost::false_type, boost::false_type, boost::false_type, Args...>
    {
    };

    // reference-to-function
    template <typename R, typename... Args>
    struct function_traits<R(&)(Args...)> : lambda_detail::types<R, void, boost::false_type, boost::false_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)&> : lambda_detail::types<R, void, boost::false_type, boost::false_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)const&> : lambda_detail::types<R, void, boost::true_type, boost::false_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)volatile&> : lambda_detail::types<R, void, boost::false_type, boost::true_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)const volatile&> : lambda_detail::types<R, void, boost::true_type, boost::true_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)&&> : lambda_detail::types<R, void, boost::false_type, boost::false_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)const&&> : lambda_detail::types<R, void, boost::true_type, boost::false_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)volatile&&> : lambda_detail::types<R, void, boost::false_type, boost::true_type, boost::false_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args...)const volatile&&> : lambda_detail::types<R, void, boost::true_type, boost::true_type, boost::false_type, Args...>
    {
    };

    // variadic-function
    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)> : lambda_detail::types<R, void, boost::false_type, boost::false_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const> : lambda_detail::types<R, void, boost::true_type, boost::false_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)volatile> : lambda_detail::types<R, void, boost::false_type, boost::true_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const volatile> : lambda_detail::types<R, void, boost::true_type, boost::true_type, boost::true_type, Args...>
    {
    };

    // pointer-to-variadic-function
    template <typename R, typename... Args>
    struct function_traits<R(*)(Args..., ...)> : lambda_detail::types<R, void, boost::false_type, boost::false_type, boost::true_type, Args...>
    {
    };

    // reference-to-variadic-function
    template <typename R, typename... Args>
    struct function_traits<R(&)(Args..., ...)> : lambda_detail::types<R, void, boost::false_type, boost::false_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)&> : lambda_detail::types<R, void, boost::false_type, boost::false_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const&> : lambda_detail::types<R, void, boost::true_type, boost::false_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)volatile&> : lambda_detail::types<R, void, boost::false_type, boost::true_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const volatile&> : lambda_detail::types<R, void, boost::true_type, boost::true_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)&&> : lambda_detail::types<R, void, boost::false_type, boost::false_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const&&> : lambda_detail::types<R, void, boost::true_type, boost::false_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)volatile&&> : lambda_detail::types<R, void, boost::false_type, boost::true_type, boost::true_type, Args...>
    {
    };

    template <typename R, typename... Args>
    struct function_traits<R(Args..., ...)const volatile&&> : lambda_detail::types<R, void, boost::true_type, boost::true_type, boost::true_type, Args...>
    {
    };

    // pointer-to-class-function
    template <typename C, typename R, typename... Args>
    struct function_traits<R (C::*)(Args...)> : lambda_detail::types<R, C, boost::false_type, boost::false_type, boost::false_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args...)const> : lambda_detail::types<R, C, boost::true_type, boost::false_type, boost::false_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args...)volatile> : lambda_detail::types<R, C, boost::false_type, boost::true_type, boost::false_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args...)const volatile> : lambda_detail::types<R, C, boost::true_type, boost::true_type, boost::false_type, Args...>
    {
    };

    // pointer-to-class-variadic-function
    template <typename C, typename R, typename... Args>
    struct function_traits<R (C::*)(Args..., ...)> : lambda_detail::types<R, C, boost::false_type, boost::false_type, boost::true_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args..., ...)const> : lambda_detail::types<R, C, boost::true_type, boost::false_type, boost::true_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args..., ...)volatile> : lambda_detail::types<R, C, boost::false_type, boost::true_type, boost::true_type, Args...>
    {
    };

    template <typename C, typename R, typename... Args>
    struct function_traits<R(C::*)(Args..., ...)const volatile> : lambda_detail::types<R, C, boost::true_type, boost::true_type, boost::true_type, Args...>
    {
    };

    //
    template<typename T, bool IsExtractable>
    struct function_traits_extractable : function_traits<decltype(&T::operator())>
    {
    };

    template<typename T>
    struct function_traits_extractable<T, false>
    {
        typedef typename boost::remove_reference<T>::type unref_type;
        static_assert(boost::is_function<unref_type>::value || boost::is_class<unref_type>::value, "type must be at least a function/class type");
        static_assert(is_callable<unref_type>::value, "type is not callable");
        static_assert(boost::is_function<unref_type>::value || has_regular_parenthesis_operator<unref_type>::value, "type is not a function and does not contain regular operator()");

        // to reduce excessive compiler errors output
        template <size_t i>
        struct arg
        {
            typedef mpl::void_ type;
        };
    };

    template<typename T>
    struct function_traits : function_traits_extractable<typename boost::remove_reference<T>::type, is_function_traits_extractable<T>::value>
    {
    };

    template <typename T>
    struct is_function_traits_extractable
    {
        typedef typename boost::remove_reference<T>::type unref_type;
        static const bool value = (boost::is_function<unref_type>::value || boost::is_class<unref_type>::value) && is_callable<unref_type>::value && (boost::is_function<unref_type>::value || has_regular_parenthesis_operator<unref_type>::value);
    };
}
