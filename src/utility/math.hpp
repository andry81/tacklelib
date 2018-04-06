#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_MATH_HPP
#define UTILITY_MATH_HPP

#include <tacklelib.hpp>

#include <utility/utility.hpp>
#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/assert.hpp>

#include <boost/type_traits/is_unsigned.hpp>
#include <boost/type_traits/make_unsigned.hpp>
#include <boost/type_traits/integral_constant.hpp>

#include <cstdint>
#include <limits>
#include <utility>

#include <float.h>
#include <math.h>


#define INT32_LOG2_FLOOR(x) ::utility::int_log2_floor<int32_t>(x)
#define UINT32_LOG2_FLOOR(x) ::utility::int_log2_floor<uint32_t>(x)

#define INT32_POF2_FLOOR(x) ::utility::int_pof2_floor<int32_t>(x)
#define UINT32_POF2_FLOOR(x) ::utility::int_pof2_floor<uint32_t>(x)

#define INT32_LOG2_FLOOR_ASSERT(x) ::utility::int_log2_floor_assert<int32_t>(x)
#define UINT32_LOG2_FLOOR_ASSERT(x) ::utility::int_log2_floor_assert<uint32_t>(x)

#define INT32_POF2_FLOOR_ASSERT(x) ::utility::int_pof2_floor_assert<int32_t>(x)
#define UINT32_POF2_FLOOR_ASSERT(x) ::utility::int_pof2_floor_assert<uint32_t>(x)

#if defined(ENABLE_POF2_DEFINITIONS) && !defined(DISABLE_POF2_DEFINITIONS)

#define INT32_MULT_POF2(x, y) int32_t(int32_t(x) << INT32_LOG2_FLOOR_ASSERT(y))
#define UINT32_MULT_POF2(x, y) uint32_t(uint32_t(x) << UINT32_LOG2_FLOOR_ASSERT(y))

#define INT32_DIV_POF2(x, y) int32_t(int32_t(x) >> INT32_LOG2_FLOOR_ASSERT(y))
#define UINT32_DIV_POF2(x, y) uint32_t(uint32_t(x) >> UINT32_LOG2_FLOOR_ASSERT(y))

#define INT32_DIVREM_POF2(x, y) ::utility::divrem<int32_t>{ int32_t(x) >> INT32_LOG2_FLOOR_ASSERT(y), int32_t(x) & (INT32_POF2_FLOOR_ASSERT(y) - 1) }
#define UINT32_DIVREM_POF2(x, y) ::utility::divrem<uint32_t>{ uint32_t(x) >> UINT32_LOG2_FLOOR_ASSERT(y), uint32_t(x) & (UINT32_POF2_FLOOR_ASSERT(y) - 1) }

#else

#define INT32_MULT_POF2(x, y) int32_t(int32_t(x) * INT32_POF2_FLOOR_ASSERT(y))
#define UINT32_MULT_POF2(x, y) uint32_t(uint32_t(x) * UINT32_POF2_FLOOR_ASSERT(y))

#define INT32_DIV_POF2(x, y) int32_t(int32_t(x) / INT32_POF2_FLOOR_ASSERT(y))
#define UINT32_DIV_POF2(x, y) uint32_t(uint32_t(x) / UINT32_POF2_FLOOR_ASSERT(y))

#define INT32_DIVREM_POF2(x, y) ::utility::divrem<int32_t>{ int32_t(x) / INT32_POF2_FLOOR_ASSERT(y), int32_t(x) % (INT32_POF2_FLOOR_ASSERT(y) - 1) }
#define UINT32_DIVREM_POF2(x, y) ::utility::divrem<uint32_t>{ uint32_t(x) / UINT32_POF2_FLOOR_ASSERT(y), uint32_t(x) % (UINT32_POF2_FLOOR_ASSERT(y) - 1) }

#endif


namespace math
{
    namespace mpl = boost::mpl;

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

