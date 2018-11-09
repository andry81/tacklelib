#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>

#include <string>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <wchar.h>
#include <uchar.h>
#include <memory>
#include <algorithm>


// hint: operator* applies to character literals, but not to double-quoted literals
#define UTILITY_LITERAL_CHAR_(c_str, char_type)     (c_str * 0, ::tackle::literal_char_caster<char_type>::cast_from(c_str, L ## c_str, u ## c_str, U ## c_str))

// hint: operator[] applies to double-quoted literals, but is not to character literals
#define UTILITY_LITERAL_STRING_(c_str, char_type)   (c_str[0], ::tackle::literal_string_caster<char_type>::cast_from(c_str, L ## c_str, u ## c_str, U ## c_str))

#define UTILITY_LITERAL_CHAR(c_str, char_type)      UTILITY_LITERAL_CHAR_(c_str, char_type)
#define UTILITY_LITERAL_STRING(c_str, char_type)    UTILITY_LITERAL_STRING_(c_str, char_type)


namespace utility {

    template <typename T>
    struct basic_char_identity {};

    using char_identity = basic_char_identity<char>;
    using wchar_identity = basic_char_identity<wchar_t>;
    using char16_identity = basic_char_identity<char16_t>;
    using char32_identity = basic_char_identity<char32_t>;

    template <class t_elem, class t_traits, class t_alloc>
    struct basic_string_identity {};

    using string_identity = basic_string_identity<char, std::char_traits<char>, std::allocator<char> >;
    using wstring_identity = basic_string_identity<wchar_t, std::char_traits<wchar_t>, std::allocator<wchar_t> >;
    using u16string_identity = basic_string_identity<char16_t, std::char_traits<char16_t>, std::allocator<char16_t> >;
    using u32string_identity = basic_string_identity<char32_t, std::char_traits<char32_t>, std::allocator<char32_t> >;

}

namespace tackle {

    template <typename CharT, size_t S>
    using literal_string_const_reference = const CharT(&)[S];

    template <typename CharT, size_t S>
    using literal_string_reference = CharT(&)[S];

    template <size_t S> using literal_char_string_const_reference   = literal_string_const_reference<char, S>;
    template <size_t S> using literal_char_string_reference         = literal_string_reference<char, S>;

    template <size_t S> using literal_wchar_string_const_reference  = literal_string_const_reference<wchar_t, S>;
    template <size_t S> using literal_wchar_string_reference        = literal_string_reference<wchar_t, S>;

    template <size_t S> using literal_char16_string_const_reference = literal_string_const_reference<char16_t, S>;
    template <size_t S> using literal_char16_string_reference       = literal_string_reference<char16_t, S>;

    template <size_t S> using literal_char32_string_const_reference = literal_string_const_reference<char32_t, S>;
    template <size_t S> using literal_char32_string_reference       = literal_string_reference<char32_t, S>;

    // template class to replace partial function specialization and bypass overload over different return types
    template <typename CharT>
    struct literal_char_caster;
    template <typename CharT>
    struct literal_string_caster;

    template <>
    struct literal_char_caster<char>
    {
        FORCE_INLINE static CONSTEXPR char
            cast_from(
                char ach,
                wchar_t wch,
                char16_t char16ch,
                char32_t char32ch)
        {
            return ach;
        }
    };

    template <>
    struct literal_char_caster<wchar_t>
    {
        FORCE_INLINE static CONSTEXPR wchar_t
            cast_from(
                char ach,
                wchar_t wch,
                char16_t char16ch,
                char32_t char32ch)
        {
            return wch;
        }
    };

    template <>
    struct literal_char_caster<char16_t>
    {
        FORCE_INLINE static CONSTEXPR char16_t
            cast_from(
                char ach,
                wchar_t wch,
                char16_t char16ch,
                char32_t char32ch)
        {
            return char16ch;
        }
    };

    template <>
    struct literal_char_caster<char32_t>
    {
        FORCE_INLINE static CONSTEXPR char32_t
            cast_from(
                char ach,
                wchar_t wch,
                char16_t char16ch,
                char32_t char32ch)
        {
            return char32ch;
        }
    };

    template <>
    struct literal_string_caster<char>
    {
        template <size_t S>
        FORCE_INLINE static CONSTEXPR literal_char_string_const_reference<S>
            cast_from(
                literal_char_string_const_reference<S> astr,
                literal_wchar_string_const_reference<S> wstr,
                literal_char16_string_const_reference<S> char16str,
                literal_char32_string_const_reference<S> char32str)
        {
            return astr;
        }
    };

    template <>
    struct literal_string_caster<wchar_t>
    {
        template <size_t S>
        FORCE_INLINE static CONSTEXPR literal_wchar_string_const_reference<S>
            cast_from(
                literal_char_string_const_reference<S> astr,
                literal_wchar_string_const_reference<S> wstr,
                literal_char16_string_const_reference<S> char16str,
                literal_char32_string_const_reference<S> char32str)
        {
            return wstr;
        }
    };

    template <>
    struct literal_string_caster<char16_t>
    {
        template <size_t S>
        FORCE_INLINE static CONSTEXPR literal_char16_string_const_reference<S>
            cast_from(
                literal_char_string_const_reference<S> astr,
                literal_wchar_string_const_reference<S> wstr,
                literal_char16_string_const_reference<S> char16str,
                literal_char32_string_const_reference<S> char32str)
        {
            return char16str;
        }
    };

    template <>
    struct literal_string_caster<char32_t>
    {
        template <size_t S>
        FORCE_INLINE static CONSTEXPR literal_char32_string_const_reference<S>
            cast_from(
                literal_char_string_const_reference<S> astr,
                literal_wchar_string_const_reference<S> wstr,
                literal_char16_string_const_reference<S> char16str,
                literal_char32_string_const_reference<S> char32str)
        {
            return char32str;
        }
    };

    // implementation based on answers from here: stackoverflow.com/questions/2342162/stdstring-formatting-like-sprintf/2342176
    //
    FORCE_INLINE std::string string_format(size_t string_reserve, const std::string fmt_str, ...)
    {
        size_t str_len = (std::max)(fmt_str.size(), string_reserve);
        std::string str;

        va_list ap;
        va_start(ap, fmt_str);

        while (true) {
            str.resize(str_len);

            const int final_n = std::vsnprintf(const_cast<char *>(str.data()), str_len, fmt_str.c_str(), ap);

            if (final_n < 0 || final_n >= int(str_len))
                str_len += (std::abs)(final_n - int(str_len) + 1);
            else {
                str.resize(final_n); // do not forget to shrink the size!
                break;
            }
        }

        va_end(ap);

        return str;
    }

}
