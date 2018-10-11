#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>

#include <string>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <algorithm>


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
            else
                break;
        }

        va_end(ap);

        return str;
    }

}
