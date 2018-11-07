#include <utility/utility.hpp>
#include <utility/assert.hpp>

#include <tackle/file_handle.hpp>

#include <boost/filesystem.hpp>
#include <boost/dll.hpp>

#include <vector>


namespace boost
{
    namespace fs = filesystem;
}

namespace utility
{

    uint64_t get_file_size(const tackle::FileHandle & file_handle)
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

    bool is_files_equal(const tackle::FileHandle & left_file_handle, const tackle::FileHandle & right_file_handle)
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

    tackle::FileHandle recreate_file(const tackle::path_string & file_path, const char * mode, SharedAccess share_flags, size_t size, uint32_t fill_by)
    {
        FILE * file_ptr =
#if defined(UTILITY_PLATFORM_WINDOWS)
            _fsopen(file_path.c_str(), mode, share_flags);
#elif defined(UTILITY_PLATFORM_POSIX)
            fopen(file_path.c_str(), mode);
        // TODO:
        //  Implement `fcntl` with `F_SETLK`, for details see: https://linux.die.net/man/3/fcntl
#else
#error platform is not implemented
#endif

        tackle::FileHandle file_handle_ptr = tackle::FileHandle(file_ptr, file_path);
        if (!file_ptr) {
            DEBUG_BREAK_IN_DEBUGGER(true);
            throw std::system_error{ errno, std::system_category(), file_path };
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
                    throw std::system_error{ file_err, std::system_category(), file_path };
                }
            }

            const size_t chunk_reminder = size % chunk.size();
            const size_t write_size = fwrite(&chunk[0], 1, chunk_reminder, file_ptr);
            const int file_err = ferror(file_ptr);
            if (write_size < chunk_reminder) {
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::system_error{ file_err, std::system_category(), file_path };
            }
        }

        return file_handle_ptr;
    }

    tackle::FileHandle create_file(const tackle::path_string & file_path, const char * mode, SharedAccess share_flags, size_t size, uint32_t fill_by)
    {
        const bool file_existed = boost::fs::exists(file_path.str());
        if (file_existed) {
            const int errno_ = 3; // file already exist
            DEBUG_BREAK_IN_DEBUGGER(true);
            throw std::system_error{ errno_, std::system_category(), file_path };
        }

        return recreate_file(file_path, mode, share_flags, size, fill_by);
    }

    tackle::FileHandle open_file(const tackle::path_string & file_path, const char * mode, SharedAccess share_flags, size_t creation_size, size_t resize_if_existed, uint32_t fill_by_on_creation)
    {
        const bool file_existed = boost::fs::exists(file_path.str());
        if (!file_existed) {
            return recreate_file(file_path, mode, share_flags, creation_size, fill_by_on_creation);
        }

        FILE * file_ptr =
#if defined(UTILITY_PLATFORM_WINDOWS)
            _fsopen(file_path.c_str(), mode, share_flags);
#elif defined(UTILITY_PLATFORM_POSIX)
            fopen(file_path.c_str(), mode);
        // TODO:
        //  Implement `fcntl` with `F_SETLK`, for details see: https://linux.die.net/man/3/fcntl
#else
#error platform is not implemented
#endif

        tackle::FileHandle file_handle_ptr = tackle::FileHandle(file_ptr, file_path);
        if (!file_ptr) {
            DEBUG_BREAK_IN_DEBUGGER(true);
            throw std::system_error{ errno, std::system_category(), file_path };
        }

        if (resize_if_existed != size_t(-1)) {
            // close handle before resize
            file_handle_ptr.reset();
            boost::fs::resize_file(file_path.str(), resize_if_existed);
            // reopen handle
            file_handle_ptr = tackle::FileHandle(file_ptr =
#if defined(UTILITY_PLATFORM_WINDOWS)
                _fsopen(file_path.c_str(), mode, share_flags),
#elif defined(UTILITY_PLATFORM_POSIX)
                fopen(file_path.c_str(), mode),
                // TODO:
                //  Implement `fcntl` with `F_SETLK`, for details see: https://linux.die.net/man/3/fcntl
#else
#error platform is not implemented
#endif
                file_path
            );
            if (!file_ptr) {
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::system_error{ errno, std::system_category(), file_path };
            }
        }

        return file_handle_ptr;
    }

    bool is_directory_path(const tackle::path_string & path)
    {
        return boost::fs::is_directory(path.str());
    }

    bool is_regular_file(const tackle::path_string & path)
    {
        return boost::fs::is_regular_file(path.str());
    }

    bool is_symlink_path(const tackle::path_string & path)
    {
        return boost::fs::is_symlink(path.str());
    }

    bool is_path_exists(const tackle::path_string & path)
    {
        return boost::fs::exists(path.str());
    }

    bool create_directory(const tackle::path_string & path, bool throw_on_error)
    {
        if (throw_on_error) {
            return boost::fs::create_directory(path.str());
        }

        boost::system::error_code ec;
        return boost::fs::create_directory(path.str(), ec);
    }

    bool create_directory_if_not_exist(const tackle::path_string & path, bool throw_on_error)
    {
        boost::system::error_code ec;
        return boost::fs::create_directories(path.str(), ec);
    }

    void create_directory_symlink(const tackle::path_string & to, const tackle::path_string & from, bool throw_on_error)
    {
        if (throw_on_error) {
            return boost::fs::create_directory_symlink(to.str(), from.str());
        }

        boost::system::error_code ec;
        return boost::fs::create_directory_symlink(to.str(), from.str(), ec);
    }

    bool create_directories(const tackle::path_string & path, bool throw_on_error)
    {
        if (throw_on_error) {
            return boost::fs::create_directories(path.str());
        }

        boost::system::error_code ec;
        return boost::fs::create_directories(path.str(), ec);
    }

    bool remove_directory(const tackle::path_string & path, bool recursively, bool throw_on_error)
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

    bool remove_file(const tackle::path_string & path, bool throw_on_error)
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

    bool is_relative_path(const tackle::path_string & path)
    {
        if (path.empty()) {
            return false;
        }

        return boost::fs::path{ path.str() }.is_relative();
    }

    bool is_relative_path(tackle::path_string && path)
    {
        if (path.empty()) {
            return false;
        }

        return boost::fs::path{ std::move(path.str()) }.is_relative();
    }

    bool is_absolute_path(const tackle::path_string & path)
    {
        if (path.empty()) {
            return false;
        }

        return boost::fs::path{ path.str() }.is_absolute();
    }

    bool is_absolute_path(tackle::path_string && path)
    {
        if (path.empty()) {
            return false;
        }

        return boost::fs::path{ std::move(path.str()) }.is_absolute();
    }

    tackle::path_string get_relative_path(const tackle::path_string & from_path, const tackle::path_string & to_path, bool throw_on_error)
    {
        if (throw_on_error) {
            return boost::fs::relative(to_path.str(), from_path.str()).string();
        }


        boost::system::error_code ec;
        return boost::fs::relative(to_path.str(), from_path.str(), ec).string();
    }

    bool remove_symlink(const tackle::path_string & path, bool throw_on_error)
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

    std::string get_file_name(const tackle::path_string & path)
    {
        return boost::fs::path(path.str()).filename().string();
    }

    std::string get_file_name_stem(const tackle::path_string & path)
    {
        return boost::fs::path(path.str()).stem().string();
    }

    tackle::path_string get_module_file_path()
    {
        return boost::dll::program_location().string();
    }

    tackle::path_string get_module_dir_path()
    {
        return boost::dll::program_location().parent_path().string();
    }
}
