#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_STRING_HPP
#define TACKLE_STRING_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/preprocessor.hpp>
#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_identity.hpp>

#include <string>
#include <cwchar>
#include <uchar.h> // in GCC `cuchar` header might not exist
#include <memory>
#include <algorithm>
#include <type_traits>


namespace tackle {

    // Uninitialized char classes, useful to construct big std::vector arrays w/o waste on initialization time.
    // Based on: https://stackoverflow.com/questions/11149665/c-vector-that-doesnt-initialize-its-members/11150052#11150052
    //

    template <typename CharT>
    struct uninitialized_basic_char
    {
        uninitialized_basic_char() {}

        CharT m;
    };

    using uninitialized_char    = uninitialized_basic_char<char>;
    using uninitialized_uchar   = uninitialized_basic_char<unsigned char>;
    using uninitialized_wchar   = uninitialized_basic_char<wchar_t>;
    using uninitialized_char16  = uninitialized_basic_char<char16_t>;
    using uninitialized_char32  = uninitialized_basic_char<char32_t>;

    // some static checks
    static_assert(sizeof(uninitialized_char) == sizeof(char),               "sizeof uninitialized_char must equal to sizeof char");
    static_assert(sizeof(uninitialized_uchar) == sizeof(unsigned char),     "sizeof uninitialized_uchar must equal to sizeof unsigned char");
    static_assert(sizeof(uninitialized_wchar) == sizeof(wchar_t),           "sizeof uninitialized_wchar must equal to sizeof wchar_t");
    static_assert(sizeof(uninitialized_char16) == sizeof(char16_t),         "sizeof uninitialized_char16 must equal to sizeof char16_t");
    static_assert(sizeof(uninitialized_char32) == sizeof(char32_t),         "sizeof uninitialized_char32 must equal to sizeof char32_t");

    static_assert(alignof(uninitialized_char) == alignof(char),             "alignof uninitialized_char must equal to alignof char");
    static_assert(alignof(uninitialized_uchar) == alignof(unsigned char),   "alignof uninitialized_uchar must equal to alignof unsigned char");
    static_assert(alignof(uninitialized_wchar) == alignof(wchar_t),         "alignof uninitialized_wchar must equal to alignof wchar_t");
    static_assert(alignof(uninitialized_char16) == alignof(char16_t),       "alignof uninitialized_char16 must equal to alignof char16_t");
    static_assert(alignof(uninitialized_char32) == alignof(char32_t),       "alignof uninitialized_char32 must equal to alignof char32_t");

}

#endif
