#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_CRC_HPP
#define UTILITY_CRC_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/assert.hpp>
#include <tacklelib/utility/utility.hpp>

#include <tacklelib/utility/crc_tables.hpp>

#include <cstdlib>
#include <cstdint>
#include <utility>

#include <fmt/format.h>


// NOTE:
// 1. Online generator: http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
// 2. Understanding:    http://www.sunshine2k.de/articles/coding/crc/understanding_crc.html
// 3. RFC1662 (HDLC FCS implementation): https://tools.ietf.org/html/rfc1662

// TODO:
//  1. 24-bit crc implementation is incomplete and untested
//  2. Ideas to speed up: https://create.stephan-brumme.com/crc32/

//polynomial example: x**0 + x**5 + x**12 + x**16
//                    (1)0001000000100001       = 0x1021
//                       1000010000001000(1)    = 0x8408
//polynomial example: x**0 + x**1 + x**2 + x**4 + x**5* +x**7 + x**8 + x**10 + x**11 + x**12 + x**16* +x**22 + x**23 + x**26 + x**32
//                    (1)00000100110000010001110110110111       = 0x04C11DB7
//                       11101101101110001000001100100000(1)    = 0xEDB88320

namespace utility
{

    template <typename CrcT, size_t TableS, typename BufT>
    FORCE_INLINE CrcT t_crc(size_t width, const CrcT (& table)[TableS], CrcT crc, const BufT * buf, size_t size, CrcT crc_init, CrcT xor_in, CrcT xor_out, bool input_reflected, bool result_reflected)
    {
        DEBUG_ASSERT_EQ(TableS, 256);
        DEBUG_ASSERT_GE(sizeof(crc) * CHAR_BIT, width);
        DEBUG_ASSERT_GE(sizeof(crc), sizeof(BufT));

        if (!crc && crc_init) crc = crc_init;

        crc ^= xor_in;

        while (size--) {
            const uint8_t buf_elem = input_reflected ? *buf++ : utility::reverse(*buf++); // LSB if true
            crc = table[(crc ^ buf_elem) & 0xFF] ^ (crc >> 8);
        }

        if (!result_reflected) { // already reflected if true
            crc = (utility::reverse(crc) >> (sizeof(crc) * CHAR_BIT - width));
        }

        return crc ^ xor_out;
    }

    namespace detail
    {
        template <typename CrcT, size_t TableS, typename BufT>
        FORCE_INLINE CONSTEXPR_FUNC CrcT _constexpr_crc(size_t next_index, const CrcT (& table)[TableS], CrcT crc, const BufT * buf, size_t size, bool input_reflected)
        {
            return (next_index < size) ?
                _constexpr_crc(next_index + 1, table, table[(crc ^ (input_reflected ? buf[next_index] : utility::constexpr_reverse(buf[next_index]))) & 0xFF] ^ (crc >> 8), buf, size, input_reflected) :
                crc;
        }
    }

    template <typename CrcT, size_t TableS, typename BufT>
    FORCE_INLINE CONSTEXPR_FUNC CrcT constexpr_crc(size_t width, const CrcT (& table)[TableS], CrcT crc, const BufT * buf, size_t size, CrcT crc_init, CrcT xor_in, CrcT xor_out, bool input_reflected, bool result_reflected)
    {
        return (
            STATIC_ASSERT_CONSTEXPR_TRUE(TableS == 256,
                STATIC_ASSERT_PARAM(TableS)),
            STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE(sizeof(crc) * CHAR_BIT >= width,
                sizeof(crc) * CHAR_BIT,
                width),
            STATIC_ASSERT_CONSTEXPR_TRUE(sizeof(crc) >= sizeof(BufT),
                STATIC_ASSERT_PARAM(sizeof(crc)),
                STATIC_ASSERT_PARAM(sizeof(BufT))),
            ((!crc && crc_init) ?
                    (result_reflected ?
                        detail::_constexpr_crc(0, table, crc_init ^ xor_in, buf, size, input_reflected) :
                        (constexpr_reverse(detail::_constexpr_crc(0, table, crc_init ^ xor_in, buf, size, input_reflected) >> (sizeof(crc) * CHAR_BIT - width)))) :
                    (result_reflected ?
                        detail::_constexpr_crc(0, table, crc ^ xor_in, buf, size, input_reflected) :
                        (constexpr_reverse(detail::_constexpr_crc(0, table, crc ^ xor_in, buf, size, input_reflected) >> (sizeof(crc) * CHAR_BIT - width))))
                ) ^ xor_out);
    }

    template <typename BufT>
    inline uint32_t crc(size_t width, uint32_t polynomial, uint32_t crc, const BufT * buf, size_t size, uint32_t crc_init = uint32_t(~0U),
        uint32_t xor_in = 0U, uint32_t xor_out = uint32_t(~0U), bool input_reflected = false, bool result_reflected = false)
    {
        switch (width) {
        case 16:
            switch (polynomial) {
            case 0x1021: return t_crc<uint16_t>(width, g_crc16_1021, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0x8005: return t_crc<uint16_t>(width, g_crc16_8005, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0xC867: return t_crc<uint16_t>(width, g_crc16_C867, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0x0589: return t_crc<uint16_t>(width, g_crc16_0589, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0x3D65: return t_crc<uint16_t>(width, g_crc16_3D65, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0x8BB7: return t_crc<uint16_t>(width, g_crc16_8BB7, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0xA097: return t_crc<uint16_t>(width, g_crc16_A097, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            }
            break;

        case 24:
            switch (polynomial) {
            case 0x864CFB: return t_crc<uint32_t>(width, g_crc24_864CFB, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0x5D6DCB: return t_crc<uint32_t>(width, g_crc24_5D6DCB, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            }
            break;

        case 32:
            switch (polynomial) {
            case 0x04C11DB7: return t_crc<uint32_t>(width, g_crc32_04C11DB7, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0x1EDC6F41: return t_crc<uint32_t>(width, g_crc32_1EDC6F41, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0xA833982B: return t_crc<uint32_t>(width, g_crc32_A833982B, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0x814141AB: return t_crc<uint32_t>(width, g_crc32_814141AB, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0x741B8CD7: return t_crc<uint32_t>(width, g_crc32_741B8CD7, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0x000000AF: return t_crc<uint32_t>(width, g_crc32_000000AF, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            }
            break;
        }

        DEBUG_ASSERT_TRUE(0); // not implemented

        DEBUG_BREAK_THROW(true) std::runtime_error(
            fmt::format("{:s}({:d}): unimplemented crc polynomial: width={:d} polynomial={:08X}",
                UTILITY_PP_FUNCSIG, UTILITY_PP_LINE, width, polynomial));

        //return 0; // unreachable code
    }

    FORCE_INLINE uint32_t crc_mask(size_t width)
    {
        switch (width) {
        case 8: return 0xFFU;
        case 16: return 0xFFFFU;
        case 24: return 0xFFFFFFU;
        case 32: return 0xFFFFFFFFU;
        }

        uint32_t mask = 0;
        for (size_t i = 0; i < width; i++) {
            mask |= (0x01U << i);
        }
        return mask;
    }

}

#endif
