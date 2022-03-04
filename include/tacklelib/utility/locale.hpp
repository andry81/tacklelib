#pragma once

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_identity.hpp>

#include <tacklelib/tackle/string.hpp>

#include <locale>
#ifdef UTILITY_PLATFORM_FEATURE_STD_HAS_CODECVT_HEADER
#   include <codecvt>
#else
#   include <boost/locale/encoding_utf.hpp>
#endif
#include <string>
#include <utility>

// CAUTION:
//  In case of GCC < 5, then workaround through the boost is used.
//  Based on: https://stackoverflow.com/questions/15615136/is-codecvt-not-a-std-header/28875347#28875347
//

namespace utility {

    enum StringConvertionType
    {
        StringConv_utf8_to_utf16        = 1,
        StringConv_utf16_to_utf8        = 2,
        StringConv_utf8_tofrom_utf16    = 3,
    };

    struct tag_string_conv_utf8_to_utf16 : utility::int_identity<StringConv_utf8_to_utf16> {};
    struct tag_string_conv_utf16_to_utf8 : utility::int_identity<StringConv_utf16_to_utf8> {};
    struct tag_string_conv_utf8_tofrom_utf16 : utility::int_identity<StringConv_utf8_tofrom_utf16> {};

    FORCE_INLINE std::string convert_utf16_to_utf8_string(std::string && astr)
    {
        return astr;
    }

    FORCE_INLINE const std::string & convert_utf16_to_utf8_string(const std::string & astr)
    {
        return astr;
    }

    template <size_t S>
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char (& astr)[S])
    {
        return std::string{ astr, astr + S };
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char * astr, const char * astr_last)
    {
        return std::string{ astr, astr_last };
    }

