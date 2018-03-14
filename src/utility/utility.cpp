#include <utility/utility.hpp>
#include <utility/assert.hpp>

#include <boost/filesystem.hpp>

#include <vector>

namespace boost
{
    namespace fs = filesystem;
}

namespace utility
{
#if defined(ENABLE_PERSISTENT_BUFFER_GUARD_CHECK) || defined(_DEBUG)
    const char Buffer::s_guard_sequence_str[49] = "XYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZ";

    void Buffer::check_buffer_guards()
    {
        if (m_size < m_reserve) {
            constexpr const size_t guard_sequence_str_len = std::size(s_guard_sequence_str) - 1;

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
                (boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": out of buffer write: reserve=%u size=%u buffer=%p")) %
                        m_reserve % m_size % buf_ptr).str());
        }
    }

    void Buffer::_fill_buffer_guards()
    {
        if (m_size < m_reserve) {
            constexpr const size_t guard_sequence_str_len = std::size(s_guard_sequence_str) - 1;

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
#endif

    uint64_t get_file_size(const FileHandle & file_handle)
    {
        ASSERT_TRUE(file_handle.get());

        fpos_t last_pos;
        if (fgetpos(file_handle.get(), &last_pos)) return 0;
        if (fseek(file_handle.get(), 0, SEEK_END)) return 0;

        const uint64_t size = _ftelli64(file_handle.get());
        fsetpos(file_handle.get(), &last_pos);

        return size;
    }

    bool is_files_equal(const FileHandle & left_file_handle, const FileHandle & right_file_handle)
    {
        const uint64_t left_file_size = get_file_size(left_file_handle);
        const uint64_t right_file_size = get_file_size(right_file_handle);
        if (left_file_size != right_file_size)
            return false;

        typedef std::shared_ptr<uint8_t> LocalBufSharedPtr;

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

    FileHandle recreate_file(const std::string & file_path, const char * mode, int flags, size_t size, uint32_t fill_by)
    {
        FILE * file_ptr = _fsopen(file_path.c_str(), mode, flags);
        FileHandle file_handle_ptr = FileHandle(file_ptr, file_path);
        if (!file_ptr) {
            utility::debug_break();
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
                    utility::debug_break();
                    throw std::system_error{ file_err, std::system_category(), file_path };
                }
            }

            const size_t chunk_reminder = size % chunk.size();
            const size_t write_size = fwrite(&chunk[0], 1, chunk_reminder, file_ptr);
            const int file_err = ferror(file_ptr);
            if (write_size < chunk_reminder) {
                utility::debug_break();
                throw std::system_error{ file_err, std::system_category(), file_path };
            }
        }

        return file_handle_ptr;
    }

    FileHandle create_file(const std::string & file_path, const char * mode, int flags, size_t size, uint32_t fill_by)
    {
        const bool file_existed = boost::fs::exists(file_path);
        if (file_existed) {
            const int errno_ = 3; // file already exist
            utility::debug_break();
            throw std::system_error{ errno_, std::system_category(), file_path };
        }

        return recreate_file(file_path, mode, flags, size, fill_by);
    }

    FileHandle open_file(const std::string & file_path, const char * mode, int flags, size_t creation_size, size_t resize_if_existed, uint32_t fill_by_on_creation)
    {
        const bool file_existed = boost::fs::exists(file_path);
        if (!file_existed) {
            return recreate_file(file_path, mode, flags, creation_size, fill_by_on_creation);
        }

        FILE * file_ptr = _fsopen(file_path.c_str(), mode, flags);
        FileHandle file_handle_ptr = FileHandle(file_ptr, file_path);
        if (!file_ptr) {
            utility::debug_break();
            throw std::system_error{ errno, std::system_category(), file_path };
        }

        if (resize_if_existed != size_t(-1)) {
            // close handle before resize
            file_handle_ptr.reset();
            boost::fs::resize_file(file_path, resize_if_existed);
            // reopen handle
            file_handle_ptr = FileHandle(file_ptr = _fsopen(file_path.c_str(), mode, flags), file_path);
            if (!file_ptr) {
                utility::debug_break();
                throw std::system_error{ errno, std::system_category(), file_path };
            }
        }

        return file_handle_ptr;
    }
}
