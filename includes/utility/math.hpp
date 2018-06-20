#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_MATH_HPP
#define UTILITY_MATH_HPP

#include <tacklelib.hpp>

#include <utility/preprocessor.hpp>
#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/assert.hpp>

#include <type_traits>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <utility>

#include <float.h>
#include <cmath>


#define INT32_LOG2_FLOOR_CONSTEXPR(x)               ::math::int32_log2_floor<x>::value
#define UINT32_LOG2_FLOOR_CONSTEXPR(x)              ::math::uint32_log2_floor<x>::value
#define INT32_LOG2_CEIL_CONSTEXPR(x)                ::math::int32_log2_ceil<x>::value
#define UINT32_LOG2_CEIL_CONSTEXPR(x)               ::math::uint32_log2_ceil<x>::value

#define INT32_POF2_FLOOR_CONSTEXPR(x)               ::math::int32_pof2_floor<x>::value
#define UINT32_POF2_FLOOR_CONSTEXPR(x)              ::math::uint32_pof2_floor<x>::value

#define INT32_POF2_CEIL_CONSTEXPR(x)                ::math::int32_pof2_ceil<x>::value
#define UINT32_POF2_CEIL_CONSTEXPR(x)               ::math::uint32_pof2_ceil<x>::value

#define INT32_LOG2_CONSTEXPR_VERIFY(x)              ::math::int32_log2_verify<x>::value
#define UINT32_LOG2_CONSTEXPR_VERIFY(x)             ::math::uint32_log2_verify<x>::value
#define STDSIZE_LOG2_CONSTEXPR_VERIFY(x)            ::math::stdsize_log2_verify<x>::value

#define INT32_POF2_CONSTEXPR_VERIFY(x)              ::math::int32_pof2_verify<x>::value
#define UINT32_POF2_CONSTEXPR_VERIFY(x)             ::math::uint32_pof2_verify<x>::value


#define INT32_LOG2_FLOOR(x)                         ::math::int_log2_floor<int32_t>(x)
#define UINT32_LOG2_FLOOR(x)                        ::math::int_log2_floor<uint32_t>(x)
#define INT32_LOG2_CEIL(x)                          ::math::int_log2_ceil<int32_t>(x)
#define UINT32_LOG2_CEIL(x)                         ::math::int_log2_ceil<uint32_t>(x)

#define INT32_POF2_FLOOR(x)                         ::math::int_pof2_floor<int32_t>(x)
#define UINT32_POF2_FLOOR(x)                        ::math::int_pof2_floor<uint32_t>(x)
#define INT32_POF2_CEIL(x)                          ::math::int_pof2_ceil<int32_t>(x)
#define UINT32_POF2_CEIL(x)                         ::math::int_pof2_ceil<uint32_t>(x)

#define INT32_LOG2_FLOOR_VERIFY(x)                  ::math::int_log2_floor_verify<int32_t>(x)
#define UINT32_LOG2_FLOOR_VERIFY(x)                 ::math::int_log2_floor_verify<uint32_t>(x)
#define INT32_LOG2_CEIL_VERIFY(x)                   ::math::int_log2_ceil_verify<int32_t>(x)
#define UINT32_LOG2_CEIL_VERIFY(x)                  ::math::int_log2_ceil_verify<uint32_t>(x)

#define INT32_POF2_FLOOR_VERIFY(x)                  ::math::int_pof2_floor_verify<int32_t>(x)
#define UINT32_POF2_FLOOR_VERIFY(x)                 ::math::int_pof2_floor_verify<uint32_t>(x)
#define INT32_POF2_CEIL_VERIFY(x)                   ::math::int_pof2_ceil_verify<int32_t>(x)
#define UINT32_POF2_CEIL_VERIFY(x)                  ::math::int_pof2_ceil_verify<uint32_t>(x)


#define INT32_MULT_POF2_FLOOR_CONSTEXPR(x, y)       int32_t(int32_t(x) << INT32_LOG2_FLOOR_CONSTEXPR(y))
#define UINT32_MULT_POF2_FLOOR_CONSTEXPR(x, y)      uint32_t(uint32_t(x) << UINT32_LOG2_FLOOR_CONSTEXPR(y))
#define INT32_MULT_POF2_CEIL_CONSTEXPR(x, y)        int32_t(int32_t(x) << INT32_LOG2_CEIL_CONSTEXPR(y))
#define UINT32_MULT_POF2_CEIL_CONSTEXPR(x, y)       uint32_t(uint32_t(x) << UINT32_LOG2_CEIL_CONSTEXPR(y))

#define INT32_MULT_POF2_CONSTEXPR_VERIFY(x, y)      int32_t(int32_t(x) << INT32_LOG2_CONSTEXPR_VERIFY(y))
#define UINT32_MULT_POF2_CONSTEXPR_VERIFY(x, y)     uint32_t(uint32_t(x) << UINT32_LOG2_CONSTEXPR_VERIFY(y))

