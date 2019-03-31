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


#define TACKLE_TMPL_STRING(id, c_str) \
    ::utility::detail::_make_tmpl_string<id>(UTILITY_LITERAL_STRING_VALUE(c_str))

#define TACKLE_TMPL_SUBSTRING(id, c_str, constexpr_offset) \
    ::utility::detail::_make_tmpl_string<id>(UTILITY_LITERAL_SUBSTRING_VALUE(c_str, constexpr_offset))

#define TACKLE_TMPL_SUBSTRING2(id, c_str, constexpr_offset, constexpr_len) \
    ::utility::detail::_make_tmpl_string<id>(UTILITY_LITERAL_SUBSTRING_VALUE2(c_str, constexpr_offset, constexpr_len))

#define TACKLE_TMPL_STRING_AS(id, ansi_str, char_type) \
    ::utility::detail::_make_tmpl_string<id>(UTILITY_LITERAL_STRING_VALUE_AS(ansi_str, char_type))


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
        FORCE_INLINE CONSTEXPR_RETURN tmpl_basic_string()
        {
        }

    private:
        // block conversion from a C raw string, from a literal string or from a static string in an overload resolution logic
        tmpl_basic_string(const CharT *);

    public:
// Workaround for compilation error under MSVC2015u3 or higher (x86 only):
//  error C2666: 'tmpl_basic_string<...>::operator []': 2 overloads have similar conversions
//  ...
//  note: or       'built-in C++ operator[](int)'
//
#if !defined(UTILITY_COMPILER_CXX_MSC) || defined(UTILITY_PLATFORM_X64)
        FORCE_INLINE CONSTEXPR_RETURN const CharT & operator[] (size_t index) const;