#ifdef UTILITY_PLATFORM_FEATURE_STD_HAS_CODECVT_HEADER
    template <class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(std::wstring && wstr, std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.to_bytes(std::move(wstr));
    }

    template <class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::wstring & wstr, std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.to_bytes(wstr);
    }

    template <size_t S, class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const wchar_t (& wstr)[S], std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.to_bytes(wstr, wstr + S);
    }

    template <class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const wchar_t * wstr, const wchar_t * wstr_last, std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.to_bytes(wstr, wstr_last);
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(std::wstring && wstr)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

        return convert_utf16_to_utf8_string(std::move(wstr), wstring_convert_t{});
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::wstring & wstr)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

        return convert_utf16_to_utf8_string(wstr, wstring_convert_t{});
    }

    template <size_t S>
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const wchar_t (& wstr)[S])
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

        return convert_utf16_to_utf8_string(wstr, wstring_convert_t{});
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const wchar_t * wstr, const wchar_t * wstr_last)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

        return convert_utf16_to_utf8_string(wstr, wstr_last, wstring_convert_t{});
    }

    //

    template <class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(std::u16string && u16str, std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && u16str_converter)
    {
        return u16str_converter.to_bytes(std::move(u16str));
    }

    template <class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::u16string & u16str, std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && u16str_converter)
    {
        return u16str_converter.to_bytes(u16str);
    }

    template <size_t S, class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char16_t (& u16str)[S], std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && u16str_converter)
    {
        return u16str_converter.to_bytes(u16str, u16str + S);
    }

    template <class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char16_t * u16str, const char16_t * u16str_last, std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && u16str_converter)
    {
        return u16str_converter.to_bytes(u16str, u16str_last);
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(std::u16string && u16str)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>;

        return convert_utf16_to_utf8_string(std::move(u16str), wstring_convert_t{});
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::u16string & u16str)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>;

        return convert_utf16_to_utf8_string(u16str, wstring_convert_t{});
    }

    template <size_t S>
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char16_t (& u16str)[S])
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>;

        return convert_utf16_to_utf8_string(u16str, wstring_convert_t{});
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char16_t * u16str, const char16_t * u16str_last)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>;

        return convert_utf16_to_utf8_string(u16str, u16str_last, wstring_convert_t{});
    }

    //

    template <class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(std::u32string && u32str, std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && u32str_converter)
    {
        return u32str_converter.to_bytes(std::move(u32str));
    }

    template <class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::u32string & u32str, std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && u32str_converter)
    {
        return u32str_converter.to_bytes(u32str);
    }

    template <size_t S, class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char32_t (& u32str)[S], std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && u32str_converter)
    {
        return u32str_converter.to_bytes(u32str, u32str + S);
    }

    template <class Codecvt, class Elem, class Walloc = std::allocator<Elem>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char32_t * u32str, const char32_t * u32str_last, std::wstring_convert<Codecvt, Elem, Walloc, Balloc> && u32str_converter)
    {
        return u32str_converter.to_bytes(u32str, u32str_last);
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(std::u32string && u32str)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char32_t>, char32_t>;

        return convert_utf16_to_utf8_string(std::move(u32str), wstring_convert_t{});
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::u32string & u32str)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char32_t>, char32_t>;

        return convert_utf16_to_utf8_string(u32str, wstring_convert_t{});
    }

    template <size_t S>
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char32_t (& u32str)[S])
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char32_t>, char32_t>;

        return convert_utf16_to_utf8_string(u32str, wstring_convert_t{});
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char32_t * u32str, const char32_t * u32str_last)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char32_t>, char32_t>;

        return convert_utf16_to_utf8_string(u32str, u32str_last, wstring_convert_t{});
    }

    //

    template <class Codecvt, class Walloc = std::allocator<wchar_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(std::string && astr, std::wstring_convert<Codecvt, wchar_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(std::move(astr));
    }

    template <class Codecvt, class Walloc = std::allocator<wchar_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(const std::string & astr, std::wstring_convert<Codecvt, wchar_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(astr);
    }

    template <size_t S, class Codecvt, class Walloc = std::allocator<wchar_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(const char (& astr)[S], std::wstring_convert<Codecvt, wchar_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(astr, astr + S);
    }

    template <class Codecvt, class Walloc = std::allocator<wchar_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(const char * astr, const char * astr_last, std::wstring_convert<Codecvt, wchar_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(astr, astr_last);
    }

    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(const std::string & astr, utility::wstring_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

        return convert_utf8_to_utf16_string(astr, wstring_convert_t{});
    }

    template <size_t S>
    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(const char (& astr)[S], utility::wstring_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

        return convert_utf8_to_utf16_string(astr, wstring_convert_t{});
    }

    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(const char * astr, const char * astr_last, utility::wstring_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

        return convert_utf8_to_utf16_string(astr, astr_last, wstring_convert_t{});
    }

    //

    template <class Codecvt, class Walloc = std::allocator<char16_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(std::string && astr, std::wstring_convert<Codecvt, char16_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(std::move(astr));
    }

    template <class Codecvt, class Walloc = std::allocator<char16_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(const std::string & astr, std::wstring_convert<Codecvt, char16_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(astr);
    }

    template <size_t S, class Codecvt, class Walloc = std::allocator<char16_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(const char (& astr)[S], std::wstring_convert<Codecvt, char16_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(astr, astr + S);
    }

    template <class Codecvt, class Walloc = std::allocator<char16_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(const char * astr, const char * astr_last, std::wstring_convert<Codecvt, char16_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(astr, astr_last);
    }

    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(std::string && astr, utility::u16string_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>;

        return convert_utf8_to_utf16_string(std::move(astr), wstring_convert_t{});
    }

    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(const std::string & astr, utility::u16string_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>;

        return convert_utf8_to_utf16_string(astr, wstring_convert_t{});
    }

    template <size_t S>
    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(const char (& astr)[S], utility::u16string_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>;

        return convert_utf8_to_utf16_string(astr, wstring_convert_t{});
    }

    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(const char * astr, const char * astr_last, utility::u16string_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>;

        return convert_utf8_to_utf16_string(astr, astr_last, wstring_convert_t{});
    }

    //

    template <class Codecvt, class Walloc = std::allocator<char32_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(std::string && astr, std::wstring_convert<Codecvt, char32_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(std::move(astr));
    }

    template <class Codecvt, class Walloc = std::allocator<char32_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(const std::string & astr, std::wstring_convert<Codecvt, char32_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(astr);
    }

    template <size_t S, class Codecvt, class Walloc = std::allocator<char32_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(const char (& astr)[S], std::wstring_convert<Codecvt, char32_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(astr);
    }

    template <class Codecvt, class Walloc = std::allocator<char32_t>, class Balloc = std::allocator<char> >
    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(const char * astr, const char * astr_last, std::wstring_convert<Codecvt, char32_t, Walloc, Balloc> && wstr_converter)
    {
        return wstr_converter.from_bytes(astr, astr_last);
    }

    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(std::string && astr, utility::u32string_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char32_t>, char32_t>;

        return convert_utf8_to_utf16_string(std::move(astr), wstring_convert_t{});
    }

    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(const std::string & astr, utility::u32string_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char32_t>, char32_t>;

        return convert_utf8_to_utf16_string(astr, wstring_convert_t{});
    }

    template <size_t S>
    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(const char (& astr)[S], utility::u32string_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char32_t>, char32_t>;

        return convert_utf8_to_utf16_string(astr, wstring_convert_t{});
    }

    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(const char * astr, const char * astr_last, utility::u32string_identity)
    {
        using wstring_convert_t = std::wstring_convert<std::codecvt_utf8_utf16<char32_t>, char32_t>;

        return convert_utf8_to_utf16_string(astr, astr_last, wstring_convert_t{});
    }