#define INT32_DIV_POF2_FLOOR_CONSTEXPR(x, y)        int32_t(int32_t(x) >> INT32_LOG2_FLOOR_CONSTEXPR(y))
#define UINT32_DIV_POF2_FLOOR_CONSTEXPR(x, y)       uint32_t(uint32_t(x) >> UINT32_LOG2_FLOOR_CONSTEXPR(y))
#define INT32_DIV_POF2_CEIL_CONSTEXPR(x, y)         int32_t(int32_t(x) >> INT32_LOG2_CEIL_CONSTEXPR(y))
#define UINT32_DIV_POF2_CEIL_CONSTEXPR(x, y)        uint32_t(uint32_t(x) >> UINT32_LOG2_CEIL_CONSTEXPR(y))

#define INT32_DIV_POF2_CONSTEXPR_VERIFY(x, y)       int32_t(int32_t(x) >> INT32_LOG2_CONSTEXPR_VERIFY(y))
#define UINT32_DIV_POF2_CONSTEXPR_VERIFY(x, y)      uint32_t(uint32_t(x) >> UINT32_LOG2_CONSTEXPR_VERIFY(y))
#define STDSIZE_DIV_POF2_CONSTEXPR_VERIFY(x, y)     std::size_t(std::size_t(x) >> STDSIZE_LOG2_CONSTEXPR_VERIFY(y))

#define INT32_DIVREM_POF2_FLOOR_CONSTEXPR_Y(x, y)   ::math::divrem<int32_t>{ INT32_DIV_POF2_FLOOR(x, y), int32_t(x) & (INT32_POF2_FLOOR_CONSTEXPR(y) - 1) }
#define UINT32_DIVREM_POF2_FLOOR_CONSTEXPR_Y(x, y)  ::math::divrem<uint32_t>{ UINT32_DIV_POF2_FLOOR(x, y), uint32_t(x) & (UINT32_POF2_FLOOR_CONSTEXPR(y) - 1) }
#define INT32_DIVREM_POF2_CEIL_CONSTEXPR_Y(x, y)    ::math::divrem<int32_t>{ INT32_DIV_POF2_CEIL(x, y), int32_t(x) & (INT32_POF2_CEIL_CONSTEXPR(y) - 1) }
#define UINT32_DIVREM_POF2_CEIL_CONSTEXPR_Y(x, y)   ::math::divrem<uint32_t>{ UINT32_DIV_POF2_CEIL(x, y), uint32_t(x) & (UINT32_POF2_CEIL_CONSTEXPR(y) - 1) }

#define INT32_DIVREM_POF2_FLOOR_CONSTEXPR_XY(x, y)  ::math::divrem<int32_t>{ INT32_DIV_POF2_FLOOR_CONSTEXPR(x, y), int32_t(x) & (INT32_POF2_FLOOR_CONSTEXPR(y) - 1) }
#define UINT32_DIVREM_POF2_FLOOR_CONSTEXPR_XY(x, y) ::math::divrem<uint32_t>{ UINT32_DIV_POF2_FLOOR_CONSTEXPR(x, y), uint32_t(x) & (UINT32_POF2_FLOOR_CONSTEXPR(y) - 1) }
#define INT32_DIVREM_POF2_CEIL_CONSTEXPR_XY(x, y)   ::math::divrem<int32_t>{ INT32_DIV_POF2_CEIL_CONSTEXPR(x, y), int32_t(x) & (INT32_POF2_CEIL_CONSTEXPR(y) - 1) }
#define UINT32_DIVREM_POF2_CEIL_CONSTEXPR_XY(x, y)  ::math::divrem<uint32_t>{ UINT32_DIV_POF2_CEIL_CONSTEXPR(x, y), uint32_t(x) & (UINT32_POF2_CEIL_CONSTEXPR(y) - 1) }

#define INT32_DIVREM_POF2_CONSTEXPR_VERIFY(x, y)   ::math::divrem<int32_t>{ INT32_DIV_POF2_CONSTEXPR_VERIFY(x, y), int32_t(x) & (INT32_POF2_CONSTEXPR_VERIFY(y) - 1) }
#define UINT32_DIVREM_POF2_CONSTEXPR_VERIFY(x, y)  ::math::divrem<uint32_t>{ UINT32_DIV_POF2_CONSTEXPR_VERIFY(x, y), uint32_t(x) & (UINT32_POF2_CONSTEXPR_VERIFY(y) - 1) }


#define INT32_MULT_POF2_FLOOR(x, y)                 int32_t(int32_t(x) << INT32_LOG2_FLOOR(y))
#define UINT32_MULT_POF2_FLOOR(x, y)                uint32_t(uint32_t(x) << UINT32_LOG2_FLOOR(y))
#define INT32_MULT_POF2_CEIL(x, y)                  int32_t(int32_t(x) << INT32_LOG2_CEIL(y))
#define UINT32_MULT_POF2_CEIL(x, y)                 uint32_t(uint32_t(x) << UINT32_LOG2_CEIL(y))

