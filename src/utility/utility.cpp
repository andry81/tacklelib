#include <tacklelib/utility/utility.hpp>
#include <tacklelib/utility/assert.hpp>
#include <tacklelib/utility/locale.hpp>
#include <tacklelib/utility/memory.hpp>

#include <tacklelib/tackle/file_handle.hpp>

#include <boost/algorithm/string/replace.hpp>
#include <boost/scope_exit.hpp>
#include <boost/filesystem.hpp>
#include <boost/dll.hpp>

#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_FORMAT_INSTEAD_UTILITY_STRING_FORMAT)
#  include <fmt/format.h>
#endif

#include <vector>
#include <regex>
#include <locale>

#if defined(UTILITY_PLATFORM_WINDOWS)
// windows includes must be ordered here!
#include <windef.h>     // instead of windows.h
#include <winbase.h>    // for GetLastError and GetComputerName
//#include <winnt.h>
//#include <minwindef.h>  // for DWORD and etc
//#include <wtypes.h>     // for HWND
#include <Crtdbg.h>     // for debug stuff
#include <Winnetwk.h>   // for WNetGetUniversalName()
#include <Lm.h>         // for NetShareGetInfo()
#include <Lmcons.h>     // for UNLEN

#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_NETWORK_UNC)
#include <pystring.h>   // from 3dparty pystring
#endif

#else
#include <unistd.h>     // for gethostname/getlogin_r
#include <limits.h>

#ifndef HOST_NAME_MAX
# include <netdb.h>      // for the workaround: https://stackoverflow.com/questions/30084116/host-name-max-undefined-after-include-limits-h
# ifndef HOST_NAME_MAX   // only in case if not yet defined!
#   ifndef MAXHOSTNAMELEN
      // workaround is not applicable
#     error MAXHOSTNAMELEN is not implemented
#   endif
#   define HOST_NAME_MAX   MAXHOSTNAMELEN  // not including null-terminated character!
# endif
#endif

#endif


namespace boost
{
    namespace fs = filesystem;
}

namespace utility {

namespace {

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool
        _is_relative_path(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path)
    {
        if (path.empty()) {
            return false;
        }

        return boost::fs::path{ std::move(path.str()) }.is_relative();
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool
        _is_absolute_path(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path)
    {
        if (path.empty()) {
            return false;
        }

        return boost::fs::path{ std::move(path.str()) }.is_absolute();
    }

    template <char separator_char>
    FORCE_INLINE tackle::basic_path_string<separator_char>
        _get_relative_path(
            tackle::basic_path_string<separator_char> from_path,
            tackle::basic_path_string<separator_char> to_path,
            bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);
        auto && to_path_rref = std::move(to_path);

        if (throw_on_error) {
            return tackle::basic_path_string<separator_char>{
                separator_char == literal_separators<char>::forward_slash_char ?
                    boost::fs::relative(to_path_rref.str(), from_path_rref.str()).generic_string() :
                    boost::fs::relative(to_path_rref.str(), from_path_rref.str()).string() };
        }

        boost::system::error_code ec;

        return tackle::basic_path_string<separator_char>{
            separator_char == literal_separators<char>::forward_slash_char ?
                boost::fs::relative(to_path_rref.str(), from_path_rref.str(), ec).generic_string() :
                boost::fs::relative(to_path_rref.str(), from_path_rref.str(), ec).string() };
    }

    template <wchar_t separator_char>
    FORCE_INLINE tackle::basic_path_wstring<separator_char>
        _get_relative_path(
            tackle::basic_path_wstring<separator_char> from_path,
            tackle::basic_path_wstring<separator_char> to_path,
            bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);
        auto && to_path_rref = std::move(to_path);

        if (throw_on_error) {
            return tackle::basic_path_wstring<separator_char>{
                separator_char == literal_separators<wchar_t>::forward_slash_char ?
                    boost::fs::relative(to_path_rref.str(), from_path_rref.str()).generic_wstring() :
                    boost::fs::relative(to_path_rref.str(), from_path_rref.str()).wstring() };
        }

        boost::system::error_code ec;

        return tackle::basic_path_wstring<separator_char>{
            separator_char == literal_separators<wchar_t>::forward_slash_char ?
                boost::fs::relative(to_path_rref.str(), from_path_rref.str(), ec).generic_wstring() :
                boost::fs::relative(to_path_rref.str(), from_path_rref.str(), ec).wstring() };
    }

    template <char separator_char>
    FORCE_INLINE tackle::basic_path_string<separator_char>
        _get_absolute_path(
            tackle::basic_path_string<separator_char> from_path,
            tackle::basic_path_string<separator_char> to_path)
    {
        auto && from_path_rref = std::move(from_path);
        auto && to_path_rref = std::move(to_path);

        return tackle::basic_path_string<separator_char>{
            separator_char == literal_separators<char>::forward_slash_char ?
                boost::fs::absolute(to_path_rref.str(), from_path_rref.str()).generic_string() :
                boost::fs::absolute(to_path_rref.str(), from_path_rref.str()).string() };
    }

    template <char separator_char>
    FORCE_INLINE tackle::basic_path_string<separator_char>
        _get_current_path(
            bool throw_on_error, tackle::tag_basic_path_string<separator_char>)
    {
        if (throw_on_error) {
            return tackle::basic_path_string<separator_char>{
                separator_char == literal_separators<char>::forward_slash_char ?
                    boost::fs::current_path().generic_string() :
                    boost::fs::current_path().string() };
        }


        boost::system::error_code ec;

        return tackle::basic_path_string<separator_char>{
            separator_char == literal_separators<char>::forward_slash_char ?
                boost::fs::current_path(ec).generic_string() :
                boost::fs::current_path(ec).string() };
    }

    template <wchar_t separator_char>
    FORCE_INLINE tackle::basic_path_wstring<separator_char>
        _get_current_path(
            bool throw_on_error, tackle::tag_basic_path_wstring<separator_char>)
    {
        if (throw_on_error) {
            return tackle::basic_path_wstring<separator_char>{
                separator_char == literal_separators<wchar_t>::forward_slash_char ?
                    boost::fs::current_path().generic_wstring() :
                    boost::fs::current_path().wstring() };
        }


        boost::system::error_code ec;

        return tackle::basic_path_wstring<separator_char>{
            separator_char == literal_separators<wchar_t>::forward_slash_char ?
                boost::fs::current_path(ec).generic_wstring() :
                boost::fs::current_path(ec).wstring() };
    }

