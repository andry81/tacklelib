#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_FILE_READER_HPP
#define TACKLE_FILE_READER_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>

#ifdef UTILITY_PLATFORM_POSIX
#define _FILE_OFFSET_BITS 64    // for ftello/fseeko with 64-bit
#endif

#include <tacklelib/utility/memory.hpp>
#include <tacklelib/utility/utility.hpp>

#include <tacklelib/tackle/file_handle.hpp>

#include <vector>
#include <functional>

#include <stdio.h>

#undef LIBRARY_API_NAMESPACE
#define LIBRARY_API_NAMESPACE TACKLELIB
#include <tacklelib/utility/library_api_define.hpp>


namespace tackle
{
    struct LIBRARY_API_DECL file_reader_state
    {
        FORCE_INLINE file_reader_state() :
            read_index(0), read_offset(0), read_chunk_index(0), break_(false)
        {
        }

        FORCE_INLINE file_reader_state(const file_reader_state &) = default;
        FORCE_INLINE file_reader_state(file_reader_state &&) = default;

        size_t      read_index;
        uint64_t    read_offset;
        uint32_t    read_chunk_index;
        bool        break_;
    };

    template <class t_elem = char>
    class LIBRARY_API_DECL file_reader
    {
    public:
        using chunk_sizes_type  = std::vector<size_t> ;
        using read_func         = std::function<void(uint8_t * buf, size_t chunk_size, void * user_data, file_reader_state & state)>;

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

        file_reader_state state;

#ifdef UTILITY_COMPILER_CXX_MSC
        state.read_offset = uint64_t(_ftelli64(m_file_handle.get()));
#elif defined(UTILITY_PLATFORM_POSIX)
        state.read_offset = uint64_t(ftello(m_file_handle.get()));
#else
#error platform is not supported
#endif

        do {
            state.read_chunk_index = 0;

            for (auto chunk_size : chunk_sizes_) {
                do { // fake scope to intercept any accidental continue/break and call an end action
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
                            m_read_pred(m_buf.get(), read_size, user_data, state);
                        }

                        state.read_index++;

#ifdef UTILITY_COMPILER_CXX_MSC
                        state.read_offset = uint64_t(_ftelli64(m_file_handle.get()));
#elif defined(UTILITY_PLATFORM_POSIX)
                        state.read_offset = uint64_t(ftello(m_file_handle.get()));
#endif

                        overall_read_size += read_size;

                        if (state.break_) goto exit_;
                    }
                } while (false);

                // end action
                state.read_chunk_index++;
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
