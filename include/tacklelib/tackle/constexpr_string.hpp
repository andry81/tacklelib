#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_CONSTEXPR_STRING_HPP
#define TACKLE_CONSTEXPR_STRING_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/preprocessor.hpp>
#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_identity.hpp>
#include <tacklelib/utility/string_identity.hpp>
#include <tacklelib/utility/debug.hpp>

#include <tacklelib/tackle/tmpl_string.hpp>

#include <string>
#include <cwchar>
#include <uchar.h> // in GCC `cuchar` header might not exist
#include <memory>
#include <utility>
#include <algorithm>
#include <type_traits>


#define TACKLE_CONSTEXPR_STRING(c_str)  ::tackle::constexpr_basic_string<decltype((c_str)[0])>(c_str)


namespace tackle {

namespace detail {

    template <bool is_constexpr>
    struct _impl
    {
        // use compile-time assert

        template <typename CharT, size_t S>
        static CONSTEXPR_RETURN const CharT * _consexpr_validate_ptr(const CharT (& str)[S])
        {
            // WORKAROUND:
            //  Use `string_length` in standalone `static_assert` instead of
            //  `constexpr_string_length` in `static_assert_constexpr_true` to avoid side errors in GCC.
            //
            static_assert(utility::detail::_string_length(str, 0) + 1 == S, "input size must be equal to compile-time calculated size");
            return str;
        }

        template <typename CharT>
        static CONSTEXPR_RETURN const CharT * _consexpr_validate_ptr(const CharT * str, size_t size)
        {
            // WORKAROUND:
            //  Use `string_length` in standalone `static_assert` instead of
            //  `constexpr_string_length` in `static_assert_constexpr_true` to avoid side errors in GCC.
            //
            static_assert(utility::detail::_string_length(str, 0) + 1 == size, "input size must be equal to compile-time calculated size");
            return str;
        }

        template <typename CharT, size_t S>
        static CONSTEXPR_RETURN size_t _consexpr_validate_size(const CharT (& str)[S])
        {
            return S;
        }

        template <typename CharT>
        static CONSTEXPR_RETURN size_t _consexpr_validate_size(const CharT * str, size_t size)
        {
            return size;
        }
    };

    template <>
    struct _impl<false>
    {
        // return empty string instead of compile-time assert

        template <typename CharT, size_t S>
        static CONSTEXPR_RETURN const CharT * _consexpr_validate_ptr(const CharT (& str)[S])
        {
            return (utility::detail::_string_length(str, 0) + 1 == S) ? str : utility::literal_separators<CharT>::null_str;
        }

        template <typename CharT>
        static CONSTEXPR_RETURN const CharT * _consexpr_validate_ptr(const CharT * str, size_t size)
        {
            return (utility::detail::_string_length(str, 0) + 1 == size) ? str : utility::literal_separators<CharT>::null_str;
        }

        template <typename CharT, size_t S>
        static CONSTEXPR_RETURN size_t _consexpr_validate_size(const CharT (& str)[S])
        {
            return (utility::detail::_string_length(str, 0) + 1 == S) ? S : 1;
        }

        template <typename CharT>
        static CONSTEXPR_RETURN size_t _consexpr_validate_size(const CharT * str, size_t size)
        {
            return (utility::detail::_string_length(str, 0) + 1 == size) ? size : 1;
        }
    };

}

    // Constexpr version of C-style string, can be used as basic overload type for literal strings, character arrays and character pointers with size.
    // Based on Scott Schurr's `str_const` or see this: https://stackoverflow.com/questions/15858141/conveniently-declaring-compile-time-strings-in-c/15863826#15863826
    //

    template <typename CharT>
    class constexpr_basic_string
    {
    public:
        template <size_t S>
        using t_array_type  = CharT[S];

        FORCE_INLINE CONSTEXPR_RETURN constexpr_basic_string() :
            m_ptr(""),
            m_size(1)
        {
        }

        FORCE_INLINE CONSTEXPR_RETURN constexpr_basic_string(constexpr_basic_string &&) = default;
        FORCE_INLINE CONSTEXPR_RETURN constexpr_basic_string(const constexpr_basic_string &) = default;

        template <size_t S>
        FORCE_INLINE CONSTEXPR_RETURN constexpr_basic_string(const CharT (& arr)[S]) :
            m_ptr(detail::
                _impl<UTILITY_IS_CONSTEXPR_VALUE(arr)>::
                _consexpr_validate_ptr(arr)
            ),
            m_size(detail::
                _impl<true>::
                _consexpr_validate_size(arr)
            )
        {
        }

