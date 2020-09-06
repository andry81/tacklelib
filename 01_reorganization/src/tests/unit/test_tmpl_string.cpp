#include "test_common.hpp"

#include <tacklelib/tackle/tmpl_string.hpp>
#include <tacklelib/tackle/constexpr_string.hpp>

#include <tacklelib/utility/type_identity.hpp>

#include <cstring>


// CAUTION:
//  The `TACKLE_TMPL_STRING` and it's derivatives can not be used directly or indirectly (through a constexpr function) in the `UTILITY_CONSTEXPR_VALUE` macro or
//  any other truly compile-time expression (at least until C++17 standard) because of the error:
//  `error C3477: a lambda cannot appear in an unevaluated context`
//

TEST(TackleTmplStringTest, constexpr_)
{
#define TEST_TACKLE_TMPL_STRING(id, c_str_) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str_); \
        static_assert(!UTILITY_IS_CONSTEXPR_VALUE(s), "s value is constexpr when should not"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.size()), "tmpl_basic_string::size() value is not constexpr"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.length()), "tmpl_basic_string::length() value is not constexpr"); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) == s.size(), \
            STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_)), STATIC_ASSERT_PARAM(s.size())); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(2, UTILITY_CONSTEXPR_STRING_LEN(c_str_) == s.length(), \
            STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_STRING_LEN(c_str_)), STATIC_ASSERT_PARAM(s.length())); \
        ASSERT_EQ(s.c_str(), s.data()); \
    } \
    { \
        STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) == TACKLE_TMPL_STRING(id, c_str_).size(), \
            UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_), TACKLE_TMPL_STRING(id, c_str_).size()); \
        STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE_ID(2, UTILITY_CONSTEXPR_STRING_LEN(c_str_) == TACKLE_TMPL_STRING(id, c_str_).length(), \
            UTILITY_CONSTEXPR_STRING_LEN(c_str_), TACKLE_TMPL_STRING(id, c_str_).length()); \
        ASSERT_EQ(TACKLE_TMPL_STRING(id, c_str_).c_str(), TACKLE_TMPL_STRING(id, c_str_).data()); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, "");
    TEST_TACKLE_TMPL_STRING(0, "test");
    TEST_TACKLE_TMPL_STRING(0, L"");
    TEST_TACKLE_TMPL_STRING(0, L"test");

    TEST_TACKLE_TMPL_STRING(1, "");
    TEST_TACKLE_TMPL_STRING(1, "test");
    TEST_TACKLE_TMPL_STRING(1, L"");
    TEST_TACKLE_TMPL_STRING(1, L"test");

    TEST_TACKLE_TMPL_STRING(2, UTILITY_PP_FILE);

#undef TEST_TACKLE_TMPL_STRING

