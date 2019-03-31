#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_STRING_HPP
#define UTILITY_STRING_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/preprocessor.hpp>
#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/string_identity.hpp>

#include <tacklelib/tackle/tmpl_string.hpp>
#include <tacklelib/tackle/constexpr_string.hpp>

#include <string>
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


namespace utility {

    template <typename CharT>
    FORCE_INLINE CONSTEXPR_RETURN CharT * get_c_str(CharT * str)
    {
        return str;
    }

    template <uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_RETURN const CharT * get_c_str(const tackle::tmpl_basic_string<id, CharT, tchars...> & str)
    {
        return str.c_str();
    }

    template <typename CharT>
    FORCE_INLINE CONSTEXPR_RETURN const CharT * get_c_str(const tackle::constexpr_basic_string<CharT> & str)
    {
        return str.c_str();
    }

    template <typename t_elem, typename t_traits, typename t_alloc>
    FORCE_INLINE CONSTEXPR_RETURN const t_elem * get_c_str(const std::basic_string<t_elem, t_traits, t_alloc> & str)
    {
        return str.c_str();
    }

    template <uint64_t id, typename CharT, CharT... tchars>
    FORCE_INLINE CONSTEXPR_RETURN const CharT * get_c_param(const tackle::tmpl_basic_string<id, CharT, tchars...> & str)
    {
        return str.c_str();
    }

    template <typename CharT>
    FORCE_INLINE CONSTEXPR_RETURN const CharT * get_c_param(const tackle::constexpr_basic_string<CharT> & str)
    {
        return str.c_str();
    }

    template <typename t_elem, typename t_traits, typename t_alloc>
    FORCE_INLINE CONSTEXPR_RETURN const t_elem * get_c_param(const std::basic_string<t_elem, t_traits, t_alloc> & str)
    {
        return str.c_str();
    }

    // pass parameter as is for all other types
    template <typename T>
    FORCE_INLINE CONSTEXPR_RETURN T & get_c_param(T & param)
    {
        return param;
    }

    // implementation based on answers from here: stackoverflow.com/questions/2342162/stdstring-formatting-like-sprintf/2342176
    //

    FORCE_INLINE std::string string_format(size_t string_reserve, std::string && fmt_str, va_list vl)
    {
        size_t str_len = (std::max)(fmt_str.size(), string_reserve);
        std::string str;

        while (true) {
            str.resize(str_len);

            const int final_n = std::vsnprintf(const_cast<char *>(str.data()), str_len, fmt_str.c_str(), vl);

            if (final_n < 0 || final_n >= int(str_len)) {
                str_len += (std::abs)(final_n - int(str_len) + 1);
            }
            else {
                str.resize(final_n); // do not forget to shrink the size!
                break;
            }
        }

        return str;
    }

    FORCE_INLINE std::string string_format(size_t string_reserve, const std::string & fmt_str, va_list vl)
    {
        size_t str_len = (std::max)(fmt_str.size(), string_reserve);
        std::string str;

        while (true) {
            str.resize(str_len);

            const int final_n = std::vsnprintf(const_cast<char *>(str.data()), str_len, fmt_str.c_str(), vl);

            if (final_n < 0 || final_n >= int(str_len)) {
                str_len += (std::abs)(final_n - int(str_len) + 1);
            }
            else {
                str.resize(final_n); // do not forget to shrink the size!
                break;
            }
        }

        return str;
    }

    template <size_t S>
    FORCE_INLINE std::string string_format(size_t string_reserve, const char (& fmt_str)[S], va_list vl)
    {
        size_t str_len = (std::max)(S, string_reserve);
        std::string str;

        while (true) {
            str.resize(str_len);

            const int final_n = std::vsnprintf(const_cast<char *>(str.data()), str_len, fmt_str, vl);

            if (final_n < 0 || final_n >= int(str_len)) {
                str_len += (std::abs)(final_n - int(str_len) + 1);
            }
            else {
                str.resize(final_n); // do not forget to shrink the size!
                break;
            }
        }

        return str;
    }

    FORCE_INLINE std::string string_format(size_t string_reserve, const char * const & fmt_str, va_list vl)
    {
        size_t str_len = (std::max)(strlen(fmt_str), string_reserve);
        std::string str;

        while (true) {
            str.resize(str_len);

            const int final_n = std::vsnprintf(const_cast<char *>(str.data()), str_len, fmt_str, vl);

            if (final_n < 0 || final_n >= int(str_len)) {
                str_len += (std::abs)(final_n - int(str_len) + 1);
            }
            else {
                str.resize(final_n); // do not forget to shrink the size!
                break;
            }
        }

        return str;
    }

