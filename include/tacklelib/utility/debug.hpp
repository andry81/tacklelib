#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_DEBUG_HPP
#define UTILITY_DEBUG_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/preprocessor.hpp>
#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/optimization.hpp>

#if defined(UTILITY_COMPILER_CXX_MSC) || defined(UTILITY_PLATFORM_MINGW)
#include <intrin.h>
#else
#include <x86intrin.h>  // Not just <immintrin.h> for compilers other than icc
#include <signal.h>
#endif


// break point placeholder, useful inside custom user macroses to emulate function call break points
#define BREAK_POINT_PLACEHOLDER()                   ::utility::unused() // `__asm nop` - can't be placed inside expressions, only statements

#if defined(UTILITY_PLATFORM_WINDOWS)

// won't require debug symbols to show the call stack, when the DebugBreak() will require system debug symbols to show the call stack correctly
#define DEBUG_BREAK(exp) \
    ((exp) ? false : true) ? decltype(__debugbreak())() : __debugbreak()

#elif defined(UTILITY_PLATFORM_POSIX)

// CAUTION:
//
// `__builtin_trap()` leads to `vex x86->IR: unhandled instruction bytes: 0xF 0xB 0x83 0xEC` under the valgrind execution!
// See for details: https://stackoverflow.com/questions/6859267/valgrind-unhandled-instruction-bytes-0xf-0xb-0xff-0x85
//
#define DEBUG_BREAK(exp) \
    ((exp) ? false : true) ? decltype(::raise(SIGTRAP))() : ::raise(SIGTRAP) // or: __builtin_trap()

#else
#error debug_break is not supported for this platform
#endif

#define DEBUG_BREAK_IN_DEBUGGER(cond)               DEBUG_BREAK((cond) && ::utility::is_under_debugger())

// CAUTION:
//  Can be in an expression context, so comma is required here and a user must surround the entire expression with the definition by the parentheses.
//
#define DEBUG_BREAK_THROW(cond)                     DEBUG_BREAK_IN_DEBUGGER(cond), throw


namespace utility
{
    // break on true
    void debug_break(bool condition = false);
    bool is_under_debugger();
}

#endif
