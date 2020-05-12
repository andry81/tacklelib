#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_UTILITY_HPP
#define UTILITY_UTILITY_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_identity.hpp>
#include <tacklelib/utility/static_constexpr.hpp>
#include <tacklelib/utility/static_assert.hpp>
#include <tacklelib/utility/type_traits.hpp>
#include <tacklelib/utility/assert.hpp>
#include <tacklelib/utility/debug.hpp>
#include <tacklelib/utility/math.hpp>
#include <tacklelib/utility/string.hpp>

#include <tacklelib/tackle/path_string.hpp>
#include <tacklelib/tackle/file_handle.hpp>

#ifdef UTILITY_COMPILER_CXX_MSC
#   include <intrin.h>
#else
#   include <x86intrin.h>  // Not just <immintrin.h> for compilers other than icc
#endif

#include <type_traits>
#include <limits>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <memory>
#include <cfloat>
#include <cmath>
#include <string>
#include <stdexcept>
#include <utility>
#include <cstdint>

#if defined(UTILITY_PLATFORM_POSIX)
#   include <termios.h>
#   include <unistd.h>
#endif

#include <cstdio>
#include <memory.h>

#if defined(UTILITY_PLATFORM_WINDOWS)
#   include <conio.h>
#elif defined(UTILITY_PLATFORM_POSIX)
#   if !defined(UTILITY_PLATFORM_MINGW)
#       include <share.h>
#   endif
#else
#   error platform is not implemented
#endif

#undef LIBRARY_API_NAMESPACE
#define LIBRARY_API_NAMESPACE TACKLELIB
#include <tacklelib/utility/library_api_define.hpp>


// forwards
namespace tackle
{
    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    class basic_file_handle;

    template <class t_elem = char>
    using file_handle = generic_basic_file_handle<t_elem, std::char_traits<t_elem>, std::allocator<t_elem> >;
}

namespace tackle
{
    template <class t_elem, class t_traits, class t_alloc>
    using unc_basic_path_string = path_basic_string<t_elem, t_traits, t_alloc, utility::literal_separators<t_elem>::filesystem_unc_dir_separator_char>;

    using unc_path_string       = unc_basic_path_string<char, std::char_traits<char>, std::allocator<char> >;
    using unc_path_wstring      = unc_basic_path_string<wchar_t, std::char_traits<wchar_t>, std::allocator<wchar_t> >;
    using unc_path_u16string    = unc_basic_path_string<char16_t, std::char_traits<char16_t>, std::allocator<char16_t> >;
    using unc_path_u32string    = unc_basic_path_string<char32_t, std::char_traits<char32_t>, std::allocator<char32_t> >;

    template <typename t_elem>
    struct LIBRARY_API_DECL tag_unc_path_basic_string    : tag_path_basic_string<t_elem, utility::literal_separators<t_elem>::filesystem_unc_dir_separator_char> {};

    template <class t_elem>
    struct LIBRARY_API_DECL tag_unc_basic_path_string    : tag_unc_path_basic_string<t_elem> {};

    struct LIBRARY_API_DECL tag_unc_path_string          : tag_unc_basic_path_string<char> {};
    struct LIBRARY_API_DECL tag_unc_path_wstring         : tag_unc_basic_path_string<wchar_t> {};
    struct LIBRARY_API_DECL tag_unc_path_u16string       : tag_unc_basic_path_string<char16_t> {};
    struct LIBRARY_API_DECL tag_unc_path_u32string       : tag_unc_basic_path_string<char32_t> {};

    template <typename t_elem>
    struct LIBRARY_API_DECL tag_unc_path_string_by_elem :
        std::conditional<std::is_same<char, t_elem>::value,
            tag_unc_path_string,
            typename std::conditional<std::is_same<wchar_t, t_elem>::value,
                tag_unc_path_wstring,
                typename std::conditional<std::is_same<char16_t, t_elem>::value,
                    tag_unc_path_u16string,
                    typename std::conditional<std::is_same<char32_t, t_elem>::value,
                        tag_unc_path_u32string,
                        utility::void_
                    >::type
                >::type
            >::type
        >::type
    {
    };

}

namespace utility
{

    enum LIBRARY_API_DECL SharedAccess
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        SharedAccess_DenyRW     = _SH_DENYRW,   // deny read/write mode
        SharedAccess_DenyWrite  = _SH_DENYWR,   // deny write mode
        SharedAccess_DenyRead   = _SH_DENYRD,   // deny read mode
        SharedAccess_DenyNone   = _SH_DENYNO,   // deny none mode
        SharedAccess_Secure     = _SH_SECURE    // secure mode
#elif defined(UTILITY_PLATFORM_POSIX)
        SharedAccess_DenyRW     = 0x10,         // deny read/write mode
        SharedAccess_DenyWrite  = 0x20,         // deny write mode
        SharedAccess_DenyRead   = 0x30,         // deny read mode
        SharedAccess_DenyNone   = 0x40,         // deny none mode
        SharedAccess_Secure     = 0x80          // secure mode
#endif
    };

    uint64_t LIBRARY_API_DECL get_file_size(tackle::file_handle<char> file_handle);
    uint64_t LIBRARY_API_DECL get_file_size(tackle::file_handle<wchar_t> file_handle);

    bool LIBRARY_API_DECL is_files_equal(tackle::file_handle<char> left_file_handle, tackle::file_handle<char> right_file_handle, size_t read_block_size);
    bool LIBRARY_API_DECL is_files_equal(tackle::file_handle<wchar_t> left_file_handle, tackle::file_handle<wchar_t> right_file_handle, size_t read_block_size);

