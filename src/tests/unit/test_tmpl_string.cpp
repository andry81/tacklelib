#include "test_common.hpp"

#include <tacklelib/tackle/tmpl_string.hpp>
#include <tacklelib/tackle/constexpr_string.hpp>

#include <tacklelib/utility/type_identity.hpp>

TEST(TackleTmplStringTest, is_ct_constexpr) // must compile w/o errors, no need to run
{
    {
        const auto s = TACKLE_TMPL_STRING(0, "");

        UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(s.size()));
        UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(s.length()));

        UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_GET(s, 0)));
    }

    {
        const auto s = TACKLE_TMPL_STRING(0, UTILITY_CONSTEXPR_VALUE("test") + 1);

        UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(s.size()));
        UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(s.length()));

        UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_GET(s, 0)));
    }


    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, "").size()));
    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, "").length()));

    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, L"").size()));
    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, L"").length()));

    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, "test").size()));
    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, "test").length()));

    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, L"test").size()));
    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, L"test").length()));

    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, "").size()));
    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, "").length()));

    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, L"").size()));
    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, L"").length()));

    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, "test").size()));
    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, "test").length()));

    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, L"test").size()));
    UTILITY_UNUSED_STATEMENT(UTILITY_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, L"test").length()));
}

TEST(TackleTmplStringTest, is_constexpr)
{
    {
        const auto s = TACKLE_TMPL_STRING(0, "");

        ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(s.size()));
        ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(s.length()));

        ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_GET(s, 0)));
    }

    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, "").size()));
    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, "").length()));

    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, L"").size()));
    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, L"").length()));

    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, "test").size()));
    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, "test").length()));

    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, L"test").size()));
    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(0, L"test").length()));

    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, "").size()));
    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, "").length()));

    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, L"").size()));
    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, L"").length()));

    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, "test").size()));
    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, "test").length()));

    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, L"test").size()));
    ASSERT_TRUE(UTILITY_IS_CONSTEXPR_VALUE(TACKLE_TMPL_STRING(1, L"test").length()));
}

TEST(TackleTmplStringTest, constexpr_get)
{
    {
        const auto s = TACKLE_TMPL_STRING(0, "123");

        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 0), '1');
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 1), '2');
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 2), '3');
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 3), '\0');
    }

    {
        const auto s = TACKLE_TMPL_STRING(0, L"123");

        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 0), L'1');
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 1), L'2');
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 2), L'3');
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 3), L'\0');
    }

    {
        const auto s = TACKLE_TMPL_STRING(0, UTILITY_CONSTEXPR_VALUE("123") + 1);

        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 0), '2');
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 1), '3');
        ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 2), '\0');
    }
}

TEST(TackleTmplStringTest, is_exception)
{
}

TEST(TackleTmplStringTest, empty_string)
{
    {
      const auto s = TACKLE_TMPL_STRING(0, "");

      ASSERT_EQ(s.size(), 1);
      ASSERT_EQ(s.length(), 0);

      ASSERT_EQ(s.c_str(), s.data());

      ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 0), '\0');
    }

    {
      const auto s = TACKLE_TMPL_STRING(0, L"");

      ASSERT_EQ(s.size(), 1);
      ASSERT_EQ(s.length(), 0);

      ASSERT_EQ(s.c_str(), s.data());

      ASSERT_EQ(UTILITY_CONSTEXPR_GET(s, 0), L'\0');
    }
}

using overload_resolution_1 = char[1];
using overload_resolution_2 = char[2];

template <uint64_t id, typename CharT, CharT... tchars>
overload_resolution_1 test_overload_resolution(const tackle::tmpl_basic_string<id, CharT, tchars...> &);
template <typename CharT>
overload_resolution_2 test_overload_resolution(const tackle::constexpr_basic_string<CharT> &);

TEST(TackleTmplStringTest, tmpl_string_vs_constexpr_string_overload)
{
    static_assert(sizeof(overload_resolution_1) == sizeof(test_overload_resolution(TACKLE_TMPL_STRING(0, ""))), "must be called function with the tmpl_basic_string argument");
    static_assert(sizeof(overload_resolution_2) == sizeof(test_overload_resolution(TACKLE_CONSTEXPR_STRING(""))), "must be called function with the constexpr_basic_string argument");
}