#else
    // CAUTION:
    //   Limited workaround ONLY for GCC < 5.
    //

    namespace boost_locale = boost::locale::conv;

    FORCE_INLINE std::string convert_utf16_to_utf8_string(std::wstring && wstr)
    {
        return boost_locale::utf_to_utf<char>(std::move(wstr));
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::wstring & wstr)
    {
        return boost_locale::utf_to_utf<char>(wstr);
    }

    template <size_t S>
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const wchar_t (& wstr)[S])
    {
        return boost_locale::utf_to_utf<char>(wstr, wstr + S);
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const wchar_t * wstr, const wchar_t * wstr_last)
    {
        return boost_locale::utf_to_utf<char>(wstr, wstr_last);
    }

    //

    FORCE_INLINE std::string convert_utf16_to_utf8_string(std::u16string && u16str)
    {
        return boost_locale::utf_to_utf<char>(std::move(u16str));
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::u16string & u16str)
    {
        return boost_locale::utf_to_utf<char>(u16str);
    }

    template <size_t S>
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char16_t (& u16str)[S])
    {
        return boost_locale::utf_to_utf<char>(u16str, u16str + S);
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char16_t * u16str, const char16_t * u16str_last)
    {
        return boost_locale::utf_to_utf<char>(u16str, u16str_last);
    }

    //

    FORCE_INLINE std::string convert_utf16_to_utf8_string(std::u32string && u32str)
    {
        return boost_locale::utf_to_utf<char>(std::move(u32str));
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const std::u32string & u32str)
    {
        return boost_locale::utf_to_utf<char>(u32str);
    }

    template <size_t S>
    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char32_t (& u32str)[S])
    {
        return boost_locale::utf_to_utf<char>(u32str, u32str + S);
    }

    FORCE_INLINE std::string convert_utf16_to_utf8_string(const char32_t * u32str, const char32_t * u32str_last)
    {
        return boost_locale::utf_to_utf<char>(u32str, u32str_last);
    }

    //

    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(std::string && astr, utility::wstring_identity)
    {
        return boost_locale::utf_to_utf<wchar_t>(std::move(astr));
    }

    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(const std::string & astr, utility::wstring_identity)
    {
        return boost_locale::utf_to_utf<wchar_t>(astr);
    }

    template <size_t S>
    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(const char (& astr)[S], utility::wstring_identity)
    {
        return boost_locale::utf_to_utf<wchar_t>(astr, astr + S);
    }

    FORCE_INLINE std::wstring convert_utf8_to_utf16_string(const char * astr, const char * astr_last, utility::wstring_identity)
    {
        return boost_locale::utf_to_utf<wchar_t>(astr, astr_last);
    }

    //

    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(std::string && astr, utility::u16string_identity)
    {
        return boost_locale::utf_to_utf<char16_t>(std::move(astr));
    }

    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(const std::string & astr, utility::u16string_identity)
    {
        return boost_locale::utf_to_utf<char16_t>(astr);
    }

    template <size_t S>
    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(const char (& astr)[S], utility::u16string_identity)
    {
        return boost_locale::utf_to_utf<char16_t>(astr, astr + S);
    }

    FORCE_INLINE std::u16string convert_utf8_to_utf16_string(const char * astr, const char * astr_last, utility::u16string_identity)
    {
        return boost_locale::utf_to_utf<char16_t>(astr, astr_last);
    }

    //

    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(std::string && astr, utility::u32string_identity)
    {
        return boost_locale::utf_to_utf<char32_t>(std::move(astr));
    }

    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(const std::string & astr, utility::u32string_identity)
    {
        return boost_locale::utf_to_utf<char32_t>(astr);
    }

    template <size_t S>
    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(const char (& astr)[S], utility::u32string_identity)
    {
        return boost_locale::utf_to_utf<char32_t>(astr, astr + S);
    }

    FORCE_INLINE std::u32string convert_utf8_to_utf16_string(const char * astr, const char * astr_last, utility::u32string_identity)
    {
        return boost_locale::utf_to_utf<char32_t>(astr, astr_last);
    }
