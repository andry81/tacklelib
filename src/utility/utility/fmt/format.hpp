#pragma once

#include <src/tacklelib_private.hpp>

#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_UTILITY_FMT)

#include <fmt/format.h>

#include <algorithm>


namespace fmt {

template <typename S0, typename S1, typename... Args>
inline std::basic_string<FMT_CHAR(S0)> format2(
    const S0 && format_str0, const S1 && format_str1, const Args &&... args)
{
    return format(std::forward<S0>(format_str0),
        format(std::forward<S1>(format_str1), std::forward<Args>(args)...));
}

}

#endif
