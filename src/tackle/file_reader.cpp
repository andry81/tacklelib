#include <tackle/file_reader.hpp>

#include <utility/utility.hpp>
#include <utility/assert.hpp>
#include <utility/math.hpp>

#include <boost/preprocessor/cat.hpp>

#include <stdio.h>


namespace
{
    using utility::Buffer;
}

namespace tackle
{
    FileReader::FileReader(ReadFunc read_pred) :
        m_read_pred(read_pred)
    {
    }

    FileReader::FileReader(const FileHandle & file_handle, FileReader::ReadFunc read_pred) :
        m_file_handle(file_handle), m_read_pred(read_pred)
    {
    }

    void FileReader::set_file_handle(const FileHandle & file_handle)
    {
        m_file_handle = file_handle;
    }

    const FileHandle & FileReader::get_file_handle() const
    {
        return m_file_handle;
    }

    void FileReader::set_read_predicate(FileReader::ReadFunc read_pred)
    {
        m_read_pred = read_pred;
    }

    FileReader::ReadFunc FileReader::get_read_predicate() const
    {
        return m_read_pred;
    }

    utility::Buffer & FileReader::get_buffer()
    {
        return m_buf;
    }

    const utility::Buffer & FileReader::get_buffer() const
    {
        return m_buf;
    }

    uint64_t FileReader::do_read(void * user_data, const ChunkSizes & chunk_sizes, uint64_t min_buf_size, uint64_t max_buf_size)
    {
        if (!m_file_handle.get()) {
            throw std::runtime_error(BOOST_PP_CAT(__FUNCTION__, ": file handle is not set"));
        }

        int is_eof = feof(m_file_handle.get());
        if (is_eof) {
            return 0;
        }

        if (max_buf_size) {
            max_buf_size = (std::max)(max_buf_size, min_buf_size); // just in case
        }

        uint64_t buf_read_size;
        uint64_t next_read_size;
        uint64_t read_size;
        uint64_t overall_read_size = 0;

        ChunkSizes chunk_sizes_ = chunk_sizes;
        if (!chunk_sizes_.empty()) {
            // add max if not 0
            if (chunk_sizes_.back()) {
                chunk_sizes_.push_back(math::uint32_max);
            }
        }
        else {
            chunk_sizes_.push_back(math::uint32_max);
        }

        do {
            for (auto chunk_size : chunk_sizes_) {
                if (!chunk_size) goto exit_; // stop on 0
                if (chunk_size != math::uint32_max) {
                    next_read_size = chunk_size;
                    buf_read_size = uint64_t(chunk_size) < min_buf_size ? min_buf_size : uint64_t(chunk_size);
                }
                else {
                    next_read_size = utility::get_file_size(m_file_handle);
                    if (overall_read_size < next_read_size) {
                        next_read_size -= overall_read_size;
                    }
                    else goto exit_;
                    if (next_read_size < min_buf_size) {
                        buf_read_size = min_buf_size;
                    }
                    else if (max_buf_size) {
                        next_read_size = (std::min)(next_read_size, max_buf_size);
                        buf_read_size = next_read_size;
                    }
                    else buf_read_size = next_read_size;
                }

                read_size = fread(m_buf.realloc_get(buf_read_size), 1, size_t(next_read_size), m_file_handle.get());
                const int file_in_read_err = ferror(m_file_handle.get());
                is_eof = feof(m_file_handle.get());
                ASSERT_TRUE(!file_in_read_err && read_size == next_read_size || is_eof);

                if (read_size) {
                    if (m_read_pred) {
                        m_read_pred(m_buf.get(), read_size, user_data);
                    }

                    overall_read_size += read_size;
                }
            }
        }
        while (!is_eof);
    exit_:;

        return overall_read_size;
    }

    void FileReader::close()
    {
        m_file_handle = FileHandle::s_null;
    }
}
