#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/utility.hpp>

#include <tackle/file_handle.hpp>

#include <vector>


namespace tackle
{
    class FileReader
    {
    public:
        typedef std::vector<size_t> ChunkSizes;
        typedef void (* ReadFunc)(uint8_t * buf, uint64_t chunk_size, void * user_data);

        FileReader(ReadFunc read_pred = nullptr);
        FileReader(const FileHandle & file_handle, ReadFunc read_pred = nullptr);

        FileReader(const FileReader &) = default;

        void set_file_handle(const FileHandle & file_handle);
        const FileHandle & get_file_handle() const;

        void set_read_predicate(ReadFunc read_pred);
        ReadFunc get_read_predicate() const;

        utility::Buffer & get_buffer();
        const utility::Buffer & get_buffer() const;

        uint64_t do_read(void * user_data, const ChunkSizes & chunk_sizes, uint64_t min_buf_size = 0, uint64_t max_buf_size = 0);
        void close();

    private:
        FileHandle          m_file_handle;
        ReadFunc            m_read_pred;
        utility::Buffer     m_buf;
    };
}