    template<typename T>
    struct divrem
    {
        T quot;
        T rem;
    };

    template<int32_t x>
    struct int32_log2 {
        STATIC_ASSERT_GT(x, 0, "value must be positive");
        STATIC_ASSERT_TRUE1(x && !(x & (x - 1)), x, "value must be power of 2");
        static const int32_t value = (int32_log2<x / 2>::value + 1);
    };

    template<>
    struct int32_log2<0>;
    template<>
    struct int32_log2<1> {
        static const int32_t value = 0;
    };

    template<uint32_t x>
    struct uint32_log2 {
        STATIC_ASSERT_TRUE1(x && !(x & (x - 1)), x, "value must be power of 2");
        static const uint32_t value = (uint32_log2<x / 2>::value + 1);
    };

    template<>
    struct uint32_log2<0>;
    template<>
    struct uint32_log2<1> {
        static const uint32_t value = 0;
    };


    template<int32_t x>
    struct int32_log2_floor {
        STATIC_ASSERT_GT(x, 0, "value must be positive");
        static const int32_t value = (int32_log2_floor<x / 2>::value + 1);
    };

    template<>
    struct int32_log2_floor<0>;
    template<>
    struct int32_log2_floor<1> {
        static const int32_t value = 0;
    };

    template<uint32_t x>
    struct uint32_log2_floor {
        static const uint32_t value = (uint32_log2_floor<x / 2>::value + 1);
    };

    template<>
    struct uint32_log2_floor<0>;
    template<>
    struct uint32_log2_floor<1> {
        static const uint32_t value = 0;
    };


    template<int32_t x>
    struct int32_log2_ceil {
        STATIC_ASSERT_GT(x, 0, "value must be positive");
        STATIC_ASSERT_TRUE2(int32_max / 2 >= x, int32_max, x, "value is too big");
        static const int32_t value = (int32_log2_floor<(x + x - 1) / 2>::value + 1);
    };

    template<>
    struct int32_log2_ceil<0>;
    template<>
    struct int32_log2_ceil<1> {
        static const int32_t value = 0;
    };

    template<uint32_t x>
    struct uint32_log2_ceil {
        STATIC_ASSERT_TRUE2(uint32_max / 2 >= x, uint32_max, x, "value is too big");
        static const uint32_t value = (uint32_log2_floor<(x + x - 1) / 2>::value + 1);
    };

    template<>
    struct uint32_log2_ceil<0>;
    template<>
    struct uint32_log2_ceil<1> {
        static const uint32_t value = 0;
    };


    template<int32_t x>
    struct int32_if_pof2
    {
        STATIC_ASSERT_TRUE1(x && !(x & (x - 1)), x, "value must be power of 2");
        static const int32_t value = x;
    };

    template<uint32_t x>
    struct uint32_if_pof2
    {
        STATIC_ASSERT_TRUE1(x && !(x & (x - 1)), x, "value must be power of 2");
        static const uint32_t value = x;
    };

    // closest lowest power of 2
    template<uint32_t x>
    struct uint32_pof2_floor
    {
        using x1_t  = mpl::integral_c<uint32_t, x | (x >> 1)>;
        using x2_t = mpl::integral_c<uint32_t, x1_t::value | (x1_t::value >> 2)>;
        using x4_t = mpl::integral_c<uint32_t, x2_t::value | (x2_t::value >> 4)>;
        using x8_t = mpl::integral_c<uint32_t, x4_t::value | (x4_t::value >> 8)>;
        using x16_t = mpl::integral_c<uint32_t, x8_t::value | (x8_t::value >> 16)>;

        static const uint32_t value = (x16_t::value >> 1) + 1;
    };

    template<int32_t x>
    struct int32_pof2_floor
    {
        static const int32_t value = int32_t(uint32_pof2_floor<uint32_t(x)>::value);
    };

