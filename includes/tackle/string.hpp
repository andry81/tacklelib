#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>

#include <string>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <algorithm>


// hint: operator* applies to character literals, but not to double-quoted literals
#define UTILITY_LITERAL_CHAR_(c_str, char_sizeof)       ((char_sizeof) == 1 ? (c_str * 0, c_str) : (L ## c_str * 0, L ## c_str))

// hint: operator[] applies to double-quoted literals, but is not to character literals
#define UTILITY_LITERAL_STRING_(c_str, char_sizeof)     ((char_sizeof) == 1 ? (c_str[0], c_str) : (L ## c_str[0], L ## c_str))

#define UTILITY_LITERAL_CHAR(c_str, char_sizeof)        UTILITY_LITERAL_CHAR_(c_str, char_sizeof)
#define UTILITY_LITERAL_STRING(c_str, char_sizeof)      UTILITY_LITERAL_STRING_(c_str, char_sizeof)


namespace tackle {

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
