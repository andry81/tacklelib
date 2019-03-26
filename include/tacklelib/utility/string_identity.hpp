#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_STRING_IDENTITY_HPP
#define UTILITY_STRING_IDENTITY_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_identity.hpp>
#include <tacklelib/utility/static_assert.hpp>

#include <string>
#include <array>
#include <cstring>
#include <cstddef>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cwchar>
#include <uchar.h> // in GCC `cuchar` header might not exist
#include <memory>
#include <algorithm>
#include <type_traits>


#define UTILITY_STATIC_STRING_SIZE_(c_str)              (sizeof(c_str) / sizeof((c_str)[0]))
#define UTILITY_STATIC_STRING_SIZE(c_str)               UTILITY_STATIC_STRING_SIZE_(c_str)

#define UTILITY_STATIC_STRING_LEN(c_str)                (UTILITY_STATIC_STRING_SIZE(c_str) - 1)

// hint: operator* applies to character literals, but not to double-quoted literals
#define UTILITY_LITERAL_CHAR_(ansi_str, char_type)      ((void)((ansi_str) * 0), ::utility::literal_char_caster<typename ::utility::remove_cvref<char_type>::type>::cast_from(ansi_str, L ## ansi_str, u ## ansi_str, U ## ansi_str))
#define UTILITY_LITERAL_CHAR(ansi_str, char_type)       UTILITY_LITERAL_CHAR_(ansi_str, char_type)

// hint: operator[] applies to double-quoted literals, but is not to character literals
#define UTILITY_LITERAL_STRING_(ansi_str, char_type)    ((void)((ansi_str)[0]), ::utility::literal_string_caster<typename ::utility::remove_cvref<char_type>::type>::cast_from(ansi_str, L ## ansi_str, u ## ansi_str, U ## ansi_str))
#define UTILITY_LITERAL_STRING(ansi_str, char_type)     UTILITY_LITERAL_STRING_(ansi_str, char_type)

#define UTILITY_LITERAL_STRING_BY_CHAR_ARRAY(char_type, ...) \
    ((void)((UTILITY_PP_MACRO_ARG0(__VA_ARGS__)) * 0), ::utility::literal_string_from_chars<typename ::utility::remove_cvref<char_type>::type>(__VA_ARGS__, UTILITY_LITERAL_CHAR('\0', char_type)))

// checker on an array string, but does not check if a literal (T[] - true, T* - false)
#define UTILITY_IS_ARRAY_STRING(c_str)                  UTILITY_CONSTEXPR_VALUE(sizeof(::utility::is_array_string::check(c_str)) == sizeof(::utility::is_array_string::yes))

// uniform literal string checker
#define UTILITY_IS_LITERAL_STRING(c_str)                UTILITY_CONSTEXPR_VALUE((sizeof(#c_str) > 1) ? #c_str [sizeof(#c_str) - 2] == UTILITY_LITERAL_CHAR('\"', decltype((c_str)[0])) : false)

// specialized literal string checker
#define UTILITY_IS_LITERAL_STRING_A(c_str)                      UTILITY_CONSTEXPR_VALUE((sizeof(#c_str) > 1) ? #c_str [sizeof(#c_str) - 2] == '\"' : false)
#define UTILITY_IS_LITERAL_STRING_WITH_PREFIX(c_str, prefix)    UTILITY_CONSTEXPR_VALUE((sizeof(#c_str) > 1) ? #c_str [sizeof(#c_str) - 2] == prefix ## '\"' : false)

#define UTILITY_IS_CONSTEXPR_STRING(c_str)              UTILITY_IS_CONSTEXPR_VALUE((c_str)[0])

#define UTILITY_LITERAL_STRING_WITH_SIZE_TUPLE(str)     str, (UTILITY_CONSTEXPR_SIZE(str))
#define UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(str)   str, (UTILITY_CONSTEXPR_SIZE(str) - 1)

#define UTILITY_STATIC_STRING_WITH_SIZE_TUPLE(str)      str, (UTILITY_STATIC_SIZE(str))
#define UTILITY_STATIC_STRING_WITH_LENGTH_TUPLE(str)    str, (UTILITY_STATIC_SIZE(str) - 1)

