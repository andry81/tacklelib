#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_FILE_HANDLE_HPP
#define TACKLE_FILE_HANDLE_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/assert.hpp>

#include <tacklelib/tackle/smart_handle.hpp>
#include <tacklelib/tackle/path_string.hpp>

#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_FORMAT_INSTEAD_UTILITY_STRING_FORMAT)
#  include <fmt/format.h>
#else
#  include <tacklelib/utility/utility.hpp>
#endif

#include <cstdio>
#include <utility>

#undef LIBRARY_API_NAMESPACE
#define LIBRARY_API_NAMESPACE TACKLELIB
#include <tacklelib/utility/library_api_define.hpp>


namespace tackle
{
    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    class LIBRARY_API_DECL basic_file_handle : public smart_handle<FILE>
    {
        using base_type = smart_handle<FILE>;

    public:
        using path_string_type = path_basic_string<t_elem, t_traits, t_alloc, separator_char>;

    private:
        static FORCE_INLINE void _deleter(void * p)
        {
            if (p) {
                fclose((FILE *)p);
            }
        }

    public:
        static FORCE_INLINE const basic_file_handle & null()
        {
            static const basic_file_handle s_null = basic_file_handle{ nullptr,
#ifdef UTILITY_PLATFORM_WINDOWS
                path_string_type{ UTILITY_LITERAL_STRING("nul", t_elem) }
#elif defined(UTILITY_PLATFORM_POSIX)
                path_string_type{ UTILITY_LITERAL_STRING("/dev/null", t_elem) }
#else
#error platform is not implemented
#endif
            };
            return s_null;
        }

        FORCE_INLINE basic_file_handle()
        {
            *this = null();
        }

        FORCE_INLINE basic_file_handle(const basic_file_handle &) = default;
        FORCE_INLINE basic_file_handle(basic_file_handle &&) = default;

        FORCE_INLINE basic_file_handle & operator =(const basic_file_handle &) = default;
        FORCE_INLINE basic_file_handle & operator =(basic_file_handle &&) = default;

        FORCE_INLINE basic_file_handle(FILE * p, const path_string_type & file_path) :
            base_type(p, _deleter),
            m_file_path(file_path)
        {
        }

        FORCE_INLINE void reset(basic_file_handle handle = basic_file_handle::null())
        {
            auto && handle_rref = std::move(handle);

            auto * deleter = DEBUG_VERIFY_TRUE(std::get_deleter<base_type::deleter_type>(handle_rref.m_pv));
            if (!deleter) {
                // must always have a deleter
                DEBUG_BREAK_THROW(true) std::runtime_error(
#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_FORMAT_INSTEAD_UTILITY_STRING_FORMAT)
                    fmt::format("{:s}({:d}): deleter is not allocated",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE)
#else
                    utility::string_format(256, "%s(%d): deleter is not allocated",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE)
#endif
                );
            }

            base_type::reset(handle_rref.get(), *deleter);
            m_file_path.clear();
        }

        FORCE_INLINE const path_string_type & path() const
        {
            return m_file_path;
        }

        FORCE_INLINE int fileno() const
        {
#ifdef UTILITY_PLATFORM_WINDOWS
            return _fileno(get());
#elif defined(UTILITY_PLATFORM_POSIX)
            return ::fileno(get());
#else
#error platform is not implemented
#endif
        }

    private:
        path_string_type m_file_path;
    };

    template <class t_elem, class t_traits, class t_alloc>
    using generic_basic_file_handle = basic_file_handle<t_elem, t_traits, t_alloc, utility::literal_separators<t_elem>::forward_slash_char>;

#if defined(UTILITY_PLATFORM_WINDOWS)
    template <class t_elem, class t_traits, class t_alloc>
    using native_basic_file_handle = basic_file_handle<t_elem, t_traits, t_alloc, utility::literal_separators<t_elem>::backward_slash_char>;
#else
    template <class t_elem, class t_traits, class t_alloc>
    using native_basic_file_handle = basic_file_handle<t_elem, t_traits, t_alloc, utility::literal_separators<t_elem>::forward_slash_char>;
#endif

    template <class t_elem = char>
    using generic_file_handle = generic_basic_file_handle<t_elem, std::char_traits<t_elem>, std::allocator<t_elem> >;

    template <class t_elem = char>
    using native_file_handle = native_basic_file_handle<t_elem, std::char_traits<t_elem>, std::allocator<t_elem> >;

    // based on generic path string
    template <class t_elem = char>
    using file_handle = generic_file_handle<t_elem>;
}

#endif
