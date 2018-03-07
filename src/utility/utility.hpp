#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/type_traits.hpp>
#include <utility/math.hpp>
#include <tackle/file_handle.hpp>

#ifdef UTILITY_COMPILER_CXX_MSC
#include <intrin.h>
#else
#include <x86intrin.h>  // Not just <immintrin.h> for compilers other than icc
#endif

#include <boost/preprocessor/cat.hpp>
#include <boost/format.hpp>

#include <bitset>
#include <limits>

#include <sstream>
#include <iomanip>


#define if_break(x) if(!(x)); else switch(0) case 0: default:
#define if_break2(label, x) if(!(x)) label:; else switch(0) case 0: default:

#define SCOPED_TYPEDEF(type_, typedef_) typedef struct { typedef type_ type; } typedef_


namespace utility
{
    using namespace math;
    using namespace tackle;

    // simple buffer to reallocate memory on demand
    //
    //  CAUTION:
    //      Because the buffer class does not reallocate memory if requested buffer size less than already existed, then out of size read/write access WOULD NOT BE CATCHED!
    //      To workaround that we must AT LEAST do guard the end of the buffer in the DEBUG.
    //
    class Buffer
    {
        typedef std::shared_ptr<uint8_t> BufSharedPtr;

        static const char s_guard_sequence_str[4];

    public:
        FORCE_INLINE Buffer(size_t size = 0) :
            m_size(0), m_reserve(0)
#ifdef ENABLE_BUFFER_REALLOC_AFTER_ALLOC
            , m_is_reallocating(false)
#endif
        {
            reset(size);
        }

        void _check_buffer_guards();
        void _fill_buffer_guards();

        FORCE_INLINE void reset(size_t size)
        {
#if defined(ENABLE_PERSISTENT_BUFFER_GUARD_CHECK) || defined(_DEBUG)
            _check_buffer_guards();
#endif

            // reallocate only if greater, deallocate only if 0
            if (size) {
                if (m_size < size) {
                    m_buf_ptr = BufSharedPtr(new uint8_t[size], std::default_delete<uint8_t[]>());
                    m_reserve = m_size = size;
                }

#if defined(ENABLE_PERSISTENT_BUFFER_GUARD_CHECK) || defined(_DEBUG)
                _fill_buffer_guards();
#endif
            }
            else {
                m_buf_ptr.reset();
                m_reserve = m_size = 0;
            }
        }

        FORCE_INLINE size_t size() const
        {
            return m_size;
        }

        FORCE_INLINE uint8_t * get()
        {
            return m_buf_ptr.get();
        }

        FORCE_INLINE const uint8_t * get() const
        {
            return m_buf_ptr.get();
        }

        FORCE_INLINE uint8_t * realloc_get(size_t size)
        {
            reset(size);

#ifdef ENABLE_BUFFER_REALLOC_AFTER_ALLOC
            if (!m_is_reallocating)
            {
                Buffer local_buf;

                local_buf.set_reallocating(true);

                realloc(local_buf);
            }
#endif

            return m_buf_ptr.get();
        }

#ifdef ENABLE_BUFFER_REALLOC_AFTER_ALLOC
        FORCE_INLINE void set_reallocating(bool is_reallocating)
        {
            m_is_reallocating = is_reallocating;
        }
#endif

        // for memory debugging on a moment of deallocation
        FORCE_INLINE void realloc(Buffer & to_buf)
        {
            uint8_t * to_buf_ptr = to_buf.realloc_get(m_size);
            memcpy(to_buf_ptr, m_buf_ptr.get(), m_size);

            *this = to_buf;
        }

#ifndef WIN64
        FORCE_INLINE uint8_t * realloc_get(uint64_t size)
        {
            if (UTILITY_CONST_EXPR(sizeof(size_t) < sizeof(uint64_t))) {
                const uint64_t max_value = uint64_t((std::numeric_limits<size_t>::max)());
                if (size > max_value) {
                    throw std::runtime_error(
                        (boost::format(
                            BOOST_PP_CAT(__FUNCTION__, ": size is out of memory: size=%llu max=%llu")) %
                                size % max_value).str());
                }
            }

            return realloc_get(size_t(size));
        }
#endif

    private:
        size_t          m_size;
        size_t          m_reserve;
        BufSharedPtr    m_buf_ptr;
#ifdef ENABLE_BUFFER_REALLOC_AFTER_ALLOC
        bool            m_is_reallocating;
#endif
    };

    uint64_t get_file_size(const FileHandle & file_handle);
    bool is_files_equal(const FileHandle & left_file_handle, const FileHandle & right_file_handle);
    FileHandle recreate_file(const std::string & file_path, const char * mode, int flags, size_t size = 0, uint32_t fill_by = 0);
    FileHandle create_file(const std::string & file_path, const char * mode, int flags, size_t size = 0, uint32_t fill_by = 0);
    FileHandle open_file(const std::string & file_path, const char * mode, int flags, size_t creation_size = 0, size_t resize_if_existed = -1, uint32_t fill_by_on_creation = 0);