#define INT32_MULT_POF2_FLOOR_VERIFY(x, y)          int32_t(int32_t(x) << INT32_LOG2_FLOOR_VERIFY(y))
#define UINT32_MULT_POF2_FLOOR_VERIFY(x, y)         uint32_t(uint32_t(x) << UINT32_LOG2_FLOOR_VERIFY(y))
#define INT32_MULT_POF2_CEIL_VERIFY(x, y)           int32_t(int32_t(x) << INT32_LOG2_CEIL_VERIFY(y))
#define UINT32_MULT_POF2_CEIL_VERIFY(x, y)          uint32_t(uint32_t(x) << UINT32_LOG2_CEIL_VERIFY(y))

#define INT32_DIV_POF2_FLOOR(x, y)                  int32_t(int32_t(x) >> INT32_LOG2_FLOOR(y))
#define UINT32_DIV_POF2_FLOOR(x, y)                 uint32_t(uint32_t(x) >> UINT32_LOG2_FLOOR(y))
#define INT32_DIV_POF2_CEIL(x, y)                   int32_t(int32_t(x) >> INT32_LOG2_CEIL(y))
#define UINT32_DIV_POF2_CEIL(x, y)                  uint32_t(uint32_t(x) >> UINT32_LOG2_CEIL(y))

#define INT32_DIV_POF2_FLOOR_VERIFY(x, y)           int32_t(int32_t(x) >> INT32_LOG2_FLOOR_VERIFY(y))
#define UINT32_DIV_POF2_FLOOR_VERIFY(x, y)          uint32_t(uint32_t(x) >> UINT32_LOG2_FLOOR_VERIFY(y))
#define INT32_DIV_POF2_CEIL_VERIFY(x, y)            int32_t(int32_t(x) >> INT32_LOG2_CEIL_VERIFY(y))
#define UINT32_DIV_POF2_CEIL_VERIFY(x, y)           uint32_t(uint32_t(x) >> UINT32_LOG2_CEIL_VERIFY(y))

#define INT32_DIVREM_POF2_FLOOR(x, y)               ::math::divrem<int32_t>{ INT32_DIV_POF2_FLOOR(x, y), int32_t(x) & (INT32_POF2_FLOOR(y) - 1) }
#define UINT32_DIVREM_POF2_FLOOR(x, y)              ::math::divrem<uint32_t>{ UINT32_DIV_POF2_FLOOR(x, y), uint32_t(x) & (UINT32_POF2_FLOOR(y) - 1) }
#define INT32_DIVREM_POF2_CEIL(x, y)                ::math::divrem<int32_t>{ INT32_DIV_POF2_CEIL(x, y), int32_t(x) & (INT32_POF2_CEIL(y) - 1) }
#define UINT32_DIVREM_POF2_CEIL(x, y)               ::math::divrem<uint32_t>{ UINT32_DIV_POF2_CEIL(x, y), uint32_t(x) & (UINT32_POF2_CEIL(y) - 1) }

#define INT32_DIVREM_POF2_FLOOR_VERIFY(x, y)        ::math::divrem<int32_t>{ INT32_DIV_POF2_FLOOR_VERIFY(x, y), int32_t(x) & (INT32_POF2_FLOOR_VERIFY(y) - 1) }
#define UINT32_DIVREM_POF2_FLOOR_VERIFY(x, y)       ::math::divrem<uint32_t>{ UINT32_DIV_POF2_FLOOR_VERIFY(x, y), uint32_t(x) & (UINT32_POF2_FLOOR_VERIFY(y) - 1) }
#define INT32_DIVREM_POF2_CEIL_VERIFY(x, y)         ::math::divrem<int32_t>{ INT32_DIV_POF2_CEIL_VERIFY(x, y), int32_t(x) & (INT32_POF2_CEIL_VERIFY(y) - 1) }
#define UINT32_DIVREM_POF2_CEIL_VERIFY(x, y)        ::math::divrem<uint32_t>{ UINT32_DIV_POF2_CEIL_VERIFY(x, y), uint32_t(x) & (UINT32_POF2_CEIL_VERIFY(y) - 1) }


// implementation through the define to reuse code in debug and avoid performance slow down in particular usage places
#define INT32_POF2_FLOOR_MACRO_INLINE(return_exp, type_, v) \
{ \
    STATIC_ASSERT_GE(4, sizeof(v), "general implementation only for numbers which sizeof is not greater than 4 bytes"); \
    DEBUG_VERIFY_GT(v, (type_)(0)); \
    \
    using unsigned_type = typename ::std::make_unsigned<type_>::type; \
    unsigned_type unsigned_value = unsigned_type(v); \
    \
    unsigned_value |= (unsigned_value >> 1); \
    unsigned_value |= (unsigned_value >> 2); \
    unsigned_value |= (unsigned_value >> 4); \
    unsigned_value |= (unsigned_value >> 8); \
    unsigned_value |= (unsigned_value >> 16); \
    \
    const type_ shifted_value = (type_)(unsigned_value >> 1); \
    \
    return_exp (type_)(shifted_value + 1); \
} (void)0

