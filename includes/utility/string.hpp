#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_STRING_HPP
#define UTILITY_STRING_HPP

#include <tacklelib.hpp>

#include <utility/preprocessor.hpp>
#include <utility/platform.hpp>
#include <utility/string_identity.hpp>

#include <string>
#include <cstring>
#include <cstddef>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cwchar>
#include <cuchar>
#include <memory>
#include <algorithm>
#include <type_traits>


namespace utility {

    template <typename CharT>
    FORCE_INLINE size_t string_length(const CharT * str)
    {
        DEBUG_ASSERT_TRUE(str);
        return std::char_traits<CharT>::length(str);
    }

    // implementation based on answers from here: stackoverflow.com/questions/2342162/stdstring-formatting-like-sprintf/2342176
    //
    FORCE_INLINE std::string string_format(size_t string_reserve, const std::string fmt_str, ...)
    {
        size_t str_len = (std::max)(fmt_str.size(), string_reserve);
        std::string str;

        va_list ap;
        va_start(ap, fmt_str);

        while (true) {
            str.resize(str_len);

            const int final_n = std::vsnprintf(const_cast<char *>(str.data()), str_len, fmt_str.c_str(), ap);

            if (final_n < 0 || final_n >= int(str_len))
                str_len += (std::abs)(final_n - int(str_len) + 1);
            else {
                str.resize(final_n); // do not forget to shrink the size!
                break;
            }
        }

        va_end(ap);

        return str;
    }


}

#endif
