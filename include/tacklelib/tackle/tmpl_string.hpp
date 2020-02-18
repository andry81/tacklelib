#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_TMPL_STRING_HPP
#define TACKLE_TMPL_STRING_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/preprocessor.hpp>
#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_identity.hpp>
#include <tacklelib/utility/string_identity.hpp>
#include <tacklelib/utility/static_constexpr.hpp>
#include <tacklelib/utility/debug.hpp>

#include <cstdint>
#include <string>
#include <cwchar>
#include <uchar.h> // in GCC `cuchar` header might not exist
#include <memory>
#include <algorithm>
#include <type_traits>


// CAUTION:
//  The `TACKLE_TMPL_STRING` and it's derivatives can not be used directly or indirectly (through a constexpr function) in the `UTILITY_CONSTEXPR_VALUE` macro or
//  any other truly compile-time expression (at least until C++17 standard) because of the error:
//  `error C3477: a lambda cannot appear in an unevaluated context`
//

#define TACKLE_TMPL_STRING(id, c_str, ...) \
    (::utility::make_tmpl_string_from_getter<(id)>(UTILITY_LITERAL_STRING_VALUE(c_str)).substr<(id), ## __VA_ARGS__>(__VA_ARGS__))

// alternative implementation
//#define TACKLE_TMPL_SUBSTRING(id, c_str, constexpr_offset) \
//    (::utility::make_tmpl_string_from_getter<(id)>(UTILITY_LITERAL_STRING_VALUE(c_str), ::utility::size_identity<(constexpr_offset)>{}))
//
//#define TACKLE_TMPL_SUBSTRING2(id, c_str, constexpr_offset, constexpr_len) \
//    (::utility::make_tmpl_string_from_getter<(id)>(UTILITY_LITERAL_STRING_VALUE(c_str), ::utility::size_identity<(constexpr_offset)>{}, ::utility::size_identity<(constexpr_len)>{}))

#define TACKLE_TMPL_STRING_AS(id, ansi_str, char_type) \
    (::utility::make_tmpl_string_from_getter<(id)>(UTILITY_LITERAL_STRING_VALUE_AS(ansi_str, char_type)))


namespace utility {

    namespace detail {

        template <size_t num_chars>
        struct _tmpl_string_impl;

    }

}

namespace tackle {

    // template version storage
    //

    template <uint64_t id, typename CharT, CharT... tchars>
    struct tmpl_basic_string_storage
    {
        static CONSTEXPR const CharT value[sizeof...(tchars)] = { tchars... };
    };

    template <uint64_t id, typename CharT, CharT... tchars>
    CONSTEXPR const CharT tmpl_basic_string_storage<id, CharT, tchars...>::value[sizeof...(tchars)];

    // template string, can be used as basic overload type for literal strings, character arrays and character pointers with size
    //

    template <uint64_t id, typename CharT, CharT... tchars>
    class tmpl_basic_string
    {
    public:
        using array_type            = utility::array_type<CharT, sizeof...(tchars)>;

        using value_identities_type = utility::value_identities<CharT, tchars...>;

        using this_type             = tmpl_basic_string<id, CharT, tchars...>;
        using storage_type          = tmpl_basic_string_storage<id, CharT, tchars...>;

        // to be able to create the string value to use template parameters deduction from a function argument
        FORCE_INLINE CONSTEXPR_FUNC tmpl_basic_string()
        {
        }

        // to be able to return by value
        FORCE_INLINE CONSTEXPR_FUNC tmpl_basic_string(const tmpl_basic_string &) = default;

    private:
        // block conversion from a C raw string, from a literal string or from a static string in an overload resolution logic
        tmpl_basic_string(const CharT *);

    private:
        template <uint64_t substr_id, size_t offset, size_t... N>
        static FORCE_INLINE CONSTEXPR_FUNC
            tmpl_basic_string<substr_id, CharT, storage_type::value[offset + N]..., UTILITY_LITERAL_CHAR('\0', CharT)>
            _make_tmpl_string_from_tmpl_string(utility::index_sequence<N...>)
        {
            return {};
        }

    public:
// Workaround for compilation error under MSVC2015u3 or higher (x86 only):
//  error C2666: 'tmpl_basic_string<...>::operator []': 2 overloads have similar conversions
//  ...
//  note: or       'built-in C++ operator[](int)'
//
#if !defined(UTILITY_COMPILER_CXX_MSC) || defined(UTILITY_PLATFORM_X64)
        FORCE_INLINE CONSTEXPR_FUNC const CharT & operator[] (size_t index) const // index - must compile time ONLY
        {
            return (
                STATIC_ASSERT_CONSTEXPR_TRUE(UTILITY_IS_CONSTEXPR_VALUE(index)),
                UTILITY_CONSTEXPR_GET(*this, index));
        }
#endif

        static FORCE_INLINE CONSTEXPR_FUNC const CharT * c_str()
        {
            return storage_type::value;
        }

        static FORCE_INLINE CONSTEXPR_FUNC const array_type & data()
        {
            return storage_type::value;
        }

        static FORCE_INLINE CONSTEXPR_FUNC size_t size()
        {
            return UTILITY_CONSTEXPR_VALUE(sizeof...(tchars));
        }

        template <uint64_t substr_id>
        static FORCE_INLINE CONSTEXPR_FUNC tmpl_basic_string substr()
        {
            return {};
        }

        template <uint64_t substr_id, size_t offset>
        static CONSTEXPR_FUNC auto substr(size_t) ->
            decltype(_make_tmpl_string_from_tmpl_string<substr_id, offset>(utility::make_index_sequence<offset < sizeof...(tchars) ? sizeof...(tchars) - offset - 1 : 0>{}))
        {
            return (
                STATIC_ASSERT_CONSTEXPR_TRUE(offset < sizeof...(tchars),
                    STATIC_ASSERT_PARAM(offset),
                    STATIC_ASSERT_PARAM(sizeof...(tchars))),
                _make_tmpl_string_from_tmpl_string<substr_id, offset>(utility::make_index_sequence<offset < sizeof...(tchars) ? sizeof...(tchars) - offset - 1 : 0>{}));
        }

        template <uint64_t substr_id, size_t offset, size_t len>
        static CONSTEXPR_FUNC auto substr(size_t, size_t) ->
            decltype(_make_tmpl_string_from_tmpl_string<substr_id, offset>(utility::make_index_sequence<len>{}))
        {
            return (
                STATIC_ASSERT_CONSTEXPR_TRUE(offset < sizeof...(tchars),
                    STATIC_ASSERT_PARAM(offset),
                    STATIC_ASSERT_PARAM(sizeof...(tchars))),
                _make_tmpl_string_from_tmpl_string<substr_id, offset>(utility::make_index_sequence<len>{}));
        }

        // CAUTION:
        //  must be implemented inside class to avoid ICE in msvc 2015 update 3
        //
        static FORCE_INLINE CONSTEXPR_FUNC size_t length()
        {
            return UTILITY_CONSTEXPR_VALUE((utility::detail::_tmpl_string_impl<sizeof...(tchars)>::TEMPLATE_SCOPE _tmpl_string_impl3<0, CharT, tchars...>::_constexpr_tmpl_string_length()));
        }

        FORCE_INLINE CONSTEXPR_FUNC operator const CharT *() const
        {
            return c_str();
        }

        FORCE_INLINE CONSTEXPR_FUNC operator const array_type &() const
        {
            return data();
        }

        // specific operator for std::basic_string, for example, to enable usage of std::is_convertible<tmpl_string, std::string>::value
        template <typename t_traits, typename t_alloc>
        FORCE_INLINE UTILITY_COMPILER_CXX_NOT_CLANG_CONSTEXPR_FUNC
            operator std::basic_string<CharT, t_traits, t_alloc>() const
        {
            return data();
        }
    };

    // minimal string must contain at least one (null) character
    template <uint64_t id, typename CharT>
    class tmpl_basic_string<id, CharT>; // forbidden

    template <uint64_t id, char... chars>
    using tmpl_string                   = tmpl_basic_string<id, char, chars...>;
    template <uint64_t id, wchar_t... wchars>
    using tmpl_wstring                  = tmpl_basic_string<id, wchar_t, wchars...>;
    template <uint64_t id, char16_t... chars16>
    using tmpl_u16string                = tmpl_basic_string<id, char16_t, chars16...>;
    template <uint64_t id, char32_t... chars32>
    using tmpl_u32string                = tmpl_basic_string<id, char32_t, chars32...>;

    // identity type exists only for type deduction
    template <typename CharT>
    struct tmpl_basic_string_identity {};

    template <>
    struct tmpl_basic_string_identity<char>
    {
        static CONSTEXPR const size_t type_index = 0;
    };

    template <>
    struct tmpl_basic_string_identity<wchar_t>
    {
        static CONSTEXPR const size_t type_index = 1;
    };

    template <>
    struct tmpl_basic_string_identity<char16_t>
    {
        static CONSTEXPR const size_t type_index = 2;
    };

    template <>
    struct tmpl_basic_string_identity<char32_t>
    {
        static CONSTEXPR const size_t type_index = 3;
    };

    using tmpl_string_identity          = tmpl_basic_string_identity<char>;
    using tmpl_wstring_identity         = tmpl_basic_string_identity<wchar_t>;
    using tmpl_u16string_identity       = tmpl_basic_string_identity<char16_t>;
    using tmpl_u32string_identity       = tmpl_basic_string_identity<char32_t>;

    // all tags must be derived as a new type
    template <typename CharT>
    struct tag_tmpl_basic_string        : tmpl_basic_string_identity<CharT> {};

    struct tag_tmpl_string              : tmpl_string_identity {};
    struct tag_tmpl_wstring             : tmpl_wstring_identity {};
    struct tag_tmpl_u16string           : tmpl_u16string_identity {};
    struct tag_tmpl_u32string           : tmpl_u32string_identity {};

}

namespace utility {

    namespace detail {

        template <size_t num_chars>
        struct _tmpl_string_impl
        {
            // CAUTION:
            //  `_get_tmpl_basic_string_char` can search a range greater than the length of a string, because by default it uses the string size instead a string length!
            //
            template <size_t index, typename CharT, CharT c0, CharT... tail_tchars>
            static FORCE_INLINE CONSTEXPR_FUNC CharT _get_tmpl_basic_string_char(size_t next_index, size_t max_size = size_t(~0))
            {
                return (index < max_size && index < next_index + 1 + sizeof...(tail_tchars)) ?
                    (index != next_index ?
                        _tmpl_string_impl<sizeof...(tail_tchars)>::TEMPLATE_SCOPE _get_tmpl_basic_string_char<index, CharT, tail_tchars...>(next_index + 1) :
                        c0) :
                    (DEBUG_BREAK_THROW(true) std::range_error("index must be in range"),
                        utility::literal_separators<CharT>::null_char);
            }

            template <size_t index, size_t next_index, size_t max_size, typename CharT, CharT c0, CharT... tail_tchars>
            struct _tmpl_string_impl2
            {
                static FORCE_INLINE CONSTEXPR_FUNC CharT _constexpr_get_tmpl_basic_string_char()
                {
                    return (
                        STATIC_ASSERT_CONSTEXPR_TRUE(index != next_index && index < max_size && index < next_index + 1 + sizeof...(tail_tchars),
                            STATIC_ASSERT_PARAM(index),
                            STATIC_ASSERT_PARAM(next_index),
                            STATIC_ASSERT_PARAM(max_size),
                            STATIC_ASSERT_PARAM(sizeof...(tail_tchars))),
                        _tmpl_string_impl<sizeof...(tail_tchars)>::TEMPLATE_SCOPE _tmpl_string_impl2<index, next_index + 1, max_size, CharT, tail_tchars...>::_constexpr_get_tmpl_basic_string_char());
                }
            };

            template <size_t index, size_t max_size, typename CharT, CharT c0, CharT... tail_tchars>
            struct _tmpl_string_impl2<index, index, max_size, CharT, c0, tail_tchars...>
            {
                static FORCE_INLINE CONSTEXPR_FUNC CharT _constexpr_get_tmpl_basic_string_char()
                {
                    return (
                        STATIC_ASSERT_CONSTEXPR_TRUE(index < max_size && index < index + 1 + sizeof...(tail_tchars),
                            STATIC_ASSERT_PARAM(index),
                            STATIC_ASSERT_PARAM(max_size),
                            STATIC_ASSERT_PARAM(sizeof...(tail_tchars))),
                        c0);
                }
            };

            template <size_t next_index, typename CharT, CharT c0, CharT... tail_tchars>
            struct _tmpl_string_impl3
            {
                static FORCE_INLINE CONSTEXPR_FUNC size_t _constexpr_tmpl_string_length()
                {
                    return (c0 != utility::literal_separators<CharT>::null_char ?
                        _tmpl_string_impl<sizeof...(tail_tchars)>::TEMPLATE_SCOPE _tmpl_string_impl3<next_index + 1, CharT, tail_tchars...>::_constexpr_tmpl_string_length() :
                        next_index);
                }
            };
        };

        template <>
        struct _tmpl_string_impl<1>
        {
            template <size_t index, typename CharT, CharT c0>
            static FORCE_INLINE CONSTEXPR_FUNC CharT _get_tmpl_basic_string_char(size_t next_index, size_t max_size = size_t(~0))
            {
                return (index < max_size && index < next_index + 1 && index == next_index) ?
                    c0 :
                    (DEBUG_BREAK_THROW(true) std::range_error("index must be in range"),
                        utility::literal_separators<CharT>::null_char);
            }

            template <size_t index, size_t next_index, size_t max_size, typename CharT, CharT c0>
            struct _tmpl_string_impl2
            {
                static FORCE_INLINE CONSTEXPR_FUNC CharT _constexpr_get_tmpl_basic_string_char()
                {
                    return (
                        STATIC_ASSERT_CONSTEXPR_TRUE(index < max_size && index < next_index + 1 && index == next_index,
                            STATIC_ASSERT_PARAM(index),
                            STATIC_ASSERT_PARAM(next_index),
                            STATIC_ASSERT_PARAM(max_size)),
                        c0);
                }
            };

            // standalone class to avoid ICE in msvc 2015 update 3
            template <size_t next_index, typename CharT, CharT c0>
            struct _tmpl_string_impl3
            {
                static FORCE_INLINE CONSTEXPR_FUNC size_t _constexpr_tmpl_string_length()
                {
                    return (c0 != utility::literal_separators<CharT>::null_char ?
                        next_index + 1 :
                        next_index);
                }
            };
        };

        template <>
        struct _tmpl_string_impl<0>;

    }

    template <size_t index, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_FUNC CharT get_tmpl_string_char()
    {
        return UTILITY_CONSTEXPR_VALUE((detail::_tmpl_string_impl<sizeof...(tchars)>::TEMPLATE_SCOPE _get_tmpl_basic_string_char<index, CharT, tchars...>(0)));
    }

    template <size_t index, uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_FUNC CharT constexpr_get()
    {
        return UTILITY_CONSTEXPR_VALUE((detail::_tmpl_string_impl<sizeof...(tchars)>::TEMPLATE_SCOPE _tmpl_string_impl2<index, 0, size_t(~0), CharT, tchars...>::_constexpr_get_tmpl_basic_string_char()));
    }

    template <size_t index, uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_FUNC CharT get(const tackle::tmpl_basic_string<id, CharT, tchars...> &)
    {
        return UTILITY_CONSTEXPR_VALUE((detail::_tmpl_string_impl<sizeof...(tchars)>::TEMPLATE_SCOPE _get_tmpl_basic_string_char<index, CharT, tchars...>(0)));
    }

    template <size_t index, uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_FUNC CharT constexpr_get(const tackle::tmpl_basic_string<id, CharT, tchars...> &)
    {
        return UTILITY_CONSTEXPR_VALUE((constexpr_get<index, id, CharT, tchars...>()));
    }

    // without decltype(auto) and std::move(str)...
    namespace detail {

        // CharT[N] -> f(Args &&...)

        template <typename Functor, uint64_t id, typename CharT, CharT... tchars, size_t... Indexes>
        FORCE_INLINE CONSTEXPR_FUNC auto _apply(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, utility::index_sequence<Indexes...> &&) ->
            decltype(f(get<Indexes>(str)...))
        {
            return f(get<Indexes>(str)...);
        }

        template <typename Functor, uint64_t id, typename CharT, CharT... tchars, size_t... Indexes, typename... Args>
        FORCE_INLINE CONSTEXPR_FUNC auto _apply(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, utility::index_sequence<Indexes...> &&, Args &&... args) ->
            decltype(f(std::forward<Args>(args)..., get<Indexes>(str)...))
        {
            return f(std::forward<Args>(args)..., get<Indexes>(str)...);
        }

        // CharT[N] -> f(To{ Args && }...)

        template <typename To, typename Functor, uint64_t id, typename CharT, CharT... tchars, size_t... Indexes>
        FORCE_INLINE CONSTEXPR_FUNC auto _apply_with_cast(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, utility::index_sequence<Indexes...> &&) ->
            decltype(f(static_cast<To>(get<Indexes>(str))...))
        {
            return f(static_cast<To>(get<Indexes>(str))...);
        }

        template <typename To, typename Functor, uint64_t id, typename CharT, CharT... tchars, size_t... Indexes, typename... Args>
        FORCE_INLINE CONSTEXPR_FUNC auto _apply_with_cast(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, utility::index_sequence<Indexes...> &&, Args &&... args) ->
            decltype(f(std::forward<Args>(args)..., static_cast<To>(get<Indexes>(str))...))
        {
            return f(std::forward<Args>(args)..., static_cast<To>(get<Indexes>(str))...);
        }

    }

    // CharT[N] -> f(Args &&...)

    template <typename Functor, uint64_t id, typename CharT, CharT... tchars, typename... Args>
    FORCE_INLINE CONSTEXPR_FUNC auto apply(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, Args &&... args) ->
        decltype(detail::_apply(f, str, make_index_sequence<tackle::tmpl_basic_string<id, CharT, tchars...>::size()>{}, std::forward<Args>(args)...))
    {
        return detail::_apply(f, str, make_index_sequence<str.size()>{}, std::forward<Args>(args)...);
    }

    // CharT[N] -> f(To{ Args && }...)

    template <typename To, typename Functor, uint64_t id, typename CharT, CharT... tchars, typename... Args>
    FORCE_INLINE CONSTEXPR_FUNC auto apply_with_cast(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, Args &&... args) ->
        decltype(detail::_apply_with_cast<To>(f, str, make_index_sequence<tackle::tmpl_basic_string<id, CharT, tchars...>::size()>{}, std::forward<Args>(args)...))
    {
        return detail::_apply_with_cast<To>(f, str, make_index_sequence<str.size()>{}, std::forward<Args>(args)...);
    }

    template <uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_file_name_constexpr_offset(const tackle::tmpl_basic_string<id, CharT, tchars...> & str)
    {
        return detail::_get_file_name_constexpr_offset(str, str.length());
    }

    template <uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_unmangled_src_func_constexpr_offset(const tackle::tmpl_basic_string<id, CharT, tchars...> & str)
    {
        return detail::_get_unmangled_src_func_constexpr_offset(str, str.length());
    }

    namespace detail {

        // make_tmpl_string

        template <uint64_t id, typename StaticGetter, size_t... N>
        FORCE_INLINE CONSTEXPR_FUNC
            tackle::tmpl_basic_string<id, typename utility::remove_cvref<decltype(StaticGetter::get()[0])>::type, StaticGetter::get()[N]...>
            _make_tmpl_string_from_getter(StaticGetter, index_sequence<N...>)
        {
            return {};
        }

        template <uint64_t id, size_t offset, typename StaticGetter, size_t... N>
        FORCE_INLINE CONSTEXPR_FUNC
            tackle::tmpl_basic_string<id, typename utility::remove_cvref<decltype(StaticGetter::get()[0])>::type, StaticGetter::get()[offset + N]...,
                UTILITY_LITERAL_CHAR('\0', typename utility::remove_cvref<decltype(StaticGetter::get()[0])>::type)>
            _make_tmpl_string_from_getter(StaticGetter, index_sequence<N...>, size_identity<offset>)
        {
            return {};
        }

        template <uint64_t substr_id, size_t offset, uint64_t id, typename CharT, CharT... tchars, size_t... N>
        FORCE_INLINE CONSTEXPR_FUNC
            tackle::tmpl_basic_string<substr_id, CharT, (tackle::tmpl_basic_string_storage<id, CharT, tchars...>::value)[offset + N]...,
                UTILITY_LITERAL_CHAR('\0', CharT)>
            _make_tmpl_string_from_tmpl_string(index_sequence<N...>)
        {
            return {};
        }

        template <uint64_t id, size_t offset, typename CharT, size_t S, size_t... N>
        FORCE_INLINE CONSTEXPR_FUNC const array_type<CharT, sizeof...(N) + 1> &
            _make_tmpl_string_from_array_impl(const CharT (& c_str)[S], index_sequence<N...>)
        {
            return tackle::tmpl_basic_string_storage<id, CharT, c_str[offset + N]..., UTILITY_LITERAL_CHAR('\0', CharT)>::value;
        }

    }

    template <uint64_t id, typename StaticGetter>
    FORCE_INLINE CONSTEXPR_FUNC auto make_tmpl_string_from_getter(StaticGetter getter) ->
        decltype(detail::_make_tmpl_string_from_getter<id>(getter, make_index_sequence<UTILITY_CONSTEXPR_ARRAY_SIZE(StaticGetter::get())>{}))
    {
        return detail::_make_tmpl_string_from_getter<id>(getter, make_index_sequence<UTILITY_CONSTEXPR_ARRAY_SIZE(StaticGetter::get())>{});
    }

    template <uint64_t id, size_t offset, typename StaticGetter>
    FORCE_INLINE CONSTEXPR_FUNC auto make_tmpl_string_from_getter(StaticGetter getter, size_identity<offset>) ->
        decltype(detail::_make_tmpl_string_from_getter<id>(getter, make_index_sequence<UTILITY_CONSTEXPR_ARRAY_SIZE(StaticGetter::get()) - offset - 1>{}, size_identity<offset>{}))
    {
        return (
            STATIC_ASSERT_CONSTEXPR_TRUE(offset < UTILITY_CONSTEXPR_ARRAY_SIZE(StaticGetter::get()),
                STATIC_ASSERT_PARAM(offset),
                STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_ARRAY_SIZE(StaticGetter::get()))),
            detail::_make_tmpl_string_from_getter<id>(getter, make_index_sequence<UTILITY_CONSTEXPR_ARRAY_SIZE(StaticGetter::get()) - offset - 1>{}, size_identity<offset>{}));
    }

    template <uint64_t id, size_t offset, size_t len, typename StaticGetter>
    FORCE_INLINE CONSTEXPR_FUNC auto make_tmpl_string_from_getter(StaticGetter getter, size_identity<offset>, size_identity<len>) ->
        decltype(detail::_make_tmpl_string_from_getter<id>(getter, make_index_sequence<len>{}, size_identity<offset>{}))
    {
        return (
            STATIC_ASSERT_CONSTEXPR_TRUE(offset + len < UTILITY_CONSTEXPR_ARRAY_SIZE(StaticGetter::get()),
                STATIC_ASSERT_PARAM(offset),
                STATIC_ASSERT_PARAM(len),
                STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_ARRAY_SIZE(StaticGetter::get()))),
            detail::_make_tmpl_string_from_getter<id>(getter, make_index_sequence<len>{}, size_identity<offset>{}));
    }

    template <uint64_t substr_id, size_t offset, size_t len, uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_FUNC auto make_tmpl_string_from_tmpl_string(tackle::tmpl_basic_string<id, CharT, tchars...>) ->
        decltype(detail::_make_tmpl_string_from_tmpl_string<substr_id, offset, len, id, CharT, tchars...>(make_index_sequence<len>{}))
    {
        return (
            STATIC_ASSERT_CONSTEXPR_TRUE(offset + len < sizeof...(tchars),
                STATIC_ASSERT_PARAM(offset),
                STATIC_ASSERT_PARAM(len),
                STATIC_ASSERT_PARAM(sizeof...(tchars))),
            detail::_make_tmpl_string_from_tmpl_string<substr_id, offset, len, id, CharT, tchars...>(make_index_sequence<len>{}));
    }

    template <uint64_t id, size_t offset, size_t len, typename CharT, size_t S>
    FORCE_INLINE CONSTEXPR_FUNC const array_type<CharT, S - offset> & make_tmpl_string_from_array(const CharT (& c_str)[S], size_identity<offset>)
    {
        return (
            STATIC_ASSERT_CONSTEXPR_TRUE(offset < S,
                STATIC_ASSERT_PARAM(offset),
                STATIC_ASSERT_PARAM(S)),
            detail::_make_tmpl_string_from_array_impl<id, offset>(c_str, make_index_sequence<S - offset - 1>{}));
    }

    template <uint64_t id, size_t offset, size_t len, typename CharT, size_t S>
    FORCE_INLINE CONSTEXPR_FUNC const array_type<CharT, len + 1> & make_tmpl_string_from_array(const CharT (& c_str)[S], size_identity<offset>, size_identity<len>)
    {
        return (
            STATIC_ASSERT_CONSTEXPR_TRUE(offset + len < S,
                STATIC_ASSERT_PARAM(offset),
                STATIC_ASSERT_PARAM(len),
                STATIC_ASSERT_PARAM(S)),
            detail::_make_tmpl_string_from_array_impl<id, offset>(c_str, make_index_sequence<len>{}));
    }

}

#endif