#endif

    // tagged functions

//    FORCE_INLINE void convert_string_to_string(std::string && from_str, std::string & to_path, ...)
//    {
//        to_path = std::move(from_str);
//    }
//
//    FORCE_INLINE void convert_string_to_string(const std::string & from_str, std::string & to_path, ...)
//    {
//        to_path = from_str;
//    }
//
//    template <size_t S>
//    FORCE_INLINE void convert_string_to_string(const char (& from_str)[S], std::string & to_path, ...)
//    {
//        to_path.assign(from_str, S);
//    }
//
//    FORCE_INLINE void convert_string_to_string(const char * from_str, const char * from_str_last, std::string & to_path, ...)
//    {
//        to_path.assign(from_str, from_str_last);
//    }

    //

    FORCE_INLINE void convert_string_to_string(std::string && from_str, std::wstring & to_path, utility::int_identity<StringConv_utf8_to_utf16>)
    {
        to_path = convert_utf8_to_utf16_string(std::move(from_str), utility::tag_wstring{});
    }

    FORCE_INLINE void convert_string_to_string(const std::string & from_str, std::wstring & to_path, utility::int_identity<StringConv_utf8_to_utf16>)
    {
        to_path = convert_utf8_to_utf16_string(from_str, utility::tag_wstring{});
    }

    template <size_t S>
    FORCE_INLINE void convert_string_to_string(const char (& from_str)[S], std::wstring & to_path, utility::int_identity<StringConv_utf8_to_utf16>)
    {
        to_path = convert_utf8_to_utf16_string(from_str, utility::tag_wstring{});
    }

    FORCE_INLINE void convert_string_to_string(const char * from_str, const char * from_str_last, std::wstring & to_path, utility::int_identity<StringConv_utf8_to_utf16>)
    {
        to_path = convert_utf8_to_utf16_string(from_str, from_str_last, utility::tag_wstring{});
    }

    FORCE_INLINE void convert_string_to_string(std::string && from_str, std::wstring & to_path, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        to_path = convert_utf8_to_utf16_string(std::move(from_str), utility::tag_wstring{});
    }

    FORCE_INLINE void convert_string_to_string(const std::string & from_str, std::wstring & to_path, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        to_path = convert_utf8_to_utf16_string(from_str, utility::tag_wstring{});
    }

    template <size_t S>
    FORCE_INLINE void convert_string_to_string(const char (& from_str)[S], std::wstring & to_path, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        to_path = convert_utf8_to_utf16_string(from_str, utility::tag_wstring{});
    }

    FORCE_INLINE void convert_string_to_string(const char * from_str, const char * from_str_last, std::wstring & to_path, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        to_path = convert_utf8_to_utf16_string(from_str, from_str_last, utility::tag_wstring{});
    }