#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_NETWORK_UNC)

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL convert_local_to_network_unc_path(tackle::generic_path_string from_path, tackle::unc_path_string & to_path, bool throw_on_error);
    bool LIBRARY_API_DECL convert_local_to_network_unc_path(tackle::generic_path_wstring from_path, tackle::unc_path_wstring & to_path, bool throw_on_error);

    bool LIBRARY_API_DECL convert_local_to_network_unc_path(tackle::native_path_string from_path, tackle::unc_path_string & to_path, bool throw_on_error);
    bool LIBRARY_API_DECL convert_local_to_network_unc_path(tackle::native_path_wstring from_path, tackle::unc_path_wstring & to_path, bool throw_on_error);

    tackle::unc_path_string LIBRARY_API_DECL convert_local_to_network_unc_path(tackle::generic_path_string from_path, tackle::tag_unc_path_string, bool throw_on_error);
    tackle::unc_path_wstring LIBRARY_API_DECL convert_local_to_network_unc_path(tackle::generic_path_wstring from_path, tackle::tag_unc_path_wstring, bool throw_on_error);

    tackle::unc_path_string LIBRARY_API_DECL convert_local_to_network_unc_path(tackle::native_path_string from_path, tackle::tag_unc_path_string, bool throw_on_error);
    tackle::unc_path_wstring LIBRARY_API_DECL convert_local_to_network_unc_path(tackle::native_path_wstring from_path, tackle::tag_unc_path_wstring, bool throw_on_error);

    bool LIBRARY_API_DECL convert_network_unc_to_local_path(tackle::unc_path_string from_path, tackle::generic_path_string & to_path, bool throw_on_error);
    bool LIBRARY_API_DECL convert_network_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::generic_path_wstring & to_path, bool throw_on_error);

    bool LIBRARY_API_DECL convert_network_unc_to_local_path(tackle::unc_path_string from_path, tackle::native_path_string & to_path, bool throw_on_error);
    bool LIBRARY_API_DECL convert_network_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::native_path_wstring & to_path, bool throw_on_error);

    tackle::generic_path_string LIBRARY_API_DECL convert_network_unc_to_local_path(tackle::unc_path_string from_path, tackle::tag_generic_path_string, bool throw_on_error);
    tackle::generic_path_wstring LIBRARY_API_DECL convert_network_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::tag_generic_path_wstring, bool throw_on_error);

    tackle::native_path_string LIBRARY_API_DECL convert_network_unc_to_local_path(tackle::unc_path_string from_path, tackle::tag_native_path_string, bool throw_on_error);
    tackle::native_path_wstring LIBRARY_API_DECL convert_network_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::tag_native_path_wstring, bool throw_on_error);
#endif

#endif

    bool LIBRARY_API_DECL convert_local_to_local_unc_path(tackle::generic_path_string from_path, tackle::unc_path_string & to_path, bool throw_on_error);
    bool LIBRARY_API_DECL convert_local_to_local_unc_path(tackle::generic_path_wstring from_path, tackle::unc_path_wstring & to_path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL convert_local_to_local_unc_path(tackle::native_path_string from_path, tackle::unc_path_string & to_path, bool throw_on_error);
    bool LIBRARY_API_DECL convert_local_to_local_unc_path(tackle::native_path_wstring from_path, tackle::unc_path_wstring & to_path, bool throw_on_error);
#endif

    tackle::unc_path_string LIBRARY_API_DECL convert_local_to_local_unc_path(tackle::generic_path_string from_path, tackle::tag_unc_path_string, bool throw_on_error);
    tackle::unc_path_wstring LIBRARY_API_DECL convert_local_to_local_unc_path(tackle::generic_path_wstring from_path, tackle::tag_unc_path_wstring, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::unc_path_string LIBRARY_API_DECL convert_local_to_local_unc_path(tackle::native_path_string from_path, tackle::tag_unc_path_string, bool throw_on_error);
    tackle::unc_path_wstring LIBRARY_API_DECL convert_local_to_local_unc_path(tackle::native_path_wstring from_path, tackle::tag_unc_path_wstring, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL convert_local_unc_to_local_path(tackle::unc_path_string from_path, tackle::generic_path_string & to_path);
    bool LIBRARY_API_DECL convert_local_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::generic_path_wstring & to_path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL convert_local_unc_to_local_path(tackle::unc_path_string from_path, tackle::native_path_string & to_path);
    bool LIBRARY_API_DECL convert_local_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::native_path_wstring & to_path);
#endif

    tackle::generic_path_string LIBRARY_API_DECL convert_local_unc_to_local_path(tackle::unc_path_string from_path, tackle::tag_generic_path_string);
    tackle::generic_path_wstring LIBRARY_API_DECL convert_local_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::tag_generic_path_wstring);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL convert_local_unc_to_local_path(tackle::unc_path_string from_path, tackle::tag_native_path_string);
    tackle::native_path_wstring LIBRARY_API_DECL convert_local_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::tag_native_path_wstring);