    FORCE_INLINE std::wstring string_format(size_t string_reserve, std::wstring && fmt_str, va_list vl)
    {
        size_t str_len = (std::max)(fmt_str.size(), string_reserve);
        std::wstring str;

        while (true) {
            str.resize(str_len);

            const int final_n = std::vswprintf(const_cast<wchar_t *>(str.data()), str_len, fmt_str.c_str(), vl);

            if (final_n < 0 || final_n >= int(str_len)) {
                str_len += (std::abs)(final_n - int(str_len) + 1);
            }
            else {
                str.resize(final_n); // do not forget to shrink the size!
                break;
            }
        }

        return str;
    }

    FORCE_INLINE std::wstring string_format(size_t string_reserve, const std::wstring & fmt_str, va_list vl)
    {
        size_t str_len = (std::max)(fmt_str.size(), string_reserve);
        std::wstring str;

        while (true) {
            str.resize(str_len);

            const int final_n = std::vswprintf(const_cast<wchar_t *>(str.data()), str_len, fmt_str.c_str(), vl);

            if (final_n < 0 || final_n >= int(str_len)) {
                str_len += (std::abs)(final_n - int(str_len) + 1);
            }
            else {
                str.resize(final_n); // do not forget to shrink the size!
                break;
            }
        }

        return str;
    }

    template <size_t S>
    FORCE_INLINE std::wstring string_format(size_t string_reserve, const wchar_t (* fmt_str)[S], va_list vl)
    {
        size_t str_len = (std::max)(S, string_reserve);
        std::wstring str;

        while (true) {
            str.resize(str_len);

            const int final_n = std::vswprintf(const_cast<wchar_t *>(str.data()), str_len, fmt_str, vl);

            if (final_n < 0 || final_n >= int(str_len)) {
                str_len += (std::abs)(final_n - int(str_len) + 1);
            }
            else {
                str.resize(final_n); // do not forget to shrink the size!
                break;
            }
        }

        return str;
    }

    FORCE_INLINE std::wstring string_format(size_t string_reserve, const wchar_t * const & fmt_str, va_list vl)
    {
        size_t str_len = (std::max)(wcslen(fmt_str), string_reserve);
        std::wstring str;

        while (true) {
            str.resize(str_len);

            const int final_n = std::vswprintf(const_cast<wchar_t *>(str.data()), str_len, fmt_str, vl);

            if (final_n < 0 || final_n >= int(str_len)) {
                str_len += (std::abs)(final_n - int(str_len) + 1);
            }
            else {
                str.resize(final_n); // do not forget to shrink the size!
                break;
            }
        }

        return str;
    }

    // CAUTION:
    //  fmt_str must be a reference here, otherwise an error: 
    //  `error C2338: va_start argument must not have reference type and must not be parenthesized`
    //
    inline std::string string_format(size_t string_reserve, std::string fmt_str, ...)
    {
        va_list vl;
        va_start(vl, fmt_str);
        std::string str{ std::move(string_format(string_reserve, std::move(fmt_str), vl)) };
        va_end(vl);

        return std::move(str);
    }

    inline std::string string_format(size_t string_reserve, const char * fmt_str, ...)
    {
        va_list vl;
        va_start(vl, fmt_str);
        std::string str{ std::move(string_format(string_reserve, fmt_str, vl)) };
        va_end(vl);

        return std::move(str);
    }

    // CAUTION:
    //  fmt_str must be a reference here, otherwise an error: 
    //  `error C2338: va_start argument must not have reference type and must not be parenthesized`
    //
    inline std::wstring string_format(size_t string_reserve, std::wstring fmt_str, ...)
    {
        va_list vl;
        va_start(vl, fmt_str);
        std::wstring str{ std::move(string_format(string_reserve, std::move(fmt_str), vl)) };
        va_end(vl);

        return std::move(str);
    }

    inline std::wstring string_format(size_t string_reserve, const wchar_t * fmt_str, ...)
    {
        va_list vl;
        va_start(vl, fmt_str);
        std::wstring str{ std::move(string_format(string_reserve, fmt_str, vl)) };
        va_end(vl);

        return std::move(str);
    }

}

#endif