#define INT32_POF2_CEIL_MACRO_INLINE(return_exp, type, v) \
{ \
    DEBUG_ASSERT_GT(v, (type)(0)); \
    DEBUG_ASSERT_GE(::std::is_unsigned<type>::value ? v : ((::std::numeric_limits<type>::max)() / 2), v); \
    \
    type pof2_floor_value; \
    INT32_POF2_FLOOR_MACRO_INLINE(pof2_floor_value =, type, v); \
    \
    return_exp (pof2_floor_value != v ? (type)(pof2_floor_value << 1) : pof2_floor_value); \
} (void)0

#define INT32_LOG2_FLOOR_MACRO_INLINE(return_exp, type, v, pof2_value_ptr) \
if_break(true) \
{ \
    STATIC_ASSERT_GE(4, sizeof(v), "general implementation only for numbers which sizeof is not greater than 4 bytes"); \
    DEBUG_ASSERT_GT(v, (type)(0)); \
    \
    type * pof2_value_ptr_ = (pof2_value_ptr); \
    \
    if ((type)(1) >= v) { \
        if (pof2_value_ptr_) { \
            if (v >= (type)(0)) { \
                *pof2_value_ptr_ = v; \
            } \
            else { \
                *pof2_value_ptr_ = (type)(0); \
            } \
        } \
        return_exp (type)(0); \
        break; \
    } \
    \
    type pof2_prev_value; \
    INT32_POF2_FLOOR_MACRO_INLINE(pof2_prev_value =, type, v); \
    \
    if (pof2_value_ptr_) { \
        *pof2_value_ptr_ = pof2_prev_value; \
    } \
    \
    type ret = (type)(0); \
    \
    /* unrolled recursion including unrolled loops */ \
    type pof2_next_value = (pof2_prev_value >> 16); \
    \
    if (pof2_next_value) { \
        ret += 16; \
        pof2_prev_value = pof2_next_value; \
        pof2_next_value >>= 8; \
    } \
    else pof2_next_value = (pof2_prev_value >> 8); \
    \
    if (pof2_next_value) { \
        ret += 8; \
        pof2_prev_value = pof2_next_value; \
        pof2_next_value >>= 4; \
    } \
    else { \
        pof2_next_value = (pof2_prev_value >> 4); \
    } \
    \
    if (pof2_next_value) { \
        ret += 4; \
        pof2_prev_value = pof2_next_value; \
        pof2_next_value >>= 2; \
    } \
    else { \
        pof2_next_value = (pof2_prev_value >> 2); \
    } \
    \
    if (pof2_next_value) { \
        ret += 2; \
        pof2_next_value >>= 1; \
    } \
    else { \
        pof2_next_value = (pof2_prev_value >> 1); \
    } \
    \
    if (pof2_next_value) ret++; \
    \
    return_exp ret; \
} (void)0

#define INT32_LOG2_CEIL_MACRO_INLINE(return_exp, type, v, pof2_value_ptr) \
if_break(true) \
{ \
    DEBUG_ASSERT_GT(v, (type)(0)); \
    DEBUG_ASSERT_GE(::std::is_unsigned<type>::value ? v : ((::std::numeric_limits<type>::max)() / 2), v); \
    \
    type * pof2_value_ptr_ = (pof2_value_ptr); \
    \
    if ((type)(1) >= v) { \
        if (pof2_value_ptr_) { \
            if (v >= (type)(0)) { \
                *pof2_value_ptr_ = v; \
            } \
            else { \
                *pof2_value_ptr_ = (type)(0); \
            } \
        } \
        return_exp (type)(0); \
        break; \
    } \
    \
    type log2_prev_value = (type)(v - 1); \
    type log2_floor_value; \
    \
    if (!pof2_value_ptr_) { \
        INT32_LOG2_FLOOR_MACRO_INLINE(log2_floor_value =, type, log2_prev_value, nullptr); \
    } \
    else { \
        type pof2_floor_value; \
        \
        INT32_LOG2_FLOOR_MACRO_INLINE(log2_floor_value =, type, log2_prev_value, &pof2_floor_value); \
        \
        *pof2_value_ptr_ = (type)(pof2_floor_value << 1); \
    } \
    \
    return_exp (type)(log2_floor_value + 1); \
} (void)0

namespace math
{
    // shortcuts
    const constexpr char char_max = (std::numeric_limits<char>::max)();
    const constexpr unsigned char uchar_max = (std::numeric_limits<unsigned char>::max)();

    const constexpr short short_max = (std::numeric_limits<short>::max)();
    const constexpr unsigned short ushort_max = (std::numeric_limits<unsigned short>::max)();

    const constexpr int int_max = (std::numeric_limits<int>::max)();
    const constexpr unsigned int uint_max = (std::numeric_limits<unsigned int>::max)();

