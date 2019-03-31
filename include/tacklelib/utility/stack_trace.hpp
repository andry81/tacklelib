#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_STACK_TRACE_HPP
#define UTILITY_STACK_TRACE_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>

#include <utility>


namespace tackle
{
    // CAUTION:
    //  In some cases (for example, for a logger function calls) the `top` must be constructed from literal strings,
    //  but there is no way to check it fully uniform and portably, so allow it be as a raw pointer and a length.
    //
    template <typename T>
    class inline_stack
    {
    public:
        using top_type = T;

        FORCE_INLINE CONSTEXPR_RETURN inline_stack(const T & top_, const inline_stack * next_ptr_ = nullptr) :
            next_ptr(next_ptr_), top(top_)
        {
        }

        CONSTEXPR_RETURN static FORCE_INLINE inline_stack make(const T & top)
        {
            return inline_stack{ top };
        }

        CONSTEXPR_RETURN static FORCE_INLINE inline_stack make_push(const inline_stack & next_stack, const T & top)
        {
            return inline_stack{ top, &next_stack };
        }

        const inline_stack *    next_ptr;
        T                       top;
    };
}

namespace utility
{
  
    template <typename T, typename F>
    FORCE_INLINE void trace_stack(const tackle::inline_stack<T> & dbg_stack, F && functor)
    {
        size_t index = 0;

        std::forward<F>(functor)(index, dbg_stack.top);

        ++index;
        const auto * next_ptr = dbg_stack.next_ptr;

        while (next_ptr) {
            std::forward<F>(functor)(index, next_ptr->top);
            ++index;
            next_ptr = next_ptr->next_ptr;
        }
    }
}

#endif
