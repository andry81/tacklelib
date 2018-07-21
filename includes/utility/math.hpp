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

#include <cfloat>
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


#define ANGLE_DEG_IN_RAD(angle_deg)                 ((angle_deg) * ::math::pi / 180)
#define ANGLE_DEG_IN_RAD_IF(in_radians, angle_deg)  ((in_radians) ? ANGLE_DEG_IN_RAD(angle_deg) : (angle_deg))

#define ANGLE_RAD_IN_DEG(angle_rad)                 ((angle_rad) * 180 / ::math::pi)
#define ANGLE_RAD_IN_DEG_IF(in_degrees, angle_rad)  ((in_degrees) ? ANGLE_RAD_IN_DEG(angle_rad) : (angle_rad))

#define DEG_45_IN_RAD                               (::math::pi / 4)
#define DEG_45_IN_RAD_IF(in_radians)                ((in_radians) ? DEG_45_IN_RAD : 45)

#define DEG_90_IN_RAD                               (::math::pi / 2)
#define DEG_90_IN_RAD_IF(in_radians)                ((in_radians) ? DEG_90_IN_RAD : 90)

#define DEG_135_IN_RAD                              (::math::pi * 3 / 4)
#define DEG_135_IN_RAD_IF(in_radians)               ((in_radians) ? DEG_135_IN_RAD : 135)

#define DEG_180_IN_RAD                              (::math::pi)
#define DEG_180_IN_RAD_IF(in_radians)               ((in_radians) ? DEG_180_IN_RAD : 180)

#define DEG_225_IN_RAD                              (::math::pi * 5 / 4)
#define DEG_225_IN_RAD_IF(in_radians)               ((in_radians) ? DEG_225_IN_RAD : 225)

#define DEG_270_IN_RAD                              (::math::pi * 3 / 2)
#define DEG_270_IN_RAD_IF(in_radians)               ((in_radians) ? DEG_270_IN_RAD : 270)

#define DEG_315_IN_RAD                              (::math::pi * 7 / 4)
#define DEG_315_IN_RAD_IF(in_radians)               ((in_radians) ? DEG_315_IN_RAD : 315)

#define DEG_360_IN_RAD                              (::math::pi * 2)
#define DEG_360_IN_RAD_IF(in_radians)               ((in_radians) ? DEG_360_IN_RAD : 360)

#define DEG_720_IN_RAD                              (::math::pi * 4)
#define DEG_720_IN_RAD_IF(in_radians)               ((in_radians) ? DEG_720_IN_RAD : 720)


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
    const constexpr char char_min = (std::numeric_limits<char>::min)();
    const constexpr char char_max = (std::numeric_limits<char>::max)();

    const constexpr unsigned char uchar_max = (std::numeric_limits<unsigned char>::max)();

    const constexpr short short_min = (std::numeric_limits<short>::min)();
    const constexpr short short_max = (std::numeric_limits<short>::max)();

    const constexpr unsigned short ushort_max = (std::numeric_limits<unsigned short>::max)();

    const constexpr int int_min = (std::numeric_limits<int>::min)();
    const constexpr int int_max = (std::numeric_limits<int>::max)();

    const constexpr unsigned int uint_max = (std::numeric_limits<unsigned int>::max)();

    const constexpr long long_min = (std::numeric_limits<long>::min)();
    const constexpr long long_max = (std::numeric_limits<long>::max)();

    const constexpr unsigned long ulong_max = (std::numeric_limits<unsigned long>::max)();

#ifdef UTILITY_PLATFORM_CXX_STANDARD_LLONG
    const constexpr long long longlong_min = (std::numeric_limits<long long>::min)();
    const constexpr long long longlong_max = (std::numeric_limits<long long>::max)();
#endif
#ifdef UTILITY_PLATFORM_CXX_STANDARD_ULLONG
    const constexpr unsigned long long ulonglong_max = (std::numeric_limits<unsigned long long>::max)();