#define TEST_TACKLE_TMPL_STRING(id, constexpr_offset, c_str_) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str_, constexpr_offset); \
        static_assert(!UTILITY_IS_CONSTEXPR_VALUE(s), "s value is constexpr when should not"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.size()), "tmpl_basic_string::size() value is not constexpr"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.length()), "tmpl_basic_string::length() value is not constexpr"); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) - constexpr_offset == s.size(), \
            STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) - constexpr_offset), STATIC_ASSERT_PARAM(s.size())); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(2, UTILITY_CONSTEXPR_STRING_LEN(c_str_) - constexpr_offset == s.length(), \
            STATIC_ASSERT_PARAM(UTILITY_CONSTEXPR_STRING_LEN(c_str_) - constexpr_offset), STATIC_ASSERT_PARAM(s.length())); \
        ASSERT_EQ(UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) - constexpr_offset, s.size()); \
        ASSERT_EQ(UTILITY_CONSTEXPR_STRING_LEN(c_str_) - constexpr_offset, s.length()); \
        ASSERT_EQ(s.c_str(), s.data()); \
    } \
    { \
        STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) - constexpr_offset == TACKLE_TMPL_STRING(id, c_str_, constexpr_offset).size(), \
            UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) - constexpr_offset, TACKLE_TMPL_STRING(id, c_str_, constexpr_offset).size()); \
        STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE_ID(2, UTILITY_CONSTEXPR_STRING_LEN(c_str_) - constexpr_offset == TACKLE_TMPL_STRING(id, c_str_, constexpr_offset).length(), \
            UTILITY_CONSTEXPR_STRING_LEN(c_str_) - constexpr_offset, TACKLE_TMPL_STRING(id, c_str_, constexpr_offset).length()); \
        ASSERT_EQ(UTILITY_CONSTEXPR_ARRAY_SIZE(c_str_) - constexpr_offset, TACKLE_TMPL_STRING(id, c_str_, constexpr_offset).size()); \
        ASSERT_EQ(UTILITY_CONSTEXPR_STRING_LEN(c_str_) - constexpr_offset, TACKLE_TMPL_STRING(id, c_str_, constexpr_offset).length()); \
        ASSERT_EQ(TACKLE_TMPL_STRING(id, c_str_, constexpr_offset).c_str(), TACKLE_TMPL_STRING(id, c_str_, constexpr_offset).data()); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, 1, "test");
    TEST_TACKLE_TMPL_STRING(0, 1, L"test");

    TEST_TACKLE_TMPL_STRING(1, 1, "test");
    TEST_TACKLE_TMPL_STRING(1, 1, L"test");

    TEST_TACKLE_TMPL_STRING(2, 1, UTILITY_PP_FILE);

#undef TEST_TACKLE_TMPL_STRING

#define TEST_TACKLE_TMPL_STRING(id, constexpr_offset, len, c_str_) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str_, constexpr_offset, len); \
        static_assert(!UTILITY_IS_CONSTEXPR_VALUE(s), "s value is constexpr when should not"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.size()), "tmpl_basic_string::size() value is not constexpr"); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(s.length()), "tmpl_basic_string::length() value is not constexpr"); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, len + 1 == s.size(), STATIC_ASSERT_PARAM(len + 1), STATIC_ASSERT_PARAM(s.size())); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(2, len == s.length(), STATIC_ASSERT_PARAM(len), STATIC_ASSERT_PARAM(s.length())); \
        ASSERT_EQ(len + 1, s.size()); \
        ASSERT_EQ(len, s.length()); \
        ASSERT_EQ(s.c_str(), s.data()); \
    } \
    { \
        STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE_ID(10, len + 1 == TACKLE_TMPL_STRING(id, c_str_, constexpr_offset, len).size(), \
            len + 1, TACKLE_TMPL_STRING(id, c_str_, constexpr_offset, len).size()); \
        STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE_ID(11, len == TACKLE_TMPL_STRING(id, c_str_, constexpr_offset, len).length(), \
            len, TACKLE_TMPL_STRING(id, c_str_, constexpr_offset, len).length()); \
        ASSERT_EQ(TACKLE_TMPL_STRING(id, c_str_, constexpr_offset, len).c_str(), TACKLE_TMPL_STRING(id, c_str_, constexpr_offset, len).data()); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, 1, 2, "test");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, L"test");

    TEST_TACKLE_TMPL_STRING(1, 1, 2, "test");
    TEST_TACKLE_TMPL_STRING(1, 1, 2, L"test");

    TEST_TACKLE_TMPL_STRING(2, 1, 2, UTILITY_PP_FILE);

#undef TEST_TACKLE_TMPL_STRING
}

TEST(TackleTmplStringTest, constexpr_get)
{
#define TEST_TACKLE_TMPL_STRING(id, index, c_str) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_GET(s, index)), "UTILITY_CONSTEXPR_GET value is not constexpr"); \
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
        const auto c = UTILITY_CONSTEXPR_GET(s, index); \
        static_assert(UTILITY_IS_CONSTEXPR_VALUE(c), "c value is not constexpr"); \
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
#define TEST_TACKLE_TMPL_STRING(id, index, c_char, c_str_) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str_); \
        const auto c = UTILITY_CONSTEXPR_GET(s, index); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, c == c_char, STATIC_ASSERT_PARAM(c), STATIC_ASSERT_PARAM(c_char)); \
        ASSERT_EQ(c, c_char); \
    } \
    { \
        STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_GET(TACKLE_TMPL_STRING(id, c_str_), index) == c_char, UTILITY_CONSTEXPR_GET(TACKLE_TMPL_STRING(id, c_str_), index), c_char); \
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(TACKLE_TMPL_STRING(id, c_str_), index), c_char); \
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

