#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_MATH_HPP
#define UTILITY_MATH_HPP

#include <tacklelib.hpp>

#include <cstdint>
#include <limits>


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

    const constexpr long long longlong_max = (std::numeric_limits<long long>::max)();
    const constexpr unsigned long long ulonglong_max = (std::numeric_limits<unsigned long long>::max)();

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
}

#endif