#endif

        static FORCE_INLINE CONSTEXPR_RETURN const CharT * c_str()
        {
            return storage_type::value;
        }

        static FORCE_INLINE CONSTEXPR_RETURN const array_type & data()
        {
            return storage_type::value;
        }

        static FORCE_INLINE CONSTEXPR_RETURN size_t size()
        {
            return UTILITY_CONSTEXPR_VALUE(sizeof...(tchars));
        }

        static FORCE_INLINE CONSTEXPR_RETURN size_t length();

        FORCE_INLINE CONSTEXPR_RETURN operator const CharT *() const
        {
            return c_str();
        }

        FORCE_INLINE CONSTEXPR_RETURN operator const array_type &() const
        {
            return data();
        }

        // specific operator for std::basic_string, for example, to enable usage of std::is_convertible<tmpl_string, std::string>::value
        template <typename t_traits, typename t_alloc>
        FORCE_INLINE UTILITY_COMPILER_CXX_NOT_CLANG_CONSTEXPR_RETURN
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

        // string length for a template string

        template <size_t num_chars>
        struct _impl
        {
            template <typename CharT, CharT c0, CharT... tail_tchars>
            static FORCE_INLINE CONSTEXPR_RETURN size_t _tmpl_string_length(size_t next_index)
            {
                return c0 != utility::literal_separators<CharT>::null_char ?
                    _impl<sizeof...(tail_tchars)>::TEMPLATE_SCOPE _tmpl_string_length<CharT, tail_tchars...>(next_index + 1) :
                    next_index;
            }

            // CAUTION:
            //  `_get_tmpl_basic_string_char` can search a range greater than the length of a string, because by default it uses the string size instead a string length!
            //
            template <size_t index, typename CharT, CharT c0, CharT... tail_tchars>
            static FORCE_INLINE CONSTEXPR_RETURN CharT _get_tmpl_basic_string_char(size_t next_index, size_t max_size = size_t(~0))
            {
                return (index < max_size && index < next_index + sizeof...(tail_tchars)) ?
                    (index != next_index ?
                        _impl<sizeof...(tail_tchars)>::TEMPLATE_SCOPE _get_tmpl_basic_string_char<index, CharT, tail_tchars...>(next_index + 1) :
                        c0) :
                    (DEBUG_BREAK_THROW(true) std::range_error("index must be in range"),
                        utility::literal_separators<CharT>::null_char);
            }

            template <size_t index, size_t next_index, size_t max_size, typename CharT, CharT c0, CharT... tail_tchars>
            static FORCE_INLINE CONSTEXPR_RETURN CharT _constexpr_get_tmpl_basic_string_char()
            {
                return (STATIC_ASSERT_CONSTEXPR_TRUE(index < max_size && index < next_index + sizeof...(tail_tchars),
                        STATIC_ASSERT_PARAM(index), STATIC_ASSERT_PARAM(max_size), STATIC_ASSERT_PARAM(sizeof...(tail_tchars)), STATIC_ASSERT_PARAM(next_index)),
                    (index != next_index ?
                        _impl<sizeof...(tail_tchars)>::TEMPLATE_SCOPE _constexpr_get_tmpl_basic_string_char<index, next_index + 1, max_size, CharT, tail_tchars...>() :
                        c0));
            }
        };

        template <>
        struct _impl<1>
        {
            template <typename CharT, CharT c0>
            static FORCE_INLINE CONSTEXPR_RETURN size_t _tmpl_string_length(size_t next_index)
            {
                return c0 != utility::literal_separators<CharT>::null_char ? next_index + 1 : next_index;
            }

            template <size_t index, typename CharT, CharT c0>
            static FORCE_INLINE CONSTEXPR_RETURN CharT _get_tmpl_basic_string_char(size_t next_index, size_t max_size = size_t(~0))
            {
                return (index < max_size && index < next_index + 1 && index == next_index) ?
                    c0 :
                    (DEBUG_BREAK_THROW(true) std::range_error("index must be in range"),
                        utility::literal_separators<CharT>::null_char);
            }

            template <size_t index, size_t next_index, size_t max_size, typename CharT, CharT c0>
            static FORCE_INLINE CONSTEXPR_RETURN CharT _constexpr_get_tmpl_basic_string_char()
            {
                return (STATIC_ASSERT_CONSTEXPR_TRUE(index < max_size && index < next_index + 1 && index == next_index,
                        STATIC_ASSERT_PARAM(index), STATIC_ASSERT_PARAM(max_size), STATIC_ASSERT_PARAM(next_index)),
                    c0);
            }
        };

        template <>
        struct _impl<0>;

    }

    template <size_t index, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_RETURN CharT get_tmpl_string_char()
    {
        return UTILITY_CONSTEXPR_VALUE((detail::_impl<sizeof...(tchars)>::TEMPLATE_SCOPE _get_tmpl_basic_string_char<index, CharT, tchars...>(0)));
    }

    template <size_t index, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_RETURN CharT constexpr_get_tmpl_string_char()
    {
        return UTILITY_CONSTEXPR_VALUE((detail::_impl<sizeof...(tchars)>::TEMPLATE_SCOPE _constexpr_get_tmpl_basic_string_char<index, 0, size_t(~0), CharT, tchars...>()));
    }

    template <size_t index, uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_RETURN CharT get(tackle::tmpl_basic_string<id, CharT, tchars...>)
    {
        return UTILITY_CONSTEXPR_VALUE((detail::_impl<sizeof...(tchars)>::TEMPLATE_SCOPE _get_tmpl_basic_string_char<index, CharT, tchars...>(0)));
    }

    template <size_t index, uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_RETURN CharT constexpr_get(tackle::tmpl_basic_string<id, CharT, tchars...>)
    {
        return UTILITY_CONSTEXPR_VALUE((detail::_impl<sizeof...(tchars)>::TEMPLATE_SCOPE _constexpr_get_tmpl_basic_string_char<index, 0, size_t(~0), CharT, tchars...>()));
    }

    // without decltype(auto) and std::move(str)...
    namespace detail {

        // CharT[N] -> f(Args &&...)

        template <typename Functor, uint64_t id, typename CharT, CharT... tchars, size_t... Indexes>
        FORCE_INLINE CONSTEXPR_RETURN auto _apply(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, utility::index_sequence<Indexes...> &&) ->
            decltype(f(get<Indexes>(str)...))
        {
            return f(get<Indexes>(str)...);
        }

        template <typename Functor, uint64_t id, typename CharT, CharT... tchars, size_t... Indexes, typename... Args>
        FORCE_INLINE CONSTEXPR_RETURN auto _apply(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, utility::index_sequence<Indexes...> &&, Args &&... args) ->
            decltype(f(std::forward<Args>(args)..., get<Indexes>(str)...))
        {
            return f(std::forward<Args>(args)..., get<Indexes>(str)...);
        }

        // CharT[N] -> f(To{ Args && }...)

        template <typename To, typename Functor, uint64_t id, typename CharT, CharT... tchars, size_t... Indexes>
        FORCE_INLINE CONSTEXPR_RETURN auto _apply_with_cast(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, utility::index_sequence<Indexes...> &&) ->
            decltype(f(static_cast<To>(get<Indexes>(str))...))
        {
            return f(static_cast<To>(get<Indexes>(str))...);
        }

        template <typename To, typename Functor, uint64_t id, typename CharT, CharT... tchars, size_t... Indexes, typename... Args>
        FORCE_INLINE CONSTEXPR_RETURN auto _apply_with_cast(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, utility::index_sequence<Indexes...> &&, Args &&... args) ->
            decltype(f(std::forward<Args>(args)..., static_cast<To>(get<Indexes>(str))...))
        {
            return f(std::forward<Args>(args)..., static_cast<To>(get<Indexes>(str))...);
        }

    }

    // CharT[N] -> f(Args &&...)

    template <typename Functor, uint64_t id, typename CharT, CharT... tchars, typename... Args>
    FORCE_INLINE CONSTEXPR_RETURN auto apply(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, Args &&... args) ->
        decltype(detail::_apply(f, str, make_index_sequence<tackle::tmpl_basic_string<id, CharT, tchars...>::size()>{}, std::forward<Args>(args)...))
    {
        return detail::_apply(f, str, make_index_sequence<str.size()>{}, std::forward<Args>(args)...);
    }

    // CharT[N] -> f(To{ Args && }...)

    template <typename To, typename Functor, uint64_t id, typename CharT, CharT... tchars, typename... Args>
    FORCE_INLINE CONSTEXPR_RETURN auto apply_with_cast(Functor && f, tackle::tmpl_basic_string<id, CharT, tchars...> && str, Args &&... args) ->
        decltype(detail::_apply_with_cast<To>(f, str, make_index_sequence<tackle::tmpl_basic_string<id, CharT, tchars...>::size()>{}, std::forward<Args>(args)...))
    {
        return detail::_apply_with_cast<To>(f, str, make_index_sequence<str.size()>{}, std::forward<Args>(args)...);
    }

    // make_tmpl_string

    namespace detail {

        template <uint64_t id, typename Holder, size_t... N>
        CONSTEXPR_RETURN
        tackle::tmpl_basic_string<id, typename utility::remove_cvref<decltype(Holder::get()[0])>::type, Holder::get()[N]...>
            _make_tmpl_string_impl(Holder, utility::index_sequence<N...>)
        {
            return {};
        }

        template <uint64_t id, typename StaticGetter>
        CONSTEXPR_RETURN auto _make_tmpl_string(StaticGetter getter) ->
            decltype(_make_tmpl_string_impl<id>(getter,
                utility::make_index_sequence<sizeof(StaticGetter::get()) / sizeof(StaticGetter::get()[0])>{}))
        {
            return _make_tmpl_string_impl<id>(getter,
                utility::make_index_sequence<sizeof(StaticGetter::get()) / sizeof(StaticGetter::get()[0])>{});
        }

    }

}


