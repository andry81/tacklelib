#include <utility/crc.hpp>
#include <utility/crc_tables.hpp>
#include <utility/assert.hpp>
#include <utility/utility.hpp>

namespace
{
    template <typename T>
    FORCE_INLINE T _t_crc(size_t width, const T * table, T crc, const void * buf, size_t size, T crc_init, T xor_in, T xor_out, bool input_reflected, bool result_reflected)
    {
        ASSERT_GE(sizeof(crc) * CHAR_BIT, width);

        const uint8_t * p = (const uint8_t *)buf;

        if (!crc && crc_init) crc = crc_init;

        crc ^= xor_in;

        while (size--) {
            const uint8_t buf_byte = input_reflected ? *p++ : utility::reverse(*p++); // LSB if true
            crc = table[(crc ^ buf_byte) & 0xFF] ^ (crc >> 8);
        }

        if (!result_reflected) { // already reflected if true
            crc = (utility::reverse(crc) >> (sizeof(crc) * CHAR_BIT - width));
        }

        return crc ^ xor_out;
    }
}

namespace utility
{
    // NOTE:
    // 1. Online generator: http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
    // 2. Understanding:    http://www.sunshine2k.de/articles/coding/crc/understanding_crc.html
    // 3. RFC1662 (HDLC FCS implementation): https://tools.ietf.org/html/rfc1662

    extern FORCE_INLINE uint32_t crc(size_t width, uint32_t polynomial, uint32_t crc, const void * buf, size_t size, uint32_t crc_init,
        uint32_t xor_in, uint32_t xor_out, bool input_reflected, bool result_reflected)
    {
        switch (width) {
        case 16:
            switch (polynomial) {
            case 0x1021: return _t_crc<uint16_t>(width, g_crc16_1021, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0x8005: return _t_crc<uint16_t>(width, g_crc16_8005, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0xC867: return _t_crc<uint16_t>(width, g_crc16_C867, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0x0589: return _t_crc<uint16_t>(width, g_crc16_0589, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0x3D65: return _t_crc<uint16_t>(width, g_crc16_3D65, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0x8BB7: return _t_crc<uint16_t>(width, g_crc16_8BB7, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            case 0xA097: return _t_crc<uint16_t>(width, g_crc16_A097, uint16_t(crc), buf, size, uint16_t(crc_init), uint16_t(xor_in), uint16_t(xor_out), input_reflected, result_reflected);
            }
            break;

        case 24:
            switch (polynomial) {
            case 0x864CFB: return _t_crc<uint32_t>(width, g_crc24_864CFB, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0x5D6DCB: return _t_crc<uint32_t>(width, g_crc24_5D6DCB, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            }
            break;

        case 32:
            switch (polynomial) {
            case 0x04C11DB7: return _t_crc<uint32_t>(width, g_crc32_04C11DB7, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0x1EDC6F41: return _t_crc<uint32_t>(width, g_crc32_1EDC6F41, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0xA833982B: return _t_crc<uint32_t>(width, g_crc32_A833982B, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0x814141AB: return _t_crc<uint32_t>(width, g_crc32_814141AB, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0x741B8CD7: return _t_crc<uint32_t>(width, g_crc32_741B8CD7, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            case 0x000000AF: return _t_crc<uint32_t>(width, g_crc32_000000AF, crc, buf, size, crc_init, xor_in, xor_out, input_reflected, result_reflected);
            }
            break;
        }

        ASSERT_TRUE(0); // not implemented

        throw std::runtime_error(
            (boost::format(
                BOOST_PP_CAT(__FUNCTION__, ": unimplemented crc polynomial: width=%u polynomial=%08X")) %
                    width % polynomial).str());

        //return 0; // unreachable code
    }

    extern FORCE_INLINE uint32_t crc_mask(size_t width)
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