// string with safe offset through the static assert on an constexpr expression
#define UTILITY_LITERAL_STRING_WITH_LENGTH_AND_CONSTEXPR_OFFSET_TUPLE(str, constexpr_offset) \
    (STATIC_ASSERT_CONSTEXPR_TRUE((constexpr_offset) < UTILITY_CONSTEXPR_SIZE(str)), UTILITY_CONSTEXPR_VALUE((str) + (constexpr_offset))), UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_SIZE(str) - (constexpr_offset) - 1)

// string with safe offset through the runtime condition on a string static size
#define UTILITY_STATIC_STRING_WITH_LENGTH_AND_OFFSET_TUPLE(str, offset) \
    (((offset) < UTILITY_STATIC_SIZE(str)) ? (str) + (offset) : (str) + UTILITY_STATIC_SIZE(str) - 1), (((offset) < UTILITY_STATIC_SIZE(str)) ? (UTILITY_STATIC_SIZE(str) - (offset) - 1) : 0)


#define UTILITY_LITERAL_STRING_VALUE(c_str) \
    ([]{ \
        static_assert(UTILITY_IS_LITERAL_STRING(c_str), "c_str is not a literal string"); \
        struct holder \
        { \
            static CONSTEXPR_RETURN auto get() -> decltype(c_str) & \
            { \
                return c_str; \
            } \
        }; \
        return holder{}; \
    }())

#define UTILITY_STATIC_STRING_VALUE(c_str) \
    ([]{ \
        static_assert(UTILITY_IS_ARRAY_STRING(c_str), "c_str is not an array string"); \
        struct holder \
        { \
            static CONSTEXPR_RETURN auto get() -> decltype(c_str) & \
            { \
                return c_str; \
            } \
        }; \
        return holder{}; \
    }())

#define UTILITY_LITERAL_STRING_VALUE_AS(ansi_str, char_type) \
    ([]{ \
        static_assert(UTILITY_IS_LITERAL_STRING(ansi_str), "ansi_str is not a literal string"); \
        struct holder \
        { \
            static CONSTEXPR_RETURN auto get() -> \
                decltype(UTILITY_LITERAL_STRING(ansi_str, char_type)) & \
            { \
                return UTILITY_LITERAL_STRING(ansi_str, char_type); \
            } \
        }; \
        return holder{}; \
    }())


namespace utility {

    template <typename CharT>
    struct basic_char_identity {};

    template <>
    struct basic_char_identity<char>
    {
        static CONSTEXPR const size_t type_index = 0;
    };

    template <>
    struct basic_char_identity<wchar_t>
    {
        static CONSTEXPR const size_t type_index = 1;
    };

    template <>
    struct basic_char_identity<char16_t>
    {
        static CONSTEXPR const size_t type_index = 2;
    };

    template <>
    struct basic_char_identity<char32_t>
    {
        static CONSTEXPR const size_t type_index = 3;
    };

    using char_identity         = basic_char_identity<char>;
    using wchar_identity        = basic_char_identity<wchar_t>;
    using char16_identity       = basic_char_identity<char16_t>;
    using char32_identity       = basic_char_identity<char32_t>;

    // all tags must be derived as a new type
    template <typename CharT>
    struct tag_basic_char       : basic_char_identity<CharT> {};

    struct tag_char             : char_identity {};
    struct tag_wchar            : wchar_identity {};
    struct tag_char16           : char16_identity {};
    struct tag_char32           : char32_identity {};

    template <typename t_elem>
    struct tag_char_by_elem :
        std::conditional<std::is_same<char, t_elem>::value,
            tag_char,
            typename std::conditional<std::is_same<wchar_t, t_elem>::value,
                tag_wchar,
                typename std::conditional<std::is_same<char16_t, t_elem>::value,
                    tag_char16,
                    typename std::conditional<std::is_same<char32_t, t_elem>::value,
                        tag_char32,
                        utility::void_
                    >::type
                >::type
            >::type
        >::type
    {
    };

    template <class t_elem, class t_traits, class t_alloc>
    struct basic_string_identity {};

    template <class t_traits, class t_alloc>
    struct basic_string_identity<char, t_traits, t_alloc>
    {
        static CONSTEXPR const size_t type_index = 0;
    };

    template <class t_traits, class t_alloc>
    struct basic_string_identity<wchar_t, t_traits, t_alloc>
    {
        static CONSTEXPR const size_t type_index = 1;
    };

