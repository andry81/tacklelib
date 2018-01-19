#pragma once

#include "utility/platform.hpp"

#ifdef UTILITY_COMPILER_CXX_MSC
#include <intrin.h>
#else
#include <x86intrin.h>  // Not just <immintrin.h> for compilers other than icc
#endif


#define UTILITY_UNUSED(exp)             {{ (void)((exp), 0); }} (void)0
#define UTILITY_UNUSED2(e0, e1)         UTILITY_UNUSED(e0); UTILITY_UNUSED(e1)
#define UTILITY_UNUSED3(e0, e1, e2)     UTILITY_UNUSED2(e0, e1); UTILITY_UNUSED(e2)
#define UTILITY_UNUSED4(e0, e1, e2, e3) UTILITY_UNUSED3(e0, e1, e2); UTILITY_UNUSED(e3)

// break point placeholder, useful inside macroses like ASSERT*
#define BREAK_POINT_PLACEHOLDER() ::utility::unused() // `__asm nop` - can't be placed inside expressions, only statements

#if defined(UTILITY_PLATFORM_WINDOWS)

#define DEBUG_BREAK(exp) \
    if(!bool(exp)); else __debugbreak() // won't require debug symbols to show the call stack, when the DebugBreak() will require system debug symbols to show the call stack correctly)

#elif defined(UTILITY_PLATFORM_POSIX)

#define DEBUG_BREAK(exp) \
    if(!bool(exp)); else __builtin_trap() //or: signal(SIGTRAP, signal_handler)

#else
#error debug_break is not supported for this platform
#endif


namespace utility
{
    // empty instruction for breakpoint placeholder
    FORCE_INLINE void unused()
    {
    }

    void debug_break(bool condition = true);
    bool is_under_debugger();
}