    template <wchar_t separator_char>
    FORCE_INLINE tackle::basic_path_wstring<separator_char>
        _get_absolute_path(
            tackle::basic_path_wstring<separator_char> from_path,
            tackle::basic_path_wstring<separator_char> to_path)
    {
        auto && from_path_rref = std::move(from_path);
        auto && to_path_rref = std::move(to_path);

        return tackle::basic_path_wstring<separator_char>{
            separator_char == literal_separators<wchar_t>::forward_slash_char ?
                boost::fs::absolute(to_path_rref.str(), from_path_rref.str()).generic_wstring() :
                boost::fs::absolute(to_path_rref.str(), from_path_rref.str()).wstring() };
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char>
        _get_absolute_path(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path, bool throw_on_error)
    {
        auto && path_rref = std::move(path);

        if (!is_absolute_path(path_rref)) {
            return _get_absolute_path(_get_current_path(throw_on_error, tackle::tag_basic_path_string_by_elem<t_elem, separator_char>{}), path_rref);
        }

        return path;
    }

    template <char separator_char>
    FORCE_INLINE tackle::basic_path_string<separator_char>
        _get_lexically_normal_path(
            tackle::basic_path_string<separator_char> path)
    {
        return tackle::basic_path_string<separator_char>{
            separator_char == literal_separators<char>::forward_slash_char ?
                boost::fs::path{ std::move(path.str()) }.lexically_normal().generic_string() :
                boost::fs::path{ std::move(path.str()) }.lexically_normal().string() };
    }

    template <wchar_t separator_char>
    FORCE_INLINE tackle::basic_path_wstring<separator_char>
        _get_lexically_normal_path(
            tackle::basic_path_wstring<separator_char> path)
    {
        return tackle::basic_path_wstring<separator_char>{
            separator_char == literal_separators<wchar_t>::forward_slash_char ?
                boost::fs::path{ std::move(path.str()) }.lexically_normal().generic_wstring() :
                boost::fs::path{ std::move(path.str()) }.lexically_normal().wstring() };
    }

    template <char separator_char>
    FORCE_INLINE tackle::basic_path_string<separator_char>
        _get_lexically_relative_path(
            tackle::basic_path_string<separator_char> from_path,
            tackle::basic_path_string<separator_char> to_path)
    {
        return tackle::basic_path_string<separator_char>{
            separator_char == literal_separators<char>::forward_slash_char ?
                boost::fs::path{ std::move(to_path.str()) }.lexically_relative(std::move(from_path.str())).generic_string() :
                boost::fs::path{ std::move(to_path.str()) }.lexically_relative(std::move(from_path.str())).string() };
    }

    template <wchar_t separator_char>
    FORCE_INLINE tackle::basic_path_wstring<separator_char>
        _get_lexically_relative_path(
            tackle::basic_path_wstring<separator_char> from_path,
            tackle::basic_path_wstring<separator_char> to_path)
    {
        return tackle::basic_path_wstring<separator_char>{
            separator_char == literal_separators<wchar_t>::forward_slash_char ?
                boost::fs::path{ std::move(to_path.str()) }.lexically_relative(std::move(from_path.str())).generic_wstring() :
                boost::fs::path{ std::move(to_path.str()) }.lexically_relative(std::move(from_path.str())).wstring() };
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE uint64_t
        _get_file_size(const tackle::basic_file_handle<t_elem, t_traits, t_alloc, separator_char> & file_handle)
    {
        DEBUG_ASSERT_TRUE(file_handle.get());

        fpos_t last_pos;
        if (fgetpos(file_handle.get(), &last_pos)) return 0;
        if (fseek(file_handle.get(), 0, SEEK_END)) return 0;

        const uint64_t size =
#if defined(UTILITY_PLATFORM_WINDOWS)
            _ftelli64(file_handle.get());
#elif defined(UTILITY_PLATFORM_POSIX)
            ftello64(file_handle.get());
#else
#error platform is not implemented
#endif

        fsetpos(file_handle.get(), &last_pos);

        return size;
    }

    // TODO:
    //  Compare files internal identifiers before compare content.
    //
    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool
        _is_files_equal(
            tackle::basic_file_handle<t_elem, t_traits, t_alloc, separator_char> left_file_handle,
            tackle::basic_file_handle<t_elem, t_traits, t_alloc, separator_char> right_file_handle,
            size_t read_block_size)
    {
        auto && left_file_handle_rref = std::move(left_file_handle);
        auto && right_file_handle_rref = std::move(right_file_handle);

        const uint64_t left_file_size = get_file_size(left_file_handle_rref);
        const uint64_t right_file_size = get_file_size(right_file_handle_rref);
        if (left_file_size != right_file_size) {
            return false;
        }

        using LocalBufSharedPtr_t = std::shared_ptr<uint8_t>;

        Buffer left_local_buf{ read_block_size };
        Buffer right_local_buf{ read_block_size };

        const uint64_t max_compare_size = (std::min)(left_local_buf.size(), right_local_buf.size());

        while (!feof(left_file_handle_rref.get())) {
            const size_t left_read_byte_size = fread(left_local_buf.get(), 1, size_t(max_compare_size), left_file_handle_rref.get());
            const size_t right_read_byte_size = fread(right_local_buf.get(), 1, size_t(max_compare_size), right_file_handle_rref.get());
            if (left_read_byte_size != right_read_byte_size) {
                return false;
            }

            if (std::memcmp(left_local_buf.get(), right_local_buf.get(), left_read_byte_size)) {
                return false;
            }
        }

        return true;
    }

    FORCE_INLINE tackle::generic_path_string _convert_to_generic_path(const char * path, size_t len)
    {
        DEBUG_ASSERT_TRUE(path);
        return tackle::generic_path_string{ boost::fs::path{ path, path + len }.generic_string() };
    }

    FORCE_INLINE tackle::generic_path_wstring _convert_to_generic_path(const wchar_t * path, size_t len)
    {
        DEBUG_ASSERT_TRUE(path);
        return tackle::generic_path_wstring{ boost::fs::path{ path, path + len }.generic_wstring() };
    }

    FORCE_INLINE tackle::generic_path_string _convert_to_generic_path(std::string path)
    {
        return tackle::generic_path_string{ boost::fs::path{ std::move(path) }.generic_string() };
    }

    FORCE_INLINE tackle::generic_path_wstring _convert_to_generic_path(std::wstring path)
    {
        return tackle::generic_path_wstring{ boost::fs::path{ std::move(path) }.generic_wstring() };
    }

    FORCE_INLINE tackle::generic_path_string _convert_to_generic_path(tackle::native_path_string path)
    {
        return tackle::generic_path_string{ boost::fs::path{ std::move(path.str()) }.generic_string() };
    }

    FORCE_INLINE tackle::generic_path_wstring _convert_to_generic_path(tackle::native_path_wstring path)
    {
        return tackle::generic_path_wstring{ boost::fs::path{ std::move(path.str()) }.generic_wstring() };
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    FORCE_INLINE tackle::generic_path_string _convert_to_generic_path(tackle::generic_path_string path)
    {
        return tackle::generic_path_string{ boost::fs::path{ std::move(path.str()) }.generic_string() };
    }

    FORCE_INLINE tackle::generic_path_wstring _convert_to_generic_path(tackle::generic_path_wstring path)
    {
        return tackle::generic_path_wstring{ boost::fs::path{ std::move(path.str()) }.generic_wstring() };
    }
#endif

    FORCE_INLINE tackle::native_path_string _convert_to_native_path(const char * path, size_t len)
    {
        DEBUG_ASSERT_TRUE(path);
        return tackle::native_path_string{ boost::fs::path{ path, path + len }.make_preferred().string() };
    }

    FORCE_INLINE tackle::native_path_wstring _convert_to_native_path(const wchar_t * path, size_t len)
    {
        DEBUG_ASSERT_TRUE(path);
        return tackle::native_path_wstring{ boost::fs::path{ path, path + len }.make_preferred().wstring() };
    }

    FORCE_INLINE tackle::native_path_string _convert_to_native_path(std::string path)
    {
        return tackle::native_path_string{ boost::fs::path{ std::move(path) }.make_preferred().string() };
    }

    FORCE_INLINE tackle::native_path_wstring _convert_to_native_path(std::wstring path)
    {
        return tackle::native_path_wstring{ boost::fs::path{ std::move(path) }.make_preferred().wstring() };
    }

    FORCE_INLINE tackle::native_path_string _convert_to_native_path(tackle::generic_path_string path)
    {
        return tackle::native_path_string{ boost::fs::path{ std::move(path.str()) }.make_preferred().string() };
    }

    FORCE_INLINE tackle::native_path_wstring _convert_to_native_path(tackle::generic_path_wstring path)
    {
        return tackle::native_path_wstring{ boost::fs::path{ std::move(path.str()) }.make_preferred().wstring() };
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    FORCE_INLINE tackle::native_path_string _convert_to_native_path(tackle::native_path_string path)
    {
        return tackle::native_path_string{ boost::fs::path{ std::move(path.str()) }.make_preferred().string() };
    }

    FORCE_INLINE tackle::native_path_wstring _convert_to_native_path(tackle::native_path_wstring path)
    {
        return tackle::native_path_wstring{ boost::fs::path{ std::move(path.str()) }.make_preferred().wstring() };
    }
#endif

    // From MSDN:
    //  CreateDirectoryA function:
    //      For the ANSI version of this function, there is a default string size limit for paths of 248 characters (MAX_PATH - enough room for a 8.3 filename).
    //      To extend this limit to 32,767 wide characters, call the Unicode version of the function and prepend `\\?\` to the path.
    //

#if defined(UTILITY_PLATFORM_WINDOWS)
    FORCE_INLINE DWORD _WNetGetUniversalName(LPCSTR lpLocalPath, DWORD dwInfoLevel, LPVOID lpBuffer, LPDWORD lpBufferSize)
    {
        return ::WNetGetUniversalNameA(const_cast<LPSTR>(lpLocalPath), dwInfoLevel, lpBuffer, lpBufferSize);
    }

    FORCE_INLINE DWORD _WNetGetUniversalName(LPCWSTR lpLocalPath, DWORD dwInfoLevel, LPVOID lpBuffer, LPDWORD lpBufferSize)
    {
        return ::WNetGetUniversalNameW(const_cast<LPWSTR>(lpLocalPath), dwInfoLevel, lpBuffer, lpBufferSize);
    }

    FORCE_INLINE NET_API_STATUS _NetShareGetInfo(LPWSTR servername, LPCWSTR netname, DWORD level, LPBYTE * bufptr)
    {
        return ::NetShareGetInfo(servername, const_cast<LPWSTR>(netname), level, bufptr);
    }

    FORCE_INLINE NET_API_STATUS _NetShareGetInfo(LPSTR servername, LPCSTR netname, DWORD level, LPBYTE * bufptr)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

        std::wstring && wstr_servername_rref = utility::convert_utf8_to_utf16_string(std::string{ servername }, wstring_convert_t{});
        std::wstring && wstr_netname_rref = utility::convert_utf8_to_utf16_string(std::string{ netname }, wstring_convert_t{});

        static_assert(sizeof(*static_cast<LPWSTR>(nullptr)) == sizeof(wchar_t), "sizeof(wchar_t) is not equal to sizeof(*LPWSTR)");

        return _NetShareGetInfo(const_cast<LPWSTR>(wstr_servername_rref.c_str()), const_cast<LPWSTR>(wstr_netname_rref.c_str()), level, bufptr);
    }
#endif

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE tackle::native_basic_path_string<t_elem, t_traits, t_alloc>
        _convert_to_native_path(
            tackle::native_basic_path_string<t_elem, t_traits, t_alloc> && path)
    {
        return path;
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE tackle::native_basic_path_string<t_elem, t_traits, t_alloc>
        _convert_to_native_path(
            tackle::generic_basic_path_string<t_elem, t_traits, t_alloc> && path)
    {
        using generic_basic_path_string_t = tackle::generic_basic_path_string<t_elem, t_traits, t_alloc>;
        return _convert_to_native_path(std::move(std::forward<typename generic_basic_path_string_t::base_type>(path)));
    }
#endif

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE tackle::native_basic_path_string<t_elem, t_traits, t_alloc>
        _convert_from_unc_path(
            tackle::unc_basic_path_string<t_elem, t_traits, t_alloc> && from_path,
            tackle::tag_native_path_basic_string<t_elem>)
    {
        return from_path;
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE tackle::generic_basic_path_string<t_elem, t_traits, t_alloc>
        _convert_from_unc_path(
            tackle::unc_basic_path_string<t_elem, t_traits, t_alloc> && from_path,
            tackle::tag_generic_path_basic_string<t_elem>)
    {
        using generic_basic_path_string_t = tackle::generic_basic_path_string<t_elem, t_traits, t_alloc>;
        return _convert_to_generic_path(std::forward<typename generic_basic_path_string_t::base_type>(from_path));
    }

#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_NETWORK_UNC)

    // Based on: https://stackoverflow.com/questions/2316927/how-to-convert-unc-to-local-path
    //

    // converts `x:\folder` -> `\\server\share\folder`
    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool _convert_local_to_network_unc_path(
        tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> from_path,
        tackle::unc_basic_path_string<t_elem, t_traits, t_alloc> & to_path,
        bool throw_on_error)
    {
        using path_basic_string_t = tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char>;
        using unc_basic_path_string_t = tackle::unc_basic_path_string<t_elem, t_traits, t_alloc>;

        auto && from_path_rref = std::move(from_path);

        if (from_path_rref.empty()) {
            to_path.clear();
            return false;
        }

        if (!_is_absolute_path(from_path_rref)) {
            from_path_rref = _get_lexically_normal_path(std::move(_get_absolute_path(from_path_rref, throw_on_error)));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        auto && from_native_path_rref = _convert_to_native_path(std::forward<path_basic_string_t>(from_path_rref));
#else
        boost::replace_all(from_path_rref, "/", "\\");
        auto && from_native_path_rref = _convert_to_native_path(from_path_rref);
#endif

#if defined(UTILITY_PLATFORM_WINDOWS)
        // get size of the remote name buffer
        DWORD   dwLastError = 0;
        int     res = 0;
        DWORD   dwBufferSize = 0;
        char    szBuff[2];
        if (_WNetGetUniversalName(from_native_path_rref.c_str(), UNIVERSAL_NAME_INFO_LEVEL, szBuff, &dwBufferSize) == ERROR_MORE_DATA) {
            // get remote name of the share
            Buffer local_buf{ dwBufferSize };

            UNIVERSAL_NAME_INFO * puni = (UNIVERSAL_NAME_INFO*)local_buf.get();
            if (_WNetGetUniversalName(from_native_path_rref.c_str(), UNIVERSAL_NAME_INFO_LEVEL, puni, &dwBufferSize) == NO_ERROR) {
                utility::convert_string_to_string(puni->lpUniversalName, to_path, utility::tag_string_conv_utf8_tofrom_utf16{});

                return true;
            }
            else {
                res = 2;
            }
        }
        else {
            res = 1;
        }

        if (res) {
            dwLastError = GetLastError();
        }

        to_path.clear();

        if (res) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_FORMAT_INSTEAD_UTILITY_STRING_FORMAT)
                    fmt::format("{:s}({:d}): local path to network UNC path conversion error: LastError={:d}",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE, dwLastError)
#else
                    utility::string_format(256, "%s(%d): local path to network UNC path conversion error: LastError=%d",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE, dwLastError)
#endif
                );
            }
        }

        return false;
#else
        // is not ill formed, see: https://stackoverflow.com/questions/5246049/c11-static-assert-and-template-instantiation/5246686#5246686
        static_assert(utility::dependent_type<t_elem>::false_value, "not implemented");
        return false;
#endif
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE tackle::unc_basic_path_string<t_elem, t_traits, t_alloc>
        _convert_local_to_network_unc_path(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> from_path,
            tackle::tag_unc_path_basic_string<t_elem>,
            bool throw_on_error)
    {
        using return_type_t = tackle::unc_basic_path_string<t_elem, t_traits, t_alloc>;

        return_type_t to_path;
        _convert_local_to_network_unc_path(from_path, to_path, throw_on_error);

        return to_path;
    }

    // Based on: https://stackoverflow.com/questions/2316927/how-to-convert-unc-to-local-path
    //

    // converts `\\server\share\folder` -> `x:\folder`
    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool _convert_network_unc_to_local_path(
        tackle::unc_basic_path_string<t_elem, t_traits, t_alloc> from_path,
        tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> & to_path,
        bool throw_on_error)
    {
        using basic_string_t = std::basic_string<t_elem, t_traits, t_alloc>;
        using path_basic_string_t = tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char>;

        auto && from_path_rref = std::move(from_path);

        if (from_path_rref.empty()) {
            to_path.clear();
            return false;
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        const auto & backward_slash_str = literal_separators<t_elem>::backward_slash_str;
        const auto space_char           = literal_separators<t_elem>::space_char;

        // get share name from UNC
        std::vector<basic_string_t> vecTokens;
        pystring::split(from_path_rref, vecTokens, backward_slash_str);

        if (vecTokens.size() < 4) {
            to_path.clear();
            return false;
        }

        // we need char for NetShareGetInfo()
        basic_string_t share_name_str(vecTokens[3].length(), space_char);
        std::copy(vecTokens[3].begin(), vecTokens[3].end(), share_name_str.begin());

        DWORD           dwLastError = 0;
        PSHARE_INFO_502 bufPtr;
        NET_API_STATUS  res;
        if ((res = _NetShareGetInfo(NULL, share_name_str.c_str(), 502, (LPBYTE*)&bufPtr)) == ERROR_SUCCESS) {
            BOOST_SCOPE_EXIT(&bufPtr) {
                // Free the allocated memory.
                ::NetApiBufferFree(bufPtr);
            } BOOST_SCOPE_EXIT_END

            // print the retrieved data.
            switch (::utility::basic_char_identity<t_elem>::type_index) {
            case ::utility::basic_char_identity<char>::type_index: {
                _RPTF3(_CRT_WARN, UTILITY_LITERAL_STRING("%ls\t%ls\t%u\n", char),
                    utility::convert_string_to_string(bufPtr->shi502_netname, utility::tag_string{}, utility::tag_string_conv_utf8_tofrom_utf16{}).c_str(),
                    utility::convert_string_to_string(bufPtr->shi502_path, utility::tag_string{}, utility::tag_string_conv_utf8_tofrom_utf16{}).c_str(),
                    bufPtr->shi502_current_uses);
            } break;
            case ::utility::basic_char_identity<wchar_t>::type_index: {
                _RPTFW3(_CRT_WARN, UTILITY_LITERAL_STRING("%ls\t%ls\t%u\n", wchar_t),
                    utility::convert_string_to_string(bufPtr->shi502_netname, utility::tag_wstring{}, utility::tag_string_conv_utf8_tofrom_utf16{}).c_str(),
                    utility::convert_string_to_string(bufPtr->shi502_path, utility::tag_wstring{}, tag_string_conv_utf8_tofrom_utf16{}).c_str(),
                    bufPtr->shi502_current_uses);
            } break;
            }

            utility::convert_string_to_string(bufPtr->shi502_path, to_path, utility::tag_string_conv_utf8_tofrom_utf16{});

            const auto * unc_separator_str = UTILITY_LITERAL_STRING_BY_CHAR_ARRAY(t_elem, separator_char).data();

            // build local path
            for (size_t i = 4; i < vecTokens.size(); ++i) {
                if (!pystring::endswith(to_path, unc_separator_str)) {
                    to_path /= vecTokens[i];
                }
                else {
                    static_cast<basic_string_t &>(to_path) += vecTokens[i]; // base string append
                }
            }

            // Validate the value of the shi502_security_descriptor member.
            if (IsValidSecurityDescriptor(bufPtr->shi502_security_descriptor)) {
                switch (::utility::basic_char_identity<t_elem>::type_index) {
                case ::utility::basic_char_identity<char>::type_index: {
                    _RPTF0(_CRT_WARN, UTILITY_LITERAL_STRING("It has a valid Security Descriptor.\n", char));
                } break;
                case ::utility::basic_char_identity<wchar_t>::type_index: {
                    _RPTFW0(_CRT_WARN, UTILITY_LITERAL_STRING("It has a valid Security Descriptor.\n", wchar_t));
                } break;
                }
            }
            else {
                switch (::utility::basic_char_identity<t_elem>::type_index) {
                case ::utility::basic_char_identity<char>::type_index: {
                    _RPTF0(_CRT_WARN, UTILITY_LITERAL_STRING("It does not have a valid Security Descriptor.\n", char));
                } break;
                case ::utility::basic_char_identity<wchar_t>::type_index: {
                    _RPTFW0(_CRT_WARN, UTILITY_LITERAL_STRING("It does not have a valid Security Descriptor.\n", wchar_t));
                } break;
                }
            }
        }
        else {
            dwLastError = GetLastError();
        }

        to_path.clear();

        if (res != ERROR_SUCCESS) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_FORMAT_INSTEAD_UTILITY_STRING_FORMAT)
                    fmt::format("{:s}({:d}): network UNC path to local path conversion error: LastError={:d}",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE, dwLastError)
#else
                    utility::string_format(256, "%s(%d): network UNC path to local path conversion error: LastError=%d",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE, dwLastError)
#endif
                );
            }
        }

        return false;
#else
        // is not ill formed, see: https://stackoverflow.com/questions/5246049/c11-static-assert-and-template-instantiation/5246686#5246686
        static_assert(utility::dependent_type<t_elem>::false_value, "not implemented");
        return false;
#endif
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char>
        _convert_network_unc_to_local_path(
            tackle::unc_basic_path_string<t_elem, t_traits, t_alloc> from_path,
            tackle::tag_path_basic_string<t_elem, separator_char>,
            bool throw_on_error)
    {
        using return_type_t = tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char>;

        return_type_t to_path;
        _convert_network_unc_to_local_path(from_path, to_path, throw_on_error);

        return to_path;
    }

#endif

    // converts `x:/folder` -> `\\?\x:folder`
    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool _convert_local_to_local_unc_path(
        tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> from_path,
        tackle::unc_basic_path_string<t_elem, t_traits, t_alloc> & to_path,
        bool throw_on_error)
    {
        using path_basic_string_t = tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char>;
        using native_path_basic_string_t = tackle::native_basic_path_string<t_elem, t_traits, t_alloc>;

        auto && from_path_rref = std::move(from_path);

        if (from_path_rref.empty()) {
            to_path.clear();
            return false;
        }

        if (!_is_absolute_path(from_path_rref)) {
            from_path_rref = _get_lexically_normal_path(std::move(_get_absolute_path(from_path_rref, throw_on_error)));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        auto && from_native_path_rref = _convert_to_native_path(std::forward<path_basic_string_t>(from_path_rref));
#else
        boost::replace_all(from_path_rref, "/", "\\");
        auto && from_native_path_rref = _convert_to_native_path(from_path_rref);
#endif

        const auto & path_prefix = UTILITY_LITERAL_STRING("\\\\?\\", t_elem);

        // including separator conversion
        if (from_native_path_rref.substr(0, 4) != path_prefix) {
            to_path = path_prefix + std::move(std::forward<typename native_path_basic_string_t::base_type>(from_native_path_rref)); // usual strings concatenation
        }
        else {
            to_path = std::move(std::forward<typename native_path_basic_string_t::base_type>(from_native_path_rref));
        }

        return true;
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE tackle::unc_basic_path_string<t_elem, t_traits, t_alloc>
        _convert_local_to_local_unc_path(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> from_path,
            tackle::tag_unc_path_basic_string<t_elem>,
            bool throw_on_error)
    {
        using return_type_t = tackle::unc_basic_path_string<t_elem, t_traits, t_alloc>;

        return_type_t to_path;
        _convert_local_to_local_unc_path(from_path, to_path, throw_on_error);

        return to_path;
    }

    // converts `\\?\x:folder` -> `x:/folder`
    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool _convert_local_unc_to_local_path(
        tackle::unc_basic_path_string<t_elem, t_traits, t_alloc> from_path,
        tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> & to_path)
    {
        using basic_string_t = std::basic_string<t_elem, t_traits, t_alloc>;
        using unc_basic_path_string_t = tackle::unc_basic_path_string<t_elem, t_traits, t_alloc>;

        auto && from_path_rref = std::move(from_path);

        if (from_path_rref.empty()) {
            to_path.clear();
            return false;
        }

        const auto & path_prefix = UTILITY_LITERAL_STRING("\\\\?\\", t_elem);

        if (from_path_rref.substr(0, 4) == path_prefix) {
            to_path = from_path_rref.substr(4);
        }
        else {
            to_path = _convert_from_unc_path(std::forward<unc_basic_path_string_t>(from_path_rref), tackle::tag_basic_path_string_by_separator_char<t_elem, separator_char>{});
        }

        return true;
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char>
        _convert_local_unc_to_local_path(
            tackle::unc_basic_path_string<t_elem, t_traits, t_alloc> from_path,
            tackle::tag_path_basic_string<t_elem, separator_char>)
    {
        using return_type_t = tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char>;

        return_type_t to_path;
        _convert_local_unc_to_local_path(from_path, to_path);

        return to_path;
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE tackle::native_basic_path_string<t_elem, t_traits, t_alloc>
        _fix_long_path(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path, bool throw_on_error)
    {
        using unc_basic_path_string_t = tackle::unc_basic_path_string<t_elem, t_traits, t_alloc>;

        auto && path_rref = std::move(path);

#if defined(UTILITY_PLATFORM_WINDOWS)
        unc_basic_path_string_t unc_path;

        if (!_convert_local_to_local_unc_path(path_rref, unc_path, throw_on_error)) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_FORMAT_INSTEAD_UTILITY_STRING_FORMAT)
                    fmt::format("{:s}({:d}): local path to local UNC path conversion error",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE)
#else
                    utility::string_format(256, "%s(%d): local path to local UNC path conversion error",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE)
#endif
                );
            }
        }

        return unc_path;
#else
        // CAUTION:
        //  No actual conversion from the UNC path, just path separators fix.
        //
        return _convert_to_native_path(path_rref);
#endif
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char>
        _unfix_long_path(
            tackle::native_basic_path_string<t_elem, t_traits, t_alloc> path,
            tackle::tag_path_basic_string<t_elem, separator_char>,
            bool throw_on_error)
    {
        auto && path_rref = std::move(path);

#if defined(UTILITY_PLATFORM_WINDOWS)
        return _convert_local_unc_to_local_path(path_rref, tackle::tag_path_basic_string<t_elem, separator_char>{});
#else
        // CAUTION:
        //  No actual conversion from the UNC path, just path separators fix.
        //
        return _convert_to_generic_path(path_rref);
#endif
    }

    FORCE_INLINE FILE * _fopen(const char * file_name, const char * mode, SharedAccess share_flags)
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        return _fsopen(file_name, mode, share_flags);
#elif defined(UTILITY_PLATFORM_POSIX)
        // TODO:
        //  Implement `fcntl` with `F_SETLK`, for details see: https://linux.die.net/man/3/fcntl
        UTILITY_UNUSED_STATEMENT(share_flags);

        return fopen(file_name, mode);
#else
        return nullptr;
#error platform is not implemented
#endif
    }

    FORCE_INLINE FILE * _fopen(const wchar_t * file_name, const wchar_t * mode, SharedAccess share_flags)
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        return _wfsopen(file_name, mode, share_flags);
#elif defined(UTILITY_PLATFORM_POSIX)
        // TODO:
        //  Implement `fcntl` with `F_SETLK`, for details see: https://linux.die.net/man/3/fcntl
        UTILITY_UNUSED_STATEMENT(share_flags);

        return fopen(
            utility::convert_string_to_string(file_name, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{}).c_str(),
            utility::convert_string_to_string(mode, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{}).c_str()
        );
#else
        return nullptr;
#error platform is not implemented
#endif
    }

