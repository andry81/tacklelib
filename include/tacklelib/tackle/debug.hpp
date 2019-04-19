#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_DEBUG_HPP
#define TACKLE_DEBUG_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/preprocessor.hpp>
#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_identity.hpp>
#include <tacklelib/utility/static_constexpr.hpp>
#include <tacklelib/utility/stack_trace.hpp>

#include <tacklelib/tackle/tmpl_string.hpp>
#include <tacklelib/tackle/constexpr_string.hpp>

#include <string>
#include <cwchar>
#include <uchar.h>  // in GCC `cuchar` header might not exist


// CAUTION:
//  TACKLE_TMPL_STRING macro has used to guarantee the same address for the same literal string, otherwise 2 the same literal strings may have different addresses following the C++ standard!
//

#define DEBUG_FUNC_LINE_A                               ::tackle::DebugFuncLineA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC).cstr() + UTILITY_CONSTEXPR_VALUE(truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNC) - (truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0) - 1) }, \
                                                        UTILITY_PP_LINE }
#define DEBUG_FUNC_LINE_MAKE_A()                        ::tackle::DebugFuncLineInlineStackA::make(::tackle::DebugFuncLineA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC).cstr() + UTILITY_CONSTEXPR_VALUE(truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNC) - (truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE })
#define DEBUG_FUNC_LINE_MAKE_PUSH_A(stack)              ::tackle::DebugFuncLineInlineStackA::make_push(stack, ::tackle::DebugFuncLineA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC).cstr() + UTILITY_CONSTEXPR_VALUE(truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNC) - (truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE })


#define DEBUG_FUNCSIG_LINE_A                            ::tackle::DebugFuncLineA{ TACKLE_TMPL_STRING(0, UTILITY_PP_FUNCSIG), UTILITY_PP_LINE }
#define DEBUG_FUNCSIG_LINE_MAKE_A()                     ::tackle::DebugFuncLineInlineStackA::make(::tackle::DebugFuncLineA{ TACKLE_TMPL_STRING(0, UTILITY_PP_FUNCSIG), UTILITY_PP_LINE })
#define DEBUG_FUNCSIG_LINE_MAKE_PUSH_A(stack)           ::tackle::DebugFuncLineInlineStackA::make_push(stack, ::tackle::DebugFuncLineA{ TACKLE_TMPL_STRING(0, UTILITY_PP_FUNCSIG), UTILITY_PP_LINE })


#define DEBUG_FILE_LINE_A_(truncate_file) \
                                                        ::tackle::DebugFileLineA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) - 1 : 0)) } , \
                                                            UTILITY_PP_LINE }
#define DEBUG_FILE_LINE_A                               DEBUG_FILE_LINE_A_(true)

#define DEBUG_FILE_LINE_MAKE_A_(truncate_file) \
                                                        ::tackle::DebugFileLineInlineStackA::make(::tackle::DebugFileLineA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) - 1 : 0)) }, \
                                                            UTILITY_PP_LINE })
#define DEBUG_FILE_LINE_MAKE_A()                        DEBUG_FILE_LINE_MAKE_A_(true)

#define DEBUG_FILE_LINE_MAKE_PUSH_A_(stack, truncate_file) \
                                                        ::tackle::DebugFileLineInlineStackA::make_push(stack, ::tackle::DebugFileLineA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE })
#define DEBUG_FILE_LINE_MAKE_PUSH_A(stack)              DEBUG_FILE_LINE_MAKE_PUSH_A_(stack, true)


#define DEBUG_FILE_LINE_W_(truncate_file) \
                                                        ::tackle::DebugFileLineW{ ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE_WIDE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0) - 1), \
                                                            UTILITY_PP_LINE }
#define DEBUG_FILE_LINE_W                               DEBUG_FILE_LINE_W_(true)

#define DEBUG_FILE_LINE_MAKE_W_(truncate_file) \
                                                        ::tackle::DebugFileLineInlineStackW::make(::tackle::DebugFileLineW{ ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE_WIDE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0) - 1), \
                                                            UTILITY_PP_LINE })
#define DEBUG_FILE_LINE_MAKE_W()                        DEBUG_FILE_LINE_MAKE_W_(true)

#define DEBUG_FILE_LINE_MAKE_PUSH_W_(stack, truncate_file) \
                                                        ::tackle::DebugFileLineInlineStackW::make_push(stack, ::tackle::DebugFileLineW{ ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE_WIDE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0) - 1), \
                                                            UTILITY_PP_LINE })