    template <class t_traits, class t_alloc>
    struct basic_string_identity<char16_t, t_traits, t_alloc>
    {
        static CONSTEXPR const size_t type_index = 2;
    };

    template <class t_traits, class t_alloc>
    struct basic_string_identity<char32_t, t_traits, t_alloc>
    {
        static CONSTEXPR const size_t type_index = 3;
    };

    using string_identity       = basic_string_identity<char, std::char_traits<char>, std::allocator<char> >;
    using wstring_identity      = basic_string_identity<wchar_t, std::char_traits<wchar_t>, std::allocator<wchar_t> >;
    using u16string_identity    = basic_string_identity<char16_t, std::char_traits<char16_t>, std::allocator<char16_t> >;
    using u32string_identity    = basic_string_identity<char32_t, std::char_traits<char32_t>, std::allocator<char32_t> >;

    // all tags must be derived as a new type
    template <class t_elem, class t_traits, class t_alloc>
    struct tag_basic_string     : basic_string_identity<t_elem, t_traits, t_alloc> {};

    struct tag_string           : string_identity {};
    struct tag_wstring          : wstring_identity {};
    struct tag_u16string        : u16string_identity {};
    struct tag_u32string        : u32string_identity {};

    template <typename t_elem>
    struct tag_string_by_elem :
        std::conditional<std::is_same<char, t_elem>::value,
            tag_string,
            typename std::conditional<std::is_same<wchar_t, t_elem>::value,
                tag_wstring,
                typename std::conditional<std::is_same<char16_t, t_elem>::value,
                    tag_u16string,
                    typename std::conditional<std::is_same<char32_t, t_elem>::value,
                        tag_u32string,
                        void_
                    >::type
                >::type
            >::type
        >::type
    {
    };

    template <typename CharT, size_t S>
    using literal_basic_string_const_arr                            = const CharT[S];

    template <typename CharT, size_t S>
    using literal_basic_string_arr                                  = CharT[S];

    template <typename CharT, size_t S>
    using literal_basic_string_const_reference_arr                  = const CharT (&)[S];

    template <typename CharT, size_t S>
    using literal_basic_string_reference_arr                        = CharT (&)[S];

    template <typename CharT, size_t S>
    using literal_char_array                                        = std::array<CharT, S>;

    template <size_t S> using literal_string_const_reference_arr    = literal_basic_string_const_reference_arr<char, S>;
    template <size_t S> using literal_string_reference_arr          = literal_basic_string_reference_arr<char, S>;

    template <size_t S> using literal_wstring_const_reference_arr   = literal_basic_string_const_reference_arr<wchar_t, S>;
    template <size_t S> using literal_wstring_reference_arr         = literal_basic_string_reference_arr<wchar_t, S>;

    template <size_t S> using literal_u16string_const_reference_arr = literal_basic_string_const_reference_arr<char16_t, S>;
    template <size_t S> using literal_u16string_reference_arr       = literal_basic_string_reference_arr<char16_t, S>;

    template <size_t S> using literal_u32string_const_reference_arr = literal_basic_string_const_reference_arr<char32_t, S>;
    template <size_t S> using literal_u32string_reference_arr       = literal_basic_string_reference_arr<char32_t, S>;

    struct is_array_string
    {
        using yes = char[1];
        using no = char[2];

        template <typename T, size_t S>
        static yes & check(const T (&)[S]);
        static no & check(...);
    };

    //// literal_char_caster

    // template class to replace partial function specialization and avoid overload over different return types
    template <typename CharT>
    struct literal_char_caster;

    template <>
    struct literal_char_caster<char>
    {
        static FORCE_INLINE CONSTEXPR_RETURN char
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
        static FORCE_INLINE CONSTEXPR_RETURN wchar_t
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
        static FORCE_INLINE CONSTEXPR_RETURN char16_t
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
        static FORCE_INLINE CONSTEXPR_RETURN char32_t
            cast_from(
                char ach,
                wchar_t wch,
                char16_t char16ch,
                char32_t char32ch)
        {
            return char32ch;
        }
    };

    // Based on: https://stackoverflow.com/questions/3703658/specifying-one-type-for-all-arguments-passed-to-variadic-function-or-variadic-te
    //

    namespace detail {

        template <typename R, typename...>
        struct _fst
        {
            using type = R;
        };

    }