    const constexpr long long_max = (std::numeric_limits<long>::max)();
    const constexpr unsigned long ulong_max = (std::numeric_limits<unsigned long>::max)();

#ifdef UTILITY_PLATFORM_CXX_STANDARD_LLONG
    const constexpr long long longlong_max = (std::numeric_limits<long long>::max)();
#endif
#ifdef UTILITY_PLATFORM_CXX_STANDARD_ULLONG
    const constexpr unsigned long long ulonglong_max = (std::numeric_limits<unsigned long long>::max)();
#endif

    const constexpr int8_t int8_max = (std::numeric_limits<int8_t>::max)();
    const constexpr uint8_t uint8_max = (std::numeric_limits<uint8_t>::max)();

    const constexpr int16_t int16_max = (std::numeric_limits<int16_t>::max)();
    const constexpr uint16_t uint16_max = (std::numeric_limits<uint16_t>::max)();

    const constexpr int32_t int32_max = (std::numeric_limits<int32_t>::max)();
    const constexpr uint32_t uint32_max = (std::numeric_limits<uint32_t>::max)();

    const constexpr int64_t int64_max = (std::numeric_limits<int64_t>::max)();
    const constexpr uint64_t uint64_max = (std::numeric_limits<uint64_t>::max)();

    const constexpr size_t size_max = (std::numeric_limits<size_t>::max)();

    const constexpr double quiet_NaN = (std::numeric_limits<double>::quiet_NaN)();

    const constexpr double pi = 3.14159265358979323846264338327950288419716939937510582;

    template<typename T>
    struct divrem
    {
        T quot;
        T rem;
    };

    //// constexpr log2 floor

    template<int32_t x>
    struct int32_log2_floor
    {
        STATIC_ASSERT_GT(x, 0, "value must be positive");
        static const int32_t value = (int32_log2_floor<x / 2>::value + 1);
    };

    template<int32_t x>
    const int32_t int32_log2_floor<x>::value;

    template<>
    struct int32_log2_floor<0>;
    template<>
    struct int32_log2_floor<1>
    {
        static const int32_t value = 0;
    };

    template<uint32_t x>
    struct uint32_log2_floor
    {
        static const uint32_t value = (uint32_log2_floor<x / 2>::value + 1);
    };

    template<uint32_t x>
    const uint32_t uint32_log2_floor<x>::value;

    template<>
    struct uint32_log2_floor<0>;
    template<>
    struct uint32_log2_floor<1>
    {
        static const uint32_t value = 0;
    };

    template<std::size_t x>
    struct stdsize_log2_floor
    {
        static const std::size_t value = (stdsize_log2_floor<x / 2>::value + 1);
    };

    template<std::size_t x>
    const std::size_t stdsize_log2_floor<x>::value;

    template<>
    struct stdsize_log2_floor<0>;
    template<>
    struct stdsize_log2_floor<1>
    {
        static const std::size_t value = 0;
    };

    //// constexpr log2 ceil

    template<int32_t x>
    struct int32_log2_ceil
    {
        STATIC_ASSERT_GT(x, 0, "value must be positive");
        STATIC_ASSERT_TRUE2(int32_max / 2 >= x, int32_max, x, "value is too big");
        static const int32_t value = (int32_log2_floor<(x + x - 1) / 2>::value + 1);
    };

    template<int32_t x>
    const int32_t int32_log2_ceil<x>::value;

    template<>
    struct int32_log2_ceil<0>;
    template<>
    struct int32_log2_ceil<1>
    {
        static const int32_t value = 0;
    };

    template<uint32_t x>
    struct uint32_log2_ceil
    {
        STATIC_ASSERT_TRUE2(uint32_max / 2 >= x, uint32_max, x, "value is too big");
        static const uint32_t value = (uint32_log2_floor<(x + x - 1) / 2>::value + 1);
    };

    template<uint32_t x>
    const uint32_t uint32_log2_ceil<x>::value;

    template<>
    struct uint32_log2_ceil<0>;
    template<>
    struct uint32_log2_ceil<1>
    {
        static const uint32_t value = 0;
    };

    //// constexpr log2 assert

    template<int32_t x>
    struct int32_log2_verify
    {
        STATIC_ASSERT_TRUE1(x && !(x & (x - 1)), x, "value must be power of 2");
        static const int32_t value = int32_log2_floor<x>::value;
    };

    template<int32_t x>
    const int32_t int32_log2_verify<x>::value;

    template<uint32_t x>
    struct uint32_log2_verify
    {
        STATIC_ASSERT_TRUE1(x && !(x & (x - 1)), x, "value must be power of 2");
        static const uint32_t value = uint32_log2_floor<x>::value;
    };

    template<uint32_t x>
    const uint32_t uint32_log2_verify<x>::value;

    template<std::size_t x>
    struct stdsize_log2_verify
    {
        STATIC_ASSERT_TRUE1(x && !(x & (x - 1)), x, "value must be power of 2");
        static const std::size_t value = stdsize_log2_floor<x>::value;
    };

    template<std::size_t x>
    const std::size_t stdsize_log2_verify<x>::value;

