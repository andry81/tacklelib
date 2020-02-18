#include "test_common.hpp"

#include <tacklelib/tackle/tmpl_string.hpp>
#include <tacklelib/tackle/constexpr_string.hpp>

#include <tacklelib/utility/type_identity.hpp>
#include <tacklelib/utility/string_identity.hpp>

#include <tacklelib/utility/crc.hpp>


// CAUTION:
//  The `TACKLE_TMPL_STRING` and it's derivatives can not be used directly or indirectly (through a constexpr function) in the `UTILITY_CONSTEXPR_VALUE` macro or
//  any other truly compile-time expression (at least until C++17 standard) because of the error:
//  `error C3477: a lambda cannot appear in an unevaluated context`
//

TEST(TackleTmplStringCrcTest, constexpr_)
{
#define TEST_TACKLE_TMPL_STRING_CRC(id, crc_value, c_str_) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str_); \
        const auto c1 = ::utility::constexpr_crc(32, ::utility::g_crc32_04C11DB7, 0U, UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(c_str_), 0U, 0xFFFFFFFFU, 0xFFFFFFFFU, true, true); \
        const auto c2 = ::utility::constexpr_crc(32, ::utility::g_crc32_04C11DB7, 0U, s.c_str(), s.length(), 0U, 0xFFFFFFFFU, 0xFFFFFFFFU, true, true); \
        const auto c3 = ::utility::constexpr_crc(32, ::utility::g_crc32_04C11DB7, 0U, s.data(), s.length(), 0U, 0xFFFFFFFFU, 0xFFFFFFFFU, true, true); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(c1), "c1 value is not constexpr"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(c2), "c2 value is not constexpr"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(c3), "c3 value is not constexpr"); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, c1 == crc_value, STATIC_ASSERT_PARAM(c1)); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(2, c2 == crc_value, STATIC_ASSERT_PARAM(c2)); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(3, c3 == crc_value, STATIC_ASSERT_PARAM(c3)); \
    } (void)0

    TEST_TACKLE_TMPL_STRING_CRC(0, 0x00000000, "");
    TEST_TACKLE_TMPL_STRING_CRC(0, 0xD87F7E0C, "test");
    TEST_TACKLE_TMPL_STRING_CRC(0, 0x00000000, L"");
    TEST_TACKLE_TMPL_STRING_CRC(0, 0xD87F7E0C, L"test");

    TEST_TACKLE_TMPL_STRING_CRC(1, 0x00000000, "");
    TEST_TACKLE_TMPL_STRING_CRC(1, 0xD87F7E0C, "test");
    TEST_TACKLE_TMPL_STRING_CRC(1, 0x00000000, L"");
    TEST_TACKLE_TMPL_STRING_CRC(1, 0xD87F7E0C, L"test");

#undef TEST_TACKLE_TMPL_STRING_CRC

#define TEST_TACKLE_TMPL_STRING_CRC(id, crc_value, constexpr_offset, c_str_) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str_, constexpr_offset); \
        const auto c1 = ::utility::constexpr_crc(32, ::utility::g_crc32_04C11DB7, 0U, UTILITY_LITERAL_STRING_WITH_LENGTH_AND_CONSTEXPR_OFFSET_TUPLE(c_str_, constexpr_offset), 0U, 0xFFFFFFFFU, 0xFFFFFFFFU, true, true); \
        const auto c2 = ::utility::constexpr_crc(32, ::utility::g_crc32_04C11DB7, 0U, s.c_str(), s.length(), 0U, 0xFFFFFFFFU, 0xFFFFFFFFU, true, true); \
        const auto c3 = ::utility::constexpr_crc(32, ::utility::g_crc32_04C11DB7, 0U, s.data(), s.length(), 0U, 0xFFFFFFFFU, 0xFFFFFFFFU, true, true); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(c1), "c1 value is not constexpr"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(c2), "c2 value is not constexpr"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(c3), "c3 value is not constexpr"); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, c1 == crc_value, STATIC_ASSERT_PARAM(c1)); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(2, c2 == crc_value, STATIC_ASSERT_PARAM(c2)); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(3, c3 == crc_value, STATIC_ASSERT_PARAM(c3)); \
    } (void)0

    TEST_TACKLE_TMPL_STRING_CRC(0, 0xE2274FC9, 1, "test");
    TEST_TACKLE_TMPL_STRING_CRC(0, 0xE2274FC9, 1, L"test");

    TEST_TACKLE_TMPL_STRING_CRC(1, 0xE2274FC9, 1, "test");
    TEST_TACKLE_TMPL_STRING_CRC(1, 0xE2274FC9, 1, L"test");

#undef TEST_TACKLE_TMPL_STRING_CRC

#define TEST_TACKLE_TMPL_STRING_CRC(id, crc_value, constexpr_offset, len, c_str_) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str_, constexpr_offset, len); \
        const auto c2 = ::utility::constexpr_crc(32, ::utility::g_crc32_04C11DB7, 0U, s.c_str(), s.length(), 0U, 0xFFFFFFFFU, 0xFFFFFFFFU, true, true); \
        const auto c3 = ::utility::constexpr_crc(32, ::utility::g_crc32_04C11DB7, 0U, s.data(), s.length(), 0U, 0xFFFFFFFFU, 0xFFFFFFFFU, true, true); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(c2), "c2 value is not constexpr"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(c3), "c3 value is not constexpr"); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, c2 == crc_value, STATIC_ASSERT_PARAM(c2)); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(2, c3 == crc_value, STATIC_ASSERT_PARAM(c3)); \
    } (void)0

    TEST_TACKLE_TMPL_STRING_CRC(0, 0x905FAD9B, 1, 2, "test");
    TEST_TACKLE_TMPL_STRING_CRC(0, 0x905FAD9B, 1, 2, L"test");

    TEST_TACKLE_TMPL_STRING_CRC(1, 0x905FAD9B, 1, 2, "test");
    TEST_TACKLE_TMPL_STRING_CRC(1, 0x905FAD9B, 1, 2, L"test");

#undef TEST_TACKLE_TMPL_STRING

}
