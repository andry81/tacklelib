#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_DEBUG_HPP
#define UTILITY_DEBUG_HPP

#include <tacklelib.hpp>

#include <utility/preprocessor.hpp>
#include <utility/platform.hpp>
#include <utility/optimization.hpp>

#ifdef UTILITY_COMPILER_CXX_MSC
#include <intrin.h>
#else
#include <x86intrin.h>  // Not just <immintrin.h> for compilers other than icc
#include <signal.h>
#endif

#include <string>


// break point placeholder, useful inside custom user macroses to emulate function call break points
#define BREAK_POINT_PLACEHOLDER() ::utility::unused() // `__asm nop` - can't be placed inside expressions, only statements

#if defined(UTILITY_PLATFORM_WINDOWS)

#define DEBUG_BREAK(cond) \
    if((cond) ? false : true); else __debugbreak() // won't require debug symbols to show the call stack, when the DebugBreak() will require system debug symbols to show the call stack correctly)

#elif defined(UTILITY_PLATFORM_POSIX)

// CAUTION:
//
// `__builtin_trap()` leads to `vex x86->IR: unhandled instruction bytes: 0xF 0xB 0x83 0xEC` under the valgrind execution!
// See for details: https://stackoverflow.com/questions/6859267/valgrind-unhandled-instruction-bytes-0xf-0xb-0xff-0x85
//
#define DEBUG_BREAK(exp) \
    if((exp) ? false : true); else raise(SIGTRAP) // or: __builtin_trap()

#else
#error debug_break is not supported for this platform
#endif

#define DEBUG_BREAK_IN_DEBUGGER(cond) DEBUG_BREAK((cond) && ::utility::is_under_debugger())

#define DEBUG_FUNC_LINE_A                           ::utility::DebugFuncLineA{ UTILITY_PP_FUNC, UTILITY_PP_LINE }
#define DEBUG_FUNC_LINE_MAKE_A()                    ::utility::DebugFuncLineInlineStackA::make(::utility::DebugFuncLineA{ UTILITY_PP_FUNC, UTILITY_PP_LINE })
#define DEBUG_FUNC_LINE_MAKE_PUSH_A(stack)          ::utility::DebugFuncLineInlineStackA::make_push(stack, ::utility::DebugFuncLineA{ UTILITY_PP_FUNC, UTILITY_PP_LINE })

#define DEBUG_FUNCSIG_LINE_A                        ::utility::DebugFuncLineA{ UTILITY_PP_FUNCSIG, UTILITY_PP_LINE }
#define DEBUG_FUNCSIG_LINE_MAKE_A()                 ::utility::DebugFuncLineInlineStackA::make(::utility::DebugFuncLineA{ UTILITY_PP_FUNCSIG, UTILITY_PP_LINE })
#define DEBUG_FUNCSIG_LINE_MAKE_PUSH_A(stack)       ::utility::DebugFuncLineInlineStackA::make_push(stack, ::utility::DebugFuncLineA{ UTILITY_PP_FUNCSIG, UTILITY_PP_LINE })

#define DEBUG_FILE_LINE_FUNC_A                      ::utility::DebugFileLineFuncA{ UTILITY_PP_FILE, UTILITY_PP_LINE, UTILITY_PP_FUNC }
#define DEBUG_FILE_LINE_FUNC_MAKE_A()               ::utility::DebugFileLineFuncInlineStackA::make(::utility::DebugFileLineFuncA{ UTILITY_PP_FILE, UTILITY_PP_LINE, UTILITY_PP_FUNC })
#define DEBUG_FILE_LINE_FUNC_MAKE_PUSH_A(stack)     ::utility::DebugFileLineFuncInlineStackA::make_push(stack, ::utility::DebugFileLineFuncA{ UTILITY_PP_FILE, UTILITY_PP_LINE, UTILITY_PP_FUNC })

#define DEBUG_FILE_LINE_FUNCSIG_A                   ::utility::DebugFileLineFuncA{ UTILITY_PP_FILE, UTILITY_PP_LINE, UTILITY_PP_FUNCSIG }
#define DEBUG_FILE_LINE_FUNCSIG_MAKE_A()            ::utility::DebugFileLineFuncInlineStackA::make(::utility::DebugFileLineFuncA{ UTILITY_PP_FILE, UTILITY_PP_LINE, UTILITY_PP_FUNCSIG })
#define DEBUG_FILE_LINE_FUNCSIG_MAKE_PUSH_A(stack)  ::utility::DebugFileLineFuncInlineStackA::make_push(stack, ::utility::DebugFileLineFuncA{ UTILITY_PP_FILE, UTILITY_PP_LINE, UTILITY_PP_FUNCSIG })


namespace utility
{
    struct DebugFuncLineA
    {
        std::string     func;
        int             line;
    };

    struct DebugFileLineFuncA
    {
        std::string     file;
        int             line;
        std::string     func;
    };

    template <typename T>
    class inline_stack
    {
    public:
        inline_stack(const T & top_, const inline_stack * next_ptr_ = nullptr) :
            next_ptr(next_ptr_), top(top_)
        {
        }

        static inline_stack make(const T & top)
        {
            return inline_stack{ top };
        }

        static inline_stack make_push(const inline_stack & next_stack, const T & top)
        {
            return inline_stack{ top, &next_stack };
        }

        const inline_stack *    next_ptr;
        T                       top;
    };

    using DebugFuncLineInlineStackA     = inline_stack<DebugFuncLineA>;
    using DebugFileLineFuncInlineStackA = inline_stack<DebugFileLineFuncA>;

    // break on true
    void debug_break(bool condition = false);
    bool is_under_debugger();
}

#endif