    //// constexpr pof2 floor

    template<uint32_t x>
    struct uint32_pof2_floor;

    template<int32_t x>
    struct int32_pof2_floor
    {
        static const int32_t value = int32_t(uint32_pof2_floor<uint32_t(x)>::value);
    };

    template<>
    struct int32_pof2_floor<0>;

    template<int32_t x>
    const int32_t int32_pof2_floor<x>::value;

    template<uint32_t x>
    struct uint32_pof2_floor
    {
        using x1_t  = std::integral_constant<uint32_t, x | (x >> 1)>;
        using x2_t = std::integral_constant<uint32_t, x1_t::value | (x1_t::value >> 2)>;
        using x4_t = std::integral_constant<uint32_t, x2_t::value | (x2_t::value >> 4)>;
        using x8_t = std::integral_constant<uint32_t, x4_t::value | (x4_t::value >> 8)>;
        using x16_t = std::integral_constant<uint32_t, x8_t::value | (x8_t::value >> 16)>;

        static const uint32_t value = (x16_t::value >> 1) + 1;
    };

    template<>
    struct uint32_pof2_floor<0>;

    template<uint32_t x>
    const uint32_t uint32_pof2_floor<x>::value;

    //// constexpr pof2 ceil

    template<uint32_t x>
    struct uint32_pof2_ceil;

    template<int32_t x>
    struct int32_pof2_ceil
    {
        static const int32_t value = int32_t(uint32_pof2_ceil<uint32_t(x)>::value);
    };

    template<int32_t x>
    const int32_t int32_pof2_ceil<x>::value;

    template<uint32_t x>
    struct uint32_pof2_ceil
    {
        using uint32_pof2_floor_t = uint32_pof2_floor<x>;
        static const uint32_t value = uint32_pof2_floor_t::value != x ? (uint32_pof2_floor_t::value << 1) : uint32_pof2_floor_t::value;
    };

    template<uint32_t x>
    const uint32_t uint32_pof2_ceil<x>::value;

    //// constexpr pof2 assert

    template<int32_t x>
    struct int32_pof2_verify
    {
        STATIC_ASSERT_TRUE1(x && !(x & (x - 1)), x, "value must be power of 2");
        static const int32_t value = x;
    };

    template<int32_t x>
    const int32_t int32_pof2_verify<x>::value;

    template<uint32_t x>
    struct uint32_pof2_verify
    {
        STATIC_ASSERT_TRUE1(x && !(x & (x - 1)), x, "value must be power of 2");
        static const uint32_t value = x;
    };

    template<uint32_t x>
    const uint32_t uint32_pof2_verify<x>::value;


    // to suppress compilation warning:
    //  `warning C4146 : unary minus operator applied to unsigned type, result still unsigned`
    FORCE_INLINE_ALWAYS unsigned int negate(unsigned int i)
    {
        return static_cast<unsigned int>(-static_cast<int>(i));
    }

    FORCE_INLINE_ALWAYS unsigned long negate(unsigned long i)
    {
        return static_cast<unsigned long>(-static_cast<long>(i));
    }

#ifdef UTILITY_PLATFORM_CXX_STANDARD_ULLONG
    FORCE_INLINE_ALWAYS unsigned long long negate(unsigned long long i)
    {
        return static_cast<unsigned long long>(-static_cast<long long>(i));
    }
#endif

    FORCE_INLINE_ALWAYS int negate(int i)
    {
        return -i;
    }

    FORCE_INLINE_ALWAYS long negate(long i)
    {
        return -i;
    }

#ifdef UTILITY_PLATFORM_CXX_STANDARD_LLONG
    FORCE_INLINE_ALWAYS long long negate(long long i)
    {
        return -i;
    }
#endif

    template<typename R, typename T0, typename T1>
    FORCE_INLINE R t_add_no_overflow(T0 a, T1 b)
    {
        R res = R(a + b);
        res |= -(res < a);
        return res;
    }

    template<typename R, typename T0, typename T1>
    FORCE_INLINE R t_sub_no_overflow(T0 a, T1 b)
    {
        R res = R(a - b);
        res &= -(res <= a);
        return res;
    }

    FORCE_INLINE_ALWAYS uint32_t uint32_add_no_overflow(uint32_t a, uint32_t b)
    {
        return t_add_no_overflow<uint32_t>(a, b);
    }

    FORCE_INLINE_ALWAYS uint64_t uint64_add_no_overflow(uint64_t a, uint64_t b)
    {
        return t_add_no_overflow<uint64_t>(a, b);
    }

    FORCE_INLINE_ALWAYS uint32_t uint32_sub_no_overflow(uint32_t a, uint32_t b)
    {
        return t_sub_no_overflow<uint32_t>(a, b);
    }

    FORCE_INLINE_ALWAYS uint64_t uint64_sub_no_overflow(uint64_t a, uint64_t b)
    {
        return t_sub_no_overflow<uint64_t>(a, b);
    }

