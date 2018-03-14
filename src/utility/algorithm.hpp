#pragma once

#include <tacklelib.hpp>

#include <utility/utility.hpp>
#include <utility/static_assert.hpp>
#include <utility/type_traits.hpp>
#include <utility/math.hpp>

#include <boost/type_traits/is_pod.hpp>

#include <boost/chrono.hpp>

#include <limits>
#include <memory>
#include <algorithm>


#define TACKLE_PP_DEFAULT_UNROLLED_COPY_SIZE    256 // should not be greater than TACKLE_PP_MAX_UNROLLED_COPY_SIZE from `utility/algorithm/generated/unroll_copy_switch.hpp`
#define TACKLE_PP_MAX_UNROLLED_COPY_SIZE        256

// copy with builtin unroll
#define UTILITY_COPY(from, to, size, ...) \
    ::utility::copy(from, to, size, __VA_ARGS__)

#define UTILITY_COPY_FORCE_INLINE(from, to, size, ...) \
    ::utility::copy_forceinline(from, to, size, __VA_ARGS__)

STATIC_ASSERT_GE(TACKLE_PP_MAX_UNROLLED_COPY_SIZE, TACKLE_PP_DEFAULT_UNROLLED_COPY_SIZE, "TACKLE_PP_DEFAULT_UNROLLED_COPY_SIZE must be not greater than TACKLE_PP_MAX_UNROLLED_COPY_SIZE");


namespace utility
{
    using namespace boost::chrono;

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

    // Unrolls even in debug, useful to speedup not optimized code, where a call to function has unnecessary overhead
    // (for example, call to `memcpy` in a `for` with relatively small copy distance).
    template<typename T>
    inline void copy(const T * from, T * to, size_t size, size_t unroll_size = TACKLE_PP_DEFAULT_UNROLLED_COPY_SIZE)
    {
        const size_t unrolled_size = (std::min)(unroll_size, size_t(TACKLE_PP_MAX_UNROLLED_COPY_SIZE));
        if (unrolled_size >= size) {
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

    // force inline version of unrolled copy
    template<typename T>
    FORCE_INLINE void copy_forceinline(const T * from, T * to, size_t size, size_t unroll_size = TACKLE_PP_DEFAULT_UNROLLED_COPY_SIZE)
    {
        const size_t unrolled_size = (std::min)(unroll_size, size_t(TACKLE_PP_MAX_UNROLLED_COPY_SIZE));
        if (unrolled_size >= size) {
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

    FORCE_INLINE_ALWAYS void spin_sleep(uint64_t wait_nsec)
    {
        const auto begin_wait_time = high_resolution_clock::now();

        while (true)
        {
            const auto next_wait_time = high_resolution_clock::now();

            const auto spent_time_dur = next_wait_time - begin_wait_time;

            const uint64_t spent_time_dur_nsec = spent_time_dur.count() >= 0 ? // workaround for negative values
                duration_cast<nanoseconds>(spent_time_dur).count() : 0;

            if (spent_time_dur_nsec >= wait_nsec) {
                return;
            }
        }
    }

    template <typename Functor>
    FORCE_INLINE void spin_sleep(uint64_t wait_nsec, Functor && spin_function)
    {
        const auto begin_wait_time = high_resolution_clock::now();

        while (true)
        {
            const auto next_wait_time = high_resolution_clock::now();

            const auto spent_time_dur = next_wait_time - begin_wait_time;

            const uint64_t spent_time_dur_nsec = spent_time_dur.count() >= 0 ? // workaround for negative values
                duration_cast<nanoseconds>(spent_time_dur).count() : 0;

            if (spent_time_dur_nsec >= wait_nsec) {
                return;
            }

            if (!spin_function()) {
                return;
            }
        }
    }

    template <typename Functor>
    FORCE_INLINE void spin_sleep(uint64_t wait_nsec, Functor && spin_function, uint64_t schedule_call_time_nsec)
    {
        const auto begin_wait_time = high_resolution_clock::now();

        uint64_t schedule_time_next_index;
        uint64_t schedule_time_prev_index = math::uint64_max;

        while (true)
        {
            const auto next_wait_time = high_resolution_clock::now();

            const auto spent_time_dur = next_wait_time - begin_wait_time;

            const uint64_t spent_time_dur_nsec = spent_time_dur.count() >= 0 ? // workaround for negative values
                duration_cast<nanoseconds>(spent_time_dur).count() : 0;

            if (spent_time_dur_nsec >= wait_nsec) {
                return;
            }

            schedule_time_next_index = spent_time_dur_nsec / schedule_call_time_nsec;

            if (schedule_time_next_index != schedule_time_prev_index) {
                if (!spin_function()) {
                    return;
                }
                schedule_time_prev_index = schedule_time_next_index;
            }
        }
    }
}