    FORCE_INLINE std::wstring _convert_to_utf16_string(std::string str)
    {
        return utility::convert_utf8_to_utf16_string(std::move(str), utility::tag_wstring{});
    }

    FORCE_INLINE std::wstring _convert_to_utf16_string(std::wstring wstr)
    {
        return wstr;
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE tackle::basic_file_handle<t_elem, t_traits, t_alloc, separator_char>
        _recreate_file(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> file_path, const tackle::path_string_codecvt & codecvt,
            const t_elem * mode, SharedAccess share_flags, size_t size, uint32_t fill_by, bool throw_on_error)
    {
        using basic_file_handle_t = tackle::basic_file_handle<t_elem, t_traits, t_alloc, separator_char>;

        auto && file_path_rref_fixed = fix_long_path(std::move(file_path), throw_on_error);

        FILE * file_ptr = nullptr;

        if (dynamic_cast<const std::codecvt_utf8<wchar_t> *>(&codecvt)) {
            // convert to utf-16
            const std::wstring file_path_wstr = _convert_to_utf16_string(file_path_rref_fixed);
            const std::wstring mode_wstr = _convert_to_utf16_string(mode);
            file_ptr = _fopen(file_path_wstr.c_str(), mode_wstr.c_str(), share_flags);
        }
        else {
            file_ptr = _fopen(file_path_rref_fixed.c_str(), mode, share_flags);
        }

        auto && file_path_rref_unfixed = _unfix_long_path(file_path_rref_fixed, tackle::tag_path_basic_string<t_elem, separator_char>{}, throw_on_error);

        basic_file_handle_t file_handle_ptr = basic_file_handle_t{ file_ptr, file_path_rref_unfixed };
        if (!file_ptr) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true) std::system_error{ errno, std::system_category(), utility::convert_utf16_to_utf8_string(file_path_rref_unfixed) };
            }
            else {
                return basic_file_handle_t::null();
            }
        }

        if (size) {
            std::vector<uint32_t> chunk;
            chunk.resize(4096, fill_by);

            const size_t num_whole_chunks = size / chunk.size();
            for (size_t i = 0; i < num_whole_chunks; i++) {
                const size_t write_size = fwrite(&chunk[0], 1, chunk.size(), file_ptr);
                const int file_err = ferror(file_ptr);
                if (write_size < chunk.size()) {
                    if (throw_on_error) {
                        DEBUG_BREAK_THROW(true) std::system_error{ file_err, std::system_category(), utility::convert_utf16_to_utf8_string(file_path_rref_unfixed) };
                    }
                    else {
                        return basic_file_handle_t::null();
                    }
                }
            }

            const size_t chunk_reminder = size % chunk.size();
            const size_t write_size = fwrite(&chunk[0], 1, chunk_reminder, file_ptr);
            const int file_err = ferror(file_ptr);
            if (write_size < chunk_reminder) {
                if (throw_on_error) {
                    DEBUG_BREAK_THROW(true) std::system_error{ file_err, std::system_category(), utility::convert_utf16_to_utf8_string(file_path_rref_unfixed) };
                }
                else {
                    return basic_file_handle_t::null();
                }
            }
        }

        return file_handle_ptr;
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE tackle::basic_file_handle<t_elem, t_traits, t_alloc, separator_char>
        _create_file(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> file_path, const tackle::path_string_codecvt & codecvt,
            const t_elem * mode, SharedAccess share_flags, size_t size, uint32_t fill_by, bool throw_on_error)
    {
        using basic_file_handle_t = tackle::basic_file_handle<t_elem, t_traits, t_alloc, separator_char>;

        auto && file_path_rref_fixed = fix_long_path(std::move(file_path), throw_on_error);

        const bool file_existed = boost::fs::exists(boost::fs::path{ file_path_rref_fixed.str(), codecvt });

        auto && file_path_rref_unfixed = _unfix_long_path(file_path_rref_fixed, tackle::tag_path_basic_string<t_elem, separator_char>{}, throw_on_error);

        if (file_existed) {
            if (throw_on_error) {
                const int errno_ = 3; // file already exist
                DEBUG_BREAK_THROW(true) std::system_error{ errno_, std::system_category(), utility::convert_utf16_to_utf8_string(file_path_rref_unfixed) };
            }
            else {
                return basic_file_handle_t::null();
            }
        }

        return _recreate_file(file_path_rref_unfixed, codecvt, mode, share_flags, size, fill_by, throw_on_error);
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE tackle::basic_file_handle<t_elem, t_traits, t_alloc, separator_char>
        _open_file(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> file_path, const tackle::path_string_codecvt & codecvt,
            const t_elem * mode, SharedAccess share_flags, size_t creation_size, size_t resize_if_existed, uint32_t fill_by_on_creation,
            bool throw_on_error)
    {
        using basic_file_handle_t = tackle::basic_file_handle<t_elem, t_traits, t_alloc, separator_char>;

        auto && file_path_rref_fixed = fix_long_path(std::move(file_path), throw_on_error);

        boost::fs::path boost_fs_path{ file_path_rref_fixed.str(), codecvt };

        const bool file_existed = boost::fs::exists(boost_fs_path);

        auto && file_path_rref_unfixed = _unfix_long_path(file_path_rref_fixed, tackle::tag_path_basic_string<t_elem, separator_char>{}, throw_on_error);

        if (!file_existed) {
            return recreate_file(file_path_rref_unfixed, codecvt, mode, share_flags, creation_size, fill_by_on_creation, throw_on_error);
        }

        FILE * file_ptr = nullptr;

        if (dynamic_cast<const std::codecvt_utf8<wchar_t> *>(&codecvt)) {
            // use wide string
            const std::wstring mode_wstr = _convert_to_utf16_string(mode);
            file_ptr = _fopen(boost_fs_path.wstring().c_str(), mode_wstr.c_str(), share_flags);
        }
        else {
            file_ptr = _fopen(file_path_rref_fixed.c_str(), mode, share_flags);
        }

        basic_file_handle_t file_handle_ptr = basic_file_handle_t{ file_ptr, file_path_rref_unfixed };
        if (!file_ptr) {
            if (throw_on_error) {
                DEBUG_BREAK_THROW(true) std::system_error{ errno, std::system_category(), utility::convert_utf16_to_utf8_string(file_path_rref_unfixed) };
            }
            else {
                return basic_file_handle_t::null();
            }
        }

        if (resize_if_existed != size_t(-1)) {
            // close handle before resize
            file_handle_ptr.reset();
            boost::fs::resize_file(boost_fs_path, resize_if_existed);
            // reopen handle
            if (dynamic_cast<const std::codecvt_utf8<wchar_t> *>(&codecvt)) {
                // use wide string
                const std::wstring mode_wstr = _convert_to_utf16_string(mode);
                file_handle_ptr = basic_file_handle_t{
                    file_ptr = _fopen(boost_fs_path.wstring().c_str(), mode_wstr.c_str(), share_flags), file_path_rref_unfixed
                };
            }
            else {
                file_handle_ptr = basic_file_handle_t{
                    file_ptr = _fopen(file_path_rref_fixed.c_str(), mode, share_flags), file_path_rref_unfixed
                };
            }
            if (!file_ptr) {
                if (throw_on_error) {
                    DEBUG_BREAK_THROW(true) std::system_error{ errno, std::system_category(), utility::convert_utf16_to_utf8_string(file_path_rref_unfixed) };
                }
                else {
                    return basic_file_handle_t::null();
                }
            }
        }

        return file_handle_ptr;
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool _is_directory_path(
        tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path,
        const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        auto && file_path_rref_fixed = fix_long_path(std::move(path), throw_on_error);

        return boost::fs::is_directory(boost::fs::path{ file_path_rref_fixed.str(), codecvt });
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool _is_regular_file(
        tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path,
        const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        auto && file_path_rref_fixed = fix_long_path(std::move(path), throw_on_error);

        return boost::fs::is_regular_file(boost::fs::path{ file_path_rref_fixed.str(), codecvt });
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool _is_same_file(
        tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> left_path,
        tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> right_path,
        const tackle::path_string_codecvt & left_codecvt,
        const tackle::path_string_codecvt & right_codecvt,
        bool throw_on_error)
    {
        auto && left_file_path_rref_fixed = fix_long_path(std::move(left_path), throw_on_error);
        auto && right_file_path_rref_fixed = fix_long_path(std::move(right_path), throw_on_error);

        return boost::fs::equivalent(
            boost::fs::path{ left_file_path_rref_fixed.str(), left_codecvt },
            boost::fs::path{ right_file_path_rref_fixed.str(), right_codecvt });
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool _is_symlink_path(
        tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path,
        const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        auto && file_path_rref_fixed = fix_long_path(std::move(path), throw_on_error);

        return boost::fs::is_symlink(boost::fs::path{ file_path_rref_fixed.str(), codecvt });
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool _is_path_exists(
        tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path,
        const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        auto && file_path_rref_fixed = fix_long_path(std::move(path), throw_on_error);

        return boost::fs::exists(boost::fs::path{ file_path_rref_fixed.str(), codecvt });
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool
        _create_directory(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path,
            const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        auto && file_path_rref_fixed = fix_long_path(std::move(path), throw_on_error);

        if (throw_on_error) {
            return boost::fs::create_directory(boost::fs::path{ file_path_rref_fixed.str(), codecvt });
        }

        boost::system::error_code ec;
        return boost::fs::create_directory(boost::fs::path{ file_path_rref_fixed.str(), codecvt }, ec);
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool
        _create_directory_if_not_exist(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path,
            const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        auto && file_path_rref_fixed = fix_long_path(std::move(path), throw_on_error);

        boost::system::error_code ec;
        return boost::fs::create_directories(boost::fs::path{ file_path_rref_fixed.str(), codecvt }, ec);
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE void
        _create_directory_symlink(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> to_path,
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> from_path,
            const tackle::path_string_codecvt & to_codecvt,
            const tackle::path_string_codecvt & from_codecvt,
            bool throw_on_error)
    {
        auto && to_path_rref_fixed = fix_long_path(std::move(to_path), throw_on_error);
        auto && from_path_rref_fixed = fix_long_path(std::move(from_path), throw_on_error);

        if (throw_on_error) {
            return boost::fs::create_directory_symlink(
                boost::fs::path{ to_path_rref_fixed.str(), to_codecvt },
                boost::fs::path{ from_path_rref_fixed.str(), from_codecvt });
        }

        boost::system::error_code ec;
        return boost::fs::create_directory_symlink(
            boost::fs::path{ to_path_rref_fixed.str(), to_codecvt },
            boost::fs::path{ from_path_rref_fixed.str(), from_codecvt }, ec);
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool
        _create_directories(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path,
            const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        auto && file_path_rref_fixed = fix_long_path(std::move(path), throw_on_error);

        if (throw_on_error) {
            return boost::fs::create_directories(boost::fs::path{ file_path_rref_fixed.str(), codecvt });
        }

        boost::system::error_code ec;
        return boost::fs::create_directories(boost::fs::path{ file_path_rref_fixed.str(), codecvt }, ec);
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool
        _remove_directory(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path,
            const tackle::path_string_codecvt & codecvt, bool recursively, bool throw_on_error)
    {
        auto && file_path_rref_fixed = fix_long_path(std::move(path), throw_on_error);

        if (boost::fs::is_directory(boost::fs::path{ file_path_rref_fixed.str(), codecvt })) {
            if (!recursively) {
                if (throw_on_error) {
                    return boost::fs::remove(boost::fs::path{ file_path_rref_fixed.str(), codecvt });
                }

                boost::system::error_code ec;
                return boost::fs::remove(boost::fs::path{ file_path_rref_fixed.str(), codecvt }, ec);
            }

            if (throw_on_error) {
                boost::fs::remove_all(boost::fs::path{ file_path_rref_fixed.str(), codecvt });
            }
            else {
                boost::system::error_code ec;
                boost::fs::remove_all(boost::fs::path{ file_path_rref_fixed.str(), codecvt }, ec);
            }

            return true;
        }

        return false;
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool
        _remove_file(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path,
            const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        auto && file_path_rref_fixed = fix_long_path(std::move(path), throw_on_error);

        if (boost::fs::is_regular_file(boost::fs::path{ file_path_rref_fixed.str(), codecvt })) {
            if (throw_on_error) {
                return boost::fs::remove(boost::fs::path{ file_path_rref_fixed.str(), codecvt });
            }
            else {
                boost::system::error_code ec;
                return boost::fs::remove(boost::fs::path{ file_path_rref_fixed.str(), codecvt }, ec);
            }
        }

        return false;
    }

    template <class t_elem, class t_traits, class t_alloc, t_elem separator_char>
    FORCE_INLINE bool
        _remove_symlink(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, separator_char> path,
            const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        auto && file_path_rref_fixed = fix_long_path(std::move(path), throw_on_error);

        if (boost::fs::is_symlink(boost::fs::path{ file_path_rref_fixed.str(), codecvt })) {
            if (throw_on_error) {
                return boost::fs::remove(boost::fs::path{ file_path_rref_fixed.str(), codecvt });
            }
            else {
                boost::system::error_code ec;
                return boost::fs::remove(boost::fs::path{ file_path_rref_fixed.str(), codecvt }, ec);
            }
        }

        return false;
    }

    template <char separator_char>
    FORCE_INLINE std::string
        _get_file_name(
            tackle::basic_path_string<separator_char> path)
    {
        return separator_char == literal_separators<char>::forward_slash_char ?
            boost::fs::path{ std::move(path.str()) }.filename().generic_string() :
            boost::fs::path{ std::move(path.str()) }.filename().string();
    }

    template <wchar_t separator_char>
    FORCE_INLINE std::wstring
        _get_file_name(
            tackle::basic_path_wstring<separator_char> path)
    {
        return separator_char == literal_separators<wchar_t>::forward_slash_char ?
            boost::fs::path{ std::move(path.str()) }.filename().generic_wstring() :
            boost::fs::path{ std::move(path.str()) }.filename().wstring();
    }

    template <char separator_char>
    FORCE_INLINE std::string
        _get_file_name_stem(
            tackle::basic_path_string<separator_char> path)
    {
        return separator_char == literal_separators<char>::forward_slash_char ?
            boost::fs::path{ std::move(path.str()) }.stem().generic_string() :
            boost::fs::path{ std::move(path.str()) }.stem().string();
    }

    template <wchar_t separator_char>
    FORCE_INLINE std::wstring
        _get_file_name_stem(
            tackle::basic_path_wstring<separator_char> path)
    {
        return separator_char == literal_separators<wchar_t>::forward_slash_char ?
            boost::fs::path{ std::move(path.str()) }.stem().generic_wstring() :
            boost::fs::path{ std::move(path.str()) }.stem().wstring();
    }

    template <char separator_char>
    FORCE_INLINE tackle::basic_path_string<separator_char>
        _get_parent_path(
            tackle::basic_path_string<separator_char> path)
    {
        return tackle::basic_path_string<separator_char>{
            separator_char == literal_separators<char>::forward_slash_char ?
                boost::fs::path{ std::move(path.str()) }.parent_path().generic_string() :
                boost::fs::path{ std::move(path.str()) }.parent_path().string() };
    }

    template <wchar_t separator_char>
    FORCE_INLINE tackle::basic_path_wstring<separator_char>
        _get_parent_path(
            tackle::basic_path_wstring<separator_char> path)
    {
        return tackle::basic_path_wstring<separator_char>{
            separator_char == literal_separators<wchar_t>::forward_slash_char ?
                boost::fs::path{ std::move(path.str()) }.parent_path().generic_wstring() :
                boost::fs::path{ std::move(path.str()) }.parent_path().wstring() };
    }

    // windows can return different driver letter case in paths in case if under debugger or not, this function fixes that making a driver letter always be in uppercase
    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE tackle::path_basic_string<t_elem, t_traits, t_alloc, literal_separators<t_elem>::forward_slash_char>
        _fix_drive_letter_case_basic(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, literal_separators<t_elem>::forward_slash_char> path, const std::locale & loc)
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        const auto path_len = path.length();
        if (path_len >= 2) {
            // usual absolute windows path
            if (path[1] == literal_separators<t_elem>::colon_char) {
                path[0] = std::toupper(path[0], loc);
            }
        }
#else
        UTILITY_UNUSED_STATEMENT(loc);
#endif

        return path;
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE tackle::path_basic_string<t_elem, t_traits, t_alloc, literal_separators<t_elem>::backward_slash_char>
        _fix_drive_letter_case_basic(
            tackle::path_basic_string<t_elem, t_traits, t_alloc, literal_separators<t_elem>::backward_slash_char> path, const std::locale & loc)
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        const auto path_len = path.length();
        if (path_len >= 2) {
            // usual absolute windows path
            if (path[1] == literal_separators<t_elem>::colon_char) {
                path[0] = std::toupper(path[0], loc);
            }
            // UNC windows path
            else if (path_len >= 5 && path.substr(0, 4) == UTILITY_LITERAL_STRING("\\\\?\\", t_elem)) {
                path[4] = std::toupper(path[4], loc);
            }
        }
#else
        UTILITY_UNUSED_STATEMENT(loc);
#endif

        return path;
    }

    template <char separator_char>
    FORCE_INLINE tackle::basic_path_string<separator_char>
        _fix_drive_letter_case(
            tackle::basic_path_string<separator_char> path, const std::locale & loc)
    {
        return _fix_drive_letter_case_basic(std::move(path), loc);
    }

    template <wchar_t separator_char>
    FORCE_INLINE tackle::basic_path_wstring<separator_char>
        _fix_drive_letter_case(
            tackle::basic_path_wstring<separator_char> path, const std::locale & loc)
    {
        return _fix_drive_letter_case_basic(path, loc);
    }

    template <char separator_char>
    FORCE_INLINE tackle::basic_path_string<separator_char>
        _get_module_file_path(
            tackle::tag_basic_path_string<separator_char>, bool cached)
    {
        std::locale loc;

        if (cached) {
            static const auto s_cached_location =
                _fix_drive_letter_case<separator_char>(
                    tackle::basic_path_string<separator_char>{
                        separator_char == literal_separators<char>::forward_slash_char ?
                            boost::dll::program_location().generic_string() :
                            boost::dll::program_location().string() }, loc);
            return s_cached_location;
        }

        return _fix_drive_letter_case<separator_char>(
            tackle::basic_path_string<separator_char>{
                separator_char == literal_separators<char>::forward_slash_char ?
                    boost::dll::program_location().generic_string() :
                    boost::dll::program_location().string() }, loc);
    }

    template <wchar_t separator_char>
    FORCE_INLINE tackle::basic_path_wstring<separator_char>
        _get_module_file_path(
            tackle::tag_basic_path_wstring<separator_char>, bool cached)
    {
        std::locale loc;

        if (cached) {
            static const auto s_cached_location =
                _fix_drive_letter_case<separator_char>(
                    tackle::basic_path_wstring<separator_char>{
                        separator_char == literal_separators<wchar_t>::forward_slash_char ?
                            boost::dll::program_location().generic_wstring() :
                            boost::dll::program_location().wstring() }, loc);
            return s_cached_location;
        }

        return _fix_drive_letter_case<separator_char>(
            tackle::basic_path_wstring<separator_char>{
                separator_char == literal_separators<wchar_t>::forward_slash_char ?
                    boost::dll::program_location().generic_wstring() :
                    boost::dll::program_location().wstring() }, loc);
    }

    template <char separator_char>
    FORCE_INLINE tackle::basic_path_string<separator_char>
        _get_module_dir_path(
            tackle::tag_basic_path_string<separator_char>, bool cached)
    {
        std::locale loc;

        if (cached) {
            static const auto s_cached_location =
                _fix_drive_letter_case<separator_char>(
                    tackle::basic_path_string<separator_char>{
                        separator_char == literal_separators<char>::forward_slash_char ?
                            boost::dll::program_location().parent_path().generic_string() :
                            boost::dll::program_location().parent_path().string() }, loc);
            return s_cached_location;
        }

        return _fix_drive_letter_case<separator_char>(
            tackle::basic_path_string<separator_char>{
                separator_char == literal_separators<char>::forward_slash_char ?
                    boost::dll::program_location().parent_path().generic_string() :
                    boost::dll::program_location().parent_path().string() }, loc);
    }

    template <wchar_t separator_char>
    FORCE_INLINE tackle::basic_path_wstring<separator_char>
        _get_module_dir_path(
            tackle::tag_basic_path_wstring<separator_char>, bool cached)
    {
        std::locale loc;

        if (cached) {
            static const auto s_cached_location =
                _fix_drive_letter_case<separator_char>(
                    tackle::basic_path_wstring<separator_char>{
                        separator_char == literal_separators<wchar_t>::forward_slash_char ?
                            boost::dll::program_location().parent_path().generic_wstring() :
                            boost::dll::program_location().parent_path().wstring() }, loc);
            return s_cached_location;
        }

        return _fix_drive_letter_case<separator_char>(
            tackle::basic_path_wstring<separator_char>{
                separator_char == literal_separators<wchar_t>::forward_slash_char ?
                    boost::dll::program_location().parent_path().generic_wstring() :
                    boost::dll::program_location().parent_path().wstring() }, loc);
    }

    FORCE_INLINE std::string _get_host_name(utility::tag_string)
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        char buf[MAX_COMPUTERNAME_LENGTH + 1]{ '\0' };
        DWORD buf_size = UTILITY_CONSTEXPR_ARRAY_SIZE(buf);
        ::GetComputerNameA(buf, &buf_size);
        return buf;
#else
        char hostname[HOST_NAME_MAX + 1]{ '\0' };
        gethostname(hostname, HOST_NAME_MAX);

        // from Linux docs:
        //    gethostname() returns the null-terminated hostname in the character
        //    array name, which has a length of len bytes. If the null-terminated
        //    hostname is too large to fit, then the name is truncated, and no
        //    error is returned(but see NOTES below). POSIX.1 says that if such
        //    truncation occurs, then it is unspecified whether the returned buffer
        //    includes a terminating null byte.
        //
        // So, we have to set null-terminating character explicitly, just in case!
        hostname[HOST_NAME_MAX] = '\0';

        return hostname;
#endif
    }

    FORCE_INLINE std::wstring _get_host_name(utility::tag_wstring)
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        wchar_t buf[MAX_COMPUTERNAME_LENGTH + 1]{ '\0' };
        DWORD buf_size = UTILITY_CONSTEXPR_ARRAY_SIZE(buf);
        ::GetComputerNameW(buf, &buf_size);
        return buf;
#else
        char hostname[HOST_NAME_MAX + 1];
        gethostname(hostname, HOST_NAME_MAX);

        // from Linux docs:
        //    gethostname() returns the null-terminated hostname in the character
        //    array name, which has a length of len bytes. If the null-terminated
        //    hostname is too large to fit, then the name is truncated, and no
        //    error is returned(but see NOTES below). POSIX.1 says that if such
        //    truncation occurs, then it is unspecified whether the returned buffer
        //    includes a terminating null byte.
        //
        // So, we have to set null-terminating character explicitly, just in case!
        hostname[HOST_NAME_MAX] = '\0';

        return utility::convert_string_to_string(hostname, utility::tag_wstring{}, utility::tag_string_conv_utf8_tofrom_utf16{});
#endif
    }

    FORCE_INLINE std::string _get_user_name(utility::tag_string)
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        char buf[UNLEN + 1]{ '\0' };
        DWORD buf_size = UTILITY_CONSTEXPR_ARRAY_SIZE(buf);
        ::GetUserNameA(buf, &buf_size);
        return buf;
#else
        char username[LOGIN_NAME_MAX + 1]{ '\0' };
        getlogin_r(username, LOGIN_NAME_MAX);

        // just in case!
        username[LOGIN_NAME_MAX] = '\0';

        return username;
#endif
    }

    FORCE_INLINE std::wstring _get_user_name(utility::tag_wstring)
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        wchar_t buf[UNLEN + 1]{ '\0' };
        DWORD buf_size = UTILITY_CONSTEXPR_ARRAY_SIZE(buf);
        ::GetUserNameW(buf, &buf_size);
        return buf;
#else
        char username[LOGIN_NAME_MAX + 1]{ '\0' };
        getlogin_r(username, LOGIN_NAME_MAX);

        // just in case!
        username[LOGIN_NAME_MAX] = '\0';

        return utility::convert_string_to_string(username, utility::tag_wstring{}, utility::tag_string_conv_utf8_tofrom_utf16{});
#endif
    }

}

    uint64_t get_file_size(tackle::file_handle<char> file_handle)
    {
        return _get_file_size(std::move(file_handle));
    }

    uint64_t get_file_size(tackle::file_handle<wchar_t> file_handle)
    {
        return _get_file_size(std::move(file_handle));
    }

    bool is_files_equal(tackle::file_handle<char> left_file_handle, tackle::file_handle<char> right_file_handle, size_t read_block_size)
    {
        return _is_files_equal(std::move(left_file_handle), std::move(right_file_handle), read_block_size);
    }

    bool is_files_equal(tackle::file_handle<wchar_t> left_file_handle, tackle::file_handle<wchar_t> right_file_handle, size_t read_block_size)
    {
        return _is_files_equal(std::move(left_file_handle), std::move(right_file_handle), read_block_size);
    }

#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_NETWORK_UNC)

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool convert_local_to_network_unc_path(tackle::generic_path_string from_path, tackle::unc_path_string & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_network_unc_path(from_path_rref, to_path, throw_on_error);
    }

    bool convert_local_to_network_unc_path(tackle::generic_path_wstring from_path, tackle::unc_path_wstring & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_network_unc_path(from_path_rref, to_path, throw_on_error);
    }

    bool convert_local_to_network_unc_path(tackle::native_path_string from_path, tackle::unc_path_string & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_network_unc_path(from_path_rref, to_path, throw_on_error);
    }

    bool convert_local_to_network_unc_path(tackle::native_path_wstring from_path, tackle::unc_path_wstring & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_network_unc_path(from_path_rref, to_path, throw_on_error);
    }

    tackle::unc_path_string convert_local_to_network_unc_path(tackle::generic_path_string from_path, tackle::tag_unc_path_string, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_network_unc_path(from_path_rref, tackle::tag_unc_path_string{}, throw_on_error);
    }

    tackle::unc_path_wstring convert_local_to_network_unc_path(tackle::generic_path_wstring from_path, tackle::tag_unc_path_wstring, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_network_unc_path(from_path_rref, tackle::tag_unc_path_wstring{}, throw_on_error);
    }

    tackle::unc_path_string convert_local_to_network_unc_path(tackle::native_path_string from_path, tackle::tag_unc_path_string, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_network_unc_path(from_path_rref, tackle::tag_unc_path_string{}, throw_on_error);
    }

    tackle::unc_path_wstring convert_local_to_network_unc_path(tackle::native_path_wstring from_path, tackle::tag_unc_path_wstring, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_network_unc_path(from_path_rref, tackle::tag_unc_path_wstring{}, throw_on_error);
    }

    bool convert_network_unc_to_local_path(tackle::unc_path_string from_path, tackle::generic_path_string & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_network_unc_to_local_path(from_path_rref, to_path, throw_on_error);
    }

    bool convert_network_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::generic_path_wstring & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_network_unc_to_local_path(from_path_rref, to_path, throw_on_error);
    }

    bool convert_network_unc_to_local_path(tackle::unc_path_string from_path, tackle::native_path_string & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_network_unc_to_local_path(from_path_rref, to_path, throw_on_error);
    }

    bool convert_network_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::native_path_wstring & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_network_unc_to_local_path(from_path_rref, to_path, throw_on_error);
    }

    tackle::generic_path_string convert_network_unc_to_local_path(tackle::unc_path_string from_path, tackle::tag_generic_path_string, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_network_unc_to_local_path(from_path_rref, tackle::tag_generic_path_basic_string<char>{}, throw_on_error);
    }

    tackle::generic_path_wstring convert_network_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::tag_generic_path_wstring, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_network_unc_to_local_path(from_path_rref, tackle::tag_generic_path_basic_string<wchar_t>{}, throw_on_error);
    }

    tackle::native_path_string convert_network_unc_to_local_path(tackle::unc_path_string from_path, tackle::tag_native_path_string, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_network_unc_to_local_path(from_path_rref, tackle::tag_native_path_basic_string<char>{}, throw_on_error);
    }

    tackle::native_path_wstring convert_network_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::tag_native_path_wstring, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_network_unc_to_local_path(from_path_rref, tackle::tag_native_path_basic_string<wchar_t>{}, throw_on_error);
    }
#endif

#endif

    bool convert_local_to_local_unc_path(tackle::generic_path_string from_path, tackle::unc_path_string & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_local_unc_path(from_path_rref, to_path, throw_on_error);
    }

    bool convert_local_to_local_unc_path(tackle::generic_path_wstring from_path, tackle::unc_path_wstring & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_local_unc_path(from_path_rref, to_path, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool convert_local_to_local_unc_path(tackle::native_path_string from_path, tackle::unc_path_string & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_local_unc_path(from_path_rref, to_path, throw_on_error);
    }

    bool convert_local_to_local_unc_path(tackle::native_path_wstring from_path, tackle::unc_path_wstring & to_path, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_local_unc_path(from_path_rref, to_path, throw_on_error);
    }
#endif

    tackle::unc_path_string convert_local_to_local_unc_path(tackle::generic_path_string from_path, tackle::tag_unc_path_string, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_local_unc_path(from_path_rref, tackle::tag_unc_path_string{}, throw_on_error);
    }

    tackle::unc_path_wstring convert_local_to_local_unc_path(tackle::generic_path_wstring from_path, tackle::tag_unc_path_wstring, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_local_unc_path(from_path_rref, tackle::tag_unc_path_wstring{}, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::unc_path_string convert_local_to_local_unc_path(tackle::native_path_string from_path, tackle::tag_unc_path_string, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_local_unc_path(from_path_rref, tackle::tag_unc_path_string{}, throw_on_error);
    }

    tackle::unc_path_wstring convert_local_to_local_unc_path(tackle::native_path_wstring from_path, tackle::tag_unc_path_wstring, bool throw_on_error)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_to_local_unc_path(from_path_rref, tackle::tag_unc_path_wstring{}, throw_on_error);
    }
#endif

    bool convert_local_unc_to_local_path(tackle::unc_path_string from_path, tackle::generic_path_string & to_path)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_unc_to_local_path(from_path_rref, to_path);
    }

    bool convert_local_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::generic_path_wstring & to_path)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_unc_to_local_path(from_path_rref, to_path);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool convert_local_unc_to_local_path(tackle::unc_path_string from_path, tackle::native_path_string & to_path)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_unc_to_local_path(from_path_rref, to_path);
    }

    bool convert_local_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::native_path_wstring & to_path)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_unc_to_local_path(from_path_rref, to_path);
    }