    template <typename T>
    FORCE_INLINE T sum_naturals(T v)
    {
        if (v >= 0)
        {
            if (v % 2) {
                return T(((v + 1) >> 1) * v);
            }

            return T((v >> 1) * (v + 1));
        }

        const T n = negate(v);
        if (n % 2) {
            return T(1) - T(((n + 1) >> 1) * n);
        }

        return T(1) - T((n >> 1) * (n + 1));
    }

    FORCE_INLINE_ALWAYS uint64_t sum_naturals(uint64_t from, uint64_t to)
    {
        if (!from)
        {
            return sum_naturals(to);
        }

        return sum_naturals(to) - sum_naturals(from - 1);
    }

    //// runtime pof2 floor

    FORCE_INLINE uint32_t pof2_floor(uint32_t x)
    {
        INT32_POF2_FLOOR_MACRO_INLINE(return, uint32_t, x);
    }

    FORCE_INLINE uint32_t pof2_ceil(uint32_t x)
    {
        INT32_POF2_CEIL_MACRO_INLINE(return, uint32_t, x);
    }

    template <typename T>
    FORCE_INLINE T int_pof2_floor(T v)
    {
        INT32_POF2_FLOOR_MACRO_INLINE(return, T, v);
    }

    template <typename T>
    FORCE_INLINE T int_pof2_ceil(T v)
    {
        INT32_POF2_CEIL_MACRO_INLINE(return, T, v);
    }

    //// runtime pof2 floor assert

    template <typename T>
    FORCE_INLINE T int_pof2_floor_verify(T v)
    {
        T pof2_value;
        INT32_POF2_FLOOR_MACRO_INLINE(pof2_value =, T, v);

        DEBUG_ASSERT_EQ(pof2_value, v);

        return pof2_value;
    }

    //// runtime pof2 ceil assert

    template <typename T>
    FORCE_INLINE T int_pof2_ceil_verify(T v)
    {
        T pof2_value;
        INT32_POF2_CEIL_MACRO_INLINE(pof2_value =, T, v);

        DEBUG_ASSERT_EQ(pof2_value, v);

        return pof2_value;
    }

    //// runtime log2 floor

    template <typename T>
    FORCE_INLINE T int_log2_floor(T v, T * pof2_value_ptr = nullptr)
    {
        INT32_LOG2_FLOOR_MACRO_INLINE(return, T, v, pof2_value_ptr);
    }

    //// runtime log2 ceil

    template <typename T>
    FORCE_INLINE T int_log2_ceil(T v, T * pof2_value_ptr = nullptr)
    {
        INT32_LOG2_CEIL_MACRO_INLINE(return, T, v, pof2_value_ptr);
    }

    //// runtime log2 floor assert

    template <typename T>
    FORCE_INLINE T int_log2_floor_verify(T v)
    {
        T log2_value;

#if ERROR_IF_EMPTY_PP_DEF(DEBUG_ASSERT_VERIFY_ENABLED)
        T pof2_value;
        INT32_LOG2_FLOOR_MACRO_INLINE(log2_value =, T, v, &pof2_value);

        DEBUG_ASSERT_EQ(pof2_value, v);
#else
        INT32_LOG2_FLOOR_MACRO_INLINE(log2_value =, T, v, nullptr);
#endif

        return log2_value;
    }

    //// runtime log2 ceil assert

    template <typename T>
    FORCE_INLINE T int_log2_ceil_verify(T v)
    {
        T log2_value;

#if ERROR_IF_EMPTY_PP_DEF(DEBUG_ASSERT_VERIFY_ENABLED)
        T pof2_value;

        INT32_LOG2_CEIL_MACRO_INLINE(log2_value =, T, v, &pof2_value);

        DEBUG_ASSERT_EQ(pof2_value, v);
#else
        INT32_LOG2_CEIL_MACRO_INLINE(log2_value =, T, v, nullptr);
#endif

        return log2_value;
    }