#endif

    const constexpr int8_t int8_min = (std::numeric_limits<int8_t>::min)();
    const constexpr int8_t int8_max = (std::numeric_limits<int8_t>::max)();

    const constexpr uint8_t uint8_max = (std::numeric_limits<uint8_t>::max)();

    const constexpr int16_t int16_min = (std::numeric_limits<int16_t>::min)();
    const constexpr int16_t int16_max = (std::numeric_limits<int16_t>::max)();

    const constexpr uint16_t uint16_max = (std::numeric_limits<uint16_t>::max)();

    const constexpr int32_t int32_min = (std::numeric_limits<int32_t>::min)();
    const constexpr int32_t int32_max = (std::numeric_limits<int32_t>::max)();

    const constexpr uint32_t uint32_max = (std::numeric_limits<uint32_t>::max)();

    const constexpr int64_t int64_min = (std::numeric_limits<int64_t>::min)();
    const constexpr int64_t int64_max = (std::numeric_limits<int64_t>::max)();

    const constexpr uint64_t uint64_max = (std::numeric_limits<uint64_t>::max)();

    const constexpr size_t size_max = (std::numeric_limits<size_t>::max)();

    const constexpr double float_quiet_NaN = (std::numeric_limits<float>::quiet_NaN)();
    const constexpr double double_quiet_NaN = (std::numeric_limits<double>::quiet_NaN)();

    const constexpr double float_min = (std::numeric_limits<float>::min)();
    const constexpr double float_max = (std::numeric_limits<float>::max)();

    const constexpr double double_min = (std::numeric_limits<double>::min)();
    const constexpr double double_max = (std::numeric_limits<double>::max)();

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


    // sign convertion into -1,0,+1 integer
    template <typename T>
    FORCE_INLINE int sign_to_int(const T & v)
    {
        if (v > 0) {
            return +1;
        }
        else if (v < 0) {
            return -1;
        }

        return 0;
    }

    // sign convertion into sign character: -1 -> `-`, 0 -> ` `, +1 -> `+`
    template <typename T>
    FORCE_INLINE char sign_to_char(const T & v)
    {
        if (v > 0) {
            return '+';
        }
        else if (v < 0) {
            return '-';
        }

        return ' ';
    }

    // sign convertion into sign character: -1 -> ` `, 0 -> ` `, +1 -> `+`
    template <typename T>
    FORCE_INLINE char sign_to_positive_char(const T & v)
    {
        if (v > 0) {
            return '+';
        }

        return ' ';
    }

    // sign convertion into sign character: -1 -> `-`, 0 -> ` `, +1 -> ` `
    template <typename T>
    FORCE_INLINE char sign_to_negative_char(const T & v)
    {
        if (v < 0) {
            return '-';
        }

        return ' ';
    }

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
    template <typename T>
    extern inline T normalize_angle(const T & ang, const T & min_ang, const T & max_ang, const T & ang_period_mod, int inclusion_direction)
    {
        DEBUG_ASSERT_LT(min_ang, max_ang);
        DEBUG_ASSERT_GT(ang_period_mod, 0U); // must be always positive

        DEBUG_ASSERT_GE(min_ang, -ang_period_mod);
        DEBUG_ASSERT_GE(ang_period_mod, max_ang);

        if (!BASIC_VERIFY_TRUE(inclusion_direction >= -1 && +1 >= inclusion_direction)) {
            // just in case
            inclusion_direction = 0; // prefer symmetric case
        }

        T ang_norm = ang;

        switch (inclusion_direction) {
        case -1:
            if (ang >= min_ang && max_ang > ang) {
                return ang;
            }

            ang_norm = ang;

            if (ang >= 0) {
                if (ang < ang_period_mod) {
                    const T ang_neg = ang - ang_period_mod;
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
                        const T ang_neg = ang_norm - ang_period_mod;
                        if (ang_neg >= min_ang && max_ang > ang_neg) {
                            return ang_neg;
                        }
                    }
                }
            }
            else if (-ang < ang_period_mod) {
                const T ang_pos = ang + ang_period_mod;
                if (ang_pos >= min_ang && max_ang > ang_pos) {
                    return ang_pos;
                }
                // additional test in direction of inclusion
                else {
                    const T ang_neg = ang - ang_period_mod;
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
                    const T ang_pos = ang_norm + ang_period_mod;
                    if (ang_pos >= min_ang && max_ang > ang_pos) {
                        return ang_pos;
                    }
                    // additional test in direction of inclusion
                    else {
                        const T ang_neg = ang_norm - ang_period_mod;
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
                    const T ang_neg = ang - ang_period_mod;
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
                        const T ang_neg = ang_norm - ang_period_mod;
                        if (ang_neg >= min_ang && max_ang >= ang_neg) {
                            return ang_neg;
                        }
                    }
                }
            }
            else if (-ang < ang_period_mod) {
                const T ang_pos = ang + ang_period_mod;
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
                    const T ang_pos = ang_norm + ang_period_mod;
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
                    const T ang_neg = ang - ang_period_mod;
                    if (ang_neg > min_ang && max_ang >= ang_neg) {
                        return ang_neg;
                    }
                    // additional test in direction of inclusion
                    else {
                        const T ang_pos = ang + ang_period_mod;
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
                        const T ang_neg = ang_norm - ang_period_mod;
                        if (ang_neg > min_ang && max_ang >= ang_neg) {
                            return ang_neg;
                        }
                        // additional test in direction of inclusion
                        else {
                            const T ang_pos = ang_norm + ang_period_mod;
                            if (ang_pos > min_ang && max_ang >= ang_pos) {
                                return ang_pos;
                            }
                        }
                    }
                }
            }
            else if (-ang < ang_period_mod) {
                const T ang_pos = ang + ang_period_mod;
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
                    const T ang_pos = ang_norm + ang_period_mod;
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

    // Calculates closest distance between 2 angles independently to angles change direction.
    //
    // CAUTION:
    //  Because the function does not use direction of angle change, the resulting angles distance will be always less or equal to 180 degrees.
    //  Use `angle_distance` function instead to get angles distance respective to angles change direction.
    //
    // start_angle=[-inf..+inf] end_angle=[-inf..+inf]
    //
    // on_equal_distances_select_closest_to_zero=true:
    //  Calculate angle distance with a sign less or equal by the modulo to the 180 degrees, where
    //  the resulting range middle point would be closest to the zero.
    //  For example, for 2 ranges [0..180] and [0..-180] the function should return +180, but for another 2 ranges
    //  [5..185] and [5..-175] the function should return -180 because an absolute value of middle point |+95| is greater than |-85|.
    //
    // Return: angle_distance=[-pi..+pi]
    //
    template <typename T>
    extern inline T angle_closest_distance(const T & start_angle, const T & end_angle, bool in_radians, bool on_equal_distances_select_closest_to_zero)
    {
        const T angle_distance_inf = end_angle - start_angle;

        T angle_distance = angle_distance_inf; // retains the sign to transfer the direction of angle

        if (angle_distance_inf < 0) {
            if (-DEG_180_IN_RAD_IF(in_radians) >= angle_distance_inf) {
                // normalize distance from [-inf..0] to (-360..0]
                const T angle_distance_360 = fmod(angle_distance_inf, DEG_360_IN_RAD_IF(in_radians));
                if (-DEG_180_IN_RAD_IF(in_radians) > angle_distance_360) {
                    angle_distance = DEG_360_IN_RAD_IF(in_radians) + angle_distance_360;
                }
                else {
                    if (-DEG_180_IN_RAD_IF(in_radians) != angle_distance_360 || !on_equal_distances_select_closest_to_zero) {
                        angle_distance = angle_distance_360;
                    }
                    else {
                        if (start_angle > 0) {
                            angle_distance = -DEG_180_IN_RAD_IF(in_radians);
                        }
                        else {
                            angle_distance = DEG_180_IN_RAD_IF(in_radians);
                        }
                    }
                }
            }
        }
        else {
            if (DEG_180_IN_RAD_IF(in_radians) <= angle_distance_inf) {
                // normalize distance from [0..+inf] to [0..+360)
                const T angle_distance_360 = fmod(angle_distance_inf, DEG_360_IN_RAD_IF(in_radians));
                if (DEG_180_IN_RAD_IF(in_radians) < angle_distance_360) {
                    angle_distance = angle_distance_360 - DEG_360_IN_RAD_IF(in_radians);
                }
                else {
                    if (DEG_180_IN_RAD_IF(in_radians) != angle_distance_360 || !on_equal_distances_select_closest_to_zero) {
                        angle_distance = angle_distance_360;
                    }
                    else {
                        if (start_angle > 0) {
                            angle_distance = -DEG_180_IN_RAD_IF(in_radians);
                        }
                        else {
                            angle_distance = DEG_180_IN_RAD_IF(in_radians);
                        }
                    }
                }
            }
        }

        DEBUG_ASSERT_GE(DEG_180_IN_RAD_IF(in_radians), fabs(angle_distance));

        return angle_distance;
    }

    // Calculates distance between 2 angles respective to angles change direction if greater than epsilon angle,
    // otherwise calculates angle closest distance.
    //
    // start_angle=[-inf..+inf] end_angle=[-inf..+inf]
    //
    // Return: angle_distance=[-2pi..+2pi]
    //
    template <typename T>
    extern inline T angle_distance(const T & start_angle, const T & end_angle, const T & angle_epsilon, bool positive_angle_change, bool in_radians)
    {
        // all epsilons must be positive
        DEBUG_ASSERT_GE(angle_epsilon, 0);

        const T angle_distance_inf = end_angle - start_angle;

        // normalize distance from [-inf..0]/[0..+inf] to (-360..0]/[0..+360)
        const T angle_distance_360 = fmod(angle_distance_inf, DEG_360_IN_RAD_IF(in_radians));
        const T angle_distance_360_abs = fabs(angle_distance_360);

        if (angle_epsilon < angle_distance_360_abs && angle_epsilon < (DEG_360_IN_RAD_IF(in_radians) - angle_distance_360_abs)) {
            if (!((angle_distance_360 >= 0) ^ positive_angle_change)) {
                // angle change sign and direction are the same
                return angle_distance_360;
            }

            return positive_angle_change ? DEG_360_IN_RAD_IF(in_radians) + angle_distance_360 : angle_distance_360 - DEG_360_IN_RAD_IF(in_radians);
        }

        // closest angle
        if (DEG_180_IN_RAD_IF(in_radians) >= angle_distance_360_abs) {
            return angle_distance_360;
        }

        return (angle_distance_360 >= 0) ? angle_distance_360 - DEG_360_IN_RAD_IF(in_radians) : DEG_360_IN_RAD_IF(in_radians) + angle_distance_360;
    }

    // Normalize the angle to a range, where the resulting angle would monotonically change (w/o discontinuity on the range) while the angle in the range.
    // Additionally the monotonical change should exists on the greater range with the discontinuity in the angle opposite to the middle angle.
    //
    template <typename T>
    extern inline T normalize_angle_to_range(const T & start_angle, const T & mid_angle, const T & angle_distance, const T & angle, bool in_radians)
    {
        // all input must be already self normalized
    #ifndef UNIT_TESTS
        DEBUG_ASSERT_TRUE(start_angle >= -DEG_360_IN_RAD_IF(in_radians) && DEG_360_IN_RAD_IF(in_radians) >= start_angle);
        DEBUG_ASSERT_TRUE(mid_angle >= -DEG_360_IN_RAD_IF(in_radians) && DEG_360_IN_RAD_IF(in_radians) >= mid_angle);
        DEBUG_ASSERT_TRUE(start_angle < mid_angle && mid_angle < start_angle + angle_distance);
    #endif
        DEBUG_ASSERT_GE(DEG_360_IN_RAD_IF(in_radians), fabs(angle_distance));

        const T angle_norm = math::normalize_angle(angle,
            -DEG_360_IN_RAD_IF(in_radians), +DEG_360_IN_RAD_IF(in_radians), DEG_360_IN_RAD_IF(in_radians), 0); // just in case
        const T end_angle_norm = start_angle + angle_distance;
        T prev_angle_tmp;
        T angle_tmp = angle_norm;

        if (angle_distance >= 0) {
            if (end_angle_norm < angle_tmp) {
                do {
                    prev_angle_tmp = angle_tmp;
                    angle_tmp -= DEG_360_IN_RAD_IF(in_radians);
                } while (end_angle_norm < angle_tmp);

                if (angle_tmp < start_angle) {
                    // choose azimuth with closest distance to the `mid_angle` point
                    if (VERIFY_GE(prev_angle_tmp - mid_angle, 0) <=
                        VERIFY_GE(mid_angle - angle_tmp, 0)) {
                        angle_tmp = prev_angle_tmp;
                    }
                }
            }
            else if (angle_tmp < start_angle) {
                do {
                    prev_angle_tmp = angle_tmp;
                    angle_tmp += DEG_360_IN_RAD_IF(in_radians);
                } while (angle_tmp < start_angle);

                if (end_angle_norm < angle_tmp) {
                    // choose azimuth with closest distance to the `mid_angle` point
                    if (VERIFY_GE(mid_angle - prev_angle_tmp, 0) <
                        VERIFY_GE(angle_tmp - mid_angle, 0)) {
                        angle_tmp = prev_angle_tmp;
                    }
                }
            }
        }
        else {
            if (start_angle < angle_tmp) {
                do {
                    prev_angle_tmp = angle_tmp;
                    angle_tmp -= DEG_360_IN_RAD_IF(in_radians);
                } while (start_angle < angle_tmp);

                if (angle_tmp < end_angle_norm) {
                    // choose azimuth with closest distance to the `mid_angle` point
                    if (VERIFY_GE(prev_angle_tmp - mid_angle, 0) <=
                        VERIFY_GE(mid_angle - angle_tmp, 0)) {
                        angle_tmp = prev_angle_tmp;
                    }
                }
            }
            else if (angle_tmp < end_angle_norm) {
                do {
                    prev_angle_tmp = angle_tmp;
                    angle_tmp += DEG_360_IN_RAD_IF(in_radians);
                } while (angle_tmp < end_angle_norm);

                if (start_angle < angle_tmp) {
                    // choose azimuth with closest distance to the `mid_angle` point
                    if (VERIFY_GE(mid_angle - prev_angle_tmp, 0) <
                        VERIFY_GE(angle_tmp - mid_angle, 0)) {
                        angle_tmp = prev_angle_tmp;
                    }
                }
            }
        }

        return angle_tmp;
    }
}

#endif