    template <typename CharT, typename... Args>
    static FORCE_INLINE CONSTEXPR_RETURN
        typename detail::_fst<literal_char_array<CharT, sizeof...(Args)>,
            typename std::enable_if<
                std::is_convertible<Args, CharT>::value
            >::type...
        >::type
        literal_string_from_chars(Args... args)
    {
        return{{ args... }};
    }

    //template <typename CharT>
    //static FORCE_INLINE CONSTEXPR auto
    //    literal_string_from_chars(CharT... args) -> literal_string_const_reference_arr<sizeof...(args)>
    //{
    //    return { args... };
    //}

    //// literal_string_caster

    template <typename CharT>
    struct literal_string_caster;

    template <>
    struct literal_string_caster<char>
    {
        template <size_t S>
        static FORCE_INLINE CONSTEXPR_RETURN literal_string_const_reference_arr<S>
            cast_from(
                literal_string_const_reference_arr<S> astr,
                literal_wstring_const_reference_arr<S> wstr,
                literal_u16string_const_reference_arr<S> char16str,
                literal_u32string_const_reference_arr<S> char32str)
        {
            return astr;
        }
    };

    template <>
    struct literal_string_caster<wchar_t>
    {
        template <size_t S>
        static FORCE_INLINE CONSTEXPR_RETURN literal_wstring_const_reference_arr<S>
            cast_from(
                literal_string_const_reference_arr<S> astr,
                literal_wstring_const_reference_arr<S> wstr,
                literal_u16string_const_reference_arr<S> char16str,
                literal_u32string_const_reference_arr<S> char32str)
        {
            return wstr;
        }
    };

    template <>
    struct literal_string_caster<char16_t>
    {
        template <size_t S>
        static FORCE_INLINE CONSTEXPR_RETURN literal_u16string_const_reference_arr<S>
            cast_from(
                literal_string_const_reference_arr<S> astr,
                literal_wstring_const_reference_arr<S> wstr,
                literal_u16string_const_reference_arr<S> char16str,
                literal_u32string_const_reference_arr<S> char32str)
        {
            return char16str;
        }
    };

    template <>
    struct literal_string_caster<char32_t>
    {
        template <size_t S>
        static FORCE_INLINE CONSTEXPR_RETURN literal_u32string_const_reference_arr<S>
            cast_from(
                literal_string_const_reference_arr<S> astr,
                literal_wstring_const_reference_arr<S> wstr,
                literal_u16string_const_reference_arr<S> char16str,
                literal_u32string_const_reference_arr<S> char32str)
        {
            return char32str;
        }
    };

    //// literal_separators

    template <typename CharT>
    struct literal_separators
    {
        // string types

        using null_str_t                                            = literal_basic_string_const_reference_arr<CharT, UTILITY_STATIC_STRING_SIZE("")>;

        using forward_slash_str_t                                   = literal_basic_string_const_reference_arr<CharT, UTILITY_STATIC_STRING_SIZE("/")>;
        using backward_slash_str_t                                  = literal_basic_string_const_reference_arr<CharT, UTILITY_STATIC_STRING_SIZE("\\")>;
        using space_str_t                                           = literal_basic_string_const_reference_arr<CharT, UTILITY_STATIC_STRING_SIZE(" ")>;

        using colon_str_t                                           = literal_basic_string_const_reference_arr<CharT, UTILITY_STATIC_STRING_SIZE(":")>;

        // string values

        static CONSTEXPR null_str_t null_str                        = UTILITY_LITERAL_STRING("", CharT);

        static CONSTEXPR forward_slash_str_t forward_slash_str      = UTILITY_LITERAL_STRING("/", CharT);
        static CONSTEXPR backward_slash_str_t backward_slash_str    = UTILITY_LITERAL_STRING("\\", CharT);
        static CONSTEXPR space_str_t space_str                      = UTILITY_LITERAL_STRING(" ", CharT);

        static CONSTEXPR colon_str_t colon_str                      = UTILITY_LITERAL_STRING(":", CharT);

        // character values

        static CONSTEXPR const CharT null_char                      = UTILITY_LITERAL_CHAR('\0', CharT);

        static CONSTEXPR const CharT forward_slash_char             = UTILITY_LITERAL_CHAR('/', CharT);
        static CONSTEXPR const CharT backward_slash_char            = UTILITY_LITERAL_CHAR('\\', CharT);
        static CONSTEXPR const CharT space_char                     = UTILITY_LITERAL_CHAR(' ', CharT);

