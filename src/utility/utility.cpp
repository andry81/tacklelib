#include <utility/utility.hpp>
#include <utility/assert.hpp>

#include <tackle/file_handle.hpp>

#include <boost/filesystem.hpp>
#include <boost/format.hpp>

#include <vector>


namespace boost
{
    namespace fs = filesystem;
}

namespace utility
{
    Buffer::~Buffer()
    {
#if !ERROR_IF_EMPTY_PP_DEF(DISABLE_BUFFER_GUARD_CHECK) && (ERROR_IF_EMPTY_PP_DEF(ENABLE_PERSISTENT_BUFFER_GUARD_CHECK) || defined(_DEBUG))
        check_buffer_guards();
#endif
    }

    const char Buffer::s_guard_sequence_str[49] = "XYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZ";
    const size_t Buffer::s_guard_max_len;

    void Buffer::check_buffer_guards()
    {
        if (m_size < m_reserve) {
            constexpr const size_t guard_sequence_str_len = utility::static_size(s_guard_sequence_str) - 1;

            uint8_t * buf_ptr = m_buf_ptr.get();

            {
                const size_t guard_size = m_offset;

                const size_t num_whole_chunks = guard_size / guard_sequence_str_len;
                const size_t chunks_remainder = guard_size % guard_sequence_str_len;

                for (size_t i = 0; i < num_whole_chunks; i++) {
                    if (VERIFY_FALSE(memcmp(&buf_ptr[i * guard_sequence_str_len], s_guard_sequence_str, guard_sequence_str_len))) {
                        goto _error;
                    }
                }
                if (chunks_remainder) {
                    if (memcmp(&buf_ptr[num_whole_chunks * guard_sequence_str_len], s_guard_sequence_str, chunks_remainder)) {
                        goto _error;
                    }
                }
            }

            {
                const size_t offset = m_offset + m_size;
                const size_t guard_size = m_reserve - offset;

                const size_t num_whole_chunks = guard_size / guard_sequence_str_len;
                const size_t chunks_remainder = guard_size % guard_sequence_str_len;

                for (size_t i = 0; i < num_whole_chunks; i++) {
                    if (VERIFY_FALSE(memcmp(&buf_ptr[offset + i * guard_sequence_str_len], s_guard_sequence_str, guard_sequence_str_len))) {
                        goto _error;
                    }
                }
                if (chunks_remainder) {
                    if (memcmp(&buf_ptr[offset + num_whole_chunks * guard_sequence_str_len], s_guard_sequence_str, chunks_remainder)) {
                        goto _error;
                    }
                }
            }

            return;

        _error:;
            throw std::out_of_range(
                (boost::format("%s : out of buffer write: reserve=%u size=%u buffer=%p") %
                    UTILITY_PP_FUNC % m_reserve % m_size % buf_ptr).str());
        }
    }

    void Buffer::_fill_buffer_guards()
    {
        if (m_size < m_reserve) {
            constexpr const size_t guard_sequence_str_len = utility::static_size(s_guard_sequence_str) - 1;

            uint8_t * buf_ptr = m_buf_ptr.get();

            {
                const size_t guard_size = m_offset;

                const size_t num_whole_chunks = guard_size / guard_sequence_str_len;
                const size_t chunks_remainder = guard_size % guard_sequence_str_len;

                for (size_t i = 0; i < num_whole_chunks; i++) {
                    memcpy(&buf_ptr[i * guard_sequence_str_len], s_guard_sequence_str, guard_sequence_str_len);
                }
                if (chunks_remainder) {
                    memcpy(&buf_ptr[num_whole_chunks * guard_sequence_str_len], s_guard_sequence_str, chunks_remainder);
                }
            }

            {
                const size_t offset = m_offset + m_size;
                const size_t guard_size = m_reserve - offset;

                const size_t num_whole_chunks = guard_size / guard_sequence_str_len;
                const size_t chunks_remainder = guard_size % guard_sequence_str_len;

                for (size_t i = 0; i < num_whole_chunks; i++) {
                    memcpy(&buf_ptr[offset + i * guard_sequence_str_len], s_guard_sequence_str, guard_sequence_str_len);
                }
                if (chunks_remainder) {
                    memcpy(&buf_ptr[offset + num_whole_chunks * guard_sequence_str_len], s_guard_sequence_str, chunks_remainder);
                }
            }
        }
    }

    void Buffer::reset(size_t size)
    {
#if !ERROR_IF_EMPTY_PP_DEF(DISABLE_BUFFER_GUARD_CHECK) && (ERROR_IF_EMPTY_PP_DEF(ENABLE_PERSISTENT_BUFFER_GUARD_CHECK) || defined(_DEBUG))
        check_buffer_guards();

        // minimum 16 bytes or 1% of allocation size for guard sections on the left and right, but not greater than `s_guard_max_len`
        const size_t offset = (std::min)((std::max)(size / 100, 16U), s_guard_max_len);
        const size_t size_extra = size ? (size + offset * 2) : 0;
#else
        const size_t offset = 0;
        const size_t size_extra = size;
#endif

        // reallocate only if greater, deallocate only if 0
        if (size_extra) {
            if (m_reserve < size_extra) {
                m_buf_ptr = BufSharedPtr(new uint8_t[size_extra], std::default_delete<uint8_t[]>());
                m_reserve = size_extra;
            }

            m_offset = offset;
            m_size = size;

#if !ERROR_IF_EMPTY_PP_DEF(DISABLE_BUFFER_GUARD_CHECK) && (ERROR_IF_EMPTY_PP_DEF(ENABLE_PERSISTENT_BUFFER_GUARD_CHECK) || defined(_DEBUG))
            _fill_buffer_guards();
#endif
        }
        else {
            m_buf_ptr.reset();
            m_offset = m_reserve = m_size = 0;
        }
    }

    uint8_t * Buffer::realloc_get(size_t size)
    {
        reset(size);

#if ERROR_IF_EMPTY_PP_DEF(ENABLE_BUFFER_REALLOC_AFTER_ALLOC)
        if (!m_is_reallocating)
        {
            Buffer local_buf;

            local_buf.set_reallocating(true);

            realloc(local_buf);
        }
#endif

        return m_buf_ptr.get() + m_offset;
    }

#ifndef UTILITY_PLATFORM_X64
    uint8_t * Buffer::realloc_get(uint64_t size)
    {
        if (UTILITY_CONST_EXPR(sizeof(size_t) < sizeof(uint64_t))) {
            const uint64_t max_value = uint64_t((std::numeric_limits<size_t>::max)());
            if (size > max_value) {
                throw std::runtime_error(
                    (boost::format("%s: size is out of memory: size=%llu max=%llu") %
                        UTILITY_PP_FUNC % size % max_value).str());
            }
        }

        return realloc_get(size_t(size));
    }
#endif

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

            if (memcmp(left_local_buf_ptr.get(), right_local_buf_ptr.get(), left_read_byte_size))
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

    bool create_directory(const tackle::path_string & path)
    {
        return boost::fs::create_directory(path.str());
    }

    void create_directory_symlink(const tackle::path_string & to, const tackle::path_string & from)
    {
        return boost::fs::create_directory_symlink(to.str(), from.str());
    }

    bool create_directories(const tackle::path_string & path)
    {
        return boost::fs::create_directories(path.str());
    }
}
