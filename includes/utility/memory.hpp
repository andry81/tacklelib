#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_MEMORY_HPP
#define UTILITY_MEMORY_HPP

#include <tacklelib.hpp>

#include <utility/assert.hpp>

#include <type_traits>

#include <cstdint>
#include <memory>


#ifndef UTILITY_PLATFORM_FEATURE_CXX_STANDARD_MAKE_UNIQUE

// std::make_unique is supported from C++14.
// implementation taken from C++ ISO papers: https://isocpp.org/files/papers/N3656.txt
//
namespace std
{
    template <typename T, typename D>
    class unique_ptr;

    namespace detail
    {
        template<class T>
        struct _unique_if
        {
            typedef unique_ptr<T> _single_object;
        };

        template<class T>
        struct _unique_if<T[]>
        {
            typedef unique_ptr<T[]> _unknown_bound;
        };

        template<class T, size_t N>
        struct _unique_if<T[N]>
        {
            typedef void _known_bound;
        };
    }

    template<class T, class... Args>
    inline typename detail::_unique_if<T>::_single_object make_unique(Args &&... args)
    {
        return unique_ptr<T>(new T(std::forward<Args>(args)...));
    }

    template<class T>
    inline typename detail::_unique_if<T>::_unknown_bound make_unique(size_t n)
    {
        typedef typename remove_extent<T>::type U;
        return unique_ptr<T>(new U[n]());
    }

    template<class T, class... Args>
    typename detail::_unique_if<T>::_known_bound make_unique(Args &&...) = delete;
}

#endif

namespace utility
{
    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(From & v)
    {
        return static_cast<To>(static_cast<void *>(std::addressof(v)));
    }

    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(const From & v)
    {
        return static_cast<To>(static_cast<const void *>(std::addressof(v)));
    }

    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(volatile From & v)
    {
        return static_cast<To>(static_cast<volatile void *>(std::addressof(v)));
    }

    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(const volatile From & v)
    {
        return static_cast<To>(static_cast<const volatile void *>(std::addressof(v)));
    }

    enum MemoryType
    {
        MemType_VirtualMemory   = 1,
        MemType_PhysicalMemory  = 2
    };

    // proc_id:
    //  0               - current process
    //  *               - target process
    uint64_t get_process_memory_size(MemoryType mem_type, size_t proc_id);

    // simple buffer to reallocate memory on demand
    //
    //  CAUTION:
    //      Because the buffer class does not reallocate memory if requested buffer size less than already existed, then out of size read/write access WOULD NOT BE CATCHED!
    //      To workaround that we must AT LEAST do guard the end of the buffer in the DEBUG.
    //
    class Buffer
    {
        using BufSharedPtr = std::shared_ptr<uint8_t>;

        static const char s_guard_sequence_str[49];
        static const size_t s_guard_max_len = 256; // to avoid comparison slowdown on big arrays

    public:
        FORCE_INLINE Buffer(size_t size = 0) :
            m_offset(0), m_size(0), m_reserve(0), m_is_reallocating(false)
        {
            reset(size);
        }

        ~Buffer();

        void check_buffer_guards();

    private:
        void _fill_buffer_guards();

    public:
        void reset(size_t size);

        FORCE_INLINE size_t size() const
        {
            return m_size;
        }

        FORCE_INLINE uint8_t * get()
        {
            DEBUG_ASSERT_TRUE(m_size);
            return m_buf_ptr.get() + m_offset;
        }

        FORCE_INLINE const uint8_t * get() const
        {
            DEBUG_ASSERT_TRUE(m_size);
            return m_buf_ptr.get() + m_offset;
        }

        uint8_t * realloc_get(size_t size);

#ifndef UTILITY_PLATFORM_X64
        uint8_t * realloc_get(uint64_t size);
#endif

        FORCE_INLINE void set_reallocating(bool is_reallocating)
        {
            m_is_reallocating = is_reallocating;
        }

        // for memory debugging on a moment of deallocation
        FORCE_INLINE void realloc(Buffer & to_buf)
        {
            uint8_t * to_buf_ptr = to_buf.realloc_get(m_size);
            memcpy(to_buf_ptr - to_buf.m_offset, m_buf_ptr.get(), m_reserve);

            *this = to_buf;
        }

    private:
        size_t          m_offset;
        size_t          m_size;
        size_t          m_reserve;
        BufSharedPtr    m_buf_ptr;
        bool            m_is_reallocating;
    };

}

#endif