//    FORCE_INLINE void convert_string_to_string(std::wstring && from_str, std::wstring & to_path, ...)
//    {
//        to_path = std::move(from_str);
//    }
//
//    FORCE_INLINE void convert_string_to_string(const std::wstring & from_str, std::wstring & to_path, ...)
//    {
//        to_path = from_str;
//    }
//
//    template <size_t S>
//    FORCE_INLINE void convert_string_to_string(const wchar_t (& from_str)[S], std::wstring & to_path, ...)
//    {
//        to_path = from_str;
//    }
//
//    FORCE_INLINE void convert_string_to_string(const wchar_t * from_str, const wchar_t * from_str_last, std::wstring & to_path, ...)
//    {
//        to_path.assign(from_str, from_str_last);
//    }

    //

    FORCE_INLINE void convert_string_to_string(std::wstring && from_str, std::string & to_path, utility::int_identity<StringConv_utf16_to_utf8>)
    {
        to_path = convert_utf16_to_utf8_string(std::move(from_str));
    }

    FORCE_INLINE void convert_string_to_string(const std::wstring & from_str, std::string & to_path, utility::int_identity<StringConv_utf16_to_utf8>)
    {
        to_path = convert_utf16_to_utf8_string(from_str);
    }

    template <size_t S>
    FORCE_INLINE void convert_string_to_string(const wchar_t (& from_str)[S], std::string & to_path, utility::int_identity<StringConv_utf16_to_utf8>)
    {
        to_path = convert_utf16_to_utf8_string(from_str);
    }

    FORCE_INLINE void convert_string_to_string(const wchar_t * from_str, const wchar_t * from_str_last, std::string & to_path, utility::int_identity<StringConv_utf16_to_utf8>)
    {
        to_path = convert_utf16_to_utf8_string(from_str, from_str_last);
    }

    FORCE_INLINE void convert_string_to_string(std::wstring && from_str, std::string & to_path, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        to_path = convert_utf16_to_utf8_string(std::move(from_str));
    }

    FORCE_INLINE void convert_string_to_string(const std::wstring & from_str, std::string & to_path, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        to_path = convert_utf16_to_utf8_string(from_str);
    }

    template <size_t S>
    FORCE_INLINE void convert_string_to_string(const wchar_t (& from_str)[S], std::string & to_path, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        to_path = convert_utf16_to_utf8_string(from_str);
    }

    FORCE_INLINE void convert_string_to_string(const wchar_t * from_str, const wchar_t * from_str_last, std::string & to_path, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        to_path = convert_utf16_to_utf8_string(from_str, from_str_last);
    }

