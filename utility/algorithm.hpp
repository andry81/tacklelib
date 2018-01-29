#pragma once

#include "tacklelib.hpp"

#include <utility/utility.hpp>
#include <utility/type_traits.hpp>

#include <boost/type_traits/is_pod.hpp>

#include <limits>
#include <memory>
#include <algorithm>


#define TACKLE_PP_DEFAULT_UNROLLED_COPY_SIZE    256 // should not be greater than TACKLE_PP_MAX_UNROLLED_COPY_SIZE from `utility/algorithm/generated/unroll_copy_switch.hpp`
#define TACKLE_PP_MAX_UNROLLED_COPY_SIZE        1024

// copy with builtin unroll
#define UTILITY_COPY(from, to, size, ...) \
    ::utility::copy(from, to, size, __VA_ARGS__)


namespace utility
{
    // for iterators debugging
    template<typename T>
    FORCE_INLINE bool is_singular_iterator(const T & it)
    {
        T tmp = {};
        return !memcmp(&tmp, &it, sizeof(it));
    }

    template<typename T, size_t S>
    struct StaticArray
    {
        T buf[S];
    };

    // unrolls even in debug, useful to speedup not optimized code, where a call to function has unnecessary overhead
    // (for example, call to `memcpy` in a `for` with relatively small copy distance)
    template<typename T>
    FORCE_INLINE void copy(const T * from, T * to, size_t size, size_t unroll_size = TACKLE_PP_DEFAULT_UNROLLED_COPY_SIZE)
    {
        const size_t unrolled_size = (std::min)(unroll_size, size_t(TACKLE_PP_MAX_UNROLLED_COPY_SIZE));
        if (unrolled_size >= size) {
            //size_t buf_offset = 0;
            switch(size) {
                case 0: break;
                #include "utility/algorithm/generated/unroll_copy_switch.hpp"
                default: ASSERT_TRUE(false);
            }
        }
        else if (UTILITY_CONST_EXPR(boost::is_pod<T>::value)) {
            memcpy(to, from, sizeof(T) * size);
        }
        else {
            for (size_t i = 0; i < size; i++) {
                to[i] = from[i];
            }
        }
    }
}