    template<typename T>
    FORCE_INLINE std::string int_to_hex(T i, size_t padding = sizeof(T) * 2)
    {
        std::stringstream stream;
        stream << std::setfill('0') << std::setw(padding)
            << std::hex << i;
        return stream.str();
    }

    template<typename T>
    FORCE_INLINE std::string int_to_dec(T i, size_t padding = sizeof(T) * 2)
    {
        std::stringstream stream;
        stream << std::setfill('0') << std::setw(padding)
            << std::dec << i;
        return stream.str();
    }

    template<typename T>
    FORCE_INLINE void int_to_bin_forceinline(std::string & ret, T i, bool first_bit_is_lowest_bit = false)
    {
        std::bitset<sizeof(T) * CHAR_BIT> bs(i);
        if (!first_bit_is_lowest_bit) {
            ret = bs.to_string();
            return;
        }

        const std::string bs_str = bs.to_string();
        ret = std::string(bs_str.rbegin(), bs_str.rend());
        return;
    }

    template<typename T>
    inline std::string int_to_bin(T i, bool first_bit_is_lowest_bit = false)
    {
        std::string res;
        int_to_bin_forceinline(res, i, first_bit_is_lowest_bit);
        return res;
    }

    FORCE_INLINE uint8_t reverse(uint8_t byte)
    {
        byte = (byte & 0xF0) >> 4 | (byte & 0x0F) << 4;
        byte = (byte & 0xCC) >> 2 | (byte & 0x33) << 2;
        byte = (byte & 0xAA) >> 1 | (byte & 0x55) << 1;
        return byte;
    }

    template <typename T>
    FORCE_INLINE T reverse(T value)
    {
        T res = 0;
        for (size_t i = 0; i < sizeof(value) * CHAR_BIT; i++) {
            if (value & (0x01U << i)) {
                res |= (0x01U << (sizeof(value) * CHAR_BIT - i - 1));
            }
        }
        return res;
    }

    template<typename T>
    FORCE_INLINE uint32_t t_rotl32(uint32_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint32_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint32_t)");
        const uint32_t byte_mask = uint32_t(-1) >> (CHAR_BIT * (sizeof(uint32_t) - sizeof(T)));
        const uint32_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & ((n << c) | ((byte_mask & n) >> (mask & negate(c))));
    }

    template<typename T>
    FORCE_INLINE uint32_t t_rotr32(uint32_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint32_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint32_t)");
        const uint32_t byte_mask = uint32_t(-1) >> (CHAR_BIT * (sizeof(uint32_t) - sizeof(T)));
        const uint32_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & (((byte_mask & n) >> c) | (n << (mask & negate(c))));
    }

    template<typename T>
    FORCE_INLINE uint64_t t_rotl64(uint64_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint64_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint64_t)");
        const uint64_t byte_mask = uint64_t(-1) >> (CHAR_BIT * (sizeof(uint64_t) - sizeof(T)));
        const uint64_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & ((n << c) | ((byte_mask & n) >> (mask & negate(c))));
    }

    template<typename T>
    FORCE_INLINE uint64_t t_rotr64(uint64_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint64_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint64_t)");
        const uint64_t byte_mask = uint64_t(-1) >> (CHAR_BIT * (sizeof(uint64_t) - sizeof(T)));
        const uint64_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & (((byte_mask & n) >> c) | (n << (mask & negate(c))));
    }

    FORCE_INLINE uint32_t rotl8(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && defined(ENABLE_INTRINSIC)
        return _rotl8(unsigned char(n), unsigned char(c));
#else
        return t_rotl32<uint8_t>(n, c);
#endif
    }

    FORCE_INLINE uint32_t rotr8(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && defined(ENABLE_INTRINSIC)
        return _rotr8(unsigned char(n), unsigned char(c));
#else
        return t_rotr32<uint8_t>(n, c);
#endif
    }

    FORCE_INLINE uint32_t rotl16(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && defined(ENABLE_INTRINSIC)
        return _rotl16(unsigned short(n), unsigned char(c));
#else
        return t_rotl32<uint16_t>(n, c);
#endif
    }

    FORCE_INLINE uint32_t rotr16(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && defined(ENABLE_INTRINSIC)
        return _rotr16(unsigned short(n), unsigned char(c));
#else
        return t_rotr32<uint16_t>(n, c);
#endif
    }

    FORCE_INLINE uint32_t rotl32(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && defined(ENABLE_INTRINSIC)
        return _rotl(unsigned int(n), int(c));
#else
        return t_rotl32<uint32_t>(n, c);
#endif
    }

    FORCE_INLINE uint32_t rotr32(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && defined(ENABLE_INTRINSIC)
        return _rotr(unsigned int(n), int(c));
#else
        return t_rotr32<uint32_t>(n, c);
#endif
    }

    FORCE_INLINE uint64_t rotl64(uint64_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && defined(ENABLE_INTRINSIC)
        return _rotl64(unsigned long long(n), int(c));
#else
        return t_rotl64<uint64_t>(n, c);
#endif
    }

    FORCE_INLINE uint64_t rotr64(uint64_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && defined(ENABLE_INTRINSIC)
        return _rotr64(unsigned long long(n), int(c));
#else
        return t_rotr64<uint64_t>(n, c);
#endif
    }
}