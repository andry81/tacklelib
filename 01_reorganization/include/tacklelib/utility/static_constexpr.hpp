#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_STATIC_CONSTEXPR_HPP
#define UTILITY_STATIC_CONSTEXPR_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/preprocessor.hpp>
#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_identity.hpp>
#include <tacklelib/utility/string_identity.hpp>

#include <cwchar>
#if !defined(UTILITY_PLATFORM_MINGW) && !defined(UTILITY_COMPILER_CXX_GCC)
#   include <uchar.h> // in GCC `cuchar` header might not exist
#endif


namespace utility
{
    namespace detail
    {
        template <typename T>
        FORCE_INLINE CONSTEXPR_FUNC size_t _get_file_name_constexpr_offset(T && str, size_t i)
        {
            using unqual_type_t = typename utility::remove_cvref_cvptr<T>::type;
            return (
                str[i] == utility::literal_separators<unqual_type_t>::forward_slash_char ||
                str[i] == utility::literal_separators<unqual_type_t>::backward_slash_char) ?
                    i + 1 : (i > 0 ? _get_file_name_constexpr_offset(str, i - 1) : 0);
        }
    }

    template <size_t S>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_file_name_constexpr_offset(const char (& str)[S])
    {
        return detail::_get_file_name_constexpr_offset(str, S - 1);
    }

    template <size_t S>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_file_name_constexpr_offset(const wchar_t (& str)[S])
    {
        return detail::_get_file_name_constexpr_offset(str, S - 1);
    }

    template <size_t S>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_file_name_constexpr_offset(const char16_t (& str)[S])
    {
        return detail::_get_file_name_constexpr_offset(str, S - 1);
    }

    template <size_t S>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_file_name_constexpr_offset(const char32_t (& str)[S])
    {
        return detail::_get_file_name_constexpr_offset(str, S - 1);
    }

    template <typename T>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_file_name_constexpr_offset(const T (& str)[1])
    {
        return 0;
    }

    template <typename T>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_file_name_constexpr_offset(const T * const & str)
    {
        return detail::_get_file_name_constexpr_offset(str, constexpr_string_length(str));
    }

    namespace detail
    {
        template <typename T>
        FORCE_INLINE CONSTEXPR_FUNC size_t _get_unmangled_src_func_constexpr_offset(T && str, size_t i)
        {
            using unqual_type_t = typename utility::remove_cvref_cvptr_extent<T>::type;
            return (str[i] == utility::literal_separators<unqual_type_t>::colon_char) ?
                i + 1 : (i > 0 ? _get_unmangled_src_func_constexpr_offset(str, i - 1) : 0);
        }
    }

    template <size_t S>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_unmangled_src_func_constexpr_offset(const char (& str)[S])
    {
        return detail::_get_unmangled_src_func_constexpr_offset(str, S - 1);
    }

    template <size_t S>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_unmangled_src_func_constexpr_offset(const wchar_t (& str)[S])
    {
        return detail::_get_unmangled_src_func_constexpr_offset(str, S - 1);
    }

    template <size_t S>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_unmangled_src_func_constexpr_offset(const char16_t (& str)[S])
    {
        return detail::_get_unmangled_src_func_constexpr_offset(str, S - 1);
    }

    template <size_t S>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_unmangled_src_func_constexpr_offset(const char32_t (& str)[S])
    {
        return _get_unmangled_src_func_constexpr_offset(str, S - 1);
    }

    template <typename T>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_unmangled_src_func_constexpr_offset(const T (& str)[1])
    {
        return 0;
    }

    template <typename T>
    FORCE_INLINE CONSTEXPR_FUNC size_t get_unmangled_src_func_constexpr_offset(const T * const & str)
    {
        return detail::_get_unmangled_src_func_constexpr_offset(str, constexpr_string_length(str));
    }

}

#endif
