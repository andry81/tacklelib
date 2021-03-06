#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_FILE_READER_HPP
#define TACKLE_FILE_READER_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/memory.hpp>
#include <tacklelib/utility/utility.hpp>

#include <tacklelib/tackle/file_handle.hpp>

#include <vector>
#include <functional>

#undef LIBRARY_API_NAMESPACE
#define LIBRARY_API_NAMESPACE TACKLELIB
#include <tacklelib/utility/library_api_define.hpp>


namespace tackle
{
    template <class t_elem = char>
    class LIBRARY_API_DECL file_reader
    {
    public:
        using chunk_sizes_type  = std::vector<size_t> ;
        using read_func         = std::function<void(uint8_t * buf, size_t chunk_size, void * user_data)>;

        FORCE_INLINE file_reader(read_func read_pred = nullptr);
        FORCE_INLINE file_reader(const file_handle<t_elem> & file_handle, read_func read_pred = nullptr);

        FORCE_INLINE file_reader(const file_reader &) = default;

        FORCE_INLINE void set_file_handle(const file_handle<t_elem> & file_handle);
        FORCE_INLINE const file_handle<t_elem> & get_file_handle() const;

        FORCE_INLINE void set_read_predicate(read_func read_pred);
        FORCE_INLINE read_func get_read_predicate() const;

        FORCE_INLINE utility::Buffer & get_buffer();
        FORCE_INLINE const utility::Buffer & get_buffer() const;

        FORCE_INLINE uint64_t do_read(void * user_data, const chunk_sizes_type & chunk_sizes, size_t min_buf_size = 0, size_t max_buf_size = 0);
        FORCE_INLINE void close();

    private:
        file_handle<t_elem> m_file_handle;
        read_func           m_read_pred;
        utility::Buffer     m_buf;
    };

    template <class t_elem>
    FORCE_INLINE file_reader<t_elem>::file_reader(read_func read_pred) :
        m_read_pred(read_pred)
    {
    }

    template <class t_elem>
    FORCE_INLINE file_reader<t_elem>::file_reader(const file_handle<t_elem> & file_handle, file_reader::read_func read_pred) :
        m_file_handle(file_handle), m_read_pred(read_pred)
    {
    }

    template <class t_elem>
    FORCE_INLINE void file_reader<t_elem>::set_file_handle(const file_handle<t_elem> & file_handle)
    {
        m_file_handle = file_handle;
    }

    template <class t_elem>
    FORCE_INLINE const file_handle<t_elem> & file_reader<t_elem>::get_file_handle() const
    {
        return m_file_handle;
    }

    template <class t_elem>
    FORCE_INLINE void file_reader<t_elem>::set_read_predicate(typename file_reader<t_elem>::read_func read_pred)
    {
        m_read_pred = read_pred;
    }

    template <class t_elem>
    FORCE_INLINE typename file_reader<t_elem>::read_func file_reader<t_elem>::get_read_predicate() const
    {
        return m_read_pred;
    }

    template <class t_elem>
    FORCE_INLINE utility::Buffer & file_reader<t_elem>::get_buffer()
    {
        return m_buf;
    }

    template <class t_elem>
    FORCE_INLINE const utility::Buffer & file_reader<t_elem>::get_buffer() const
    {
        return m_buf;
    }

    template <class t_elem>
    FORCE_INLINE uint64_t file_reader<t_elem>::do_read(void * user_data, const chunk_sizes_type & chunk_sizes, size_t min_buf_size, size_t max_buf_size)
    {
        static_assert(sizeof(uint64_t) >= sizeof(size_t), "uint64_t must be at least the same size as size_t type here");

        if (!m_file_handle.get()) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): file handle is not set",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

        int is_eof = feof(m_file_handle.get());
        if (is_eof) {
            return 0;
        }

        if (max_buf_size) {
            max_buf_size = (std::max)(max_buf_size, min_buf_size); // just in case
        }

        size_t buf_read_size;
        uint64_t next_read_size;
        size_t read_size;
        uint64_t overall_read_size = 0;

        chunk_sizes_type chunk_sizes_ = chunk_sizes;
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
                    buf_read_size = chunk_size < min_buf_size ? min_buf_size : chunk_size;
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
                        next_read_size = (std::min)(next_read_size, uint64_t(max_buf_size));
                        buf_read_size = size_t(next_read_size); // is safe to cast to lesser size type
                    }
                    else {
                        if (min_buf_size < next_read_size) {
                            next_read_size = min_buf_size;
                        }
                        buf_read_size = size_t(next_read_size); // is safe to cast to lesser size type
                    }
                }

                read_size = fread(m_buf.realloc_get(buf_read_size), 1, size_t(next_read_size), m_file_handle.get());
                const int file_in_read_err = ferror(m_file_handle.get());
                is_eof = feof(m_file_handle.get());
                DEBUG_ASSERT_TRUE(!file_in_read_err && read_size == next_read_size || is_eof);

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

    template <class t_elem>
    FORCE_INLINE void file_reader<t_elem>::close()
    {
        m_file_handle = file_handle<t_elem>::null();
    }

}

#endif
