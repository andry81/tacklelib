#include "test_common.hpp"

#include <tacklelib/tackle/tmpl_string.hpp>
#include <tacklelib/tackle/constexpr_string.hpp>

#include <tacklelib/utility/type_identity.hpp>


// CAUTION:
//  TACKLE_TMPL_STRING can not be used directly in the UTILITY_CONSTEXPR_VALUE macro because of the error:
//  `error C3477: a lambda cannot appear in an unevaluated context`
//

TEST(TackleTmplStringTest, constexpr_)
{
#define TEST_TACKLE_TMPL_STRING(id, c_str_) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str_); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.size()), "tmpl_basic_string::size() having not compile time result"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.length()), "tmpl_basic_string::length() having not compile time result"); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) == s.size(), STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_)), STATIC_ASSERT_PARAM(s.size())); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(2, UTILITY_CONSTEXPR_STRING_LEN(c_str_) == s.length(), STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_STRING_LEN(c_str_)), STATIC_ASSERT_PARAM(s.length())); \
        ASSERT_EQ(s.c_str(), s.data()); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, "");
    TEST_TACKLE_TMPL_STRING(0, "test");
    TEST_TACKLE_TMPL_STRING(0, L"");
    TEST_TACKLE_TMPL_STRING(0, L"test");

    TEST_TACKLE_TMPL_STRING(1, "");
    TEST_TACKLE_TMPL_STRING(1, "test");
    TEST_TACKLE_TMPL_STRING(1, L"");
    TEST_TACKLE_TMPL_STRING(1, L"test");

#undef TEST_TACKLE_TMPL_STRING

#define TEST_TACKLE_TMPL_STRING(id, constexpr_offset, c_str_) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str_, constexpr_offset); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.size()), "tmpl_basic_string::size() having not compile time result"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.length()), "tmpl_basic_string::length() having not compile time result"); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) - constexpr_offset == s.size(), STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) - constexpr_offset), STATIC_ASSERT_PARAM(s.size())); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(2, UTILITY_CONSTEXPR_STRING_LEN(c_str_) - constexpr_offset == s.length(), STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_STRING_LEN(c_str_) - constexpr_offset), STATIC_ASSERT_PARAM(s.length())); \
        ASSERT_EQ(s.c_str(), s.data()); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, 1, "test");
    TEST_TACKLE_TMPL_STRING(0, 1, L"test");

    TEST_TACKLE_TMPL_STRING(1, 1, "test");
    TEST_TACKLE_TMPL_STRING(1, 1, L"test");

#undef TEST_TACKLE_TMPL_STRING

#define TEST_TACKLE_TMPL_STRING(id, constexpr_offset, len, c_str_) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str_, constexpr_offset, len); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.size()), "tmpl_basic_string::size() having not compile time result"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.length()), "tmpl_basic_string::length() having not compile time result"); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, len + 1 == s.size(), STATIC_ASSERT_PARAM(len + 1), STATIC_ASSERT_PARAM(s.size())); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(2, len == s.length(), STATIC_ASSERT_PARAM(len), STATIC_ASSERT_PARAM(s.length())); \
        ASSERT_EQ(s.c_str(), s.data()); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, 1, 2, "test");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, L"test");

    TEST_TACKLE_TMPL_STRING(1, 1, 2, "test");
    TEST_TACKLE_TMPL_STRING(1, 1, 2, L"test");

#undef TEST_TACKLE_TMPL_STRING
}

TEST(TackleTmplStringTest, constexpr_get)
{
#define TEST_TACKLE_TMPL_STRING(id, index, c_str) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_GET(s, index)), "UTILITY_CONSTEXPR_GET having not compile time result"); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, 0, "");
    TEST_TACKLE_TMPL_STRING(0, 0, "test");
    TEST_TACKLE_TMPL_STRING(0, 0, L"");
    TEST_TACKLE_TMPL_STRING(0, 0, L"test");

    TEST_TACKLE_TMPL_STRING(1, 0, "");
    TEST_TACKLE_TMPL_STRING(1, 0, "test");
    TEST_TACKLE_TMPL_STRING(1, 0, L"");
    TEST_TACKLE_TMPL_STRING(1, 0, L"test");

#undef TEST_TACKLE_TMPL_STRING

#define TEST_TACKLE_TMPL_STRING(id, constexpr_offset, index, c_str) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str, constexpr_offset); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_GET(s, index)), "UTILITY_CONSTEXPR_GET having not compile time result"); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, 0, 0, "");
    TEST_TACKLE_TMPL_STRING(0, 0, 0, "test");
    TEST_TACKLE_TMPL_STRING(0, 0, 0, L"");
    TEST_TACKLE_TMPL_STRING(0, 0, 0, L"test");

    TEST_TACKLE_TMPL_STRING(1, 0, 0, "");
    TEST_TACKLE_TMPL_STRING(1, 0, 0, "test");
    TEST_TACKLE_TMPL_STRING(1, 0, 0, L"");
    TEST_TACKLE_TMPL_STRING(1, 0, 0, L"test");

    TEST_TACKLE_TMPL_STRING(0, 1, 1, "abc");
    TEST_TACKLE_TMPL_STRING(0, 1, 1, L"abc");

    TEST_TACKLE_TMPL_STRING(1, 1, 1, "abc");
    TEST_TACKLE_TMPL_STRING(1, 1, 1, L"abc");

#undef TEST_TACKLE_TMPL_STRING
}