#define DEBUG_FILE_LINE_MAKE_PUSH_W(stack)              DEBUG_FILE_LINE_MAKE_PUSH_W_(stack, true)


#define DEBUG_FILE_LINE_FUNC_A_(truncate_file, truncate_func) \
                                                        ::tackle::DebugFileLineFuncA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNC) - (truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0) - 1) } }
#define DEBUG_FILE_LINE_FUNC_A                          DEBUG_FILE_LINE_FUNC_A_(true, true)

#define DEBUG_FILE_LINE_FUNC_MAKE_A_(truncate_file, truncate_func) \
                                                        ::tackle::DebugFileLineFuncInlineStackA::make(::tackle::DebugFileLineFuncA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNC) - (truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0) - 1) } })
#define DEBUG_FILE_LINE_FUNC_MAKE_A()                   DEBUG_FILE_LINE_FUNC_MAKE_A_(true, true)

#define DEBUG_FILE_LINE_FUNC_MAKE_PUSH_A_(stack, truncate_file, truncate_func) \
                                                        ::tackle::DebugFileLineFuncInlineStackA::make_push(stack, ::tackle::DebugFileLineFuncA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNC) - (truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0) - 1) } })
#define DEBUG_FILE_LINE_FUNC_MAKE_PUSH_A(stack)         DEBUG_FILE_LINE_FUNC_MAKE_PUSH_A_(stack, true, true)


#define DEBUG_FILE_LINE_FUNC_W_(truncate_file, truncate_func) \
                                                        ::tackle::DebugFileLineFuncW{ ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE_WIDE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNC) - (truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0) - 1) } }
#define DEBUG_FILE_LINE_FUNC_W                          DEBUG_FILE_LINE_FUNC_W_(true, true)

#define DEBUG_FILE_LINE_FUNC_MAKE_W_(truncate_file, truncate_func) \
                                                        ::tackle::DebugFileLineFuncInlineStackW::make(::tackle::DebugFileLineFuncW{ ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE_WIDE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNC) - (truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0) - 1) } })
#define DEBUG_FILE_LINE_FUNC_MAKE_W()                   DEBUG_FILE_LINE_FUNC_MAKE_W_(true, true)

#define DEBUG_FILE_LINE_FUNC_MAKE_PUSH_W_(stack, truncate_file, truncate_func) \
                                                        ::tackle::DebugFileLineFuncInlineStackW::make_push(stack, ::tackle::DebugFileLineFuncW{ ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE_WIDE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNC) - (truncate_func ? ::utility::get_unmangled_src_func_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FUNC)) : 0) - 1) } })
#define DEBUG_FILE_LINE_FUNC_MAKE_PUSH_W(stack)         DEBUG_FILE_LINE_FUNC_MAKE_PUSH_W_(stack, true, true)


#define DEBUG_FILE_LINE_FUNCSIG_A_(truncate_file) \
                                                        ::tackle::DebugFileLineFuncA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNCSIG).c_str(), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNCSIG) - 1) } }
#define DEBUG_FILE_LINE_FUNCSIG_A                       DEBUG_FILE_LINE_FUNCSIG_A_(true)

#define DEBUG_FILE_LINE_FUNCSIG_MAKE_A_(truncate_file) \
                                                        ::tackle::DebugFileLineFuncInlineStackA::make(::tackle::DebugFileLineFuncA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNCSIG).c_str(), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNCSIG) - 1) } })
#define DEBUG_FILE_LINE_FUNCSIG_MAKE_A()                DEBUG_FILE_LINE_FUNCSIG_MAKE_A_(true)

#define DEBUG_FILE_LINE_FUNCSIG_MAKE_PUSH_A_(stack, truncate_file) \
                                                        ::tackle::DebugFileLineFuncInlineStackA::make_push(stack, ::tackle::DebugFileLineFuncA{ ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_string{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNCSIG).c_str(), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNCSIG) - 1) } })
#define DEBUG_FILE_LINE_FUNCSIG_MAKE_PUSH_A(stack)      DEBUG_FILE_LINE_FUNCSIG_MAKE_PUSH_A_(stack, true)


#define DEBUG_FILE_LINE_FUNCSIG_W_(truncate_file) \
                                                        ::tackle::DebugFileLineFuncW{ ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE_WIDE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNCSIG).c_str(), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNCSIG) - 1) } }
#define DEBUG_FILE_LINE_FUNCSIG_W                       DEBUG_FILE_LINE_FUNCSIG_W_(true)