    // closest greatest power of 2
    template<uint32_t x>
    struct uint32_pof2_ceil
    {
        using uint32_pof2_floor_t = uint32_pof2_floor<x>;
        static const uint32_t value = uint32_pof2_floor_t::value != x ? (uint32_pof2_floor_t::value << 1) : uint32_pof2_floor_t::value;
    };

    template<int32_t x>
    struct int32_pof2_ceil
    {
        static const int32_t value = int32_t(uint32_pof2_ceil<uint32_t(x)>::value);
    };

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

    template <typename T>
    FORCE_INLINE T int_pof2_floor(T v)
    {
        ASSERT_GT(v, T(0));

        using unsigned_type = typename boost::make_unsigned<T>::type;

        unsigned_type unsigned_value = unsigned_type(v);

        unsigned_value |= (unsigned_value >> 1);
        unsigned_value |= (unsigned_value >> 2);
        unsigned_value |= (unsigned_value >> 4);
        unsigned_value |= (unsigned_value >> 8);
        unsigned_value |= (unsigned_value >> 16);

        return T((unsigned_value >> 1) + 1);
    }

    template <typename T>
    FORCE_INLINE T int_pof2_ceil(T v)
    {
        ASSERT_GT(v, T(0));
        ASSERT_GE(boost::is_unsigned<T>::value ? v : ((std::numeric_limits<T>::max)() / 2), v);

        const auto floor_value = int_pof2_floor(v);
        return T(floor_value != v ? (floor_value << 1) : floor_value);
    }

    template <typename T>
    FORCE_INLINE T int_pof2_floor_assert(T v)
    {
        ASSERT_EQ(int_pof2_floor(v), v);
        return int_pof2_floor(v);
    }

    template <typename T>
    FORCE_INLINE T int_pof2_ceil_assert(T v)
    {
        ASSERT_EQ(int_pof2_ceil(v), v);
        return int_pof2_ceil(v);
    }

    template <typename T>
    FORCE_INLINE T int_log2_floor(T v)
    {
        ASSERT_GT(v, T(0));

        if (1 >= v) return 0;

        T ret = 0;
        T i = v;

        // unrolled recursion
        do {
            ++ret;
            i /= 2;
        } while (i >= 2);

        return ret;
    }

    template <typename T>
    FORCE_INLINE T int_log2_ceil(T v)
    {
        ASSERT_GT(v, T(0));
        ASSERT_GE(boost::is_unsigned<T>::value ? v : ((std::numeric_limits<T>::max)() / 2), v);

        if (1 >= v) return 0;

        return T((v >= 2 ? int_log2_floor((v + v - 1) / 2) : 0) + 1);
    }

    template <typename T>
    FORCE_INLINE T int_log2_floor_assert(T v)
    {
        ASSERT_EQ(int_pof2_floor(v), v);
        return int_log2_floor(v);
    }

    template <typename T>
    FORCE_INLINE T int_log2_ceil_assert(T v)
    {
        ASSERT_EQ(int_pof2_ceil(v), v);
        return int_log2_ceil(v);
    }

    // inclusion_direction:
    //  -1 - minimal is included, maximal is excluded (ex: [   0 - +360) )
    //  +1 - minimal is excluded, maximal is included (ex: (-180 - +180] )
    //   0 - minimal and maximal both included (ex: [0 - +180] or [-90 - +90])
    FORCE_INLINE_ALWAYS double normalize_angle(double ang, double min_ang, double max_ang, double ang_period_mod, int inclusion_direction)
    {
        ASSERT_LT(min_ang, max_ang);
        ASSERT_GT(ang_period_mod, 0U); // must be always positive

        ASSERT_GE(min_ang, -ang_period_mod);
        ASSERT_GE(+ang_period_mod, max_ang);

        if (!VERIFY_TRUE(inclusion_direction >= -1 && +1 >= inclusion_direction)) {
            // just in case
            inclusion_direction = 0; // prefer symmetric case
        }

        double ang_norm;

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
        }

        return ang_norm;
    }
}

#endif
