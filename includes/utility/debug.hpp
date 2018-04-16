#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_DEBUG_HPP
#define UTILITY_DEBUG_HPP

#include <tacklelib.hpp>

#include <utility/preprocessor.hpp>
#include <utility/platform.hpp>


#ifdef UTILITY_COMPILER_CXX_MSC
#include <intrin.h>
#else
#include <x86intrin.h>  // Not just <immintrin.h> for compilers other than icc
#endif


#define UTILITY_UNUSED(suffix, exp)                 UTILITY_UNUSED_ ## suffix(exp)

#define UTILITY_UNUSED_EXPR(exp)                    (( (void)((exp), nullptr) ))
#define UTILITY_UNUSED_STATEMENT(exp)               do {{ (void)((exp), 0); }} while(false)

#define UTILITY_UNUSED_EXPR2(e0, e1)                (( UTILITY_UNUSED_EXPR(e0), UTILITY_UNUSED_EXPR(e1) ))
#define UTILITY_UNUSED_STATEMENT2(e0, e1)           do {{ UTILITY_UNUSED_STATEMENT(e0); UTILITY_UNUSED_STATEMENT(e1); }} while(false)

#define UTILITY_UNUSED_EXPR3(e0, e1, e2)            (( UTILITY_UNUSED_EXPR2(e0, e1), UTILITY_UNUSED_EXPR(e2) ))
#define UTILITY_UNUSED_STATEMENT3(e0, e1, e2)       do {{ UTILITY_UNUSED_STATEMENT2(e0, e1); UTILITY_UNUSED_STATEMENT(e2); }} while(false)

#define UTILITY_UNUSED_EXPR4(e0, e1, e2, e3)        (( UTILITY_UNUSED_EXPR3(e0, e1, e2), UTILITY_UNUSED_EXPR(e3) ))
#define UTILITY_UNUSED_STATEMENT4(e0, e1, e2, e3)   do {{ UTILITY_UNUSED_STATEMENT3(e0, e1, e2); UTILITY_UNUSED_STATEMENT(e3); }} while(false)

#define UTILITY_UNUSED_EXPR5(e0, e1, e2, e3, e4)    (( UTILITY_UNUSED_EXPR4(e0, e1, e2, e3), UTILITY_UNUSED_EXPR(e4) ))
#define UTILITY_UNUSED_STATEMENT5(e0, e1, e2, e3, e4) do {{ UTILITY_UNUSED_STATEMENT4(e0, e1, e2, e3); UTILITY_UNUSED_STATEMENT(e4); }} while(false)

#define UTILITY_UNUSED_EXPR6(e0, e1, e2, e3, e4, e5) (( UTILITY_UNUSED_EXPR5(e0, e1, e2, e3, e4), UTILITY_UNUSED_EXPR(e5) ))
#define UTILITY_UNUSED_STATEMENT6(e0, e1, e2, e3, e4, e5) do {{ UTILITY_UNUSED_STATEMENT5(e0, e1, e2, e3, e4); UTILITY_UNUSED_STATEMENT(e5); }} while(false)

#define UTILITY_UNUSED_EXPR7(e0, e1, e2, e3, e4, e5, e6) (( UTILITY_UNUSED_EXPR6(e0, e1, e2, e3, e4, e5), UTILITY_UNUSED_EXPR(e6) ))
#define UTILITY_UNUSED_STATEMENT7(e0, e1, e2, e3, e4, e5, e6) do {{ UTILITY_UNUSED_STATEMENT6(e0, e1, e2, e3, e4, e5); UTILITY_UNUSED_STATEMENT(e6); }} while(false)

#define UTILITY_UNUSED_EXPR8(e0, e1, e2, e3, e4, e5, e6, e7) (( UTILITY_UNUSED_EXPR7(e0, e1, e2, e3, e4, e5, e6), UTILITY_UNUSED_EXPR(e7) ))
#define UTILITY_UNUSED_STATEMENT8(e0, e1, e2, e3, e4, e5, e6, e7) do {{ UTILITY_UNUSED_STATEMENT7(e0, e1, e2, e3, e4, e5, e6); UTILITY_UNUSED_STATEMENT(e7); }} while(false)

// break point placeholder, useful inside custom user macroses to emulate function call break points
#define BREAK_POINT_PLACEHOLDER() ::utility::unused() // `__asm nop` - can't be placed inside expressions, only statements

#if defined(UTILITY_PLATFORM_WINDOWS)

#define DEBUG_BREAK(exp) \
    if((exp) ? false : true); else __debugbreak() // won't require debug symbols to show the call stack, when the DebugBreak() will require system debug symbols to show the call stack correctly)

#elif defined(UTILITY_PLATFORM_POSIX)

#define DEBUG_BREAK(exp) \
    if((exp) ? false : true); else __builtin_trap() //or: signal(SIGTRAP, signal_handler)

#else
#error debug_break is not supported for this platform
#endif


namespace utility
{
    // empty instruction for breakpoint placeholder
    FORCE_INLINE_ALWAYS void unused()
    {
    }

    void debug_break(bool condition = true);
    bool is_under_debugger();
}

#endif
