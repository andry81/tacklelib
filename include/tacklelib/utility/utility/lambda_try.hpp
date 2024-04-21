#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_UTILITY_LAMBDA_TRY_HPP
#define UTILITY_UTILITY_LAMBDA_TRY_HPP

namespace utility
{
    // naked return usage protection in lambda-try
    template <typename T = void>
    class lambda_try_return_holder;

    template <typename T>
    class lambda_try_return_holder
    {
    public:
        lambda_try_return_holder(lambda_try_return_holder&&) = default;
        lambda_try_return_holder(const lambda_try_return_holder&) = default;

        lambda_try_return_holder()
            : this_()
        {
        }

        explicit lambda_try_return_holder(T&& v)
            : this_(std::forward<T>(v))
        {
        }

        explicit lambda_try_return_holder(const T& v)
            : this_(v)
        {
        }

        lambda_try_return_holder& operator =(const lambda_try_return_holder&) = default;
        lambda_try_return_holder& operator =(lambda_try_return_holder&&) = default;

        operator T& ()
        {
            return this_;
        }

        operator const T& ()
        {
            return this_;
        }

        T& get()
        {
            return this_;
        }

        const T& get() const
        {
            return this_;
        }

        T&& move()
        {
            return std::move(this_);
        }

    private:
        T this_;
    };

    template <>
    class lambda_try_return_holder<void>
    {
    public:
        lambda_try_return_holder(lambda_try_return_holder&&) = default;
        lambda_try_return_holder(const lambda_try_return_holder&) = default;

        lambda_try_return_holder()
        {
        }

        lambda_try_return_holder& operator =(const lambda_try_return_holder&) = default;
        lambda_try_return_holder& operator =(lambda_try_return_holder&&) = default;

        void get() const
        {
        }

        void move()
        {
        }
    };

    template <typename T>
    lambda_try_return_holder<T> make_lambda_try_return_holder(T&& v)
    {
        return lambda_try_return_holder<T>{ std::forward<T>(v) };
    }

    template <typename T>
    lambda_try_return_holder<T> make_lambda_try_return_holder(const T& v)
    {
        return lambda_try_return_holder<T>{ v };
    }

    lambda_try_return_holder<void> make_lambda_try_return_holder()
    {
        return lambda_try_return_holder<void>{};
    }
}

#if ERROR_IF_EMPTY_PP_DEF(ENABLE_WIN32_LAMBDA_TRY_FINALLY)
#   ifdef LAMBDA_TRY_BEGIN
#       error: LAMBDA_TRY_BEGIN already defined
#   endif

// NOTE:
//  lambda to bypass msvc error: `error C2712: Cannot use ... in functions that require object unwinding`
//
// NOTE:
//  `do` and `while(false);` between macroses is required to avoid quantity of errors around missed brackets and in the same time requires to use `{}` brackets separately.
//
#   define LAMBDA_TRY_BEGIN(return_type)    [&]() -> ::utility::lambda_try_return_holder<return_type> { __try { return [&]() -> ::utility::lambda_try_return_holder<return_type> { do
#   define LAMBDA_TRY_BEGIN_VA(...)         [&]() -> ::utility::lambda_try_return_holder<UTILITY_PP_VA_ARGS(__VA_ARGS__)> { __try { return [&]() -> ::utility::lambda_try_return_holder<UTILITY_PP_VA_ARGS(__VA_ARGS__)> { do
#   define LAMBDA_TRY_FINALLY()             while(false); return {}; }(); } __finally { (void)0;
#   define LAMBDA_TRY_END()                 while(false); } return {}; }().get();
#   define LAMBDA_TRY_RETURN(v)             return ::utility::make_lambda_try_return_holder(v)
#   define LAMBDA_TRY_RETURN_VA(...)        return ::utility::make_lambda_try_return_holder(UTILITY_PP_VA_ARGS(__VA_ARGS__))
#endif

#if ERROR_IF_EMPTY_PP_DEF(ENABLE_CXX_LAMBDA_TRY_FINALLY)
#   ifdef LAMBDA_TRY_BEGIN
#       error: LAMBDA_TRY_BEGIN already defined
#   endif

// NOTE:
//  `do` and `while(false);` between macroses is required to avoid quantity of errors around missed brackets and in the same time requires to use `{}` brackets separately.
//
#   define LAMBDA_TRY_BEGIN(return_type)    [&]() -> ::utility::lambda_try_return_holder<return_type> { \
                                                static const auto & lambda_try_catch = [&](bool lambda_try_throw_finally) -> ::utility::lambda_try_return_holder<return_type> { \
                                                    try { if (lambda_try_throw_finally) throw UTILITY_DECLARE_LINE_UNIQUE_TYPE(lambda_try_throw_finally){}; do
#   define LAMBDA_TRY_BEGIN_VA(...)         [&]() -> ::utility::lambda_try_return_holder<return_type> { \
                                                static const auto & lambda_try_catch = [&](bool lambda_try_throw_finally) -> ::utility::lambda_try_return_holder<UTILITY_PP_VA_ARGS(__VA_ARGS__)> { \
                                                    try { if (lambda_try_throw_finally) throw UTILITY_DECLARE_LINE_UNIQUE_TYPE(lambda_try_throw_finally){}; do
#   define LAMBDA_TRY_FINALLY()             while(false); } catch(...) { do
#   define LAMBDA_TRY_END()                 while(false); if(!lambda_try_throw_finally) throw; } return {}; }; auto ret = lambda_try_catch(false); lambda_try_catch(true); return ret; }().get();
#   define LAMBDA_TRY_RETURN(v)             return ::utility::make_lambda_try_return_holder(v)
#   define LAMBDA_TRY_RETURN_VA(...)        return ::utility::make_lambda_try_return_holder(UTILITY_PP_VA_ARGS(__VA_ARGS__))
#endif

#endif
