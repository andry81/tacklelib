#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>

#include <tackle/string.hpp>

#include <locale>
#include <codecvt>


namespace utility {

    FORCE_INLINE const std::string & convert_utf16_to_utf8_string(const std::string & astr)
    {
        return astr;
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::wstring & wstr)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

        wstring_convert_t wstring_utf16_to_utf8{};

        return wstring_utf16_to_utf8.to_bytes(wstr);
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::u16string & u16str)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>;

        wstring_convert_t wstring_utf16_to_utf8{};

        return wstring_utf16_to_utf8.to_bytes(u16str);
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::u32string & u32str)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char32_t>, char32_t>;

        wstring_convert_t wstring_utf16_to_utf8{};

        return wstring_utf16_to_utf8.to_bytes(u32str);
    }

    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(const std::string & astr, utility::wstring_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

        wstring_convert_t wstring_utf8_to_utf16{};

        return wstring_utf8_to_utf16.from_bytes(astr);
    }

    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(const std::string & astr, utility::u16string_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>;

        wstring_convert_t wstring_utf8_to_utf16{};

        return wstring_utf8_to_utf16.from_bytes(astr);
    }

    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(const std::string & astr, utility::u32string_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char32_t>, char32_t>;

        wstring_convert_t wstring_utf8_to_utf16{};

        return wstring_utf8_to_utf16.from_bytes(astr);
    }

}