    // inclusion_direction:
    //  -1 - minimal is included, maximal is excluded (ex: [   0 - +360) )
    //  +1 - minimal is excluded, maximal is included (ex: (-180 - +180] )
    //   0 - minimal and maximal both included (ex: [0 - +180] or [-90 - +90])
    extern inline double normalize_angle(double ang, double min_ang, double max_ang, double ang_period_mod, int inclusion_direction)
    {
        DEBUG_ASSERT_LT(min_ang, max_ang);
        DEBUG_ASSERT_GT(ang_period_mod, 0U); // must be always positive

        DEBUG_ASSERT_GE(min_ang, -ang_period_mod);
        DEBUG_ASSERT_GE(+ang_period_mod, max_ang);

        if (!BASIC_VERIFY_TRUE(inclusion_direction >= -1 && +1 >= inclusion_direction)) {
            // just in case
            inclusion_direction = 0; // prefer symmetric case
        }

        double ang_norm = ang;

        switch (inclusion_direction) {
        case -1:
            if (ang >= min_ang && max_ang > ang) {
                return ang;
            }

            ang_norm = ang;

            if (ang >= 0) {
                if (ang < ang_period_mod) {
                    const double ang_neg = ang - ang_period_mod;
                    if (ang_neg >= min_ang && max_ang > ang_neg) {
                        return ang_neg;
                    }
                    break;
                }
                else {
                    ang_norm = fmod(ang, ang_period_mod);
                    if (ang_norm >= min_ang && max_ang > ang_norm) {
                        return ang_norm;
                    }
                    else {
                        const double ang_neg = ang_norm - ang_period_mod;
                        if (ang_neg >= min_ang && max_ang > ang_neg) {
                            return ang_neg;
                        }
                    }
                }
            }
            else if (-ang < ang_period_mod) {
                const double ang_pos = ang + ang_period_mod;
                if (ang_pos >= min_ang && max_ang > ang_pos) {
                    return ang_pos;
                }
                // additional test in direction of inclusion
                else {
                    const double ang_neg = ang - ang_period_mod;
                    if (ang_neg >= min_ang && max_ang > ang_neg) {
                        return ang_neg;
                    }
                }
            }
            else {
                ang_norm = fmod(ang, ang_period_mod);
                if (ang_norm >= min_ang && max_ang > ang_norm) {
                    return ang_norm;
                }
                else {
                    const double ang_pos = ang_norm + ang_period_mod;
                    if (ang_pos >= min_ang && max_ang > ang_pos) {
                        return ang_pos;
                    }
                    // additional test in direction of inclusion
                    else {
                        const double ang_neg = ang_norm - ang_period_mod;
                        if (ang_neg >= min_ang && max_ang > ang_neg) {
                            return ang_neg;
                        }
                    }
                }
            }
            break;

        case 0:
            if (ang >= min_ang && max_ang >= ang) {
                return ang;
            }

            ang_norm = ang;

            if (ang >= 0) {
                if (ang < ang_period_mod) {
                    const double ang_neg = ang - ang_period_mod;
                    if (ang_neg >= min_ang && max_ang >= ang_neg) {
                        return ang_neg;
                    }
                    break;
                }
                else {
                    ang_norm = fmod(ang, ang_period_mod);
                    if (ang_norm >= min_ang && max_ang >= ang_norm) {
                        return ang_norm;
                    }
                    else {
                        const double ang_neg = ang_norm - ang_period_mod;
                        if (ang_neg >= min_ang && max_ang >= ang_neg) {
                            return ang_neg;
                        }
                    }
                }
            }
            else if (-ang < ang_period_mod) {
                const double ang_pos = ang + ang_period_mod;
                if (ang_pos >= min_ang && max_ang >= ang_pos) {
                    return ang_pos;
                }
            }
            else {
                ang_norm = fmod(ang, ang_period_mod);
                if (ang_norm >= min_ang && max_ang >= ang_norm) {
                    return ang_norm;
                }
                else {
                    const double ang_pos = ang_norm + ang_period_mod;
                    if (ang_pos >= min_ang && max_ang >= ang_pos) {
                        return ang_pos;
                    }
                }
            }
            break;

        case +1:
            if (ang > min_ang && max_ang >= ang) {
                return ang;
            }

            ang_norm = ang;

            if (ang >= 0) {
                if (ang < ang_period_mod) {
                    const double ang_neg = ang - ang_period_mod;
                    if (ang_neg > min_ang && max_ang >= ang_neg) {
                        return ang_neg;
                    }
                    // additional test in direction of inclusion
                    else {
                        const double ang_pos = ang + ang_period_mod;
                        if (ang_pos > min_ang && max_ang >= ang_pos) {
                            return ang_pos;
                        }
                    }
                    break;
                }
                else {
                    ang_norm = fmod(ang, ang_period_mod);
                    if (ang_norm > min_ang && max_ang >= ang_norm) {
                        return ang_norm;
                    }
                    else {
                        const double ang_neg = ang_norm - ang_period_mod;
                        if (ang_neg > min_ang && max_ang >= ang_neg) {
                            return ang_neg;
                        }
                        // additional test in direction of inclusion
                        else {
                            const double ang_pos = ang_norm + ang_period_mod;
                            if (ang_pos > min_ang && max_ang >= ang_pos) {
                                return ang_pos;
                            }
                        }
                    }
                }
            }
            else if (-ang < ang_period_mod) {
                const double ang_pos = ang + ang_period_mod;
                if (ang_pos > min_ang && max_ang >= ang_pos) {
                    return ang_pos;
                }
            }
            else {
                ang_norm = fmod(ang, ang_period_mod);
                if (ang_norm > min_ang && max_ang >= ang_norm) {
                    return ang_norm;
                }
                else {
                    const double ang_pos = ang_norm + ang_period_mod;
                    if (ang_pos > min_ang && max_ang >= ang_pos) {
                        return ang_pos;
                    }
                }
            }
            break;

        default:
            DEBUG_ASSERT_TRUE(false);
        }

        return ang_norm;
    }
}

#endif