namespace tackle {

// Workaround for compilation error under MSVC2015u3 or higher (x86 only):
//  error C2666: 'tmpl_basic_string<...>::operator []': 2 overloads have similar conversions
//  ...
//  note: or       'built-in C++ operator[(CharT, int)'
//
#if !defined(UTILITY_COMPILER_CXX_MSC) || defined(UTILITY_PLATFORM_X64)
    template <uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_RETURN const CharT & tmpl_basic_string<id, CharT, tchars...>::operator[] (size_t index) const // index - must compile time ONLY
    {
        return UTILITY_CONSTEXPR_GET(*this, index);
    }
#endif

    template <uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_RETURN size_t tmpl_basic_string<id, CharT, tchars...>::length()
    {
        return UTILITY_CONSTEXPR_VALUE((utility::detail::_impl<sizeof...(tchars)>::TEMPLATE_SCOPE _tmpl_string_length<CharT, tchars...>(0)));
    }

}

namespace utility {

    template <uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_RETURN size_t get_file_name_constexpr_offset(const tackle::tmpl_basic_string<id, CharT, tchars...> & str)
    {
        return detail::_get_file_name_constexpr_offset(str, str.length());
    }

    template <uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_RETURN size_t get_unmangled_src_func_constexpr_offset(const tackle::tmpl_basic_string<id, CharT, tchars...> & str)
    {
        return detail::_get_unmangled_src_func_constexpr_offset(str, str.length());
    }

}

#endif
