#pragma once

#include "utility/platform.hpp"

#ifdef UTILITY_COMPILER_CXX_MSC
#include <intrin.h>
#else
#include <x86intrin.h>  // Not just <immintrin.h> for compilers other than icc
#endif


#if defined(ENABLE_CPP11_UNUSED_SUPPRESSION) && !defined(DISABLE_CPP11_UNUSED_SUPPRESSION)
#define UTILITY_UNUSED(exp) (void)::utility::unused((exp))
#define UTILITY_UNUSED2(e0, e1) (void)::utility::unused((e0), (e1))
#else
// better implementation for time critical segments of code, because of interfering with the compiler optimizer somehow !!!
#ifndef _DEBUG
#define UTILITY_UNUSED(exp) (void)0
#define UTILITY_UNUSED2(e0, e1) (void)0
#else
#define UTILITY_UNUSED(exp) (void)((void)(exp), 0)
#define UTILITY_UNUSED2(e0, e1) (void)((void)(e0), (void)(e1), 0)
#endif
//#define UTILITY_UNUSED(exp) (void)(false ? (void)(exp) : (void)0)
//#define UTILITY_UNUSED2(e0, e1) (void)(false ? (void)(UTILITY_UNUSED(e0), UTILITY_UNUSED(e1)) : (void)0)
#endif

// break point placeholder, useful inside macroses like ASSERT*
#define BREAK_POINT_PLACEHOLDER() ::utility::unused() // `__asm nop` - can't be placed inside expressions, only statements

#ifdef _DEBUG
#define IF_DEBUG(x) x
#else
#define IF_DEBUG(x) UTILITY_UNUSED(x)
#endif

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

    // better parameter suppression in release than (void)
    template<typename T>
    FORCE_INLINE void unused(T &&)
    {
    }

    template<typename T0,typename T1>
    FORCE_INLINE void unused(T0 &&, T1 &&)
    {
    }

    void debug_break(bool condition = true);
    bool is_under_debugger();
}
