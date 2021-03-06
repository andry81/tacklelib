#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_STATIC_CONSTEXPR_HPP
#define TACKLE_STATIC_CONSTEXPR_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_identity.hpp>
#include <tacklelib/utility/addressof.hpp>

#include <type_traits>
#include <utility>


// CAUTION:
//  Redundant parentheses are required here to bypass a tricky error in the GCC 5.4.x around expressions with `>` and `<` characters in case of usage inside another expressions with the same characters:
//      `error: wrong number of template arguments (1, should be at least 2)`
//      `error: macro "..." passed 2 arguments, but takes just 1`
//

#define TACKLE_STATIC_CONSTEXPR_VALUE_WITH_ARGS(type_name, ...) \
    (::tackle::static_constexpr_value<type_name, UTILITY_IS_CONSTEXPR_VALUE(type_name{ __VA_ARGS__ })>::construct_get(__VA_ARGS__))

#define TACKLE_STATIC_CONSTEXPR_VALUE_WITH_INITER(type_name, ...) \
    (::tackle::static_constexpr_value<type_name, UTILITY_IS_CONSTEXPR_VALUE(__VA_ARGS__)>::construct_get(__VA_ARGS__))

namespace tackle
{
    // CAUTION:
    //
    //  Exists only for evalution of returned expression on `constexpr` type for the sake of implementation under C++11
    //  standard limited compiler, because C++11 standard states that the consexpr function must use basically a single return statement in the body of a constexpr function.
    //  So, in C++11 you must use `static_constexpr_value::construct_get` to request a static constexpr value of respected type.
    //  Direct usage of a class scoped static value can compromise the static initialization order, you must use a
    //  function to request a static value construction on demand!
    //

    //  Type `T` must be `constexpr` constructible here.
    //
    template <typename T, bool is_constexpr_initializer>
    class static_constexpr_value
    {
        using unconst_type      = typename std::remove_const<T>::type;

    public:
        // CAUTION:
        //  This typename has not much sense here because rvalue does not have any address and
        //  GCC compiler would show the address of a value returned by the construct_get function as `(nul)`!
        //  The only reason it has to exist is to avoid additional compilation errors on instantiation
        //  of such ill-formed pointers.
        //
        using address_type      = const unconst_type *;
        using reference_type    = const unconst_type &;

        static CONSTEXPR const bool is_const_type_v = true;

        template <typename... Args>
        static FORCE_INLINE CONSTEXPR_FUNC T construct_get(Args &&... args)
        {
            return T{ std::forward<decltype(args)>(args)... };
        }
    };

    //  Type `T` must not be `constexpr` constructible here.
    //
    template <typename T>
    class static_constexpr_value<T, false>
    {
        using unconst_type      = typename std::remove_const<T>::type;

    public:
        static CONSTEXPR const bool is_const_type_v = std::is_const<T>::value;

        using address_type      = typename std::conditional<is_const_type_v, const unconst_type *, unconst_type *>::type;
        using reference_type    = typename std::conditional<is_const_type_v, const unconst_type &, unconst_type &>::type;

        template <typename... Args>
        static FORCE_INLINE CONSTEXPR_FUNC T & construct_get(Args &&... args) // specialization must be constexpr too
        {
            // workaround for: `error C2134: 'tackle::static_constexpr_value<...,false>::construct_get': call does not result in a constant expression`
            return utility::construct_static_as<T>(std::forward<decltype(args)>(args)...);
        }
    };
}

#endif