#endif

    tackle::native_path_string LIBRARY_API_DECL fix_long_path(tackle::generic_path_string file_path, bool throw_on_error);
    tackle::native_path_wstring LIBRARY_API_DECL fix_long_path(tackle::generic_path_wstring file_path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL fix_long_path(tackle::native_path_string file_path, bool throw_on_error);
    tackle::native_path_wstring LIBRARY_API_DECL fix_long_path(tackle::native_path_wstring file_path, bool throw_on_error);
#endif

    tackle::generic_path_string LIBRARY_API_DECL unfix_long_path(tackle::native_path_string file_path, tackle::tag_generic_path_string, bool throw_on_error);
    tackle::generic_path_wstring LIBRARY_API_DECL unfix_long_path(tackle::native_path_wstring file_path, tackle::tag_generic_path_wstring, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL unfix_long_path(tackle::native_path_string file_path, tackle::tag_native_path_string, bool throw_on_error);
    tackle::native_path_wstring LIBRARY_API_DECL unfix_long_path(tackle::native_path_wstring file_path, tackle::tag_native_path_wstring, bool throw_on_error);
#endif

    tackle::generic_file_handle<char> LIBRARY_API_DECL recreate_file(tackle::generic_path_string file_path, const char * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0, bool throw_on_error = true);
    tackle::generic_file_handle<wchar_t> LIBRARY_API_DECL recreate_file(tackle::generic_path_wstring file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0, bool throw_on_error = true);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_file_handle<char> LIBRARY_API_DECL recreate_file(tackle::native_path_string file_path, const char * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0, bool throw_on_error = true);
    tackle::native_file_handle<wchar_t> LIBRARY_API_DECL recreate_file(tackle::native_path_wstring file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0, bool throw_on_error = true);
#endif

    tackle::generic_file_handle<char> LIBRARY_API_DECL create_file(tackle::generic_path_string file_path, const char * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0, bool throw_on_error = true);
    tackle::generic_file_handle<wchar_t> LIBRARY_API_DECL create_file(tackle::generic_path_wstring file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0, bool throw_on_error = true);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_file_handle<char> LIBRARY_API_DECL create_file(tackle::native_path_string file_path, const char * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0, bool throw_on_error = true);
    tackle::native_file_handle<wchar_t> LIBRARY_API_DECL create_file(tackle::native_path_wstring file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0, bool throw_on_error = true);
#endif

    tackle::generic_file_handle<char> LIBRARY_API_DECL open_file(tackle::generic_path_string file_path, const char * mode, SharedAccess share_flags,
        size_t creation_size = 0, size_t resize_if_existed = -1, uint32_t fill_by_on_creation = 0,
        bool throw_on_error = true);
    tackle::generic_file_handle<wchar_t> LIBRARY_API_DECL open_file(tackle::generic_path_wstring file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t creation_size = 0, size_t resize_if_existed = -1, uint32_t fill_by_on_creation = 0,
        bool throw_on_error = true);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_file_handle<char> LIBRARY_API_DECL open_file(tackle::native_path_string file_path, const char * mode, SharedAccess share_flags,
        size_t creation_size = 0, size_t resize_if_existed = -1, uint32_t fill_by_on_creation = 0,
        bool throw_on_error = true);
    tackle::native_file_handle<wchar_t> LIBRARY_API_DECL open_file(tackle::native_path_wstring file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t creation_size = 0, size_t resize_if_existed = -1, uint32_t fill_by_on_creation = 0,
        bool throw_on_error = true);
#endif

    bool LIBRARY_API_DECL is_directory_path(tackle::generic_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL is_directory_path(tackle::generic_path_wstring path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL is_directory_path(tackle::native_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL is_directory_path(tackle::native_path_wstring path, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL is_regular_file(tackle::generic_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL is_regular_file(tackle::generic_path_wstring path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL is_regular_file(tackle::native_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL is_regular_file(tackle::native_path_wstring path, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL is_symlink_path(tackle::generic_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL is_symlink_path(tackle::generic_path_wstring path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL is_symlink_path(tackle::native_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL is_symlink_path(tackle::native_path_wstring path, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL is_path_exists(tackle::generic_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL is_path_exists(tackle::generic_path_wstring path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL is_path_exists(tackle::native_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL is_path_exists(tackle::native_path_wstring path, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL create_directory(tackle::generic_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL create_directory(tackle::generic_path_wstring path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL create_directory(tackle::native_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL create_directory(tackle::native_path_wstring path, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL create_directory_if_not_exist(tackle::generic_path_string path, bool throw_on_error); // no exception if directory already exists
    bool LIBRARY_API_DECL create_directory_if_not_exist(tackle::generic_path_wstring path, bool throw_on_error); // no exception if directory already exists

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL create_directory_if_not_exist(tackle::native_path_string path, bool throw_on_error); // no exception if directory already exists
    bool LIBRARY_API_DECL create_directory_if_not_exist(tackle::native_path_wstring path, bool throw_on_error); // no exception if directory already exists
#endif

    void LIBRARY_API_DECL create_directory_symlink(tackle::generic_path_string to, tackle::generic_path_string from, bool throw_on_error);
    void LIBRARY_API_DECL create_directory_symlink(tackle::generic_path_wstring to, tackle::generic_path_wstring from, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    void LIBRARY_API_DECL create_directory_symlink(tackle::native_path_string to, tackle::native_path_string from, bool throw_on_error);
    void LIBRARY_API_DECL create_directory_symlink(tackle::native_path_wstring to, tackle::native_path_wstring from, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL create_directories(tackle::generic_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL create_directories(tackle::generic_path_wstring path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL create_directories(tackle::native_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL create_directories(tackle::native_path_wstring path, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL remove_directory(tackle::generic_path_string path, bool recursively, bool throw_on_error);
    bool LIBRARY_API_DECL remove_directory(tackle::generic_path_wstring path, bool recursively, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL remove_directory(tackle::native_path_string path, bool recursively, bool throw_on_error);
    bool LIBRARY_API_DECL remove_directory(tackle::native_path_wstring path, bool recursively, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL remove_file(tackle::generic_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL remove_file(tackle::generic_path_wstring path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL remove_file(tackle::native_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL remove_file(tackle::native_path_wstring path, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL remove_symlink(tackle::generic_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL remove_symlink(tackle::generic_path_wstring path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL remove_symlink(tackle::native_path_string path, bool throw_on_error);
    bool LIBRARY_API_DECL remove_symlink(tackle::native_path_wstring path, bool throw_on_error);
#endif

    bool LIBRARY_API_DECL is_relative_path(tackle::generic_path_string path);
    bool LIBRARY_API_DECL is_relative_path(tackle::generic_path_wstring path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL is_relative_path(tackle::native_path_string path);
    bool LIBRARY_API_DECL is_relative_path(tackle::native_path_wstring path);
#endif

    bool LIBRARY_API_DECL is_absolute_path(tackle::generic_path_string path);
    bool LIBRARY_API_DECL is_absolute_path(tackle::generic_path_wstring path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool LIBRARY_API_DECL is_absolute_path(tackle::native_path_string path);
    bool LIBRARY_API_DECL is_absolute_path(tackle::native_path_wstring path);
#endif

    tackle::generic_path_string LIBRARY_API_DECL get_relative_path(tackle::generic_path_string from_path, tackle::generic_path_string to_path, bool throw_on_error);
    tackle::generic_path_wstring LIBRARY_API_DECL get_relative_path(tackle::generic_path_wstring from_path, tackle::generic_path_wstring to_path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL get_relative_path(tackle::native_path_string from_path, tackle::native_path_string to_path, bool throw_on_error);
    tackle::native_path_wstring LIBRARY_API_DECL get_relative_path(tackle::native_path_wstring from_path, tackle::native_path_wstring to_path, bool throw_on_error);
#endif

    tackle::generic_path_string LIBRARY_API_DECL get_absolute_path(tackle::generic_path_string from_path, tackle::generic_path_string to_path);
    tackle::generic_path_wstring LIBRARY_API_DECL get_absolute_path(tackle::generic_path_wstring from_path, tackle::generic_path_wstring to_path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL get_absolute_path(tackle::native_path_string from_path, tackle::native_path_string to_path);
    tackle::native_path_wstring LIBRARY_API_DECL get_absolute_path(tackle::native_path_wstring from_path, tackle::native_path_wstring to_path);
#endif

    tackle::generic_path_string LIBRARY_API_DECL get_absolute_path(tackle::generic_path_string path, bool throw_on_error);
    tackle::generic_path_wstring LIBRARY_API_DECL get_absolute_path(tackle::generic_path_wstring path, bool throw_on_error);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL get_absolute_path(tackle::native_path_string path, bool throw_on_error);
    tackle::native_path_wstring LIBRARY_API_DECL get_absolute_path(tackle::native_path_wstring path, bool throw_on_error);
#endif

    tackle::generic_path_string LIBRARY_API_DECL get_current_path(bool throw_on_error, tackle::tag_generic_path_string);
    tackle::generic_path_wstring LIBRARY_API_DECL get_current_path(bool throw_on_error, tackle::tag_generic_path_wstring);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL get_current_path(bool throw_on_error, tackle::tag_native_path_string);
    tackle::native_path_wstring LIBRARY_API_DECL get_current_path(bool throw_on_error, tackle::tag_native_path_wstring);
#endif

    std::string LIBRARY_API_DECL get_file_name(tackle::generic_path_string path);
    std::wstring LIBRARY_API_DECL get_file_name(tackle::generic_path_wstring path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    std::string LIBRARY_API_DECL get_file_name(tackle::native_path_string path);
    std::wstring LIBRARY_API_DECL get_file_name(tackle::native_path_wstring path);
#endif

    std::string LIBRARY_API_DECL get_file_name_stem(tackle::generic_path_string path);
    std::wstring LIBRARY_API_DECL get_file_name_stem(tackle::generic_path_wstring path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    std::string LIBRARY_API_DECL get_file_name_stem(tackle::native_path_string path);
    std::wstring LIBRARY_API_DECL get_file_name_stem(tackle::native_path_wstring path);
#endif

    tackle::generic_path_string LIBRARY_API_DECL get_parent_path(tackle::generic_path_string path);
    tackle::generic_path_wstring LIBRARY_API_DECL get_parent_path(tackle::generic_path_wstring path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL get_parent_path(tackle::native_path_string path);
    tackle::native_path_wstring LIBRARY_API_DECL get_parent_path(tackle::native_path_wstring path);
#endif

    tackle::generic_path_string LIBRARY_API_DECL get_module_file_path(tackle::tag_generic_path_string, bool cached);
    tackle::generic_path_wstring LIBRARY_API_DECL get_module_file_path(tackle::tag_generic_path_wstring, bool cached);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL get_module_file_path(tackle::tag_native_path_string, bool cached);
    tackle::native_path_wstring LIBRARY_API_DECL get_module_file_path(tackle::tag_native_path_wstring, bool cached);
#endif

    tackle::generic_path_string LIBRARY_API_DECL get_module_dir_path(tackle::tag_generic_path_string, bool cached);
    tackle::generic_path_wstring LIBRARY_API_DECL get_module_dir_path(tackle::tag_generic_path_wstring, bool cached);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL get_module_dir_path(tackle::tag_native_path_string, bool cached);
    tackle::native_path_wstring LIBRARY_API_DECL get_module_dir_path(tackle::tag_native_path_wstring, bool cached);
#endif

    tackle::generic_path_string LIBRARY_API_DECL get_lexically_normal_path(tackle::generic_path_string path);
    tackle::generic_path_wstring LIBRARY_API_DECL get_lexically_normal_path(tackle::generic_path_wstring path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL get_lexically_normal_path(tackle::native_path_string path);
    tackle::native_path_wstring LIBRARY_API_DECL get_lexically_normal_path(tackle::native_path_wstring path);
#endif

    tackle::generic_path_string LIBRARY_API_DECL get_lexically_relative_path(tackle::generic_path_string from_path, tackle::generic_path_string to_path);
    tackle::generic_path_wstring LIBRARY_API_DECL get_lexically_relative_path(tackle::generic_path_wstring from_path, tackle::generic_path_wstring to_path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL get_lexically_relative_path(tackle::native_path_string from_path, tackle::native_path_string to_path);
    tackle::native_path_wstring LIBRARY_API_DECL get_lexically_relative_path(tackle::native_path_wstring from_path, tackle::native_path_wstring to_path);
#endif

    tackle::generic_path_string LIBRARY_API_DECL convert_to_generic_path(const char * path, size_t len);
    tackle::generic_path_wstring LIBRARY_API_DECL convert_to_generic_path(const wchar_t * path, size_t len);

    tackle::generic_path_string LIBRARY_API_DECL convert_to_generic_path(std::string path);
    tackle::generic_path_wstring LIBRARY_API_DECL convert_to_generic_path(std::wstring path);

    tackle::generic_path_string LIBRARY_API_DECL convert_to_generic_path(tackle::generic_path_string path);
    tackle::generic_path_wstring LIBRARY_API_DECL convert_to_generic_path(tackle::generic_path_wstring path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::generic_path_string LIBRARY_API_DECL convert_to_generic_path(tackle::native_path_string path);
    tackle::generic_path_wstring LIBRARY_API_DECL convert_to_generic_path(tackle::native_path_wstring path);
#endif

    tackle::native_path_string LIBRARY_API_DECL convert_to_native_path(const char * path, size_t len);
    tackle::native_path_wstring LIBRARY_API_DECL convert_to_native_path(const wchar_t * path, size_t len);

    tackle::native_path_string LIBRARY_API_DECL convert_to_native_path(std::string path);
    tackle::native_path_wstring LIBRARY_API_DECL convert_to_native_path(std::wstring path);

    tackle::native_path_string LIBRARY_API_DECL convert_to_native_path(tackle::generic_path_string path);
    tackle::native_path_wstring LIBRARY_API_DECL convert_to_native_path(tackle::generic_path_wstring path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL convert_to_native_path(tackle::native_path_string path);
    tackle::native_path_wstring LIBRARY_API_DECL convert_to_native_path(tackle::native_path_wstring path);
#endif

    tackle::generic_path_string LIBRARY_API_DECL truncate_path_relative_prefix(tackle::generic_path_string path);
    tackle::generic_path_wstring LIBRARY_API_DECL truncate_path_relative_prefix(tackle::generic_path_wstring path);

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string LIBRARY_API_DECL truncate_path_relative_prefix(tackle::native_path_string path);
    tackle::native_path_wstring LIBRARY_API_DECL truncate_path_relative_prefix(tackle::native_path_wstring path);
#endif

    std::string LIBRARY_API_DECL get_host_name(utility::tag_string, bool cached);
    std::wstring LIBRARY_API_DECL get_host_name(utility::tag_wstring, bool cached);

    std::string LIBRARY_API_DECL get_user_name(utility::tag_string, bool cached);
    std::wstring LIBRARY_API_DECL get_user_name(utility::tag_wstring, bool cached);

    std::string LIBRARY_API_DECL get_module_name(utility::tag_string, bool cached);
    std::wstring LIBRARY_API_DECL get_module_name(utility::tag_wstring, bool cached);

    FORCE_INLINE int LIBRARY_API_DECL str_to_int(const std::string & str, std::size_t * pos = nullptr, int base = 0, bool throw_on_error = false)
    {
        int i{}; // value initialization default construction is required in case if an error has happend and throw_on_error = false

        try {
            i = std::stoi(str, pos, base);
        }
        // by default suppress exceptions
        catch (const std::invalid_argument & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::out_of_range & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::exception & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (...) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }

        return i;
    }

    FORCE_INLINE unsigned int LIBRARY_API_DECL str_to_uint(const std::string & str, std::size_t * pos = nullptr, int base = 0, bool throw_on_error = false)
    {
        unsigned int i{}; // value initialization default construction is required in case if an error has happend and throw_on_error = false

        try {
            i = (unsigned int)(std::stoul(str, pos, base));
        }
        // by default suppress exceptions
        catch (const std::invalid_argument & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::out_of_range & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::exception & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (...) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }

        return i;
    }

    FORCE_INLINE long LIBRARY_API_DECL str_to_long(const std::string & str, std::size_t * pos = nullptr, int base = 0, bool throw_on_error = false)
    {
        long i{}; // value initialization default construction is required in case if an error has happend and throw_on_error = false

        try {
            i = std::stol(str, pos, base);
        }
        // by default suppress exceptions
        catch (const std::invalid_argument & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::out_of_range & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::exception & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (...) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }

        return i;
    }

    FORCE_INLINE unsigned long LIBRARY_API_DECL str_to_ulong(const std::string & str, std::size_t * pos = nullptr, int base = 0, bool throw_on_error = false)
    {
        unsigned long i{}; // value initialization default construction is required in case if an error has happend and throw_on_error = false

        try {
            i = std::stoul(str, pos, base);
        }
        // by default suppress exceptions
        catch (const std::invalid_argument & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::out_of_range & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::exception & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (...) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }

        return i;
    }

#ifdef UTILITY_PLATFORM_FEATURE_CXX_STANDARD_LLONG
    FORCE_INLINE long long LIBRARY_API_DECL str_to_llong(const std::string & str, std::size_t * pos = nullptr, int base = 0, bool throw_on_error = false)
    {
        long long i{}; // value initialization default construction is required in case if an error has happend and throw_on_error = false

        try {
            i = std::stoll(str, pos, base);
        }
        // by default suppress exceptions
        catch (const std::invalid_argument & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::out_of_range & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::exception & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (...) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }

        return i;
    }
#endif

#ifdef UTILITY_PLATFORM_FEATURE_CXX_STANDARD_ULLONG
    FORCE_INLINE unsigned long long LIBRARY_API_DECL str_to_ullong(const std::string & str, std::size_t * pos = nullptr, int base = 0, bool throw_on_error = false)
    {
        unsigned long long i{}; // value initialization default construction is required in case if an error has happend and throw_on_error = false

        try {
            i = std::stoull(str, pos, base);
        }
        // by default suppress exceptions
        catch (const std::invalid_argument & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::out_of_range & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::exception & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (...) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }

        return i;
    }
#endif

    FORCE_INLINE float LIBRARY_API_DECL str_to_float(const std::string & str, std::size_t * pos = nullptr, bool throw_on_error = false)
    {
        float i{}; // value initialization default construction is required in case if an error has happend and throw_on_error = false

        try {
            i = std::stof(str, pos);
        }
        // by default suppress exceptions
        catch (const std::invalid_argument & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::out_of_range & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::exception & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (...) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }

        return i;
    }

    FORCE_INLINE double LIBRARY_API_DECL str_to_double(const std::string & str, std::size_t * pos = nullptr, bool throw_on_error = false)
    {
        double i{}; // value initialization default construction is required in case if an error has happend and throw_on_error = false

        try {
            i = std::stod(str, pos);
        }
        // by default suppress exceptions
        catch (const std::invalid_argument & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::out_of_range & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::exception & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (...) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }

        return i;
    }

    FORCE_INLINE long double LIBRARY_API_DECL str_to_ldouble(const std::string & str, std::size_t * pos = nullptr, bool throw_on_error = false)
    {
        long double i{}; // value initialization default construction is required in case if an error has happend and throw_on_error = false

        try {
            i = std::stold(str, pos);
        }
        // by default suppress exceptions
        catch (const std::invalid_argument & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::out_of_range & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (const std::exception & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }
        catch (...) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true);
            }
        }

        return i;
    }

    template<typename T>
    FORCE_INLINE T LIBRARY_API_DECL str_to_number(const std::string & str, std::size_t * pos = nullptr, int int_base = 0, bool throw_on_error = false);

    template<>
    FORCE_INLINE int LIBRARY_API_DECL str_to_number<int>(const std::string & str, std::size_t * pos, int int_base, bool throw_on_error)
    {
        return str_to_int(str, pos, int_base, throw_on_error);
    }

    template<>
    FORCE_INLINE unsigned int LIBRARY_API_DECL str_to_number<unsigned int>(const std::string & str, std::size_t * pos, int int_base, bool throw_on_error)
    {
        return str_to_uint(str, pos, int_base, throw_on_error);
    }

    template<>
    FORCE_INLINE long LIBRARY_API_DECL str_to_number<long>(const std::string & str, std::size_t * pos, int int_base, bool throw_on_error)
    {
        return str_to_long(str, pos, int_base, throw_on_error);
    }

    template<>
    FORCE_INLINE unsigned long LIBRARY_API_DECL str_to_number<unsigned long>(const std::string & str, std::size_t * pos, int int_base, bool throw_on_error)
    {
        return str_to_ulong(str, pos, int_base, throw_on_error);
    }

#ifdef UTILITY_PLATFORM_FEATURE_CXX_STANDARD_LLONG
    template<>
    FORCE_INLINE long long LIBRARY_API_DECL str_to_number<long long>(const std::string & str, std::size_t * pos, int int_base, bool throw_on_error)
    {
        return str_to_llong(str, pos, int_base, throw_on_error);
    }
#endif

#ifdef UTILITY_PLATFORM_FEATURE_CXX_STANDARD_ULLONG
    template<>
    FORCE_INLINE unsigned long long LIBRARY_API_DECL str_to_number<unsigned long long>(const std::string & str, std::size_t * pos, int int_base, bool throw_on_error)
    {
        return str_to_ullong(str, pos, int_base, throw_on_error);
    }
#endif

    template<>
    FORCE_INLINE float LIBRARY_API_DECL str_to_number<float>(const std::string & str, std::size_t * pos, int int_base, bool throw_on_error)
    {
        return str_to_float(str, pos, throw_on_error);
    }

    template<>
    FORCE_INLINE double LIBRARY_API_DECL str_to_number<double>(const std::string & str, std::size_t * pos, int int_base, bool throw_on_error)
    {
        return str_to_double(str, pos, throw_on_error);
    }

    template<>
    FORCE_INLINE long double LIBRARY_API_DECL str_to_number<long double>(const std::string & str, std::size_t * pos, int int_base, bool throw_on_error)
    {
        return str_to_ldouble(str, pos, throw_on_error);
    }

    template<typename T>
    FORCE_INLINE LIBRARY_API_DECL std::string int_to_hex(T i, size_t padding = sizeof(T) * 2)
    {
#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_INSTEAD_STD_STRINGSTREAMS)
        const std::string fmt_format{ utility::string_format(256, "{:%s%ux}", padding ? "0" : "", padding ? padding : 0) }; // faster than fmt format
        return fmt::format(fmt_format, int64_t(i));
#else
        std::stringstream stream;
        stream << std::setfill('0') << std::setw(padding) << std::hex << i;
        return stream.str();
#endif
    }

    template<typename T>
    FORCE_INLINE LIBRARY_API_DECL std::string int_to_dec(T i, size_t padding = sizeof(T) * 2)
    {
#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_INSTEAD_STD_STRINGSTREAMS)
        const std::string fmt_format{ utility::string_format(256, "{:%s%ud}", padding ? "0" : "", padding ? padding : 0) }; // faster than fmt format
        return fmt::format(fmt_format, int64_t(i));
#else
        std::stringstream stream;
        stream << std::setfill('0') << std::setw(padding) << std::dec << i;
        return stream.str();
#endif
    }

    template<typename T>
    FORCE_INLINE void LIBRARY_API_DECL int_to_bin_forceinline(std::string & ret, T i, bool first_bit_is_lowest_bit = false)
    {
        STATIC_ASSERT_TRUE(std::is_trivially_copyable<T>::value, "T must be a trivial copy type");

        CONSTEXPR const size_t num_bytes = sizeof(T);

        ret.resize(num_bytes * CHAR_BIT);

        char * data_ptr = &ret[0]; // faster than for-ed operator[] in the Debug

        size_t char_offset;
        const uint32_t * chunks_ptr = (const uint32_t *)&i;

        const size_t num_whole_chunks = num_bytes / 4;
        const size_t chunks_remainder = num_bytes % 4;

        if (first_bit_is_lowest_bit) {
            char_offset = 0;

            for (size_t i = 0; i < num_whole_chunks; i++, chunks_ptr++) {
                for (size_t j = 0; j < 32; j++, char_offset++) {
                    data_ptr[char_offset] = (chunks_ptr[i] & (0x01U << j)) ? '1' : '0';
                }
            }
            if (chunks_remainder) {
                for (size_t j = 0; j < chunks_remainder * CHAR_BIT; j++, char_offset++) {
                    data_ptr[char_offset] = (chunks_ptr[i] & (0x01U << j)) ? '1' : '0';
                }
            }

            data_ptr[char_offset] = '\0';
        }
        else {
            char_offset = num_bytes * CHAR_BIT;

            data_ptr[char_offset] = '\0';

            for (size_t i = 0; i < num_whole_chunks; i++, chunks_ptr++) {
                for (size_t j = 0; j < 32; j++, char_offset--) {
                    data_ptr[char_offset] = (chunks_ptr[i] & (0x01U << j)) ? '1' : '0';
                }
            }
            if (chunks_remainder) {
                for (size_t j = 0; j < chunks_remainder * CHAR_BIT; j++, char_offset--) {
                    data_ptr[char_offset] = (chunks_ptr[i] & (0x01U << j)) ? '1' : '0';
                }
            }
        }
    }

    template<typename T>
    inline std::string LIBRARY_API_DECL int_to_bin(T i, bool first_bit_is_lowest_bit = false)
    {
        std::string res;
        int_to_bin_forceinline(res, i, first_bit_is_lowest_bit);
        return res;
    }

    FORCE_INLINE_ALWAYS uint8_t LIBRARY_API_DECL reverse(uint8_t byte)
    {
        byte = (byte & 0xF0) >> 4 | (byte & 0x0F) << 4;
        byte = (byte & 0xCC) >> 2 | (byte & 0x33) << 2;
        byte = (byte & 0xAA) >> 1 | (byte & 0x55) << 1;
        return byte;
    }

    template <typename T>
    FORCE_INLINE T LIBRARY_API_DECL reverse(T value)
    {
        T res = 0;
        for (size_t i = 0; i < sizeof(value) * CHAR_BIT; i++) {
            if (value & (0x01U << i)) {
                res |= (0x01U << (sizeof(value) * CHAR_BIT - i - 1));
            }
        }
        return res;
    }

    namespace detail
    {
        template <typename T>
        static FORCE_INLINE CONSTEXPR_FUNC T _constexpr_reverse(size_t next_index, T value)
        {
            return (next_index < sizeof(value) * CHAR_BIT) ?
                ((value & (T(0x01U) << next_index)) ?
                    (T(0x01U) << (sizeof(value) * CHAR_BIT - next_index - 1)) :
                    0) |
                _constexpr_reverse(next_index + 1, value) : 0;
        }
    }

    template <typename T>
    FORCE_INLINE CONSTEXPR_FUNC T LIBRARY_API_DECL constexpr_reverse(T value)
    {
        return detail::_constexpr_reverse(0, value);
    }

    template<typename T>
    FORCE_INLINE uint32_t LIBRARY_API_DECL t_rotl32(uint32_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint32_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint32_t)");
        const uint32_t byte_mask = uint32_t(-1) >> (CHAR_BIT * (sizeof(uint32_t) - sizeof(T)));
        const uint32_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & ((n << c) | ((byte_mask & n) >> (mask & math::negate(c))));
    }

    template<typename T>
    FORCE_INLINE uint32_t LIBRARY_API_DECL t_rotr32(uint32_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint32_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint32_t)");
        const uint32_t byte_mask = uint32_t(-1) >> (CHAR_BIT * (sizeof(uint32_t) - sizeof(T)));
        const uint32_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & (((byte_mask & n) >> c) | (n << (mask & math::negate(c))));
    }

    template<typename T>
    FORCE_INLINE uint64_t LIBRARY_API_DECL t_rotl64(uint64_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint64_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint64_t)");
        const uint64_t byte_mask = uint64_t(-1) >> (CHAR_BIT * (sizeof(uint64_t) - sizeof(T)));
        const uint64_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & ((n << c) | ((byte_mask & n) >> (mask & math::negate(c))));
    }

    template<typename T>
    FORCE_INLINE uint64_t LIBRARY_API_DECL t_rotr64(uint64_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint64_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint64_t)");
        const uint64_t byte_mask = uint64_t(-1) >> (CHAR_BIT * (sizeof(uint64_t) - sizeof(T)));
        const uint64_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & (((byte_mask & n) >> c) | (n << (mask & math::negate(c))));
    }

    FORCE_INLINE_ALWAYS uint32_t LIBRARY_API_DECL rotl8(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotl8(unsigned char(n), unsigned char(c));
#else
        return t_rotl32<uint8_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint32_t LIBRARY_API_DECL rotr8(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotr8(unsigned char(n), unsigned char(c));
#else
        return t_rotr32<uint8_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint32_t LIBRARY_API_DECL rotl16(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotl16(unsigned short(n), unsigned char(c));
#else
        return t_rotl32<uint16_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint32_t LIBRARY_API_DECL rotr16(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotr16(unsigned short(n), unsigned char(c));
#else
        return t_rotr32<uint16_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint32_t LIBRARY_API_DECL rotl32(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotl(unsigned int(n), int(c));
#else
        return t_rotl32<uint32_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint32_t LIBRARY_API_DECL rotr32(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotr(unsigned int(n), int(c));
#else
        return t_rotr32<uint32_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint64_t LIBRARY_API_DECL rotl64(uint64_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotl64(unsigned long long(n), int(c));
#else
        return t_rotl64<uint64_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint64_t LIBRARY_API_DECL rotr64(uint64_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotr64(unsigned long long(n), int(c));
#else
        return t_rotr64<uint64_t>(n, c);
#endif
    }

    // reads from keypress, doesn't echo
    inline int LIBRARY_API_DECL getch()
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        return ::_getch();
#elif defined(UTILITY_PLATFORM_POSIX)
        struct termios oldattr, newattr;
        int ch;
        tcgetattr(STDIN_FILENO, &oldattr);
        newattr = oldattr;
        newattr.c_lflag &= ~(ICANON | ECHO);
        tcsetattr(STDIN_FILENO, TCSANOW, &newattr);
        ch = getchar();
        tcsetattr(STDIN_FILENO, TCSANOW, &oldattr);
        return ch;
#endif
    }

    // reads from keypress, echoes
    inline int LIBRARY_API_DECL getche()
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        return ::_getche();
#elif defined(UTILITY_PLATFORM_POSIX)
        struct termios oldattr, newattr;
        int ch;
        tcgetattr(STDIN_FILENO, &oldattr);
        newattr = oldattr;
        newattr.c_lflag &= ~(ICANON);
        tcsetattr(STDIN_FILENO, TCSANOW, &newattr);
        ch = getchar();
        tcsetattr(STDIN_FILENO, TCSANOW, &oldattr);
        return ch;
#endif
    }

    // reset std::stringstream object
    // Based on: https://stackoverflow.com/questions/7623650/resetting-a-stringstream
    //
    FORCE_INLINE void LIBRARY_API_DECL reset_stringstream(std::stringstream & ss)
    {
        const static std::stringstream initial;

        ss.str(std::string{});
        ss.clear();
        ss.copyfmt(initial);
    }

    FORCE_INLINE double LIBRARY_API_DECL modf(double d)
    {
        double whole;
        return std::modf(d, &whole);
    }

    // Calculates tick step between min/max range closest to power-of-10 and if not enough, then
    // splits in twice down to a value multiple to `5` and if not enough, then
    // splits in twice down to a value multiple to `2`.
    // The idea all of this is to end a floating point value by a finite set of digits on an axis multiple either to power-of-10 or to `5` or to `2`.
    //
    template <typename U, typename T>
    FORCE_INLINE U LIBRARY_API_DECL calibrate_ruler_tick_step_to_closest_power_of_10(T min, T max, size_t ticks, const U & float_point_identity = U{})
    {
        static_assert(std::is_floating_point<U>::value, "U must be a floating point type");

        DEBUG_ASSERT_LT(min, max);
        DEBUG_ASSERT_LT(0U, ticks);

        const T distance = max - min;

        U tick_step = U(distance) / ticks;

        int tick_step_exp;
        std::frexp(tick_step, &tick_step_exp);

        if (tick_step < 1.0) {
            size_t rounded_integer_part_numerator;
            size_t rounded_integer_part_denominator;

            const U tick_step_power_of_10 = U(tick_step_exp) * std::log(U(2)) / std::log(U(10)); // must cast to float point arithmetic
            DEBUG_ASSERT_GE(0, tick_step_power_of_10);

            const size_t num_digits_in_power_of_10 = size_t(std::floor(tick_step_power_of_10 >= 0 ?
                tick_step_power_of_10 : -tick_step_power_of_10 + 1));
            const auto signed_num_digits_in_power_of_10 = tick_step_power_of_10 >= 0 ?
                math::make_signed_from(num_digits_in_power_of_10) : -math::make_signed_from(num_digits_in_power_of_10);

            U closest_value_with_integer_part = tick_step * std::pow(U(10.0), num_digits_in_power_of_10);

            if (closest_value_with_integer_part >= 5) {
                rounded_integer_part_numerator = 5;
                rounded_integer_part_denominator = 1;
            }
            else {
                rounded_integer_part_numerator = 25;
                rounded_integer_part_denominator = 10;
            }

            tick_step = rounded_integer_part_numerator *
                std::pow(U(10.0), tick_step_power_of_10 >= 0 ?
                    math::make_signed_from(num_digits_in_power_of_10) : -math::make_signed_from(num_digits_in_power_of_10)) / rounded_integer_part_denominator; // drop the rest fraction

            // calibration through overflow/underflow

            U prev_tick_step;
            U next_tick_step = tick_step;
            size_t rounded_integer_part_next_numerator = rounded_integer_part_numerator;

            if (next_tick_step * ticks < 2 * distance) {
                do {
                    // step still not big enough, increase step in twice
                    rounded_integer_part_numerator = rounded_integer_part_next_numerator;
                    prev_tick_step = next_tick_step;

                    rounded_integer_part_next_numerator *= 2;
                    next_tick_step = rounded_integer_part_next_numerator *
                        std::pow(U(10.0), signed_num_digits_in_power_of_10) / rounded_integer_part_denominator;
                } while (next_tick_step * ticks < 2 * distance);

                tick_step = prev_tick_step;

                next_tick_step = prev_tick_step;
            }

            size_t rounded_integer_part_next_denominator = rounded_integer_part_denominator;

            if (next_tick_step * ticks >= distance) {
                do {
                    // step still not small enough, decrease step in twice
                    rounded_integer_part_denominator = rounded_integer_part_next_denominator;
                    prev_tick_step = next_tick_step;

                    rounded_integer_part_next_denominator *= 2;
                    next_tick_step = rounded_integer_part_numerator *
                        std::pow(U(10.0), signed_num_digits_in_power_of_10) / rounded_integer_part_next_denominator;
                } while (next_tick_step * ticks >= distance);

                tick_step = prev_tick_step;
            }
        }
        else {
            U closest_value_with_integer_part = std::floor(tick_step / 5) * 5;
            if (!closest_value_with_integer_part) {
                closest_value_with_integer_part = std::floor(tick_step);
            }

            U rounded_integer_part_numerator = size_t(closest_value_with_integer_part + 0.5);
            U rounded_integer_part_denominator = 1;

            // calibration through overflow/underflow

            U prev_tick_step;
            U next_tick_step = tick_step;
            U rounded_integer_part_next_numerator = rounded_integer_part_numerator;

            if (next_tick_step * ticks < 2 * distance) {
                do {
                    // step still not big enough, increase step in twice
                    rounded_integer_part_numerator = rounded_integer_part_next_numerator;
                    prev_tick_step = next_tick_step;

                    rounded_integer_part_next_numerator *= 2;
                    next_tick_step = rounded_integer_part_next_numerator / rounded_integer_part_denominator;
                } while (next_tick_step * ticks < 2 * distance);

                tick_step = prev_tick_step;

                next_tick_step = prev_tick_step;
            }

            U rounded_integer_part_next_denominator = rounded_integer_part_denominator;

            if (next_tick_step * ticks >= distance) {
                do {
                    // step still not small enough, decrease step in twice
                    rounded_integer_part_denominator = rounded_integer_part_next_denominator;
                    prev_tick_step = next_tick_step;

                    rounded_integer_part_next_denominator *= 2;
                    next_tick_step = rounded_integer_part_numerator / rounded_integer_part_next_denominator;
                } while (next_tick_step * ticks >= distance);

                tick_step = prev_tick_step;
            }
        }

        return tick_step;
    }
}

#endif