#endif

    tackle::generic_path_string convert_local_unc_to_local_path(tackle::unc_path_string from_path, tackle::tag_generic_path_string)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_unc_to_local_path(from_path_rref, tackle::tag_generic_path_basic_string<char>{});
    }

    tackle::generic_path_wstring convert_local_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::tag_generic_path_wstring)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_unc_to_local_path(from_path_rref, tackle::tag_generic_path_basic_string<wchar_t>{});
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string convert_local_unc_to_local_path(tackle::unc_path_string from_path, tackle::tag_native_path_string)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_unc_to_local_path(from_path_rref, tackle::tag_native_path_basic_string<char>{});
    }

    tackle::native_path_wstring convert_local_unc_to_local_path(tackle::unc_path_wstring from_path, tackle::tag_native_path_wstring)
    {
        auto && from_path_rref = std::move(from_path);

        return _convert_local_unc_to_local_path(from_path_rref, tackle::tag_native_path_basic_string<wchar_t>{});
    }
#endif

    tackle::native_path_string fix_long_path(tackle::generic_path_string file_path, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _fix_long_path(file_path_rref, throw_on_error);
    }

    tackle::native_path_wstring fix_long_path(tackle::generic_path_wstring file_path, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _fix_long_path(file_path_rref, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string fix_long_path(tackle::native_path_string file_path, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _fix_long_path(file_path_rref, throw_on_error);
    }

    tackle::native_path_wstring fix_long_path(tackle::native_path_wstring file_path, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _fix_long_path(file_path_rref, throw_on_error);
    }
#endif

    tackle::generic_path_string unfix_long_path(tackle::native_path_string file_path, tackle::tag_generic_path_string, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _unfix_long_path(file_path_rref, tackle::tag_generic_path_string{}, throw_on_error);
    }

    tackle::generic_path_wstring unfix_long_path(tackle::native_path_wstring file_path, tackle::tag_generic_path_wstring, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _unfix_long_path(file_path_rref, tackle::tag_generic_path_wstring{}, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string unfix_long_path(tackle::native_path_string file_path, tackle::tag_native_path_string, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _unfix_long_path(file_path_rref, tackle::tag_native_path_string{}, throw_on_error);
    }

    tackle::native_path_wstring unfix_long_path(tackle::native_path_wstring file_path, tackle::tag_native_path_wstring, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _unfix_long_path<>(file_path_rref, tackle::tag_native_path_wstring{}, throw_on_error);
    }
#endif

    tackle::file_handle<char> recreate_file(tackle::generic_path_string file_path, const tackle::path_string_codecvt & codecvt, const char * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _recreate_file(file_path_rref, codecvt, mode, share_flags, size, fill_by, throw_on_error);
    }

    tackle::file_handle<wchar_t> recreate_file(tackle::generic_path_wstring file_path, const tackle::path_string_codecvt & codecvt, const wchar_t * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _recreate_file(file_path_rref, codecvt, mode, share_flags, size, fill_by, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_file_handle<char> recreate_file(tackle::native_path_string file_path, const tackle::path_string_codecvt & codecvt, const char * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _recreate_file(file_path_rref, codecvt, mode, share_flags, size, fill_by, throw_on_error);
    }

    tackle::native_file_handle<wchar_t> recreate_file(tackle::native_path_wstring file_path, const tackle::path_string_codecvt & codecvt, const wchar_t * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _recreate_file(file_path_rref, codecvt, mode, share_flags, size, fill_by, throw_on_error);
    }
#endif

    tackle::generic_file_handle<char> create_file(tackle::generic_path_string file_path, const tackle::path_string_codecvt & codecvt, const char * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _create_file(file_path_rref, codecvt, mode, share_flags, size, fill_by, throw_on_error);
    }

    tackle::generic_file_handle<wchar_t> create_file(tackle::generic_path_wstring file_path, const tackle::path_string_codecvt & codecvt, const wchar_t * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _create_file(file_path_rref, codecvt, mode, share_flags, size, fill_by, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_file_handle<char> create_file(tackle::native_path_string file_path, const tackle::path_string_codecvt & codecvt, const char * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _create_file(file_path_rref, codecvt, mode, share_flags, size, fill_by, throw_on_error);
    }

    tackle::native_file_handle<wchar_t> create_file(tackle::native_path_wstring file_path, const tackle::path_string_codecvt & codecvt, const wchar_t * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _create_file(file_path_rref, codecvt, mode, share_flags, size, fill_by, throw_on_error);
    }
#endif

    tackle::generic_file_handle<char> open_file(tackle::generic_path_string file_path, const tackle::path_string_codecvt & codecvt, const char * mode, SharedAccess share_flags,
        size_t creation_size, size_t resize_if_existed, uint32_t fill_by_on_creation, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _open_file(file_path_rref, codecvt, mode, share_flags, creation_size, resize_if_existed, fill_by_on_creation, throw_on_error);
    }

    tackle::generic_file_handle<wchar_t> open_file(tackle::generic_path_wstring file_path, const tackle::path_string_codecvt & codecvt, const wchar_t * mode, SharedAccess share_flags,
        size_t creation_size, size_t resize_if_existed, uint32_t fill_by_on_creation, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _open_file(file_path_rref, codecvt, mode, share_flags, creation_size, resize_if_existed, fill_by_on_creation, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_file_handle<char> open_file(tackle::native_path_string file_path, const tackle::path_string_codecvt & codecvt, const char * mode, SharedAccess share_flags,
        size_t creation_size, size_t resize_if_existed, uint32_t fill_by_on_creation, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _open_file(file_path_rref, codecvt, mode, share_flags, creation_size, resize_if_existed, fill_by_on_creation, throw_on_error);
    }

    tackle::native_file_handle<wchar_t> open_file(tackle::native_path_wstring file_path, const tackle::path_string_codecvt & codecvt, const wchar_t * mode, SharedAccess share_flags,
        size_t creation_size, size_t resize_if_existed, uint32_t fill_by_on_creation, bool throw_on_error)
    {
        auto && file_path_rref = std::move(file_path);

        return _open_file(file_path_rref, codecvt, mode, share_flags, creation_size, resize_if_existed, fill_by_on_creation, throw_on_error);
    }
#endif

    bool is_directory_path(tackle::generic_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_directory_path(std::move(path), codecvt, throw_on_error);
    }

    bool is_directory_path(tackle::generic_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_directory_path(std::move(path), codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool is_directory_path(tackle::native_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_directory_path(std::move(path), codecvt, throw_on_error);
    }

    bool is_directory_path(tackle::native_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_directory_path(std::move(path), codecvt, throw_on_error);
    }
#endif

    bool is_regular_file(tackle::generic_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_regular_file(std::move(path), codecvt, throw_on_error);
    }

    bool is_regular_file(tackle::generic_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_regular_file(std::move(path), codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool is_regular_file(tackle::native_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_regular_file(std::move(path), codecvt, throw_on_error);
    }

    bool is_regular_file(tackle::native_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_regular_file(std::move(path), codecvt, throw_on_error);
    }
#endif

    bool is_same_file(tackle::generic_path_string left_path, tackle::generic_path_string right_path,
        const tackle::path_string_codecvt & left_codecvt, const tackle::path_string_codecvt & right_codecvt, bool throw_on_error)
    {
        return _is_same_file(std::move(left_path), std::move(right_path), left_codecvt, right_codecvt, throw_on_error);
    }

    bool is_same_file(tackle::generic_path_wstring left_path, tackle::generic_path_wstring right_path,
        const tackle::path_string_codecvt & left_codecvt, const tackle::path_string_codecvt & right_codecvt, bool throw_on_error)
    {
        return _is_same_file(std::move(left_path), std::move(right_path), left_codecvt, right_codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool is_same_file(tackle::native_path_string left_path, tackle::native_path_string right_path,
        const tackle::path_string_codecvt & left_codecvt, const tackle::path_string_codecvt & right_codecvt, bool throw_on_error)
    {
        return _is_same_file(std::move(left_path), std::move(right_path), left_codecvt, right_codecvt, throw_on_error);
    }

    bool is_same_file(tackle::native_path_wstring left_path, tackle::native_path_wstring right_path,
        const tackle::path_string_codecvt & left_codecvt, const tackle::path_string_codecvt & right_codecvt, bool throw_on_error)
    {
        return _is_same_file(std::move(left_path), std::move(right_path), left_codecvt, right_codecvt, throw_on_error);
    }
#endif

    bool is_symlink_path(tackle::generic_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_symlink_path(std::move(path), codecvt, throw_on_error);
    }

    bool is_symlink_path(tackle::generic_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_symlink_path(std::move(path), codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool is_symlink_path(tackle::native_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_symlink_path(std::move(path), codecvt, throw_on_error);
    }

    bool is_symlink_path(tackle::native_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_symlink_path(std::move(path), codecvt, throw_on_error);
    }
#endif

    bool is_path_exists(tackle::generic_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_path_exists(std::move(path), codecvt, throw_on_error);
    }

    bool is_path_exists(tackle::generic_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_path_exists(std::move(path), codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool is_path_exists(tackle::native_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_path_exists(std::move(path), codecvt, throw_on_error);
    }

    bool is_path_exists(tackle::native_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _is_path_exists(std::move(path), codecvt, throw_on_error);
    }
#endif

    bool create_directory(tackle::generic_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directory(std::move(path), codecvt, throw_on_error);
    }

    bool create_directory(tackle::generic_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directory(std::move(path), codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool create_directory(tackle::native_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directory(std::move(path), codecvt, throw_on_error);
    }

    bool create_directory(tackle::native_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directory(std::move(path), codecvt, throw_on_error);
    }
#endif

    bool create_directory_if_not_exist(tackle::generic_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directory_if_not_exist(std::move(path), codecvt, throw_on_error);
    }

    bool create_directory_if_not_exist(tackle::generic_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directory_if_not_exist(std::move(path), codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool create_directory_if_not_exist(tackle::native_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directory_if_not_exist(std::move(path), codecvt, throw_on_error);
    }

    bool create_directory_if_not_exist(tackle::native_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directory_if_not_exist(std::move(path), codecvt, throw_on_error);
    }
#endif

    void create_directory_symlink(tackle::generic_path_string to, tackle::generic_path_string from,
        const tackle::path_string_codecvt & to_codecvt, const tackle::path_string_codecvt & from_codecvt, bool throw_on_error)
    {
        return _create_directory_symlink(std::move(to), std::move(from), to_codecvt, from_codecvt, throw_on_error);
    }

    void create_directory_symlink(tackle::generic_path_wstring to, tackle::generic_path_wstring from,
        const tackle::path_string_codecvt & to_codecvt, const tackle::path_string_codecvt & from_codecvt, bool throw_on_error)
    {
        return _create_directory_symlink(std::move(to), std::move(from), to_codecvt, from_codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    void create_directory_symlink(tackle::native_path_string to, tackle::native_path_string from,
        const tackle::path_string_codecvt & to_codecvt, const tackle::path_string_codecvt & from_codecvt, bool throw_on_error)
    {
        return _create_directory_symlink(std::move(to), std::move(from), to_codecvt, from_codecvt, throw_on_error);
    }

    void create_directory_symlink(tackle::native_path_wstring to, tackle::native_path_wstring from,
        const tackle::path_string_codecvt & to_codecvt, const tackle::path_string_codecvt & from_codecvt, bool throw_on_error)
    {
        return _create_directory_symlink(std::move(to), std::move(from), to_codecvt, from_codecvt, throw_on_error);
    }
#endif

    bool create_directories(tackle::generic_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directories(std::move(path), codecvt, throw_on_error);
    }

    bool create_directories(tackle::generic_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directories(std::move(path), codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool create_directories(tackle::native_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directories(std::move(path), codecvt, throw_on_error);
    }

    bool create_directories(tackle::native_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _create_directories(std::move(path), codecvt, throw_on_error);
    }
#endif

    bool remove_directory(tackle::generic_path_string path, const tackle::path_string_codecvt & codecvt, bool recursively, bool throw_on_error)
    {
        return _remove_directory(std::move(path), codecvt, recursively, throw_on_error);
    }

    bool remove_directory(tackle::generic_path_wstring path, const tackle::path_string_codecvt & codecvt, bool recursively, bool throw_on_error)
    {
        return _remove_directory(std::move(path), codecvt, recursively, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool remove_directory(tackle::native_path_string path, const tackle::path_string_codecvt & codecvt, bool recursively, bool throw_on_error)
    {
        return _remove_directory(std::move(path), codecvt, recursively, throw_on_error);
    }

    bool remove_directory(tackle::native_path_wstring path, const tackle::path_string_codecvt & codecvt, bool recursively, bool throw_on_error)
    {
        return _remove_directory(std::move(path), codecvt, recursively, throw_on_error);
    }
#endif

    bool remove_file(tackle::generic_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _remove_file(std::move(path), codecvt, throw_on_error);
    }

    bool remove_file(tackle::generic_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _remove_file(std::move(path), codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool remove_file(tackle::native_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _remove_file(std::move(path), codecvt, throw_on_error);
    }

    bool remove_file(tackle::native_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _remove_file(std::move(path), codecvt, throw_on_error);
    }
#endif

    bool remove_symlink(tackle::generic_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _remove_symlink(std::move(path), codecvt, throw_on_error);
    }

    bool remove_symlink(tackle::generic_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _remove_symlink(std::move(path), codecvt, throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool remove_symlink(tackle::native_path_string path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _remove_symlink(std::move(path), codecvt, throw_on_error);
    }

    bool remove_symlink(tackle::native_path_wstring path, const tackle::path_string_codecvt & codecvt, bool throw_on_error)
    {
        return _remove_symlink(std::move(path), codecvt, throw_on_error);
    }
#endif

    bool is_relative_path(tackle::generic_path_string path)
    {
        return _is_relative_path(std::move(path));
    }

    bool is_relative_path(tackle::generic_path_wstring path)
    {
        return _is_relative_path(std::move(path));
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool is_relative_path(tackle::native_path_string path)
    {
        return _is_relative_path(std::move(path));
    }

    bool is_relative_path(tackle::native_path_wstring path)
    {
        return _is_relative_path(std::move(path));
    }
#endif

    bool is_absolute_path(tackle::generic_path_string path)
    {
        return _is_absolute_path(std::move(path));
    }

    bool is_absolute_path(tackle::generic_path_wstring path)
    {
        return _is_absolute_path(std::move(path));
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    bool is_absolute_path(tackle::native_path_string path)
    {
        return _is_absolute_path(std::move(path));
    }

    bool is_absolute_path(tackle::native_path_wstring path)
    {
        return _is_absolute_path(std::move(path));
    }
#endif

    tackle::generic_path_string get_relative_path(tackle::generic_path_string from_path, tackle::generic_path_string to_path, bool throw_on_error)
    {
        return _get_relative_path(std::move(from_path), std::move(to_path), throw_on_error);
    }

    tackle::generic_path_wstring get_relative_path(tackle::generic_path_wstring from_path, tackle::generic_path_wstring to_path, bool throw_on_error)
    {
        return _get_relative_path(std::move(from_path), std::move(to_path), throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string get_relative_path(tackle::native_path_string from_path, tackle::native_path_string to_path, bool throw_on_error)
    {
        return _get_relative_path(std::move(from_path), std::move(to_path), throw_on_error);
    }

    tackle::native_path_wstring get_relative_path(tackle::native_path_wstring from_path, tackle::native_path_wstring to_path, bool throw_on_error)
    {
        return _get_relative_path(std::move(from_path), std::move(to_path), throw_on_error);
    }
#endif

    tackle::generic_path_string get_absolute_path(tackle::generic_path_string from_path, tackle::generic_path_string to_path)
    {
        return _get_absolute_path(std::move(from_path), std::move(to_path));
    }

    tackle::generic_path_wstring get_absolute_path(tackle::generic_path_wstring from_path, tackle::generic_path_wstring to_path)
    {
        return _get_absolute_path(std::move(from_path), std::move(to_path));
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string get_absolute_path(tackle::native_path_string from_path, tackle::native_path_string to_path)
    {
        return _get_absolute_path(std::move(from_path), std::move(to_path));
    }

    tackle::native_path_wstring get_absolute_path(tackle::native_path_wstring from_path, tackle::native_path_wstring to_path)
    {
        return _get_absolute_path(std::move(from_path), std::move(to_path));
    }
#endif

    tackle::generic_path_string get_absolute_path(tackle::generic_path_string path, bool throw_on_error)
    {
        return _get_absolute_path(std::move(path), throw_on_error);
    }

    tackle::generic_path_wstring get_absolute_path(tackle::generic_path_wstring path, bool throw_on_error)
    {
        return _get_absolute_path(std::move(path), throw_on_error);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string get_absolute_path(tackle::native_path_string path, bool throw_on_error)
    {
        return _get_absolute_path(std::move(path), throw_on_error);
    }

    tackle::native_path_wstring get_absolute_path(tackle::native_path_wstring path, bool throw_on_error)
    {
        return _get_absolute_path(std::move(path), throw_on_error);
    }
#endif

    tackle::generic_path_string get_current_path(bool throw_on_error, tackle::tag_generic_path_string)
    {
        return _get_current_path(throw_on_error, tackle::tag_generic_path_string{});
    }

    tackle::generic_path_wstring get_current_path(bool throw_on_error, tackle::tag_generic_path_wstring)
    {
        return _get_current_path(throw_on_error, tackle::tag_generic_path_wstring{});
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string get_current_path(bool throw_on_error, tackle::tag_native_path_string)
    {
        return _get_current_path(throw_on_error, tackle::tag_native_path_string{});
    }

    tackle::native_path_wstring get_current_path(bool throw_on_error, tackle::tag_native_path_wstring)
    {
        return _get_current_path(throw_on_error, tackle::tag_native_path_wstring{});
    }
#endif

    std::string get_file_name(tackle::generic_path_string path)
    {
        return _get_file_name(std::move(path));
    }

    std::wstring get_file_name(tackle::generic_path_wstring path)
    {
        return _get_file_name(std::move(path));
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    std::string get_file_name(tackle::native_path_string path)
    {
        return _get_file_name(std::move(path));
    }

    std::wstring get_file_name(tackle::native_path_wstring path)
    {
        return _get_file_name(std::move(path));
    }
#endif

    std::string get_file_name_stem(tackle::generic_path_string path)
    {
        return _get_file_name_stem(std::move(path));
    }

    std::wstring get_file_name_stem(tackle::generic_path_wstring path)
    {
        return _get_file_name_stem(std::move(path));
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    std::string get_file_name_stem(tackle::native_path_string path)
    {
        return _get_file_name_stem(std::move(path));
    }

    std::wstring get_file_name_stem(tackle::native_path_wstring path)
    {
        return _get_file_name_stem(std::move(path));
    }
#endif

    tackle::generic_path_string get_parent_path(tackle::generic_path_string path)
    {
        return _get_parent_path(std::move(path));
    }

    tackle::generic_path_wstring get_parent_path(tackle::generic_path_wstring path)
    {
        return _get_parent_path(std::move(path));
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string get_parent_path(tackle::native_path_string path)
    {
        return _get_parent_path(std::move(path));
    }

    tackle::native_path_wstring get_parent_path(tackle::native_path_wstring path)
    {
        return _get_parent_path(std::move(path));
    }
#endif

    tackle::generic_path_string get_module_file_path(tackle::tag_generic_path_string, bool cached)
    {
        return _get_module_file_path(tackle::tag_generic_path_string{}, cached);
    }

    tackle::generic_path_wstring get_module_file_path(tackle::tag_generic_path_wstring, bool cached)
    {
        return _get_module_file_path(tackle::tag_generic_path_wstring{}, cached);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string get_module_file_path(tackle::tag_native_path_string, bool cached)
    {
        return _get_module_file_path(tackle::tag_native_path_string{}, cached);
    }

    tackle::native_path_wstring get_module_file_path(tackle::tag_native_path_wstring, bool cached)
    {
        return _get_module_file_path(tackle::tag_native_path_wstring{}, cached);
    }
#endif

    tackle::generic_path_string get_module_dir_path(tackle::tag_generic_path_string, bool cached)
    {
        return _get_module_dir_path(tackle::tag_generic_path_string{}, cached);
    }

    tackle::generic_path_wstring get_module_dir_path(tackle::tag_generic_path_wstring, bool cached)
    {
        return _get_module_dir_path(tackle::tag_generic_path_wstring{}, cached);
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string get_module_dir_path(tackle::tag_native_path_string, bool cached)
    {
        return _get_module_dir_path(tackle::tag_native_path_string{}, cached);
    }

    tackle::native_path_wstring get_module_dir_path(tackle::tag_native_path_wstring, bool cached)
    {
        return _get_module_dir_path(tackle::tag_native_path_wstring{}, cached);
    }
#endif

    tackle::generic_path_string get_lexically_normal_path(tackle::generic_path_string path)
    {
        return _get_lexically_normal_path(std::move(path));
    }

    tackle::generic_path_wstring get_lexically_normal_path(tackle::generic_path_wstring path)
    {
        return _get_lexically_normal_path(std::move(path));
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string get_lexically_normal_path(tackle::native_path_string path)
    {
        return _get_lexically_normal_path(std::move(path));
    }

    tackle::native_path_wstring get_lexically_normal_path(tackle::native_path_wstring path)
    {
        return _get_lexically_normal_path(std::move(path));
    }
#endif

    tackle::generic_path_string get_lexically_relative_path(tackle::generic_path_string from_path, tackle::generic_path_string to_path)
    {
        return _get_lexically_relative_path(std::move(from_path), std::move(to_path));
    }

    tackle::generic_path_wstring get_lexically_relative_path(tackle::generic_path_wstring from_path, tackle::generic_path_wstring to_path)
    {
        return _get_lexically_relative_path(std::move(from_path), std::move(to_path));
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string get_lexically_relative_path(tackle::native_path_string from_path, tackle::native_path_string to_path)
    {
        return _get_lexically_relative_path(std::move(from_path), std::move(to_path));
    }

    tackle::native_path_wstring get_lexically_relative_path(tackle::native_path_wstring from_path, tackle::native_path_wstring to_path)
    {
        return _get_lexically_relative_path(std::move(from_path), std::move(to_path));
    }
#endif

    tackle::generic_path_string convert_to_generic_path(const char * path, size_t len)
    {
        return _convert_to_generic_path(path, len);
    }

    tackle::generic_path_wstring convert_to_generic_path(const wchar_t * path, size_t len)
    {
        return _convert_to_generic_path(path, len);
    }

    tackle::generic_path_string convert_to_generic_path(std::string path)
    {
        return _convert_to_generic_path(std::move(path));
    }

    tackle::generic_path_wstring convert_to_generic_path(std::wstring path)
    {
        return _convert_to_generic_path(std::move(path));
    }

    tackle::generic_path_string convert_to_generic_path(tackle::generic_path_string path)
    {
        return _convert_to_generic_path(std::move(path));
    }

    tackle::generic_path_wstring convert_to_generic_path(tackle::generic_path_wstring path)
    {
        return _convert_to_generic_path(std::move(path));
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::generic_path_string convert_to_generic_path(tackle::native_path_string path)
    {
        return _convert_to_generic_path(std::move(path));
    }

    tackle::generic_path_wstring convert_to_generic_path(tackle::native_path_wstring path)
    {
        return _convert_to_generic_path(std::move(path));
    }
#endif

    tackle::native_path_string convert_to_native_path(const char * path, size_t len)
    {
        return _convert_to_native_path(path, len);
    }

    tackle::native_path_wstring convert_to_native_path(const wchar_t * path, size_t len)
    {
        return _convert_to_native_path(path, len);
    }

    tackle::native_path_string convert_to_native_path(std::string path)
    {
        return _convert_to_native_path(std::move(path));
    }

    tackle::native_path_wstring convert_to_native_path(std::wstring path)
    {
        return _convert_to_native_path(std::move(path));
    }

    tackle::native_path_string convert_to_native_path(tackle::generic_path_string path)
    {
        return _convert_to_native_path(std::move(path));
    }

    tackle::native_path_wstring convert_to_native_path(tackle::generic_path_wstring path)
    {
        return _convert_to_native_path(std::move(path));
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string convert_to_native_path(tackle::native_path_string path)
    {
        return _convert_to_native_path(std::move(path));
    }

    tackle::native_path_wstring convert_to_native_path(tackle::native_path_wstring path)
    {
        return _convert_to_native_path(std::move(path));
    }
#endif

    tackle::generic_path_string truncate_path_relative_prefix(tackle::generic_path_string path)
    {
        return tackle::generic_path_string{ std::regex_replace(path.str(), std::regex{ "(\\.+/)+" }, "") };
    }

    tackle::generic_path_wstring truncate_path_relative_prefix(tackle::generic_path_wstring path)
    {
        return tackle::generic_path_wstring{ std::regex_replace(path.str(), std::wregex{ L"(\\.+/)+" }, L"") };
    }

#if defined(UTILITY_PLATFORM_WINDOWS)
    tackle::native_path_string truncate_path_relative_prefix(tackle::native_path_string path)
    {
        return tackle::native_path_string{ std::regex_replace(path.str(), std::regex{ "(\\.+\\\\)+" }, "") };
    }

    tackle::native_path_wstring truncate_path_relative_prefix(tackle::native_path_wstring path)
    {
        return tackle::native_path_wstring{ std::regex_replace(std::move(path), std::wregex{ L"(\\.+\\\\)+" }, L"") };
    }
#endif

    std::string get_host_name(utility::tag_string t, bool cached)
    {
        if (cached) {
            static const auto s_cached_name = _get_host_name(t);
            return s_cached_name;
        }

        return _get_host_name(t);
    }

    std::wstring get_host_name(utility::tag_wstring t, bool cached)
    {
        if (cached) {
            static const auto s_cached_name = _get_host_name(t);
            return s_cached_name;
        }

        return _get_host_name(t);
    }

    std::string get_user_name(utility::tag_string t, bool cached)
    {
        if (cached) {
            static const auto s_cached_name = _get_user_name(t);
            return s_cached_name;
        }

        return _get_user_name(t);
    }

    std::wstring get_user_name(utility::tag_wstring t, bool cached)
    {
        if (cached) {
            static const auto s_cached_name = _get_user_name(t);
            return s_cached_name;
        }

        return _get_user_name(t);
    }

    std::string get_module_file_name(utility::tag_string, bool cached)
    {
        if (cached) {
            static const auto s_cached_name = boost::dll::program_location().filename().string();
            return s_cached_name;
        }

        return boost::dll::program_location().filename().string();
    }

    std::wstring get_module_file_name(utility::tag_wstring, bool cached)
    {
        if (cached) {
            static const auto s_cached_name = boost::dll::program_location().filename().wstring();
            return s_cached_name;
        }

        return boost::dll::program_location().filename().wstring();
    }

}
