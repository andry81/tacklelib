#pragma once

#include <utility/utility.hpp>

#include <memory>

namespace utility
{
    // for iterators debugging
    template<typename T>
    bool is_singular_iterator(const T & it)
    {
        T tmp = {};
        return !memcmp(&tmp, &it, sizeof(it));
    }
}