        // we still need both constructors to reduce unnecessary casts to/from C-style character arrays
        FORCE_INLINE CONSTEXPR_RETURN constexpr_basic_string(const CharT * const & ptr) :
            m_ptr(ptr),
            m_size(utility::string_length(ptr) + 1)
        {
        }

        // we still need both constructors to reduce unnecessary casts to/from C-style character arrays
        FORCE_INLINE CONSTEXPR_RETURN constexpr_basic_string(const CharT * ptr, size_t len) :
            m_ptr(detail::
                _impl<UTILITY_IS_CONSTEXPR_VALUE(ptr)>::
                _consexpr_validate_ptr(ptr, len + 1)
            ),
            m_size(detail::
                _impl<UTILITY_IS_CONSTEXPR_VALUE(size)>::
                _consexpr_validate_size(ptr, len + 1)
            )
        {
        }

        template <uint64_t id, typename CharT, CharT... chars>
        FORCE_INLINE CONSTEXPR_RETURN constexpr_basic_string(const tmpl_basic_string<id, CharT, chars...> & str) :
            m_ptr(str.data()),
            m_size(str.size())
        {
        }

        FORCE_INLINE CONSTEXPR_RETURN constexpr_basic_string(const std::string & str) :
            m_ptr(detail::
                _impl<UTILITY_IS_CONSTEXPR_VALUE(str.data())>::
                _consexpr_validate_ptr(str.data(), str.size())
            ),
            m_size(detail::
                _impl<UTILITY_IS_CONSTEXPR_VALUE(str.size())>::
                _consexpr_validate_size(str.data(), str.size())
            )
        {
        }

// Workaround for compilation error under MSVC2015u3 or higher (x86 only):
//  error C2666: 'constexpr_basic_string<...>::operator []': 2 overloads have similar conversions
//  ...
//  note: or       'built-in C++ operator[(CharT, int)'
//
#if !defined(UTILITY_COMPILER_CXX_MSC) || defined(UTILITY_PLATFORM_X64)
        FORCE_INLINE CONSTEXPR_RETURN CharT operator [](size_t index) const
        {
            return (index < m_size - 1) ?
                m_ptr[index] :
                (DEBUG_BREAK_THROW(true) std::range_error("index must be in range"),
                    tackle::literal_separators<CharT>::null_char);
        }
#endif

        FORCE_INLINE CONSTEXPR_RETURN const CharT * c_str() const
        {
            return m_ptr;
        }

        template <size_t S>
        FORCE_INLINE CONSTEXPR_RETURN const t_array_type<S> & data() const
        {
            return *((S == m_size) ?
                reinterpret_cast<const CharT(*)[S]>(m_ptr) :
                (DEBUG_BREAK_THROW(true) std::range_error("S must be equal to string size"),
                    reinterpret_cast<const CharT(*)[S]>(static_cast<const void *>(nullptr))));
        }

        FORCE_INLINE CONSTEXPR_RETURN size_t size() const
        {
            return m_size;
        }

        FORCE_INLINE CONSTEXPR_RETURN size_t length() const
        {
            return m_size - 1;
        }

        FORCE_INLINE CONSTEXPR_RETURN operator const CharT *() const
        {
            return c_str();
        }

        template <size_t S>
        FORCE_INLINE CONSTEXPR_RETURN operator const t_array_type<S> &() const
        {
            return data<S>();
        }

        // specific operator for std::basic_string, for example, to enable usage of std::is_convertible<constexpr_string, std::string>::value
        template <typename t_traits, typename t_alloc>
        FORCE_INLINE UTILITY_COMPILER_CXX_NOT_CLANG_CONSTEXPR_RETURN
            operator std::basic_string<CharT, t_traits, t_alloc>() const
        {
            return data<m_size>();
        }

    private:
        const CharT * const m_ptr;
        const size_t        m_size;
    };

    using constexpr_string      = constexpr_basic_string<char>;
    using constexpr_wstring     = constexpr_basic_string<wchar_t>;
    using constexpr_u16string   = constexpr_basic_string<char16_t>;
    using constexpr_u32string   = constexpr_basic_string<char32_t>;

}

namespace utility {

    // string length for a constexpr string

    template <typename CharT>
    FORCE_INLINE CONSTEXPR_RETURN size_t constexpr_string_length(const tackle::constexpr_basic_string<CharT> & str)
    {
        return str.length();
    }

    // string length for a runtime string

    template <typename CharT>
    FORCE_INLINE CONSTEXPR_RETURN size_t string_length(const tackle::constexpr_basic_string<CharT> & str)
    {
        return str.length();
    }

}

#endif
