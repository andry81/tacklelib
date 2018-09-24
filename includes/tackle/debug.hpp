#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_DEBUG_HPP
#define TACKLE_DEBUG_HPP

#include <tacklelib.hpp>

#include <utility/preprocessor.hpp>
#include <utility/platform.hpp>


#define DEBUG_FUNC_LINE_A                       ::tackle::DebugFuncLineA{ UTILITY_PP_FUNC, UTILITY_PP_LINE }
#define DEBUG_FUNC_LINE_MAKE_A()                ::tackle::DebugFuncLineInlineStackA::make(::tackle::DebugFuncLineA{ UTILITY_PP_FUNC, UTILITY_PP_LINE })
#define DEBUG_FUNC_LINE_MAKE_PUSH_A(stack)      ::tackle::DebugFuncLineInlineStackA::make_push(stack, ::tackle::DebugFuncLineA{ UTILITY_PP_FUNC, UTILITY_PP_LINE })

#define DEBUG_FUNCSIG_LINE_A                    ::tackle::DebugFuncLineA{ UTILITY_PP_FUNCSIG, UTILITY_PP_LINE }
#define DEBUG_FUNCSIG_LINE_MAKE_A()             ::tackle::DebugFuncLineInlineStackA::make(::tackle::DebugFuncLineA{ UTILITY_PP_FUNCSIG, UTILITY_PP_LINE })
#define DEBUG_FUNCSIG_LINE_MAKE_PUSH_A(stack)   ::tackle::DebugFuncLineInlineStackA::make_push(stack, ::tackle::DebugFuncLineA{ UTILITY_PP_FUNCSIG, UTILITY_PP_LINE })

#define DEBUG_FUNC_LINE_W                       ::tackle::DebugFuncLineW{ UTILITY_PP_FUNC, UTILITY_PP_LINE }
#define DEBUG_FUNC_LINE_MAKE_W()                ::tackle::DebugFuncLineInlineStackW::make(::tackle::DebugFuncLineW{ UTILITY_PP_FUNC, UTILITY_PP_LINE })
#define DEBUG_FUNC_LINE_MAKE_PUSH_W(stack)      ::tackle::DebugFuncLineInlineStackW::make_push(stack, ::tackle::DebugFuncLineW{ UTILITY_PP_FUNC, UTILITY_PP_LINE })

#define DEBUG_FUNCSIG_LINE_W                    ::tackle::DebugFuncLineW{ UTILITY_PP_FUNCSIG, UTILITY_PP_LINE }
#define DEBUG_FUNCSIG_LINE_MAKE_W()             ::tackle::DebugFuncLineInlineStackW::make(::tackle::DebugFuncLineW{ UTILITY_PP_FUNCSIG, UTILITY_PP_LINE })
#define DEBUG_FUNCSIG_LINE_MAKE_PUSH_W(stack)   ::tackle::DebugFuncLineInlineStackW::make_push(stack, ::tackle::DebugFuncLineW{ UTILITY_PP_FUNCSIG, UTILITY_PP_LINE })


namespace tackle
{
    struct DebugFuncLineA
    {
        std::string     func;
        int             line;
    };

    struct DebugFuncLineW
    {
        std::wstring    func;
        int             line;
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

    using DebugFuncLineInlineStackA = inline_stack<DebugFuncLineA>;
}

#endif