TEST(TackleTmplStringTest, constexpr_get2)
{
#define TEST_TACKLE_TMPL_STRING(id, index, c_char, c_str) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_GET(s, index) == c_char, STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_GET(s, index)), STATIC_ASSERT_PARAM(c_char)); \
        ASSERT_EQ(UTILITY_GET(s, index), c_char); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, 0, '0', "012");
    TEST_TACKLE_TMPL_STRING(0, 1, '1', "012");
    TEST_TACKLE_TMPL_STRING(0, 2, '2', "012");
    TEST_TACKLE_TMPL_STRING(0, 3, '\0', "012");

    TEST_TACKLE_TMPL_STRING(0, 0, L'0', L"012");
    TEST_TACKLE_TMPL_STRING(0, 1, L'1', L"012");
    TEST_TACKLE_TMPL_STRING(0, 2, L'2', L"012");
    TEST_TACKLE_TMPL_STRING(0, 3, L'\0', L"012");

#undef TEST_TACKLE_TMPL_STRING

    const auto s1 = TACKLE_TMPL_STRING(0, "0123", 1);
    STATIC_ASSERT_CONSTEXPR_TRUE(UTILITY_CONSTEXPR_GET(s1, 0) == '1', STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_GET(s1, 0)));

#define TEST_TACKLE_TMPL_STRING(id, constexpr_offset, index, c_char, c_str) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str, constexpr_offset); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_GET(s, index) == c_char, STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_GET(s, index)), STATIC_ASSERT_PARAM(c_char)); \
        ASSERT_EQ(UTILITY_GET(s, index), c_char); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, 1, 0, '1', "012");
    TEST_TACKLE_TMPL_STRING(0, 1, 1, '2', "012");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, '\0', "012");

    TEST_TACKLE_TMPL_STRING(0, 1, 0, L'1', L"012");
    TEST_TACKLE_TMPL_STRING(0, 1, 1, L'2', L"012");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, L'\0', L"012");

#undef TEST_TACKLE_TMPL_STRING

#define TEST_TACKLE_TMPL_STRING(id, constexpr_offset, len, index, c_char, c_str) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str, constexpr_offset, len); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_GET(s, index) == c_char, STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_GET(s, index)), STATIC_ASSERT_PARAM(c_char)); \
        ASSERT_EQ(UTILITY_GET(s, index), c_char); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, 1, 2, 0, '1', "0123");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, 1, '2', "0123");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, 2, '\0', "0123");

    TEST_TACKLE_TMPL_STRING(0, 1, 2, 0, L'1', L"0123");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, 1, L'2', L"0123");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, 2, L'\0', L"0123");

#undef TEST_TACKLE_TMPL_STRING
}

TEST(TackleTmplStringTest, is_exception)
{
}

using overload_resolution_1 = char[1];
using overload_resolution_2 = char[2];

template <uint64_t id, typename CharT, CharT... tchars>
const overload_resolution_1 & test_overload_resolution(const tackle::tmpl_basic_string<id, CharT, tchars...> &);
template <typename CharT>
const overload_resolution_2 & test_overload_resolution(const tackle::constexpr_basic_string<CharT> &);

TEST(TackleTmplStringTest, tmpl_string_vs_constexpr_string_overload)
{
    {
        const auto s = TACKLE_TMPL_STRING(0, "");
        static_assert(sizeof(overload_resolution_1) == sizeof(test_overload_resolution(s)), "must be called function with the tmpl_basic_string argument");
    }

    {
        const auto s = TACKLE_CONSTEXPR_STRING("");
        static_assert(sizeof(overload_resolution_2) == sizeof(test_overload_resolution(s)), "must be called function with the constexpr_basic_string argument");
    }
}