#define DEBUG_FILE_LINE_FUNCSIG_MAKE_W_(truncate_file) \
                                                        ::tackle::DebugFileLineFuncInlineStackW::make(::tackle::DebugFileLineFuncW{ ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE_WIDE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNCSIG).c_str(), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNCSIG) - 1) } })
#define DEBUG_FILE_LINE_FUNCSIG_MAKE_W()                DEBUG_FILE_LINE_FUNCSIG_MAKE_W_(true)

#define DEBUG_FILE_LINE_FUNCSIG_MAKE_PUSH_W_(stack, truncate_file) \
                                                        ::tackle::DebugFileLineFuncInlineStackW::make_push(stack, ::tackle::DebugFileLineFuncW{ ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE).c_str() + UTILITY_CONSTEXPR_VALUE(truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FILE_WIDE) - (truncate_file ? ::utility::get_file_name_constexpr_offset(TACKLE_TMPL_STRING(0, UTILITY_PP_FILE_WIDE)) : 0) - 1) }, \
                                                            UTILITY_PP_LINE, \
                                                        ::tackle::constexpr_wstring{ \
                                                            TACKLE_TMPL_STRING(0, UTILITY_PP_FUNCSIG).c_str(), \
                                                            UTILITY_CONSTEXPR_VALUE(UTILITY_CONSTEXPR_ARRAY_SIZE(UTILITY_PP_FUNCSIG) - 1) } })
#define DEBUG_FILE_LINE_FUNCSIG_MAKE_PUSH_W(stack)      DEBUG_FILE_LINE_FUNCSIG_MAKE_PUSH_W_(stack, true)


namespace tackle
{
    // implementation through tmpl_string, multiple parameter packs through the specialization
    template <typename>
    struct TDebugFileLine;

    template <typename CharT, CharT... tchars>
    struct TDebugFileLine<utility::value_identities<CharT, tchars...> >
    {
        using file_type = tmpl_basic_string<0, CharT, tchars...>;

        file_type   file;
        int         line;
    };

    // implementation through raw c string with length
    template <typename CharT>
    struct DebugFilePathLine
    {
        FORCE_INLINE CONSTEXPR_FUNC DebugFilePathLine(const constexpr_basic_string<CharT> & file_, int line_) :
            file(file_), line(line_)
        {
        }

        constexpr_basic_string<CharT>   file;
        int                             line;
    };

    // implementation through raw c string with length
    template <typename CharT>
    struct DebugFileLine
    {
        FORCE_INLINE CONSTEXPR_FUNC DebugFileLine(const constexpr_basic_string<CharT> & file_, int line_) :
            file(file_), line(line_)
        {
        }

        constexpr_basic_string<CharT>   file;
        int                             line;
    };

    // implementation through tmpl_string, multiple parameter packs through the specialization
    template <typename>
    struct TDebugFuncLineA;

    template <char... chars>
    struct TDebugFuncLineA<utility::value_identities<char, chars...> >
    {
        using func_type = tmpl_string<0, chars...>;

        func_type   func;
        int         line;
    };

    // implementation through raw c string with length
    struct DebugFuncLineA
    {
        FORCE_INLINE CONSTEXPR_FUNC DebugFuncLineA(const constexpr_string & func_, int line_) :
            func(func_), line(line_)
        {
        }

        constexpr_string    func;
        int                 line;
    };

    // implementation through tmpl_string, single parameter pack
    template <char... chars>
    using TDebugFileLineA = TDebugFileLine<utility::value_identities<char, chars...> >;

    template <wchar_t... wchars>
    using TDebugFileLineW = TDebugFileLine<utility::value_identities<wchar_t, wchars...> >;

    // implementation through raw c string with length
    using DebugFilePathLineA    = DebugFilePathLine<char>;
    using DebugFilePathLineW    = DebugFilePathLine<wchar_t>;

    using DebugFileLineA        = DebugFileLine<char>;
    using DebugFileLineW        = DebugFileLine<wchar_t>;

    // implementation through tmpl_string, multiple parameter packs through the specialization
    template <typename, typename>
    struct TDebugFileLineFunc;

    template <typename CharT, CharT... file_tchars, char... func_chars>
    struct TDebugFileLineFunc<
        utility::value_identities<CharT, file_tchars...>,
        utility::value_identities<char, func_chars...>
    >
    {
        using file_type = tmpl_basic_string<0, CharT, file_tchars...>;
        using func_type = tmpl_string<0, func_chars...>;

        file_type   file;
        int         line;
        func_type   func;
    };