//    FORCE_INLINE std::string convert_string_to_string(std::string && from_str, utility::string_identity, ...)
//    {
//        return from_str;
//    }
//
//    FORCE_INLINE std::string convert_string_to_string(const std::string & from_str, utility::string_identity, ...)
//    {
//        return from_str;
//    }
//
//    template <size_t S>
//    FORCE_INLINE std::string convert_string_to_string(const char (& from_str)[S], utility::string_identity, ...)
//    {
//        return from_str;
//    }
//
//    FORCE_INLINE std::string convert_string_to_string(const char * from_str, const char * from_str_last, utility::string_identity, ...)
//    {
//        return std::string{ from_str, from_str_last };
//    }

    //

    FORCE_INLINE std::wstring convert_string_to_string(std::string && from_str, utility::wstring_identity, utility::int_identity<StringConv_utf8_to_utf16>)
    {
        return convert_utf8_to_utf16_string(std::move(from_str), utility::tag_wstring{});
    }

    FORCE_INLINE std::wstring convert_string_to_string(const std::string & from_str, utility::wstring_identity, utility::int_identity<StringConv_utf8_to_utf16>)
    {
        return convert_utf8_to_utf16_string(from_str, utility::tag_wstring{});
    }

    template <size_t S>
    FORCE_INLINE std::wstring convert_string_to_string(const char (& from_str)[S], utility::wstring_identity, utility::int_identity<StringConv_utf8_to_utf16>)
    {
        return convert_utf8_to_utf16_string(from_str, utility::tag_wstring{});
    }

    FORCE_INLINE std::wstring convert_string_to_string(const char * from_str, const char * from_str_last, utility::wstring_identity, utility::int_identity<StringConv_utf8_to_utf16>)
    {
        return convert_utf8_to_utf16_string(from_str, from_str_last, utility::tag_wstring{});
    }

    FORCE_INLINE std::wstring convert_string_to_string(std::string && from_str, utility::wstring_identity, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        return convert_utf8_to_utf16_string(std::move(from_str), utility::tag_wstring{});
    }

    FORCE_INLINE std::wstring convert_string_to_string(const std::string & from_str, utility::wstring_identity, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        return convert_utf8_to_utf16_string(from_str, utility::tag_wstring{});
    }

    template <size_t S>
    FORCE_INLINE std::wstring convert_string_to_string(const char (& from_str)[S], utility::wstring_identity, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        return convert_utf8_to_utf16_string(from_str, utility::tag_wstring{});
    }

    FORCE_INLINE std::wstring convert_string_to_string(const char * from_str, const char * from_str_last, utility::wstring_identity, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        return convert_utf8_to_utf16_string(from_str, from_str_last, utility::tag_wstring{});
    }

//    FORCE_INLINE std::wstring convert_string_to_string(std::wstring && from_str, utility::wstring_identity, ...)
//    {
//        return from_str;
//    }
//
//    FORCE_INLINE std::wstring convert_string_to_string(const std::wstring & from_str, utility::wstring_identity, ...)
//    {
//        return from_str;
//    }
//
//    template <size_t S>
//    FORCE_INLINE std::wstring convert_string_to_string(const wchar_t (& from_str)[S], utility::wstring_identity, ...)
//    {
//        return from_str;
//    }
//
//    FORCE_INLINE std::wstring convert_string_to_string(const wchar_t * from_str, const wchar_t * from_str_last, utility::wstring_identity, ...)
//    {
//        return std::wstring{ from_str, from_str_last };
//    }

    //

    FORCE_INLINE std::string convert_string_to_string(std::wstring && from_str, utility::string_identity, utility::int_identity<StringConv_utf16_to_utf8>)
    {
        return convert_utf16_to_utf8_string(std::move(from_str));
    }

    FORCE_INLINE std::string convert_string_to_string(const std::wstring & from_str, utility::string_identity, utility::int_identity<StringConv_utf16_to_utf8>)
    {
        return convert_utf16_to_utf8_string(from_str);
    }

    template <size_t S>
    FORCE_INLINE std::string convert_string_to_string(const wchar_t (& from_str)[S], utility::string_identity, utility::int_identity<StringConv_utf16_to_utf8>)
    {
        return convert_utf16_to_utf8_string(from_str);
    }

    FORCE_INLINE std::string convert_string_to_string(const wchar_t * from_str, const wchar_t * from_str_last, utility::string_identity, utility::int_identity<StringConv_utf16_to_utf8>)
    {
        return convert_utf16_to_utf8_string(from_str, from_str_last);
    }

    FORCE_INLINE std::string convert_string_to_string(std::wstring && from_str, utility::string_identity, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        return convert_utf16_to_utf8_string(std::move(from_str));
    }

    FORCE_INLINE std::string convert_string_to_string(const std::wstring & from_str, utility::string_identity, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        return convert_utf16_to_utf8_string(from_str);
    }

    template <size_t S>
    FORCE_INLINE std::string convert_string_to_string(const wchar_t (& from_str)[S], utility::string_identity, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        return convert_utf16_to_utf8_string(from_str);
    }

    FORCE_INLINE std::string convert_string_to_string(const wchar_t * from_str, const wchar_t * from_str_last, utility::string_identity, utility::int_identity<StringConv_utf8_tofrom_utf16>)
    {
        return convert_utf16_to_utf8_string(from_str, from_str_last);
    }

}
