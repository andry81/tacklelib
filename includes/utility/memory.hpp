#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_MEMORY_HPP
#define UTILITY_MEMORY_HPP

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/type_traits.hpp>
#include <utility/assert.hpp>
#include <utility/utility.hpp>

#include <type_traits>

#include <cstdint>
#include <cstdio>
#include <memory>
#include <stdexcept>


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
        using BufSharedPtr = std::unique_ptr<uint8_t[]>;

        static const char s_guard_sequence_str[49];
        static const size_t s_guard_max_len = 256; // to avoid comparison slow down on big arrays

    public:
        FORCE_INLINE Buffer(size_t size = 0) :
            m_offset(0), m_size(0), m_reserve(0), m_is_reallocating(false)
        {
            if (size) { // optimization to avoid an empty call in constructor
                reset(size);
            }
        }

        FORCE_INLINE Buffer::~Buffer()
        {
#if !ERROR_IF_EMPTY_PP_DEF(DISABLE_BUFFER_GUARD_CHECK) && (ERROR_IF_EMPTY_PP_DEF(ENABLE_PERSISTENT_BUFFER_GUARD_CHECK) || defined(_DEBUG))
            check_buffer_guards();
#endif
        }

        void check_buffer_guards();

    private:
        void _fill_buffer_guards();

    public:
        FORCE_INLINE void reset(size_t size)
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

        FORCE_INLINE uint8_t * realloc_get(size_t size)
        {
            reset(size);

#if ERROR_IF_EMPTY_PP_DEF(ENABLE_BUFFER_REALLOC_AFTER_ALLOC)
            if (!m_is_reallocating)
            {
                Buffer local_buf;

                local_buf.set_reallocating(true);

                realloc_debug(local_buf);
            }
#endif

            return m_buf_ptr.get() + m_offset;
        }

#ifndef UTILITY_PLATFORM_X64
        FORCE_INLINE uint8_t * realloc_get(uint64_t size)
        {
            if (UTILITY_CONST_EXPR(sizeof(size_t) < sizeof(uint64_t))) {
                const uint64_t max_value = uint64_t((std::numeric_limits<size_t>::max)());
                if (size > max_value) {
                    char fmt_buf[256];
                    snprintf(fmt_buf, utility::static_size(fmt_buf), "%s(%u): size is out of memory: size=%llu max=%llu",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE, size, max_value);
                    DEBUG_BREAK_IN_DEBUGGER(true);
                    throw std::runtime_error(fmt_buf);
                }
            }

            return realloc_get(size_t(size));
        }
#endif

        FORCE_INLINE void set_reallocating(bool is_reallocating)
        {
            m_is_reallocating = is_reallocating;
        }

        FORCE_INLINE uint8_t * release()
        {
            m_offset = m_size = m_reserve = 0;
            return m_buf_ptr.release();
        }

        // for memory debugging on a moment of deallocation
        FORCE_INLINE void realloc_debug(Buffer & to_buf)
        {
            uint8_t * to_buf_ptr = to_buf.realloc_get(m_size);
            memcpy(to_buf_ptr - to_buf.m_offset, m_buf_ptr.get(), m_reserve);

            m_buf_ptr.reset(to_buf.release());
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