        // back slash separator has meaning only on the Windows systems in the UNC paths
        static CONSTEXPR const CharT filesystem_unc_dir_separator_char = backward_slash_char;

        static CONSTEXPR const CharT colon_char                     = UTILITY_LITERAL_CHAR(':', CharT);
    };

    // To check conversion from `T &&` to std::basic_string

    template <typename T, typename t_elem, typename t_traits, typename t_alloc>
    struct is_convertible_to_basic_string
    {
        static CONSTEXPR const bool value = std::is_convertible<T, std::basic_string<t_elem, t_traits, t_alloc> >::value;
    };

    template <typename T>
    struct is_convertible_to_string
    {
        static CONSTEXPR const bool value = std::is_convertible<T, std::string>::value;
    };

    template <typename T>
    struct is_convertible_to_wstring
    {
        static CONSTEXPR const bool value = std::is_convertible<T, std::wstring>::value;
    };

    template <typename T>
    struct is_convertible_to_u16string
    {
        static CONSTEXPR const bool value = std::is_convertible<T, std::u16string>::value;
    };

    template <typename T>
    struct is_convertible_to_u32string
    {
        static CONSTEXPR const bool value = std::is_convertible<T, std::u32string>::value;
    };

    template <typename T>
    struct is_convertible_to_stdstring
    {
        static CONSTEXPR const bool value =
            is_convertible_to_string<T>::value || is_convertible_to_wstring<T>::value ||
            is_convertible_to_u16string<T>::value || is_convertible_to_u32string<T>::value;
    };

    // string length for a constexpr/runtime string

    namespace detail
    {
        template <typename CharT, size_t S>
        FORCE_INLINE CONSTEXPR_RETURN size_t _string_length(const CharT (& str)[S], size_t i)
        {
            return S - 1;
        }

        template <typename CharT>
        FORCE_INLINE CONSTEXPR_RETURN size_t _string_length(const CharT * const & str, size_t i)
        {
            using unqual_type_t = typename utility::remove_cvrefcvptr<CharT>::type;
            return (str[i] == utility::literal_separators<unqual_type_t>::null_char) ?
                i : _string_length(str, i + 1);
        }
    }

    // string length for a constexpr string

    template <typename CharT, size_t S>
    FORCE_INLINE CONSTEXPR_RETURN size_t constexpr_string_length(const CharT (& str)[S]) noexcept
    {
        return S - 1; // no need static assert here
    }

    template <typename CharT>
    FORCE_INLINE CONSTEXPR_RETURN size_t constexpr_string_length(const CharT * const & str)
    {
        return (STATIC_ASSERT_CONSTEXPR_TRUE(str), detail::_string_length(str, 0));
    }

    // string length for a runtime string

    template <typename CharT, size_t S>
    FORCE_INLINE CONSTEXPR_RETURN size_t string_length(const CharT (& str)[S]) noexcept
    {
        return S - 1;
    }

    template <typename CharT>
    FORCE_INLINE CONSTEXPR_RETURN size_t string_length(const CharT * const & str)
    {
        return detail::_string_length(str, 0);
    }

    template <typename t_elem, typename t_traits, typename t_alloc>
    FORCE_INLINE CONSTEXPR_RETURN size_t string_length(const std::basic_string<t_elem, t_traits, t_alloc> & str)
    {
        return str.length();
    }

    // To compare strings in a static assert.
    // Based on: https://stackoverflow.com/questions/27490858/how-can-you-compare-two-character-strings-statically-at-compile-time
    //

    template <typename CharT>
    FORCE_INLINE CONSTEXPR_RETURN bool is_equal_c_str(const CharT * const & a, const CharT * const & b)
    {
        return *a == *b && (*a == UTILITY_LITERAL_CHAR('\0', CharT) || is_equal_c_str(a + 1, b + 1));
    }

    template <typename CharT, size_t S>
    FORCE_INLINE CONSTEXPR_RETURN bool is_equal_c_str(const CharT (& a)[S], const CharT (& b)[S])
    {
        return is_equal_c_str(a + 0, b + 0);
    }

    template <typename CharT, size_t S0, size_t S1>
    FORCE_INLINE CONSTEXPR_RETURN bool is_equal_c_str(const CharT (& a)[S0], const CharT (& b)[S1])
    {
        return false;
    }

}

#endif