    // implementation through raw c string with offset and length
    template <typename CharT>
    struct DebugFilePathLineFunc
    {
        FORCE_INLINE CONSTEXPR_FUNC DebugFilePathLineFunc(const constexpr_basic_string<CharT> & file_, int line_, const constexpr_string & func_) :
            file(file_), line(line_), func(func_)
        {
        }

        constexpr_basic_string<CharT>   file;
        int                             line;
        constexpr_string                func;
    };

    template <typename CharT>
    struct DebugFileLineFunc
    {
        FORCE_INLINE CONSTEXPR_FUNC DebugFileLineFunc(const constexpr_basic_string<CharT> & file_, int line_, const constexpr_string & func_) :
            file(file_), line(line_), func(func_)
        {
        }

        constexpr_basic_string<CharT>   file;
        int                             line;
        constexpr_string                func;
    };

    // implementation through tmpl_string, multiple parameter packs through the specialization
    template <typename, typename>
    struct TDebugFileLineFuncA;

    template <char... file_chars, char... func_chars>
    struct TDebugFileLineFuncA<
        utility::value_identities<char, file_chars...>,
        utility::value_identities<char, func_chars...>
    >
    {
        using type = TDebugFileLineFunc<
            utility::value_identities<char, file_chars...>,
            utility::value_identities<char, func_chars...>
        >;
    };

    // implementation through tmpl_string, multiple parameter packs through the specialization
    template <typename, typename>
    struct TDebugFileLineFuncW;

    template <wchar_t... file_wchars, char... func_chars>
    struct TDebugFileLineFuncW<
        utility::value_identities<wchar_t, file_wchars...>,
        utility::value_identities<char, func_chars...>
    >
    {
        using type = TDebugFileLineFunc<
            utility::value_identities<wchar_t, file_wchars...>,
            utility::value_identities<char, func_chars...>
        >;
    };

    // implementation through raw c string with length
    using DebugFilePathLineFuncA        = DebugFilePathLineFunc<char>;
    using DebugFilePathLineFuncW        = DebugFilePathLineFunc<wchar_t>;

    using DebugFileLineFuncA            = DebugFileLineFunc<char>;
    using DebugFileLineFuncW            = DebugFileLineFunc<wchar_t>;

    template <char... chars>
    using TDebugFileLineInlineStackA    = inline_stack<TDebugFileLineA<chars...> >;

    template <wchar_t... wchars>
    using TDebugFileLineInlineStackW    = inline_stack<TDebugFileLineW<wchars...> >;

    template <char... chars>
    using TDebugFuncLineInlineStackA    = inline_stack<TDebugFuncLineA<utility::value_identities<char, chars...> > >;

    // implementation through tmpl_string, multiple parameter packs through the specialization
    template <typename, typename>
    struct TDebugFileLineFuncInlineStackA;

    template <char... file_chars, char... func_chars>
    struct TDebugFileLineFuncInlineStackA<
        utility::value_identities<char, file_chars...>,
        utility::value_identities<char, func_chars...>
    >
    {
        using type = inline_stack<TDebugFileLineFuncA<
            utility::value_identities<char, file_chars...>,
            utility::value_identities<char, func_chars...>
        > >;
    };

    // implementation through tmpl_string, multiple parameter packs through the specialization
    template <typename, typename>
    struct TDebugFileLineFuncInlineStackW;

    template <wchar_t... file_wchars, char... func_chars>
    struct TDebugFileLineFuncInlineStackW<
        utility::value_identities<wchar_t, file_wchars...>,
        utility::value_identities<char, func_chars...>
    >
    {
        using type = inline_stack<TDebugFileLineFuncW<
            utility::value_identities<wchar_t, file_wchars...>,
            utility::value_identities<char, func_chars...>
        > >;
    };

    // implementation through raw c string with length
    using DebugFilePathLineInlineStackA     = inline_stack<DebugFilePathLineA>;
    using DebugFilePathLineInlineStackW     = inline_stack<DebugFilePathLineW>;

    using DebugFileLineInlineStackA         = inline_stack<DebugFileLineA>;
    using DebugFileLineInlineStackW         = inline_stack<DebugFileLineW>;

    using DebugFuncLineInlineStackA         = inline_stack<DebugFuncLineA>;

    using DebugFilePathLineFuncInlineStackA = inline_stack<DebugFilePathLineFuncA>;
    using DebugFilePathLineFuncInlineStackW = inline_stack<DebugFilePathLineFuncW>;

    using DebugFileLineFuncInlineStackA     = inline_stack<DebugFileLineFuncA>;
    using DebugFileLineFuncInlineStackW     = inline_stack<DebugFileLineFuncW>;
}

#endif
