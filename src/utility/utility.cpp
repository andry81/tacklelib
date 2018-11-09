#include <utility/utility.hpp>
#include <utility/assert.hpp>
#include <utility/locale.hpp>

#include <tackle/file_handle.hpp>

#include <boost/filesystem.hpp>
#include <boost/dll.hpp>

#include <vector>


namespace boost
{
    namespace fs = filesystem;
}

namespace utility {

namespace {

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE uint64_t
        _get_file_size(const tackle::FileHandle<t_elem, t_traits, t_alloc> & file_handle)
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

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _is_files_equal(
            const tackle::FileHandle<t_elem, t_traits, t_alloc> & left_file_handle,
            const tackle::FileHandle<t_elem, t_traits, t_alloc> & right_file_handle)
    {
        const uint64_t left_file_size = get_file_size(left_file_handle);
        const uint64_t right_file_size = get_file_size(right_file_handle);
        if (left_file_size != right_file_size)
            return false;

        using LocalBufSharedPtr = std::shared_ptr<uint8_t>;

        const static size_t s_local_buf_size = 4 * 1024 * 1024; // 4MB

        LocalBufSharedPtr left_local_buf_ptr = LocalBufSharedPtr(new uint8_t[s_local_buf_size], std::default_delete<uint8_t[]>());
        LocalBufSharedPtr right_local_buf_ptr = LocalBufSharedPtr(new uint8_t[s_local_buf_size], std::default_delete<uint8_t[]>());

        while (!feof(left_file_handle.get())) {
            const size_t left_read_byte_size = fread(left_local_buf_ptr.get(), 1, s_local_buf_size, left_file_handle.get());
            const size_t right_read_byte_size = fread(right_local_buf_ptr.get(), 1, s_local_buf_size, right_file_handle.get());
            if (left_read_byte_size != right_read_byte_size)
                return false;

            if (std::memcmp(left_local_buf_ptr.get(), right_local_buf_ptr.get(), left_read_byte_size))
                return false;
        }

        return true;
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

        return fopen(file_name, mode);
#else
        return nullptr;
#error platform is not implemented
#endif
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE tackle::FileHandle<t_elem, t_traits, t_alloc>
        _recreate_file(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & file_path,
            const t_elem * mode, SharedAccess share_flags, size_t size, uint32_t fill_by)
    {
        FILE * file_ptr = _fopen(file_path.c_str(), mode, share_flags);


        tackle::FileHandle<t_elem, t_traits, t_alloc> file_handle_ptr =
            tackle::FileHandle<t_elem, t_traits, t_alloc>(file_ptr, file_path);
        if (!file_ptr) {
            DEBUG_BREAK_IN_DEBUGGER(true);
            throw std::system_error{ errno, std::system_category(), utility::convert_utf16_to_utf8_string(file_path) };
        }

        if (size) {
            std::vector<uint32_t> chunk;
            chunk.resize(4096, fill_by);

            const size_t num_whole_chunks = size / chunk.size();
            for (size_t i = 0; i < num_whole_chunks; i++) {
                const size_t write_size = fwrite(&chunk[0], 1, chunk.size(), file_ptr);
                const int file_err = ferror(file_ptr);
                if (write_size < chunk.size()) {
                    DEBUG_BREAK_IN_DEBUGGER(true);
                    throw std::system_error{ file_err, std::system_category(), utility::convert_utf16_to_utf8_string(file_path) };
                }
            }

            const size_t chunk_reminder = size % chunk.size();
            const size_t write_size = fwrite(&chunk[0], 1, chunk_reminder, file_ptr);
            const int file_err = ferror(file_ptr);
            if (write_size < chunk_reminder) {
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::system_error{ file_err, std::system_category(), utility::convert_utf16_to_utf8_string(file_path) };
            }
        }

        return file_handle_ptr;
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE tackle::FileHandle<t_elem, t_traits, t_alloc>
        _create_file(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & file_path,
            const t_elem * mode, SharedAccess share_flags, size_t size, uint32_t fill_by)
    {
        const bool file_existed = boost::fs::exists(file_path.str());
        if (file_existed) {
            const int errno_ = 3; // file already exist
            DEBUG_BREAK_IN_DEBUGGER(true);
            throw std::system_error{ errno_, std::system_category(), utility::convert_utf16_to_utf8_string(file_path) };
        }

        return _recreate_file(file_path, mode, share_flags, size, fill_by);
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE tackle::FileHandle<t_elem, t_traits, t_alloc>
        _open_file(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & file_path,
            const t_elem * mode, SharedAccess share_flags, size_t creation_size, size_t resize_if_existed, uint32_t fill_by_on_creation)
    {
        const bool file_existed = boost::fs::exists(file_path.str());
        if (!file_existed) {
            return recreate_file(file_path, mode, share_flags, creation_size, fill_by_on_creation);
        }

        FILE * file_ptr = _fopen(file_path.c_str(), mode, share_flags);

        tackle::FileHandle<t_elem, t_traits, t_alloc> file_handle_ptr =
            tackle::FileHandle<t_elem, t_traits, t_alloc>(file_ptr, file_path);
        if (!file_ptr) {
            DEBUG_BREAK_IN_DEBUGGER(true);
            throw std::system_error{ errno, std::system_category(), utility::convert_utf16_to_utf8_string(file_path) };
        }

        if (resize_if_existed != size_t(-1)) {
            // close handle before resize
            file_handle_ptr.reset();
            boost::fs::resize_file(file_path.str(), resize_if_existed);
            // reopen handle
            file_handle_ptr = tackle::FileHandle<t_elem, t_traits, t_alloc>{
                file_ptr = _fopen(file_path.c_str(), mode, share_flags), file_path
            };
            if (!file_ptr) {
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::system_error{ errno, std::system_category(), utility::convert_utf16_to_utf8_string(file_path) };
            }
        }

        return file_handle_ptr;
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool _is_directory_path(const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path)
    {
        return boost::fs::is_directory(path.str());
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool _is_regular_file(const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path)
    {
        return boost::fs::is_regular_file(path.str());
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool _is_symlink_path(const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path)
    {
        return boost::fs::is_symlink(path.str());
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool _is_path_exists(const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path)
    {
        return boost::fs::exists(path.str());
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _create_directory(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path, bool throw_on_error)
    {
        if (throw_on_error) {
            return boost::fs::create_directory(path.str());
        }

        boost::system::error_code ec;
        return boost::fs::create_directory(path.str(), ec);
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _create_directory_if_not_exist(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path, bool throw_on_error)
    {
        boost::system::error_code ec;
        return boost::fs::create_directories(path.str(), ec);
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE void
        _create_directory_symlink(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & to,
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & from, bool throw_on_error)
    {
        if (throw_on_error) {
            return boost::fs::create_directory_symlink(to.str(), from.str());
        }

        boost::system::error_code ec;
        return boost::fs::create_directory_symlink(to.str(), from.str(), ec);
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _create_directories(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path, bool throw_on_error)
    {
        if (throw_on_error) {
            return boost::fs::create_directories(path.str());
        }

        boost::system::error_code ec;
        return boost::fs::create_directories(path.str(), ec);
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _remove_directory(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path, bool recursively, bool throw_on_error)
    {
        if (boost::fs::is_directory(path.str())) {
            if (!recursively) {
                if (throw_on_error) {
                    return boost::fs::remove(path.str());
                }

                boost::system::error_code ec;
                return boost::fs::remove(path.str(), ec);
            }

            if (throw_on_error) {
                boost::fs::remove_all(path.str());
            }
            else {
                boost::system::error_code ec;
                boost::fs::remove_all(path.str(), ec);
            }

            return true;
        }

        return false;
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _remove_file(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path, bool throw_on_error)
    {
        if (boost::fs::is_regular_file(path.str())) {
            if (throw_on_error) {
                return boost::fs::remove(path.str());
            }
            else {
                boost::system::error_code ec;
                return boost::fs::remove(path.str(), ec);
            }
        }

        return false;
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _is_relative_path(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path)
    {
        if (path.empty()) {
            return false;
        }

        return boost::fs::path{ path.str() }.is_relative();
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _is_relative_path(
            tackle::path_basic_string<t_elem, t_traits, t_alloc> && path)
    {
        if (path.empty()) {
            return false;
        }

        return boost::fs::path{ std::move(path.str()) }.is_relative();
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _is_absolute_path(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path)
    {
        if (path.empty()) {
            return false;
        }

        return boost::fs::path{ path.str() }.is_absolute();
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _is_absolute_path(
            tackle::path_basic_string<t_elem, t_traits, t_alloc> && path)
    {
        if (path.empty()) {
            return false;
        }

        return boost::fs::path{ std::move(path.str()) }.is_absolute();
    }

    FORCE_INLINE tackle::path_string
        _get_relative_path(const tackle::path_string & from_path, const tackle::path_string & to_path, bool throw_on_error)
    {
        if (throw_on_error) {
            return boost::fs::relative(to_path.str(), from_path.str()).string();
        }


        boost::system::error_code ec;
        return boost::fs::relative(to_path.str(), from_path.str(), ec).string();
    }

    FORCE_INLINE tackle::path_wstring
        _get_relative_path(const tackle::path_wstring & from_path, const tackle::path_wstring & to_path, bool throw_on_error)
    {
        if (throw_on_error) {
            return boost::fs::relative(to_path.str(), from_path.str()).wstring();
        }


        boost::system::error_code ec;
        return boost::fs::relative(to_path.str(), from_path.str(), ec).wstring();
    }

    FORCE_INLINE tackle::path_string
        _get_absolute_path(const tackle::path_string & from_path, const tackle::path_string & to_path)
    {
        return boost::fs::absolute(to_path.str(), from_path.str()).string();
    }

    FORCE_INLINE tackle::path_wstring
        _get_absolute_path(const tackle::path_wstring & from_path, const tackle::path_wstring & to_path)
    {
        return boost::fs::absolute(to_path.str(), from_path.str()).wstring();
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE tackle::path_basic_string<t_elem, t_traits, t_alloc>
        _get_absolute_path(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path, bool throw_on_error)
    {
        if (!is_absolute_path(path)) {
            return _get_absolute_path(_get_current_path(throw_on_error, basic_string_identity<t_elem, t_traits, t_alloc>{}), path);
        }

        return path;
    }

    FORCE_INLINE tackle::path_string _get_current_path(bool throw_on_error, string_identity)
    {
        if (throw_on_error) {
            return boost::fs::current_path().string();
        }


        boost::system::error_code ec;
        return boost::fs::current_path(ec).string();
    }

    FORCE_INLINE tackle::path_wstring _get_current_path(bool throw_on_error, wstring_identity)
    {
        if (throw_on_error) {
            return boost::fs::current_path().wstring();
        }


        boost::system::error_code ec;
        return boost::fs::current_path(ec).wstring();
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE bool
        _remove_symlink(
            const tackle::path_basic_string<t_elem, t_traits, t_alloc> & path, bool throw_on_error)
    {
        if (boost::fs::is_symlink(path.str())) {
            if (throw_on_error) {
                return boost::fs::remove(path.str());
            }
            else {
                boost::system::error_code ec;
                return boost::fs::remove(path.str(), ec);
            }
        }

        return false;
    }

    FORCE_INLINE std::string _get_file_name(const tackle::path_string & path)
    {
        return boost::fs::path{ path.str() }.filename().string();
    }

    FORCE_INLINE std::wstring _get_file_name(const tackle::path_wstring & path)
    {
        return boost::fs::path{ path.str() }.filename().wstring();
    }

    FORCE_INLINE std::string _get_file_name_stem(const tackle::path_string & path)
    {
        return boost::fs::path{ path.str() }.stem().string();
    }

    FORCE_INLINE std::wstring _get_file_name_stem(const tackle::path_wstring & path)
    {
        return boost::fs::path{ path.str() }.stem().wstring();
    }

    FORCE_INLINE tackle::path_string _get_module_file_path(string_identity)
    {
        return boost::dll::program_location().string();
    }

    FORCE_INLINE tackle::path_wstring _get_module_file_path(wstring_identity)
    {
        return boost::dll::program_location().wstring();
    }

    FORCE_INLINE tackle::path_string _get_module_dir_path(string_identity)
    {
        return boost::dll::program_location().parent_path().string();
    }

    FORCE_INLINE tackle::path_wstring _get_module_dir_path(wstring_identity)
    {
        return boost::dll::program_location().parent_path().wstring();
    }

    FORCE_INLINE tackle::path_string _get_lexically_normal_path(const tackle::path_string & path)
    {
        return boost::fs::path{ path.str() }.lexically_normal().string();
    }

    FORCE_INLINE tackle::path_wstring _get_lexically_normal_path(const tackle::path_wstring & path)
    {
        return boost::fs::path{ path.str() }.lexically_normal().wstring();
    }

    FORCE_INLINE tackle::path_string _get_lexically_relative_path(const tackle::path_string & from_path, const tackle::path_string & to_path)
    {
        return boost::fs::path{ to_path.str() }.lexically_relative(from_path.str()).string();
    }

    FORCE_INLINE tackle::path_wstring _get_lexically_relative_path(const tackle::path_wstring & from_path, const tackle::path_wstring & to_path)
    {
        return boost::fs::path{ to_path.str() }.lexically_relative(from_path.str()).wstring();
    }

    FORCE_INLINE tackle::path_string _convert_to_uniform_path(const tackle::path_string & path)
    {
        return boost::fs::path{ path.str() }.generic_string();
    }

    FORCE_INLINE tackle::path_wstring _convert_to_uniform_path(const tackle::path_wstring & path)
    {
        return boost::fs::path{ path.str() }.generic_wstring();
    }

    FORCE_INLINE tackle::path_string _convert_to_native_path(const tackle::path_string & path)
    {
        return boost::fs::path{ path.str() }.make_preferred().string();
    }

    FORCE_INLINE tackle::path_wstring _convert_to_native_path(const tackle::path_wstring & path)
    {
        return boost::fs::path{ path.str() }.make_preferred().wstring();
    }

}

    uint64_t get_file_size(const tackle::FileHandleA & file_handle)
    {
        return _get_file_size(file_handle);
    }

    uint64_t get_file_size(const tackle::FileHandleW & file_handle)
    {
        return _get_file_size(file_handle);
    }

    bool is_files_equal(const tackle::FileHandleA & left_file_handle, const tackle::FileHandleA & right_file_handle)
    {
        return _is_files_equal(left_file_handle, right_file_handle);
    }

    bool is_files_equal(const tackle::FileHandleW & left_file_handle, const tackle::FileHandleW & right_file_handle)
    {
        return _is_files_equal(left_file_handle, right_file_handle);
    }

    tackle::FileHandleA recreate_file(const tackle::path_string & file_path, const char * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by)
    {
        return _recreate_file(file_path, mode, share_flags, size, fill_by);
    }

    tackle::FileHandleW recreate_file(const tackle::path_wstring & file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by)
    {
        return _recreate_file(file_path, mode, share_flags, size, fill_by);
    }

    tackle::FileHandleA create_file(const tackle::path_string & file_path, const char * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by)
    {
        return _create_file(file_path, mode, share_flags, size, fill_by);
    }

    tackle::FileHandleW create_file(const tackle::path_wstring & file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t size, uint32_t fill_by)
    {
        return _create_file(file_path, mode, share_flags, size, fill_by);
    }

    tackle::FileHandleA open_file(const tackle::path_string & file_path, const char * mode, SharedAccess share_flags,
        size_t creation_size, size_t resize_if_existed, uint32_t fill_by_on_creation)
    {
        return _open_file(file_path, mode, share_flags, creation_size, resize_if_existed, fill_by_on_creation);
    }

    tackle::FileHandleW open_file(const tackle::path_wstring & file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t creation_size, size_t resize_if_existed, uint32_t fill_by_on_creation)
    {
        return _open_file(file_path, mode, share_flags, creation_size, resize_if_existed, fill_by_on_creation);
    }

    bool is_directory_path(const tackle::path_string & path)
    {
        return _is_directory_path(path);
    }

    bool is_directory_path(const tackle::path_wstring & path)
    {
        return _is_directory_path(path);
    }

    bool is_regular_file(const tackle::path_string & path)
    {
        return _is_regular_file(path);
    }

    bool is_regular_file(const tackle::path_wstring & path)
    {
        return _is_regular_file(path);
    }

    bool is_symlink_path(const tackle::path_string & path)
    {
        return _is_symlink_path(path);
    }

    bool is_symlink_path(const tackle::path_wstring & path)
    {
        return _is_symlink_path(path);
    }

    bool is_path_exists(const tackle::path_string & path)
    {
        return _is_path_exists(path);
    }

    bool is_path_exists(const tackle::path_wstring & path)
    {
        return _is_path_exists(path);
    }

    bool create_directory(const tackle::path_string & path, bool throw_on_error)
    {
        return _create_directory(path, throw_on_error);
    }

    bool create_directory(const tackle::path_wstring & path, bool throw_on_error)
    {
        return _create_directory(path, throw_on_error);
    }

    bool create_directory_if_not_exist(const tackle::path_string & path, bool throw_on_error)
    {
        return _create_directory_if_not_exist(path, throw_on_error);
    }

    bool create_directory_if_not_exist(const tackle::path_wstring & path, bool throw_on_error)
    {
        return _create_directory_if_not_exist(path, throw_on_error);
    }

    void create_directory_symlink(const tackle::path_string & to, const tackle::path_string & from, bool throw_on_error)
    {
        return _create_directory_symlink(to, from, throw_on_error);
    }

    void create_directory_symlink(const tackle::path_wstring & to, const tackle::path_wstring & from, bool throw_on_error)
    {
        return _create_directory_symlink(to, from, throw_on_error);
    }

    bool create_directories(const tackle::path_string & path, bool throw_on_error)
    {
        return _create_directories(path, throw_on_error);
    }

    bool create_directories(const tackle::path_wstring & path, bool throw_on_error)
    {
        return _create_directories(path, throw_on_error);
    }

    bool remove_directory(const tackle::path_string & path, bool recursively, bool throw_on_error)
    {
        return _remove_directory(path, recursively, throw_on_error);
    }

    bool remove_directory(const tackle::path_wstring & path, bool recursively, bool throw_on_error)
    {
        return _remove_directory(path, recursively, throw_on_error);
    }

    bool remove_file(const tackle::path_string & path, bool throw_on_error)
    {
        return _remove_file(path, throw_on_error);
    }

    bool remove_file(const tackle::path_wstring & path, bool throw_on_error)
    {
        return _remove_file(path, throw_on_error);
    }

    bool remove_symlink(const tackle::path_string & path, bool throw_on_error)
    {
        return _remove_symlink(path, throw_on_error);
    }

    bool remove_symlink(const tackle::path_wstring & path, bool throw_on_error)
    {
        return _remove_symlink(path, throw_on_error);
    }

    bool is_relative_path(const tackle::path_string & path)
    {
        return _is_relative_path(path);
    }

    bool is_relative_path(const tackle::path_wstring & path)
    {
        return _is_relative_path(path);
    }

    bool is_relative_path(tackle::path_string && path)
    {
        return _is_relative_path(path);
    }

    bool is_relative_path(tackle::path_wstring && path)
    {
        return _is_relative_path(path);
    }

    bool is_absolute_path(const tackle::path_string & path)
    {
        return _is_absolute_path(path);
    }

    bool is_absolute_path(const tackle::path_wstring & path)
    {
        return _is_absolute_path(path);
    }

    bool is_absolute_path(tackle::path_string && path)
    {
        return _is_absolute_path(path);
    }

    bool is_absolute_path(tackle::path_wstring && path)
    {
        return _is_absolute_path(path);
    }

    tackle::path_string get_relative_path(const tackle::path_string & from_path, const tackle::path_string & to_path, bool throw_on_error)
    {
        return _get_relative_path(from_path, to_path, throw_on_error);
    }

    tackle::path_wstring get_relative_path(const tackle::path_wstring & from_path, const tackle::path_wstring & to_path, bool throw_on_error)
    {
        return _get_relative_path(from_path, to_path, throw_on_error);
    }

    tackle::path_string get_absolute_path(const tackle::path_string & from_path, const tackle::path_string & to_path)
    {
        return _get_absolute_path(from_path, to_path);
    }

    tackle::path_wstring get_absolute_path(const tackle::path_wstring & from_path, const tackle::path_wstring & to_path)
    {
        return _get_absolute_path(from_path, to_path);
    }

    tackle::path_string get_absolute_path(const tackle::path_string & path, bool throw_on_error)
    {
        return _get_absolute_path(path, throw_on_error);
    }

    tackle::path_wstring get_absolute_path(const tackle::path_wstring & path, bool throw_on_error)
    {
        return _get_absolute_path(path, throw_on_error);
    }

    tackle::path_string get_current_path(bool throw_on_error, utility::string_identity)
    {
        return _get_current_path(throw_on_error, utility::string_identity{});
    }

    tackle::path_wstring get_current_path(bool throw_on_error, utility::wstring_identity)
    {
        return _get_current_path(throw_on_error, utility::wstring_identity{});
    }

    std::string get_file_name(const tackle::path_string & path)
    {
        return _get_file_name(path);
    }

    std::wstring get_file_name(const tackle::path_wstring & path)
    {
        return _get_file_name(path);
    }

    std::string get_file_name_stem(const tackle::path_string & path)
    {
        return _get_file_name_stem(path);
    }

    std::wstring get_file_name_stem(const tackle::path_wstring & path)
    {
        return _get_file_name_stem(path);
    }

    tackle::path_string get_module_file_path(string_identity)
    {
        return _get_module_file_path(string_identity{});
    }

    tackle::path_wstring get_module_file_path(wstring_identity)
    {
        return _get_module_file_path(wstring_identity{});
    }

    tackle::path_string get_module_dir_path(string_identity)
    {
        return _get_module_dir_path(string_identity{});
    }

    tackle::path_wstring get_module_dir_path(wstring_identity)
    {
        return _get_module_dir_path(wstring_identity{});
    }

    tackle::path_string get_lexically_normal_path(const tackle::path_string & path)
    {
        return _get_lexically_normal_path(path);
    }

    tackle::path_wstring get_lexically_normal_path(const tackle::path_wstring & path)
    {
        return _get_lexically_normal_path(path);
    }

    tackle::path_string get_lexically_relative_path(const tackle::path_string & from_path, const tackle::path_string & to_path)
    {
        return _get_lexically_relative_path(from_path, to_path);
    }

    tackle::path_wstring get_lexically_relative_path(const tackle::path_wstring & from_path, const tackle::path_wstring & to_path)
    {
        return _get_lexically_relative_path(from_path, to_path);
    }

    tackle::path_string convert_to_uniform_path(const tackle::path_string & path)
    {
        return _convert_to_uniform_path(path);
    }

    tackle::path_wstring convert_to_uniform_path(const tackle::path_wstring & path)
    {
        return _convert_to_uniform_path(path);
    }

    tackle::path_string convert_to_native_path(const tackle::path_string & path)
    {
        return _convert_to_native_path(path);
    }

    tackle::path_wstring convert_to_native_path(const tackle::path_wstring & path)
    {
        return _convert_to_native_path(path);
    }

}