#define TEST_TACKLE_TMPL_STRING(id, constexpr_offset, index, c_char, c_str) \
    { \
        const auto s = TACKLE_TMPL_STRING(id, c_str, constexpr_offset); \
        const auto c = UTILITY_CONSTEXPR_GET(s, index); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, c == c_char, STATIC_ASSERT_PARAM(c), STATIC_ASSERT_PARAM(c_char)); \
        ASSERT_EQ(c, c_char); \
    } \
    { \
        STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_GET(TACKLE_TMPL_STRING(id, c_str, constexpr_offset), index) == c_char, \
            UTILITY_CONSTEXPR_GET(TACKLE_TMPL_STRING(id, c_str, constexpr_offset), index), c_char); \
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(TACKLE_TMPL_STRING(id, c_str, constexpr_offset), index), c_char); \
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
        const auto c = UTILITY_CONSTEXPR_GET(s, index); \
        STATIC_ASSERT_CONSTEXPR_TRUE_ID(1, c == c_char, STATIC_ASSERT_PARAM(c), STATIC_ASSERT_PARAM(c_char)); \
        ASSERT_EQ(c, c_char); \
    } \
    { \
        STATIC_ASSERT_RELAXED_CONSTEXPR_TRUE_ID(1, UTILITY_CONSTEXPR_GET(TACKLE_TMPL_STRING(id, c_str, constexpr_offset, len), index) == c_char, \
            UTILITY_CONSTEXPR_GET(TACKLE_TMPL_STRING(id, c_str, constexpr_offset, len), index), c_char); \
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(TACKLE_TMPL_STRING(id, c_str, constexpr_offset, len), index), c_char); \
    } (void)0

    TEST_TACKLE_TMPL_STRING(0, 1, 2, 0, '1', "0123");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, 1, '2', "0123");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, 2, '\0', "0123");

    TEST_TACKLE_TMPL_STRING(0, 1, 2, 0, L'1', L"0123");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, 1, L'2', L"0123");
    TEST_TACKLE_TMPL_STRING(0, 1, 2, 2, L'\0', L"0123");

#undef TEST_TACKLE_TMPL_STRING
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

using overload_resolution_3 = char[3];
using overload_resolution_4 = char[4];

template <uint64_t id, typename CharT, CharT... tchars>
const overload_resolution_1 & test_overload_resolution2(const tackle::tmpl_basic_string<id, CharT, tchars...> &);
template <typename CharT>
const overload_resolution_2 & test_overload_resolution2(const tackle::constexpr_basic_string<CharT> &);
template <typename CharT>
const overload_resolution_3 & test_overload_resolution2(const std::basic_string<CharT> &);
template <typename CharT>
const overload_resolution_4 & test_overload_resolution2(const CharT *);

TEST(TackleTmplStringTest, tmpl_string_vs_constexpr_string_overload2)
{
    {
        const auto s = TACKLE_TMPL_STRING(0, "");
        static_assert(sizeof(overload_resolution_1) == sizeof(test_overload_resolution2(s)), "must be called function with the tmpl_basic_string argument");
    }

    {
        const auto s = TACKLE_CONSTEXPR_STRING("");
        static_assert(sizeof(overload_resolution_2) == sizeof(test_overload_resolution2(s)), "must be called function with the constexpr_basic_string argument");
    }

    {
        const auto s = std::string("");
        static_assert(sizeof(overload_resolution_3) == sizeof(test_overload_resolution2(s)), "must be called function with the std::basic_string argument");
    }

    {
        const auto s = "";
        static_assert(sizeof(overload_resolution_4) == sizeof(test_overload_resolution2(s)), "must be called function with the CharT* argument");
    }
}
