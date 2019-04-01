#pragma once

#include <src/tacklelib_private.hpp>

#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_LOG_P7_LOGGER)

#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_identity.hpp>
#include <tacklelib/utility/string_identity.hpp>
#include <tacklelib/utility/debug.hpp>
#include <tacklelib/utility/assert.hpp>
#include <tacklelib/utility/locale.hpp>
#include <tacklelib/utility/string.hpp>
#include <tacklelib/utility/stack_trace.hpp>
#include <tacklelib/utility/utility.hpp>

#include <tacklelib/tackle/debug.hpp>
#include <tacklelib/tackle/string.hpp>
#include <tacklelib/tackle/smart_handle.hpp>
#include <tacklelib/tackle/log/log_handle.hpp>

#include <fmt/format.h>

#include <P7_Trace.h>
#include <P7_Telemetry.h>

#include <vector>
#include <string>
#include <cstdio>
#include <cstdint>
#include <stdexcept>
#include <sstream>
#include <istream>
#include <ios>
#include <utility>
#include <type_traits>


// Some review and tests versus other loggers on russian website (RU):
//   https://habr.com/post/313686/
//

// CAUTION:
//  From the library documentation:
//  N.B.: DO NOT USE VARIABLES for format string, file name, function name! You should always use
//  CONSTANT TEXT like "My Format %d, %s", ”myfile.cpp”, “myfunction”
//

#if defined(UTILITY_PLATFORM_WINDOWS)
#elif defined(UTILITY_PLATFORM_LINUX)
#else
#error platform is not implemented
#endif

#define LOG_P7_APP_INIT() \
    {{ P7_Set_Crash_Handler(); }} (void)0

#define LOG_P7_APP_UNINIT() \
    {{ ; }} (void)0

#define LOG_P7_CREATE_CLIENT(cmd_line, ...) \
    ::utility::log::p7logger::p7_create_client(cmd_line, ## __VA_ARGS__)

#define LOG_P7_CREATE_TRACE(client, channel_name, ...) \
    client.create_trace(channel_name, ## __VA_ARGS__)

#define LOG_P7_CREATE_TELEMETRY(client, channel_name, ...) \
    client.create_telemetry(channel_name, ## __VA_ARGS__)

#define LOG_P7_CREATE_TELEMETRY_PARAM(telemetry, param_catalog_name, min_value, alarm_min, max_value, alarm_max, is_enabled, ...) \
    telemetry.create_param(param_catalog_name, min_value, alarm_min, max_value, alarm_max, is_enabled, ## __VA_ARGS__)


// log immediate (constexpr) flags
#define LOG_P7_FLAG_TRUNCATE_FILE_TO_NAME                   ::utility::log::p7logger::LogFlag_TruncateSrcFileToFileName
#define LOG_P7_FLAG_TRUNCATE_FUNC_TO_NAME                   ::utility::log::p7logger::LogFlag_TruncateSrcFuncToName
#define LOG_P7_FLAG_TRUNCATE_FILE_TO_REL_PATH               ::utility::log::p7logger::LogFlag_TruncateSrcFileToRelativePath
#define LOG_P7_FLAG_ALLOW_NOT_STATIC_FMT                    ::utility::log::p7logger::LogFlag_AllowToUseNotStaticFmt
#define LOG_P7_FLAG_USE_STD_FMT_FORMAT                      ::utility::log::p7logger::LogFlag_UseStdFmtCompatibleFmt        // not yet a c++ standard, but will be: http://fmtlib.net/Text%20Formatting.html
#define LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT               ::utility::log::p7logger::LogFlag_UseStdPrintfCompatibleFmt
#define LOG_P7_FLAG_DEFAULT                                 ::utility::log::p7logger::LogFlag_Default

#define LOG_P7_DEFAULT_MODULE                               ::utility::log::p7logger::p7TraceModule{}


// impl macroses

#define LOG_P7_(func_name, constexpr_flags, trace_handle, trace_module, id, lvl, fmt, ...) \
    (trace_handle.func_name<constexpr_flags>(trace_module, id, lvl, \
        DEBUG_FILE_LINE_FUNC_MAKE_A_( \
            UTILITY_CONSTEXPR(constexpr_flags & LOG_P7_FLAG_TRUNCATE_FILE_TO_NAME), \
            UTILITY_CONSTEXPR(constexpr_flags & LOG_P7_FLAG_TRUNCATE_FUNC_TO_NAME)) \
        fmt, ## __VA_ARGS__))

// full set of arguments

#define LOG_P7(constexpr_flags, trace_handle, trace_module, id, lvl, fmt, ...) \
    LOG_P7_(log, constexpr_flags, trace_handle, trace_module, id, lvl, fmt, ## __VA_ARGS__)

#define LOG_P7_TRACE(constexpr_flags, trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_TRACE, fmt, ## __VA_ARGS__)

#define LOG_P7_DEBUG(constexpr_flags, trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_DEBUG, fmt, ## __VA_ARGS__)

#define LOG_P7_INFO(constexpr_flags, trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_INFO, fmt, ## __VA_ARGS__)

#define LOG_P7_WARNING(constexpr_flags, trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_WARNING, fmt, ## __VA_ARGS__)

#define LOG_P7_ERROR(constexpr_flags, trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_ERROR, fmt, ## __VA_ARGS__)

#define LOG_P7_CRITICAL(constexpr_flags, trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_CRITICAL, fmt, ## __VA_ARGS__)

// reduced version to std fmt compatible fmt argument

#define LOG_P7_STDFMT(trace_handle, trace_module, id, lvl, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, lvl, fmt, ## __VA_ARGS__)

#define LOG_P7_STDFMT_TRACE(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_TRACE, fmt, ## __VA_ARGS__)

#define LOG_P7_STDFMT_DEBUG(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_DEBUG, fmt, ## __VA_ARGS__)

#define LOG_P7_STDFMT_INFO(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_INFO, fmt, ## __VA_ARGS__)

#define LOG_P7_STDFMT_WARNING(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_WARNING, fmt, ## __VA_ARGS__)

#define LOG_P7_STDFMT_ERROR(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_ERROR, fmt, ## __VA_ARGS__)

#define LOG_P7_STDFMT_CRITICAL(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_CRITICAL, fmt, ## __VA_ARGS__)

// reduced version to std printf compatible fmt argument

#define LOG_P7_CFMT(trace_handle, trace_module, id, lvl, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, lvl, fmt, ## __VA_ARGS__)

#define LOG_P7_CFMT_TRACE(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_TRACE, fmt, ## __VA_ARGS__)

#define LOG_P7_CFMT_DEBUG(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_DEBUG, fmt, ## __VA_ARGS__)

#define LOG_P7_CFMT_INFO(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_INFO, fmt, ## __VA_ARGS__)

#define LOG_P7_CFMT_WARNING(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_WARNING, fmt, ## __VA_ARGS__)

#define LOG_P7_CFMT_ERROR(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_ERROR, fmt, ## __VA_ARGS__)

#define LOG_P7_CFMT_CRITICAL(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_CRITICAL, fmt, ## __VA_ARGS__)

// multiline version for full set of arguments

#define LOG_P7M(constexpr_flags, trace_handle, trace_module, id, lvl, fmt, ...) \
    LOG_P7_(log_multiline, constexpr_flags, trace_handle, trace_module, id, lvl, fmt, ## __VA_ARGS__)

#define LOG_P7M_TRACE(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_TRACE, fmt, ## __VA_ARGS__)

#define LOG_P7M_DEBUG(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_DEBUG, fmt, ## __VA_ARGS__)

#define LOG_P7M_INFO(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_INFO, fmt, ## __VA_ARGS__)

#define LOG_P7M_WARNING(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_WARNING, fmt, ## __VA_ARGS__)

#define LOG_P7M_ERROR(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_ERROR, fmt, ## __VA_ARGS__)

#define LOG_P7M_CRITICAL(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, constexpr_flags, trace_handle, trace_module, id, EP7TRACE_LEVEL_CRITICAL, fmt, ## __VA_ARGS__)

// mutiline version reduced to std fmt compatible fmt argument

#define LOG_P7M_STDFMT(trace_handle, trace_module, id, lvl, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, lvl, fmt, ## __VA_ARGS__)

#define LOG_P7M_STDFMT_TRACE(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_TRACE, fmt, ## __VA_ARGS__)

#define LOG_P7M_STDFMT_DEBUG(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_DEBUG, fmt, ## __VA_ARGS__)

#define LOG_P7M_STDFMT_INFO(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_INFO, fmt, ## __VA_ARGS__)

#define LOG_P7M_STDFMT_WARNING(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_WARNING, fmt, ## __VA_ARGS__)

#define LOG_P7M_STDFMT_ERROR(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_ERROR, fmt, ## __VA_ARGS__)

#define LOG_P7M_STDFMT_CRITICAL(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_CRITICAL, fmt, ## __VA_ARGS__)

// mutiline version reduced to std printf compatible fmt argument

#define LOG_P7M_CFMT(trace_handle, trace_module, id, lvl, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, lvl, fmt, ## __VA_ARGS__)

#define LOG_P7M_CFMT_TRACE(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_TRACE, fmt, ## __VA_ARGS__)

#define LOG_P7M_CFMT_DEBUG(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_DEBUG, fmt, ## __VA_ARGS__)

#define LOG_P7M_CFMT_INFO(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_INFO, fmt, ## __VA_ARGS__)

#define LOG_P7M_CFMT_WARNING(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_WARNING, fmt, ## __VA_ARGS__)

#define LOG_P7M_CFMT_ERROR(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_ERROR, fmt, ## __VA_ARGS__)

#define LOG_P7M_CFMT_CRITICAL(trace_handle, trace_module, id, fmt, ...) \
    LOG_P7_(log_multiline, LOG_P7_FLAG_DEFAULT | LOG_P7_FLAG_USE_STD_PRINTF_FMT_FORMAT, trace_handle, trace_module, id, EP7TRACE_LEVEL_CRITICAL, fmt, ## __VA_ARGS__)


// workaround for the bug in v4.7 around __FILE__/__LINE__ caching
#define LOG_P7_TRACE_DESC_HARDCODED_COUNT       1024                            // internal P7_TRACE_DESC_HARDCODED_COUNT definition
#define LOG_P7_BASE_ID                          LOG_P7_TRACE_DESC_HARDCODED_COUNT

#define LOG_P7_STRING_FORMAT_BUFFER_RESERVE     1024 // minimal reserve for a string output buffer in case of usage the utility::string_format funtion


//#define FMT_P7_FORMAT(fmt_str, ...)             ::fmt::p7format(TM(fmt_str), ## __VA_ARGS__)
//
//
//// extension of fmt for p7 logger
//namespace fmt {
//
//#if defined(UTILITY_PLATFORM_WINDOWS)
//    template <size_t S, typename... Args>
//    inline std::basic_string<wchar_t> p7format(const wchar_t (& fmt)[S], Args &&... args)
//    {
//        return format(fmt, std::forward<Args>(args)...);
//    }
//#elif defined(UTILITY_PLATFORM_LINUX)
//    template <size_t S, typename... Args>
//    inline std::basic_string<char> p7format(const char (& fmt)[S], Args &&... args)
//    {
//        return format(fmt, std::forward<Args>(args)...);
//    }
//#endif
//
//}


namespace tackle {

    template <class t_elem, class t_traits = std::char_traits<t_elem>, class t_alloc = std::allocator<t_elem> >
    using p7_basic_string   = std::basic_string<t_elem, t_traits, t_alloc>;

    using p7_char           = tXCHAR;

    // p7 style standard string type
    using p7_string         = p7_basic_string<p7_char, std::char_traits<p7_char>, std::allocator<p7_char> >;

}


namespace utility {
namespace log {
namespace p7logger {

    class p7ClientHandle;
    class p7TraceModule;
    class p7TraceHandle;
    class p7TelemetryHandle;
    class p7TelemetryParamHandle;

    enum LogFlags : uint32_t
    {
        LogFlag_None                                = 0,

        // Will truncate source file argument at compile time to a file name (address shifts statically on a compile time calculated offset).
        // Overrides the LogFlag_TruncateSrcFileToRelativePath flag (fastest truncation).
        // Example: "c:/src/mydir/myfile.cpp" -> "myfile.cpp"
        //
        LogFlag_TruncateSrcFileToFileName           = 0x00000001,

        // Will truncate source function argument at compile time to a function name (address shifts statically on a compile time calculated offset).
        // Example: "myns::`anonymous-namespace'::myfoo" -> "myfoo"
        //
        LogFlag_TruncateSrcFuncToName               = 0x00000002,

        // Will truncate source file argument at runtime to a relative path that relative either to the LOG_SRC_ROOT if defined, or
        // to the module directory path if on the same storage drive letter (in Windows), otherwise will left it as is (slowest truncation).
        //
        LogFlag_TruncateSrcFileToRelativePath       = 0x00000010,

        // Allow to make a client side runtime conversion if required to make all necessary transformations to the platform representation (p7 format).
        //
        LogFlag_AllowRuntimeClientSideConversion    = 0x80000000,

        // Allow to use not static storage `fmt` argument to evaluate it on a client side to replace it by a static storage string as required by the p7 format.
        //
        LogFlag_AllowToUseNotStaticFmt              = 0x40000000, // must be used together with LogFlag_UseStdPrintfCompatibleFmt and with LogFlag_AllowRuntimeClientSideConversion

        // Will treat the `fmt` argument as compatible with the `fmt::format`/`fmt::print` function format string.
        // This will require to convert this type of format string into the p7 format string (which has non C++ standard conformant printf string format!),
        // which automatically requires to reformat on a client side.
        //
        LogFlag_UseStdFmtCompatibleFmt              = 0x01000000, // must be used together with LogFlag_AllowRuntimeClientSideConversion

        // Will treat the `fmt` argument as compatible with the `std::printf`/`std::wprintf` function format string.
        // This will require to convert this type of format string into the p7 format string (which has non C++ standard conformant printf string format!),
        // which automatically requires to reformat on a client side.
        //
        LogFlag_UseStdPrintfCompatibleFmt           = 0x00100000, // must be used together with LogFlag_AllowRuntimeClientSideConversion

        LogFlag_Default                             = LogFlag_TruncateSrcFileToFileName | LogFlag_TruncateSrcFuncToName
    };

namespace detail {

    // struct instead a function to avoid code generation in disabled optimization compiler context
    template <uint32_t log_flags, typename CharT, bool is_static_storage_fmt, bool is_multiline_log>
    struct _validate_log_flags;

    template <uint32_t log_flags, typename CharT, bool is_static_storage_fmt, bool is_multiline_log>
    struct _validate_basic_log_flags
    {
        static_assert(is_static_storage_fmt || (log_flags & LogFlag_AllowToUseNotStaticFmt),
            "If the fmt may be not a static storage string, then the fmt has to be explicitly allowed to be not a static storage string");

        static_assert(
            !((log_flags & LogFlag_UseStdFmtCompatibleFmt) && (log_flags & LogFlag_UseStdPrintfCompatibleFmt)),
            "Only one of 2 supported formats is available at a time");

        static_assert(
            !(log_flags & LogFlag_UseStdFmtCompatibleFmt) || (log_flags & LogFlag_AllowRuntimeClientSideConversion),
            "Current implementation is required the LogFlag_UseStdFmtCompatibleFmt flag to be set together with the LogFlag_AllowRuntimeClientSideConversion flag");

        static_assert(
            !(log_flags & LogFlag_UseStdPrintfCompatibleFmt) || (log_flags & LogFlag_AllowRuntimeClientSideConversion),
            "Current implementation is required the LogFlag_UseStdPrintfCompatibleFmt flag to be set together with the LogFlag_AllowRuntimeClientSideConversion flag");

        static_assert(!is_multiline_log || (log_flags & LogFlag_UseStdFmtCompatibleFmt) || (log_flags & LogFlag_UseStdPrintfCompatibleFmt),
            "Currently multiline log implementation available only through the client side evaluation through one of 2 supported format strings");

        // duplication for a standalone check for particularly multiline log
        static_assert(!is_multiline_log || (log_flags & LogFlag_AllowRuntimeClientSideConversion),
            "Currently multiline log implementation has to be used together with the LogFlag_AllowRuntimeClientSideConversion flag");
    };

    template <uint32_t log_flags, bool is_multiline_log>
    struct _validate_log_flags<log_flags, char, true, is_multiline_log> : _validate_basic_log_flags<log_flags, char, true, is_multiline_log>
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        // char is not supported by the platform, has to be converted or evaluated inplace
        static_assert((log_flags & LogFlag_UseStdFmtCompatibleFmt) || (log_flags & LogFlag_UseStdPrintfCompatibleFmt),
            "Currently implementation has no support for evaluation from the p7 format over guaranteed a static storage string (tmpl_basic_string), fmt has to be compatible with one of 2 supported format strings to be evaluatable");
#endif
    };

    template <uint32_t log_flags, bool is_multiline_log>
    struct _validate_log_flags<log_flags, char, false, is_multiline_log> : _validate_basic_log_flags<log_flags, char, false, is_multiline_log>
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        // char is not supported by the platform, has to be converted or evaluated inplace
        static_assert((log_flags & LogFlag_UseStdFmtCompatibleFmt) || (log_flags & LogFlag_UseStdPrintfCompatibleFmt),
            "Currently implementation has no support for evaluation from the p7 format over may be not a static storage string (constexpr_basic_string), fmt has to be compatible with one of 2 supported format strings to be evaluatable");
#endif
    };

    template <uint32_t log_flags, bool is_multiline_log>
    struct _validate_log_flags<log_flags, wchar_t, true, is_multiline_log> : _validate_basic_log_flags<log_flags, wchar_t, true, is_multiline_log>
    {
#if !defined(UTILITY_PLATFORM_WINDOWS)
        // wchar_t is not supported by the platform, has to be converted or evaluated inplace
        static_assert((log_flags & LogFlag_UseStdFmtCompatibleFmt) || (log_flags & LogFlag_UseStdPrintfCompatibleFmt),
            "Currently implementation has no support for evaluation from the p7 format over guaranteed a static storage string (tmpl_basic_string), fmt has to be compatible with one of 2 supported format strings to be evaluatable");
#endif
    };

    template <uint32_t log_flags, bool is_multiline_log>
    struct _validate_log_flags<log_flags, wchar_t, false, is_multiline_log> : _validate_basic_log_flags<log_flags, wchar_t, false, is_multiline_log>
    {
#if !defined(UTILITY_PLATFORM_WINDOWS)
        // wchar_t is not supported by the platform, has to be converted or evaluated inplace
        static_assert((log_flags & LogFlag_UseStdFmtCompatibleFmt) || (log_flags & LogFlag_UseStdPrintfCompatibleFmt),
            "Currently implementation has no support for evaluation from the p7 format over may be not a static storage string (constexpr_basic_string), fmt has to be compatible with one of 2 supported format strings to be evaluatable");
#endif
    };

    template <typename T>
    FORCE_INLINE p7ClientHandle _p7_create_client(T && cmd_line, utility::tag_string);
    template <typename T>
    FORCE_INLINE p7ClientHandle _p7_create_client(T && cmd_line, utility::tag_wstring);

}

    //// p7ClientHandle

    class p7ClientHandle : protected tackle::SmartHandle<IP7_Client>
    {
        template <typename T>
        friend p7ClientHandle detail::_p7_create_client(T && cmd_line, utility::tag_string);
        template <typename T>
        friend p7ClientHandle detail::_p7_create_client(T && cmd_line, utility::tag_wstring);

        using base_type = SmartHandle;

    public:
        static FORCE_INLINE const p7ClientHandle & null()
        {
            static const p7ClientHandle s_null = p7ClientHandle{ nullptr };
            return s_null;
        }

    protected:
        static FORCE_INLINE void _deleter(void * p)
        {
            if (p) {
                static_cast<IP7_Client *>(p)->Release();
            }
        }

    public:
        FORCE_INLINE p7ClientHandle()
        {
            *this = null();
        }

        FORCE_INLINE p7ClientHandle(const p7ClientHandle &) = default;
        FORCE_INLINE p7ClientHandle(p7ClientHandle &&) = default;

        FORCE_INLINE p7ClientHandle & operator =(const p7ClientHandle &) = default;
        FORCE_INLINE p7ClientHandle & operator =(p7ClientHandle &&) = default;

    protected:
        FORCE_INLINE p7ClientHandle(IP7_Client * p) :
            base_type(p, _deleter)
        {
        }

    public:
        FORCE_INLINE void reset(p7ClientHandle handle = p7ClientHandle::null())
        {
            auto && handle_rref = std::move(handle);

            auto * deleter = DEBUG_VERIFY_TRUE(std::get_deleter<base_type::DeleterType>(handle_rref.m_pv));
            if (!deleter) {
                // must always have a deleter
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): deleter is not allocated",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            base_type::reset(handle_rref.get(), *deleter);
        }

        FORCE_INLINE IP7_Client * handle() const
        {
            return base_type::get();
        }

        FORCE_INLINE IP7_Client * operator ->() const
        {

            IP7_Client * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            return p;
        }

        FORCE_INLINE IP7_Client & operator *() const
        {
            return *this->operator->();
        }

    private:
        template <typename T>
        FORCE_INLINE p7TraceHandle _create_trace(T && channel_name, utility::tag_string, const stTrace_Conf * config_ptr,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        template <typename T>
        FORCE_INLINE p7TraceHandle _create_trace(T && channel_name, utility::tag_wstring, const stTrace_Conf * config_ptr,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        template <typename T>
        FORCE_INLINE p7TelemetryHandle _create_telemetry(T && channel_name, utility::tag_string, const stTelemetry_Conf * config_ptr,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        template <typename T>
        FORCE_INLINE p7TelemetryHandle _create_telemetry(T && channel_name, utility::tag_wstring, const stTelemetry_Conf * config_ptr,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

    public:
        FORCE_INLINE p7TraceHandle create_trace(std::string && channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        FORCE_INLINE p7TraceHandle create_trace(const std::string & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        template <size_t S>
        FORCE_INLINE p7TraceHandle create_trace(const char (& channel_name)[S], const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        FORCE_INLINE p7TraceHandle create_trace(std::wstring && channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        FORCE_INLINE p7TraceHandle create_trace(const std::wstring & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        template <size_t S>
        FORCE_INLINE p7TraceHandle create_trace(const wchar_t (& channel_name)[S], const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        // through template specialization to equalize priorities over function overloading deduction
        template <typename T>
        FORCE_INLINE p7TraceHandle create_trace(const T * const & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        FORCE_INLINE p7TraceHandle create_trace(std::string && channel_name, const stTrace_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        FORCE_INLINE p7TraceHandle create_trace(const std::string & channel_name, const stTrace_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        template <size_t S>
        FORCE_INLINE p7TraceHandle create_trace(const char (& channel_name)[S], const stTrace_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        FORCE_INLINE p7TraceHandle create_trace(std::wstring && channel_name, const stTrace_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        FORCE_INLINE p7TraceHandle create_trace(const std::wstring & channel_name, const stTrace_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        template <size_t S>
        FORCE_INLINE p7TraceHandle create_trace(const wchar_t (& channel_name)[S], const stTrace_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        // through template specialization to equalize priorities over function overloading deduction
        template <typename T>
        FORCE_INLINE p7TraceHandle create_trace(const T * const & channel_name, const stTrace_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        FORCE_INLINE p7TelemetryHandle create_telemetry(std::string && channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        FORCE_INLINE p7TelemetryHandle create_telemetry(const std::string & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        template <size_t S>
        FORCE_INLINE p7TelemetryHandle create_telemetry(const char (& channel_name)[S], const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        FORCE_INLINE p7TelemetryHandle create_telemetry(std::wstring && channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        FORCE_INLINE p7TelemetryHandle create_telemetry(const std::wstring & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        template <size_t S>
        FORCE_INLINE p7TelemetryHandle create_telemetry(const wchar_t (& channel_name)[S], const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        // through template specialization to equalize priorities over function overloading deduction
        template <typename T>
        FORCE_INLINE p7TelemetryHandle create_telemetry(const T * const & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        FORCE_INLINE p7TelemetryHandle create_telemetry(std::string && channel_name, const stTelemetry_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        FORCE_INLINE p7TelemetryHandle create_telemetry(const std::string & channel_name, const stTelemetry_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        template <size_t S>
        FORCE_INLINE p7TelemetryHandle create_telemetry(const char (& channel_name)[S], const stTelemetry_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        FORCE_INLINE p7TelemetryHandle create_telemetry(std::wstring && channel_name, const stTelemetry_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        FORCE_INLINE p7TelemetryHandle create_telemetry(const std::wstring & channel_name, const stTelemetry_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        template <size_t S>
        FORCE_INLINE p7TelemetryHandle create_telemetry(const wchar_t (& channel_name)[S], const stTelemetry_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        // through template specialization to equalize priorities over function overloading deduction
        template <typename T>
        FORCE_INLINE p7TelemetryHandle create_telemetry(const T * const & channel_name, const stTelemetry_Conf & config, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
    };


    //// p7TraceModule

    class p7TraceModule
    {
        friend class p7TraceHandle;

    public:
        static FORCE_INLINE const p7TraceModule & null()
        {
            static const p7TraceModule s_null = p7TraceModule{ IP7_Trace::hModule{}, TM("") };
            return s_null;
        }

    public:
        FORCE_INLINE p7TraceModule()
        {
            *this = null();
        }

        FORCE_INLINE p7TraceModule(const p7TraceModule &) = default;
        FORCE_INLINE p7TraceModule(p7TraceModule &&) = default;

        FORCE_INLINE p7TraceModule & operator =(const p7TraceModule &) = default;
        FORCE_INLINE p7TraceModule & operator =(p7TraceModule &&) = default;

    protected:
        FORCE_INLINE p7TraceModule(IP7_Trace::hModule hmodule, tackle::p7_string && module_name) :
            m_hmodule(hmodule), m_module_name(std::move(module_name))
        {
        }

        FORCE_INLINE p7TraceModule(IP7_Trace::hModule hmodule, const tackle::p7_string & module_name) :
            m_hmodule(hmodule), m_module_name(module_name)
        {
        }

        template <size_t S>
        FORCE_INLINE p7TraceModule(IP7_Trace::hModule hmodule, const tackle::p7_char (& module_name)[S]) :
            m_hmodule(hmodule), m_module_name(module_name)
        {
        }

    public:
        FORCE_INLINE void reset(p7TraceModule handle = p7TraceModule::null())
        {
            auto && handle_rref = std::move(handle);

            m_hmodule = handle_rref.m_hmodule;
        }

        FORCE_INLINE IP7_Trace::hModule handle() const
        {
            return m_hmodule;
        }

        FORCE_INLINE const tackle::p7_string & module_name() const
        {
            return m_module_name;
        }

    private:
        IP7_Trace::hModule  m_hmodule;
        tackle::p7_string   m_module_name;
    };


    //// p7TraceHandle

    class p7TraceHandle : protected tackle::SmartHandle<IP7_Trace>
    {
        friend class p7ClientHandle;

        using base_type = SmartHandle;

    public:
        static FORCE_INLINE const p7TraceHandle & null()
        {
            static const p7TraceHandle s_null = p7TraceHandle{ nullptr, TM("") };
            return s_null;
        }

    protected:
        static FORCE_INLINE void _deleter(void * p)
        {
            if (p) {
                static_cast<IP7_Trace *>(p)->Release();
            }
        }

    public:
        FORCE_INLINE p7TraceHandle()
        {
            *this = null();
        }

        FORCE_INLINE p7TraceHandle(const p7TraceHandle &) = default;
        FORCE_INLINE p7TraceHandle(p7TraceHandle &&) = default;

        FORCE_INLINE p7TraceHandle & operator =(const p7TraceHandle &) = default;
        FORCE_INLINE p7TraceHandle & operator =(p7TraceHandle &&) = default;

    protected:
        FORCE_INLINE p7TraceHandle(IP7_Trace * p, tackle::p7_string && channel_name) :
            base_type(p, _deleter), m_channel_name(std::move(channel_name))
        {
        }

        FORCE_INLINE p7TraceHandle(IP7_Trace * p, const tackle::p7_string & channel_name) :
            base_type(p, _deleter), m_channel_name(channel_name)
        {
        }

        template <size_t S>
        FORCE_INLINE p7TraceHandle(IP7_Trace * p, const tackle::p7_char (& channel_name)[S]) :
            base_type(p, _deleter), m_channel_name(channel_name)
        {
        }

    public:
        FORCE_INLINE void reset(p7TraceHandle handle = p7TraceHandle::null())
        {
            auto && handle_rref = std::move(handle);

            auto * deleter = DEBUG_VERIFY_TRUE(std::get_deleter<base_type::DeleterType>(handle_rref.m_pv));
            if (!deleter) {
                // must always have a deleter
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): deleter is not allocated",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            base_type::reset(handle_rref.get(), *deleter);
        }

        FORCE_INLINE IP7_Trace * handle() const
        {
            return base_type::get();
        }

        FORCE_INLINE const tackle::p7_string & channel_name() const
        {
            return m_channel_name;
        }

        FORCE_INLINE IP7_Trace * operator ->() const
        {

            IP7_Trace * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            return p;
        }

        FORCE_INLINE IP7_Trace & operator *() const
        {
            return *this->operator->();
        }

    private:
        template <typename T>
        FORCE_INLINE bool _register_thread(T && thread_name, utility::tag_string, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack);
        template <typename T>
        FORCE_INLINE bool _register_thread(T && thread_name, utility::tag_wstring, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

    public:
        FORCE_INLINE bool register_thread(std::string && thread_name, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack);
        FORCE_INLINE bool register_thread(const std::string & thread_name, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

        template <size_t S>
        FORCE_INLINE bool register_thread(const char (& thread_name)[S], uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

        FORCE_INLINE bool register_thread(std::wstring && thread_name, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack);
        FORCE_INLINE bool register_thread(const std::wstring & thread_name, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

        template <size_t S>
        FORCE_INLINE bool register_thread(const wchar_t (& thread_name)[S], uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

        template <typename T>
        FORCE_INLINE bool register_thread(const T * const & thread_name, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

        FORCE_INLINE bool unregister_thread(uint32_t thread_id);

    private:
        template <typename T>
        FORCE_INLINE bool _register_module(T && module_name, utility::tag_string, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack);
        template <typename T>
        FORCE_INLINE bool _register_module(T && module_name, utility::tag_wstring, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

    public:
        FORCE_INLINE bool register_module(std::string && module_name, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack);
        FORCE_INLINE bool register_module(const std::string & module_name, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

        template <size_t S>
        FORCE_INLINE bool register_module(const char (& module_name)[S], p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

        FORCE_INLINE bool register_module(std::wstring && module_name, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack);
        FORCE_INLINE bool register_module(const std::wstring & module_name, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

        template <size_t S>
        FORCE_INLINE bool register_module(const wchar_t (& module_name)[S], p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

        template <typename T>
        FORCE_INLINE bool register_module(const T * const & module_name, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack);

    public:
        template <uint32_t log_flags, uint64_t str_id, char... chars, typename... Args>
        FORCE_INLINE bool log(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::tmpl_string<str_id, chars...> & fmt, Args... args) const;

        template <uint32_t log_flags, typename... Args>
        FORCE_INLINE bool log(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::constexpr_string & fmt, Args... args) const;

        template <uint32_t log_flags, uint64_t str_id, wchar_t... wchars, typename... Args>
        FORCE_INLINE bool log(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::tmpl_wstring<str_id, wchars...> & fmt, Args... args) const;

        template <uint32_t log_flags, typename... Args>
        FORCE_INLINE bool log(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::constexpr_wstring & fmt, Args... args) const;

        template <uint32_t log_flags, uint64_t str_id, char... chars, typename... Args>
        FORCE_INLINE bool log_multiline(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::tmpl_string<str_id, chars...> & fmt, Args... args) const;

        template <uint32_t log_flags, typename... Args>
        FORCE_INLINE bool log_multiline(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::constexpr_string & fmt, Args... args) const;

        template <uint32_t log_flags, uint64_t str_id, wchar_t... wchars, typename... Args>
        FORCE_INLINE bool log_multiline(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::tmpl_wstring<str_id, wchars...> & fmt, Args... args) const;

        template <uint32_t log_flags, typename... Args>
        FORCE_INLINE bool log_multiline(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
            const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::constexpr_wstring & fmt, Args... args) const;

    private:
        tackle::p7_string   m_channel_name;
    };


    //// p7TelemetryHandle

    class p7TelemetryHandle : protected tackle::SmartHandle<IP7_Telemetry>
    {
        friend class p7ClientHandle;

        using base_type = SmartHandle;

    public:
        static FORCE_INLINE const p7TelemetryHandle & null()
        {
            static const p7TelemetryHandle s_null = p7TelemetryHandle{ nullptr, TM("") };
            return s_null;
        }

    protected:
        static FORCE_INLINE void _deleter(void * p)
        {
            if (p) {
                static_cast<IP7_Telemetry *>(p)->Release();
            }
        }

    public:
        FORCE_INLINE p7TelemetryHandle()
        {
            *this = null();
        }

        FORCE_INLINE p7TelemetryHandle(const p7TelemetryHandle &) = default;
        FORCE_INLINE p7TelemetryHandle(p7TelemetryHandle &&) = default;

        FORCE_INLINE p7TelemetryHandle & operator =(const p7TelemetryHandle &) = default;
        FORCE_INLINE p7TelemetryHandle & operator =(p7TelemetryHandle &&) = default;

    protected:
        FORCE_INLINE p7TelemetryHandle(IP7_Telemetry * p, tackle::p7_string && channel_name) :
            base_type(p, _deleter), m_channel_name(std::move(channel_name))
        {
        }

        FORCE_INLINE p7TelemetryHandle(IP7_Telemetry * p, const tackle::p7_string & channel_name) :
            base_type(p, _deleter), m_channel_name(channel_name)
        {
        }

        template <size_t S>
        FORCE_INLINE p7TelemetryHandle(IP7_Telemetry * p, const tackle::p7_char (& channel_name)[S]) :
            base_type(p, _deleter), m_channel_name(channel_name)
        {
        }

    public:
        FORCE_INLINE void reset(p7TelemetryHandle handle = p7TelemetryHandle::null())
        {
            auto && handle_rref = std::move(handle);

            auto * deleter = DEBUG_VERIFY_TRUE(std::get_deleter<base_type::DeleterType>(handle_rref.m_pv));
            if (!deleter) {
                // must always have a deleter
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): deleter is not allocated",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            base_type::reset(handle_rref.get(), *deleter);
        }

        FORCE_INLINE IP7_Telemetry * handle() const
        {
            return base_type::get();
        }

        FORCE_INLINE const tackle::p7_string & channel_name() const
        {
            return m_channel_name;
        }

        FORCE_INLINE IP7_Telemetry * operator ->() const
        {

            IP7_Telemetry * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            return p;
        }

        FORCE_INLINE IP7_Telemetry & operator *() const
        {
            return *this->operator->();
        }

    private:
        template <typename T>
        FORCE_INLINE p7TelemetryParamHandle _create_param(T && param_catalog_name, utility::tag_string,
            tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        template <typename T>
        FORCE_INLINE p7TelemetryParamHandle _create_param(T && param_catalog_name, utility::tag_wstring,
            tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;


    public:
        FORCE_INLINE p7TelemetryParamHandle create_param(std::string && param_catalog_name,
            tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        FORCE_INLINE p7TelemetryParamHandle create_param(const std::string & param_catalog_name,
            tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        template <size_t S>
        FORCE_INLINE p7TelemetryParamHandle create_param(const char (& param_catalog_name)[S],
            tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        FORCE_INLINE p7TelemetryParamHandle create_param(std::wstring && param_catalog_name,
            tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;
        FORCE_INLINE p7TelemetryParamHandle create_param(const std::wstring & param_catalog_name,
            tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        template <size_t S>
        FORCE_INLINE p7TelemetryParamHandle create_param(const wchar_t (& param_catalog_name)[S],
            tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

        template <typename T>
        FORCE_INLINE p7TelemetryParamHandle create_param(const T * const & param_catalog_name,
            tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const;

    private:
        tackle::p7_string   m_channel_name;
    };


    //// p7TelemetryParamHandle

    class p7TelemetryParamHandle : protected p7TelemetryHandle
    {
        friend class p7TelemetryHandle;

        using base_type = p7TelemetryHandle;

    public:
        static FORCE_INLINE const p7TelemetryParamHandle & null()
        {
            static const p7TelemetryParamHandle s_null = p7TelemetryParamHandle{ p7TelemetryHandle::null(), 0, TM("") };
            return s_null;
        }

    public:
        FORCE_INLINE p7TelemetryParamHandle()
        {
            *this = null();
        }

        FORCE_INLINE p7TelemetryParamHandle(const p7TelemetryParamHandle &) = default;
        FORCE_INLINE p7TelemetryParamHandle(p7TelemetryParamHandle &&) = default;

        FORCE_INLINE p7TelemetryParamHandle & operator =(const p7TelemetryParamHandle &) = default;
        FORCE_INLINE p7TelemetryParamHandle & operator =(p7TelemetryParamHandle &&) = default;

    protected:
        FORCE_INLINE p7TelemetryParamHandle(p7TelemetryHandle telemetry_handle, tUINT16 param_id, tackle::p7_string && param_catalog_name) :
            base_type(std::move(telemetry_handle)),
            m_param_id(param_id),
            m_param_catalog_name(std::move(param_catalog_name))
        {
        }

        FORCE_INLINE p7TelemetryParamHandle(p7TelemetryHandle telemetry_handle, tUINT16 param_id, const tackle::p7_string & param_catalog_name) :
            base_type(std::move(telemetry_handle)),
            m_param_id(param_id),
            m_param_catalog_name(param_catalog_name)
        {
        }

        template <size_t S>
        FORCE_INLINE p7TelemetryParamHandle(p7TelemetryHandle telemetry_handle, tUINT16 param_id, const tackle::p7_char (&param_catalog_name)[S]) :
            base_type(std::move(telemetry_handle)),
            m_param_id(param_id),
            m_param_catalog_name(param_catalog_name)
        {
        }

    public:
        FORCE_INLINE void reset(p7TelemetryParamHandle handle = p7TelemetryParamHandle::null())
        {
            base_type::reset(std::move(handle));
            m_param_id = handle.m_param_id;
        }

        FORCE_INLINE bool add(tDOUBLE value)
        {
            IP7_Telemetry * p = base_type::get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            return p->Add(m_param_id, value) ? true : false;
        }

        FORCE_INLINE tUINT16 id() const
        {
            return m_param_id;
        }

    private:
        tUINT16             m_param_id;
        tackle::p7_string   m_param_catalog_name;
    };


    //// p7ClientHandle

    template <typename T>
    FORCE_INLINE p7TraceHandle p7ClientHandle::_create_trace(T && channel_name, utility::tag_string, const stTrace_Conf * config_ptr,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        auto channel_name_converted{
            utility::convert_string_to_string(std::forward<T>(channel_name), utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{})
        };

        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        auto * trace_ptr = P7_Create_Trace(p, channel_name_converted.c_str(), config_ptr);

        return p7TraceHandle{
            trace_ptr, std::move(channel_name_converted)
        };
#else
        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        auto * trace_ptr = P7_Create_Trace(p, utility::get_c_str(channel_name), config_ptr);

        return p7TraceHandle{
            trace_ptr, std::forward<T>(channel_name)
        };
#endif
    }

    template <typename T>
    FORCE_INLINE p7TraceHandle p7ClientHandle::_create_trace(T && channel_name, utility::tag_wstring, const stTrace_Conf * config_ptr,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        auto * trace_ptr = P7_Create_Trace(p, utility::get_c_str(channel_name), config_ptr);

        return p7TraceHandle{
            trace_ptr, std::move(channel_name)
        };
#else
        auto channel_name_converted{
            utility::convert_string_to_string(std::move(channel_name), utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{})
        };

        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        auto * trace_ptr = P7_Create_Trace(p, channel_name_converted.c_str(), config_ptr);

        return p7TraceHandle{
            trace_ptr, std::move(channel_name_converted)
        };
#endif
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(std::string && channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(std::move(channel_name), utility::tag_string{}, nullptr, inline_stack);
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const std::string & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_string{}, nullptr, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const char (& channel_name)[S], const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_string{}, nullptr, inline_stack);
    }

    template <>
    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const char * const & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_string{}, nullptr, inline_stack);
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(std::wstring && channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(std::move(channel_name), utility::tag_wstring{}, nullptr, inline_stack);
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const std::wstring & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_wstring{}, nullptr, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const wchar_t (& channel_name)[S], const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_wstring{}, nullptr, inline_stack);
    }

    template <>
    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const wchar_t * const & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_wstring{}, nullptr, inline_stack);
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(std::string && channel_name, const stTrace_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(std::move(channel_name), utility::tag_string{}, &config, inline_stack);
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const std::string & channel_name, const stTrace_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_string{}, &config, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const char (& channel_name)[S], const stTrace_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_string{}, &config, inline_stack);
    }

    template <>
    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const char * const & channel_name, const stTrace_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_string{}, &config, inline_stack);
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(std::wstring && channel_name, const stTrace_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(std::move(channel_name), utility::tag_wstring{}, &config, inline_stack);
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const std::wstring & channel_name, const stTrace_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_wstring{}, &config, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const wchar_t (& channel_name)[S], const stTrace_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_wstring{}, &config, inline_stack);
    }

    template <>
    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const wchar_t * const & channel_name, const stTrace_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_trace(channel_name, utility::tag_wstring{}, &config, inline_stack);
    }

    template <typename T>
    FORCE_INLINE p7TelemetryHandle p7ClientHandle::_create_telemetry(T && channel_name, utility::tag_string, const stTelemetry_Conf * config_ptr,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        auto channel_name_converted{
            utility::convert_string_to_string(channel_name, utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{})
        };

        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        auto * telemetry_ptr = P7_Create_Telemetry(p, channel_name_converted.c_str(), config_ptr);

        return p7TelemetryHandle{
            telemetry_ptr, std::move(channel_name_converted)
        };
#else
        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        auto * telemetry_ptr = P7_Create_Telemetry(p, utility::get_c_str(channel_name), config_ptr);

        return p7TelemetryHandle{
            telemetry_ptr, std::move(channel_name)
        };
#endif
    }

    template <typename T>
    FORCE_INLINE p7TelemetryHandle p7ClientHandle::_create_telemetry(T && channel_name, utility::tag_wstring, const stTelemetry_Conf * config_ptr,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        auto * telemetry_ptr = P7_Create_Telemetry(p, utility::get_c_str(channel_name), config_ptr);

        return p7TelemetryHandle{
            telemetry_ptr, std::move(channel_name)
        };
#else
        auto channel_name_converted{
            utility::convert_string_to_string(channel_name, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{})
        };

        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        auto * telemetry_ptr = P7_Create_Telemetry(p, channel_name_converted.c_str(), config_ptr);

        return p7TelemetryHandle{
            telemetry_ptr, std::move(channel_name_converted)
        };
#endif
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(std::string && channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(std::move(channel_name), utility::tag_string{}, nullptr, inline_stack);
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const std::string & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_string{}, nullptr, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const char (& channel_name)[S], const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_string{}, nullptr, inline_stack);
    }

    template <>
    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const char * const & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_string{}, nullptr, inline_stack);
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(std::wstring && channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(std::move(channel_name), utility::tag_wstring{}, nullptr, inline_stack);
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const std::wstring & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_wstring{}, nullptr, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const wchar_t (& channel_name)[S], const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_wstring{}, nullptr, inline_stack);
    }

    template <>
    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const wchar_t * const & channel_name, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_wstring{}, nullptr, inline_stack);
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(std::string && channel_name, const stTelemetry_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(std::move(channel_name), utility::tag_string{}, &config, inline_stack);
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const std::string & channel_name, const stTelemetry_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_string{}, &config, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const char (& channel_name)[S], const stTelemetry_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_string{}, &config, inline_stack);
    }

    template <>
    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const char * const & channel_name, const stTelemetry_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_string{}, &config, inline_stack);
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(std::wstring && channel_name, const stTelemetry_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(std::move(channel_name), utility::tag_wstring{}, &config, inline_stack);
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const std::wstring & channel_name, const stTelemetry_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_wstring{}, &config, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const wchar_t (& channel_name)[S], const stTelemetry_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_wstring{}, &config, inline_stack);
    }

    template <>
    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const wchar_t * const & channel_name, const stTelemetry_Conf & config,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_telemetry(channel_name, utility::tag_wstring{}, &config, inline_stack);
    }


    ////////////////////////////////////////////////////////////////////////////////

    //// p7TraceHandle

    template <typename T>
    FORCE_INLINE bool p7TraceHandle::_register_thread(T && thread_name, utility::tag_string, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        static_assert(utility::is_convertible_to_string<T>::value, "thread_name must be convertible to a std::string type");

        IP7_Trace * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        auto thread_name_converted{
            utility::convert_string_to_string(std::move(thread_name), utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{})
        };

        return p->Register_Thread(thread_name_converted.c_str(), thread_id) ? true : false;
#else
        return p->Register_Thread(utility::get_c_str(thread_name), thread_id) ? true : false;
#endif
    }

    template <typename T>
    FORCE_INLINE bool p7TraceHandle::_register_thread(T && thread_name, utility::tag_wstring, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        static_assert(utility::is_convertible_to_wstring<T>::value, "thread_name must be convertible to a std::wstring type");

        IP7_Trace * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        return p->Register_Thread(utility::get_c_str(thread_name), thread_id) ? true : false;
#else
        auto thread_name_converted{
            utility::convert_string_to_string(std::move(thread_name), utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{})
        };

        return p->Register_Thread(thread_name_converted.c_str(), thread_id) ? true : false;
#endif
    }

    FORCE_INLINE bool p7TraceHandle::register_thread(std::string && thread_name, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_thread(std::move(thread_name), utility::tag_string{}, thread_id, inline_stack);
    }

    FORCE_INLINE bool p7TraceHandle::register_thread(const std::string & thread_name, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_thread(thread_name, utility::tag_string{}, thread_id, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE bool p7TraceHandle::register_thread(const char (& thread_name)[S], uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_thread(thread_name, utility::tag_string{}, thread_id, inline_stack);
    }

    template <>
    FORCE_INLINE bool p7TraceHandle::register_thread(const char * const & thread_name, uint32_t thread_id,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_thread(thread_name, utility::tag_string{}, thread_id, inline_stack);
    }

    FORCE_INLINE bool p7TraceHandle::register_thread(std::wstring && thread_name, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_thread(std::move(thread_name), utility::tag_wstring{}, thread_id, inline_stack);
    }

    FORCE_INLINE bool p7TraceHandle::register_thread(const std::wstring & thread_name, uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_thread(thread_name, utility::tag_wstring{}, thread_id, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE bool register_thread(const wchar_t (& thread_name)[S], uint32_t thread_id, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_thread(thread_name, utility::tag_wstring{}, thread_id, inline_stack);
    }

    template <>
    FORCE_INLINE bool p7TraceHandle::register_thread(const wchar_t * const & thread_name, uint32_t thread_id,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_thread(thread_name, utility::tag_wstring{}, thread_id, inline_stack);
    }

    FORCE_INLINE bool p7TraceHandle::unregister_thread(uint32_t thread_id)
    {
        IP7_Trace * p = get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

        return p->Unregister_Thread(thread_id) ? true : false;
    }

    template <typename T>
    FORCE_INLINE bool p7TraceHandle::_register_module(T && module_name, utility::tag_string, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        static_assert(utility::is_convertible_to_string<T>::value, "module_name must be convertible to a std::string type");

        IP7_Trace * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        auto module_name_converted{
            utility::convert_string_to_string(std::move(module_name), utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{})
        };

        return p->Register_Module(module_name_converted.c_str(), &trace_module.m_hmodule) ? true : false;
#else
        return p->Register_Module(utility::get_c_str(module_name), &trace_module.m_hmodule) ? true : false;
#endif
    }

    template <typename T>
    FORCE_INLINE bool p7TraceHandle::_register_module(T && module_name, utility::tag_wstring, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        static_assert(utility::is_convertible_to_wstring<T>::value, "module_name must be convertible to a std::wstring type");

        IP7_Trace * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        return p->Register_Module(utility::get_c_str(module_name), &trace_module.m_hmodule) ? true : false;
#else
        auto module_name_converted{
            utility::convert_string_to_string(std::move(module_name), utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{})
        };

        return p->Register_Module(module_name_converted.c_str(), &trace_module.m_hmodule) ? true : false;
#endif
    }

    FORCE_INLINE bool p7TraceHandle::register_module(std::string && module_name, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_module(std::move(module_name), utility::tag_string{}, trace_module, inline_stack);
    }

    FORCE_INLINE bool p7TraceHandle::register_module(const std::string & module_name, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_module(module_name, utility::tag_string{}, trace_module, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE bool p7TraceHandle::register_module(const char (& module_name)[S], p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_module(module_name, utility::tag_string{}, trace_module, inline_stack);
    }

    template <>
    FORCE_INLINE bool p7TraceHandle::register_module(const char * const & module_name, p7TraceModule & trace_module,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_module(module_name, utility::tag_string{}, trace_module, inline_stack);
    }

    FORCE_INLINE bool p7TraceHandle::register_module(std::wstring && module_name, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_module(std::move(module_name), utility::tag_wstring{}, trace_module, inline_stack);
    }

    FORCE_INLINE bool p7TraceHandle::register_module(const std::wstring & module_name, p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_module(module_name, utility::tag_wstring{}, trace_module, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE bool p7TraceHandle::register_module(const wchar_t (& module_name)[S], p7TraceModule & trace_module, const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_module(module_name, utility::tag_wstring{}, trace_module, inline_stack);
    }

    template <>
    FORCE_INLINE bool p7TraceHandle::register_module(const wchar_t * const & module_name, p7TraceModule & trace_module,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack)
    {
        return _register_module(module_name, utility::tag_wstring{}, trace_module, inline_stack);
    }

    template <uint32_t log_flags, uint64_t str_id, char... chars, typename... Args>
    FORCE_INLINE bool p7TraceHandle::log(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::tmpl_string<str_id, chars...> & fmt, Args... args) const
    {
        UTILITY_UNUSED_STATEMENT((detail::_validate_log_flags<log_flags, char, true, false>()));

        IP7_Trace * p = get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

        const char * file_path_c_str = nullptr;
        tackle::generic_path_string file_path;

        if (UTILITY_CONSTEXPR((log_flags & LogFlag_TruncateSrcFileToFileName) || !(log_flags & LogFlag_TruncateSrcFileToRelativePath))) {
            file_path_c_str = inline_stack.top.file.c_str();
        }
        else {
            // try to make relative path to source file from either LOG_SRC_ROOT or cached module directory location
#ifdef LOG_SRC_ROOT
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::convert_to_generic_path(UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(LOG_SRC_ROOT)), inline_stack.top.file.c_str(), false);
#else
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::get_module_dir_path(tackle::tag_generic_path_string{}, true), inline_stack.top.file.c_str(), false);
#endif
            file_path = !base_file_path.empty() ? utility::truncate_path_relative_prefix(base_file_path) :
                utility::convert_to_generic_path(inline_stack.top.file.c_str(), inline_stack.top.file.length());

            file_path_c_str = file_path.c_str();
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        // not supported character type, we have to evaluate fmt here
        std::string fmt_utf8;

        if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            fmt_utf8 = fmt::format(fmt, std::forward<Args>(args)...);
        }
        else {
            fmt_utf8 = utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...);
        }

        std::wstring fmt_utf16;
        utility::convert_string_to_string(fmt_utf8, fmt_utf16, utility::tag_string_conv_utf8_to_utf16{});

        return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
            TM("%s"),   // UTF-16
            utility::get_c_str(fmt_utf16)) ? true : false;
#else
        if (UTILITY_CONSTEXPR(!(log_flags & LogFlag_UseStdFmtCompatibleFmt) && !(log_flags & LogFlag_UseStdPrintfCompatibleFmt))) {
            // p7 fmt format
            return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                utility::get_c_str(fmt),
                utility::get_c_param(std::forward<Args>(args)...)) ? true : false;
        }
        else if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            // std fmt format, we have to evaluate fmt here
            auto fmt_utf8{
                fmt::format(fmt, std::forward<Args>(args)...)
            };

            return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),  // UTF-8
                utility::get_c_str(fmt_utf8)) ? true : false;
        }

        // std printf format, we have to evaluate fmt here
        auto fmt_utf8{
            utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...)
        };

        return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
            TM("%s"),  // UTF-8
            utility::get_c_str(fmt_utf8)) ? true : false;
#endif
    }

    template <uint32_t log_flags, typename... Args>
    FORCE_INLINE bool p7TraceHandle::log(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::constexpr_string & fmt, Args... args) const
    {
        UTILITY_UNUSED_STATEMENT((detail::_validate_log_flags<log_flags, char, false, false>()));

        IP7_Trace * p = get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

        const char * file_path_c_str = nullptr;
        tackle::generic_path_string file_path;

        if (UTILITY_CONSTEXPR((log_flags & LogFlag_TruncateSrcFileToFileName) || !(log_flags & LogFlag_TruncateSrcFileToRelativePath))) {
            file_path_c_str = inline_stack.top.file.c_str();
        }
        else {
            // try to make relative path to source file from either LOG_SRC_ROOT or cached module directory location
#ifdef LOG_SRC_ROOT
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::convert_to_generic_path(UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(LOG_SRC_ROOT)), inline_stack.top.file.c_str(), false);
#else
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::get_module_dir_path(tackle::tag_generic_path_string{}, true), inline_stack.top.file.c_str(), false);
#endif
            file_path = !base_file_path.empty() ? utility::truncate_path_relative_prefix(base_file_path) :
                utility::convert_to_generic_path(inline_stack.top.file.c_str(), inline_stack.top.file.length());

            file_path_c_str = file_path.c_str();
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        // not supported character type, we have to evaluate fmt here
        std::string fmt_utf8;

        if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            fmt_utf8 = fmt::format(fmt, std::forward<Args>(args)...);
        }
        else {
            fmt_utf8 = utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...);
        }

        std::wstring fmt_utf16;
        utility::convert_string_to_string(fmt_utf8, fmt_utf16, utility::tag_string_conv_utf8_to_utf16{});

        return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
            TM("%s"),   // UTF-16
            utility::get_c_str(fmt_utf16)) ? true : false;
#else
        if (UTILITY_CONSTEXPR(!(log_flags & LogFlag_UseStdFmtCompatibleFmt) && !(log_flags & LogFlag_UseStdPrintfCompatibleFmt))) {
            // p7 fmt format
            return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                utility::get_c_str(fmt),
                utility::get_c_param(std::forward<Args>(args)...)) ? true : false;
        }
        else if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            // std fmt format, we have to evaluate fmt here
            auto fmt_utf8{
                fmt::format(fmt, std::forward<Args>(args)...)
            };

            return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),  // UTF-8
                utility::get_c_str(fmt_utf8)) ? true : false;
        }

        // std printf format, we have to evaluate fmt here
        auto fmt_utf8{
            utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...)
        };

        return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
            TM("%s"),  // UTF-8
            utility::get_c_str(fmt_utf8)) ? true : false;
#endif
    }

    template <uint32_t log_flags, uint64_t str_id, wchar_t... wchars, typename... Args>
    FORCE_INLINE bool p7TraceHandle::log(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::tmpl_wstring<str_id, wchars...> & fmt, Args... args) const
    {
        UTILITY_UNUSED_STATEMENT((detail::_validate_log_flags<log_flags, wchar_t, true, false>()));

        IP7_Trace * p = get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

        const char * file_path_c_str = nullptr;
        tackle::generic_path_string file_path;

        if (UTILITY_CONSTEXPR((log_flags & LogFlag_TruncateSrcFileToFileName) || !(log_flags & LogFlag_TruncateSrcFileToRelativePath))) {
            file_path_c_str = inline_stack.top.file.c_str();
        }
        else {
            // try to make relative path to source file from either LOG_SRC_ROOT or cached module directory location
#ifdef LOG_SRC_ROOT
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::convert_to_generic_path(UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(LOG_SRC_ROOT)), inline_stack.top.file.c_str(), false);
#else
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::get_module_dir_path(tackle::tag_generic_path_string{}, true), inline_stack.top.file.c_str(), false);
#endif
            file_path = !base_file_path.empty() ? utility::truncate_path_relative_prefix(base_file_path) :
                utility::convert_to_generic_path(inline_stack.top.file.c_str(), inline_stack.top.file.length());

            file_path_c_str = file_path.c_str();
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        if (UTILITY_CONSTEXPR(!(log_flags & LogFlag_UseStdFmtCompatibleFmt) && !(log_flags & LogFlag_UseStdPrintfCompatibleFmt))) {
            // p7 fmt format
            return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                utility::get_c_str(fmt),
                utility::get_c_param(std::forward<Args>(args)...)) ? true : false;
        }
        else if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            // std fmt format, we have to evaluate fmt here
            auto fmt_utf16{
                fmt::format(fmt, std::forward<Args>(args)...)
            };

            return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),  // UTF-16
                utility::get_c_str(fmt_utf16)) ? true : false;
        }

        // std printf format, we have to evaluate fmt here
        auto fmt_utf16{
            utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...)
        };

        return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
            TM("%s"),  // UTF-16
            utility::get_c_str(fmt_utf16)) ? true : false;
#else
        // not supported character type, we have to evaluate fmt here
        std::wstring fmt_utf16;

        if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            fmt_utf16 = fmt::format(fmt, std::forward<Args>(args)...);
        }
        else {
            fmt_utf16 = utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...);
        }

        std::string fmt_utf8;
        utility::convert_string_to_string(fmt_utf16, fmt_utf8, utility::tag_string_conv_utf16_to_utf8{});

        return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
            TM("%s"),   // UTF-16
            utility::get_c_str(fmt_utf8)) ? true : false;
#endif
    }

    template <uint32_t log_flags, typename... Args>
    FORCE_INLINE bool p7TraceHandle::log(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::constexpr_wstring & fmt, Args... args) const
    {
        UTILITY_UNUSED_STATEMENT((detail::_validate_log_flags<log_flags, wchar_t, false, false>()));

        IP7_Trace * p = get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

        const char * file_path_c_str = nullptr;
        tackle::generic_path_string file_path;

        if (UTILITY_CONSTEXPR((log_flags & LogFlag_TruncateSrcFileToFileName) || !(log_flags & LogFlag_TruncateSrcFileToRelativePath))) {
            file_path_c_str = inline_stack.top.file.c_str();
        }
        else {
            // try to make relative path to source file from either LOG_SRC_ROOT or cached module directory location
#ifdef LOG_SRC_ROOT
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::convert_to_generic_path(UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(LOG_SRC_ROOT)), inline_stack.top.file.c_str(), false);
#else
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::get_module_dir_path(tackle::tag_generic_path_string{}, true), inline_stack.top.file.c_str(), false);
#endif
            file_path = !base_file_path.empty() ? utility::truncate_path_relative_prefix(base_file_path) :
                utility::convert_to_generic_path(inline_stack.top.file.c_str(), inline_stack.top.file.length());

            file_path_c_str = file_path.c_str();
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        if (UTILITY_CONSTEXPR(!(log_flags & LogFlag_UseStdFmtCompatibleFmt) && !(log_flags & LogFlag_UseStdPrintfCompatibleFmt))) {
            // p7 fmt format
            return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                utility::get_c_str(fmt),
                utility::get_c_param(std::forward<Args>(args)...)) ? true : false;
        }
        else if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            // std fmt format, we have to evaluate fmt here
            auto fmt_utf16{
                fmt::format(fmt, std::forward<Args>(args)...)
            };

            return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),  // UTF-16
                utility::get_c_str(fmt_utf16)) ? true : false;
        }

        // std printf format, we have to evaluate fmt here
        auto fmt_utf16{
            utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...)
        };

        return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
            TM("%s"),  // UTF-16
            utility::get_c_str(fmt_utf16)) ? true : false;
#else
        // not supported character type, we have to evaluate fmt here
        std::wstring fmt_utf16;

        if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            fmt_utf16 = fmt::format(fmt, std::forward<Args>(args)...);
        }
        else {
            fmt_utf16 = utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...);
        }

        std::string fmt_utf8;
        utility::convert_string_to_string(fmt_utf16, fmt_utf8, utility::tag_string_conv_utf16_to_utf8{});

        return p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
            TM("%s"),   // UTF-16
            utility::get_c_str(fmt_utf8)) ? true : false;
#endif
    }

    template <uint32_t log_flags, uint64_t str_id, char... chars, typename... Args>
    FORCE_INLINE bool p7TraceHandle::log_multiline(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::tmpl_string<str_id, chars...> & fmt, Args... args) const
    {
        UTILITY_UNUSED_STATEMENT((detail::_validate_log_flags<log_flags, char, true, true>()));

        IP7_Trace * p = get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

        const char * file_path_c_str = nullptr;
        tackle::generic_path_string file_path;

        if (UTILITY_CONSTEXPR((log_flags & LogFlag_TruncateSrcFileToFileName) || !(log_flags & LogFlag_TruncateSrcFileToRelativePath))) {
            file_path_c_str = inline_stack.top.file.c_str();
        }
        else {
            // try to make relative path to source file from either LOG_SRC_ROOT or cached module directory location
#ifdef LOG_SRC_ROOT
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::convert_to_generic_path(UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(LOG_SRC_ROOT)), inline_stack.top.file.c_str(), false);
#else
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::get_module_dir_path(tackle::tag_generic_path_string{}, true), inline_stack.top.file.c_str(), false);
#endif
            file_path = !base_file_path.empty() ? utility::truncate_path_relative_prefix(base_file_path) :
                utility::convert_to_generic_path(inline_stack.top.file.c_str(), inline_stack.top.file.length());

            file_path_c_str = file_path.c_str();
        }

        // we have to evaluate fmt here
        std::string fmt_utf8;

        if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            fmt_utf8 = fmt::format(fmt, std::forward<Args>(args)...);
        }
        else {
            fmt_utf8 = utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...);
        }

        bool res_multiline = false;

#if defined(UTILITY_PLATFORM_WINDOWS)
        std::wstring fmt_utf16;
        utility::convert_string_to_string(fmt_utf8, fmt_utf16, utility::tag_string_conv_utf8_to_utf16{});

        std::wistringstream text_stream_in{ fmt_utf16, std::ios_base::in };
        std::wstring line;

        while (text_stream_in) {
            if (!std::getline(text_stream_in, line)) {
                break;
            }

            res_multiline |= p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),   // UTF-16
                utility::get_c_str(line)) ? true : false;
        }
#else
        std::istringstream text_stream_in{ fmt_utf8, std::ios_base::in };
        std::string line;

        while (text_stream_in) {
            if (!std::getline(text_stream_in, line)) {
                break;
            }

            res_multiline |= p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),   // UTF-8
                utility::get_c_str(line)) ? true : false;
        }
#endif

        return res_multiline;
    }

    template <uint32_t log_flags, typename... Args>
    FORCE_INLINE bool p7TraceHandle::log_multiline(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::constexpr_string & fmt, Args... args) const
    {
        UTILITY_UNUSED_STATEMENT((detail::_validate_log_flags<log_flags, char, false, true>()));

        IP7_Trace * p = get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

        const char * file_path_c_str = nullptr;
        tackle::generic_path_string file_path;

        if (UTILITY_CONSTEXPR((log_flags & LogFlag_TruncateSrcFileToFileName) || !(log_flags & LogFlag_TruncateSrcFileToRelativePath))) {
            file_path_c_str = inline_stack.top.file.c_str();
        }
        else {
            // try to make relative path to source file from either LOG_SRC_ROOT or cached module directory location
#ifdef LOG_SRC_ROOT
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::convert_to_generic_path(UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(LOG_SRC_ROOT)), inline_stack.top.file.c_str(), false);
#else
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::get_module_dir_path(tackle::tag_generic_path_string{}, true), inline_stack.top.file.c_str(), false);
#endif
            file_path = !base_file_path.empty() ? utility::truncate_path_relative_prefix(base_file_path) :
                utility::convert_to_generic_path(inline_stack.top.file.c_str(), inline_stack.top.file.length());

            file_path_c_str = file_path.c_str();
        }

        // we have to evaluate fmt here
        std::string fmt_utf8;

        if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            fmt_utf8 = fmt::format(fmt, std::forward<Args>(args)...);
        }
        else {
            fmt_utf8 = utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...);
        }

        bool res_multiline = false;

#if defined(UTILITY_PLATFORM_WINDOWS)
        std::wstring fmt_utf16;
        utility::convert_string_to_string(fmt_utf8, fmt_utf16, utility::tag_string_conv_utf8_to_utf16{});

        std::wistringstream text_stream_in{ fmt_utf16, std::ios_base::in };
        std::wstring line;

        while (text_stream_in) {
            if (!std::getline(text_stream_in, line)) {
                break;
            }

            res_multiline |= p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),   // UTF-16
                utility::get_c_str(line)) ? true : false;
        }
#else
        std::istringstream text_stream_in{ fmt_utf8, std::ios_base::in };
        std::string line;

        while (text_stream_in) {
            if (!std::getline(text_stream_in, line)) {
                break;
            }

            res_multiline |= p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),   // UTF-8
                utility::get_c_str(line)) ? true : false;
        }
#endif

        return res_multiline;
    }

    template <uint32_t log_flags, uint64_t str_id, wchar_t... wchars, typename... Args>
    FORCE_INLINE bool p7TraceHandle::log_multiline(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::tmpl_wstring<str_id, wchars...> & fmt, Args... args) const
    {
        UTILITY_UNUSED_STATEMENT((detail::_validate_log_flags<log_flags, wchar_t, true, true>()));

        IP7_Trace * p = get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

        const char * file_path_c_str = nullptr;
        tackle::generic_path_string file_path;

        if (UTILITY_CONSTEXPR((log_flags & LogFlag_TruncateSrcFileToFileName) || !(log_flags & LogFlag_TruncateSrcFileToRelativePath))) {
            file_path_c_str = inline_stack.top.file.c_str();
        }
        else {
            // try to make relative path to source file from either LOG_SRC_ROOT or cached module directory location
#ifdef LOG_SRC_ROOT
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::convert_to_generic_path(UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(LOG_SRC_ROOT)), inline_stack.top.file.c_str(), false);
#else
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::get_module_dir_path(tackle::tag_generic_path_string{}, true), inline_stack.top.file.c_str(), false);
#endif
            file_path = !base_file_path.empty() ? utility::truncate_path_relative_prefix(base_file_path) :
                utility::convert_to_generic_path(inline_stack.top.file.c_str(), inline_stack.top.file.length());

            file_path_c_str = file_path.c_str();
        }

        // we have to evaluate fmt here
        std::wstring fmt_utf16;

        if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            fmt_utf16 = fmt::format(fmt, std::forward<Args>(args)...);
        }
        else {
            fmt_utf16 = utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...);
        }

        bool res_multiline = false;

#if defined(UTILITY_PLATFORM_WINDOWS)
        std::istringstream text_stream_in{ fmt_utf16, std::ios_base::in };
        std::string line;

        while (text_stream_in) {
            if (!std::getline(text_stream_in, line)) {
                break;
            }

            res_multiline |= p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),   // UTF-16
                utility::get_c_str(line)) ? true : false;
        }
#else
        std::string fmt_utf8;
        utility::convert_string_to_string(fmt_utf16, fmt_utf8, utility::tag_string_conv_utf16_to_utf8{});

        std::istringstream text_stream_in{ fmt_utf8, std::ios_base::in };
        std::string line;

        while (text_stream_in) {
            if (!std::getline(text_stream_in, line)) {
                break;
            }

            res_multiline |= p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),   // UTF-8
                utility::get_c_str(line)) ? true : false;
        }
#endif

        return res_multiline;
    }

    template <uint32_t log_flags, typename... Args>
    FORCE_INLINE bool p7TraceHandle::log_multiline(const p7TraceModule & trace_module, tUINT16 id, eP7Trace_Level lvl,
        const tackle::DebugFileLineFuncInlineStackA & inline_stack, const tackle::constexpr_wstring & fmt, Args... args) const
    {
        UTILITY_UNUSED_STATEMENT((detail::_validate_log_flags<log_flags, wchar_t, false, true>()));

        IP7_Trace * p = get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    inline_stack.top.func.c_str(), inline_stack.top.line));
        }

        const char * file_path_c_str = nullptr;
        tackle::generic_path_string file_path;

        if (UTILITY_CONSTEXPR((log_flags & LogFlag_TruncateSrcFileToFileName) || !(log_flags & LogFlag_TruncateSrcFileToRelativePath))) {
            file_path_c_str = inline_stack.top.file.c_str();
        }
        else {
            // try to make relative path to source file from either LOG_SRC_ROOT or cached module directory location
#ifdef LOG_SRC_ROOT
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::convert_to_generic_path(UTILITY_LITERAL_STRING_WITH_LENGTH_TUPLE(LOG_SRC_ROOT)), inline_stack.top.file.c_str(), false);
#else
            const tackle::generic_path_string base_file_path = utility::get_relative_path(utility::get_module_dir_path(tackle::tag_generic_path_string{}, true), inline_stack.top.file.c_str(), false);
#endif
            file_path = !base_file_path.empty() ? utility::truncate_path_relative_prefix(base_file_path) :
                utility::convert_to_generic_path(inline_stack.top.file.c_str(), inline_stack.top.file.length());

            file_path_c_str = file_path.c_str();
        }

        // we have to evaluate fmt here
        std::wstring fmt_utf16;

        if (UTILITY_CONSTEXPR(log_flags & LogFlag_UseStdFmtCompatibleFmt)) {
            fmt_utf16 = fmt::format(fmt, std::forward<Args>(args)...);
        }
        else {
            fmt_utf16 = utility::string_format(LOG_P7_STRING_FORMAT_BUFFER_RESERVE, utility::get_c_str(fmt), std::forward<Args>(args)...);
        }

        bool res_multiline = false;

#if defined(UTILITY_PLATFORM_WINDOWS)
        std::istringstream text_stream_in{ fmt_utf16, std::ios_base::in };
        std::string line;

        while (text_stream_in) {
            if (!std::getline(text_stream_in, line)) {
                break;
            }

            res_multiline |= p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),   // UTF-16
                utility::get_c_str(line)) ? true : false;
        }
#else
        std::string fmt_utf8;
        utility::convert_string_to_string(fmt_utf16, fmt_utf8, utility::tag_string_conv_utf16_to_utf8{});

        std::istringstream text_stream_in{ fmt_utf8, std::ios_base::in };
        std::string line;

        while (text_stream_in) {
            if (!std::getline(text_stream_in, line)) {
                break;
            }

            res_multiline |= p->Trace(id, lvl, trace_module.handle(), (tUINT16)inline_stack.top.line, file_path_c_str, inline_stack.top.func.c_str(),
                TM("%s"),   // UTF-8
                utility::get_c_str(line)) ? true : false;
        }
#endif

        return res_multiline;
    }


    ////////////////////////////////////////////////////////////////////////////////

    //// p7TelemetryHandle

    template <typename T>
    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::_create_param(T && param_catalog_name, utility::tag_string,
        tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        IP7_Telemetry * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

        tUINT16 param_id = 0;

#if defined(UTILITY_PLATFORM_WINDOWS)
        auto param_catalog_name_converted{
            utility::convert_string_to_string(std::move(param_catalog_name), utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{})
        };

        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        const tBOOL is_created = p->Create(param_catalog_name_converted.c_str(), min_value, alarm_min, max_value, alarm_max, is_enabled ? TRUE : FALSE, &param_id);

        if (is_created) {
            return p7TelemetryParamHandle{
                *this, param_id, std::move(param_catalog_name_converted)
            };
        }
#else
        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        const tBOOL is_created = p->Create(utility::get_c_str(param_catalog_name), min_value, alarm_min, max_value, alarm_max, is_enabled ? TRUE : FALSE, &param_id);

        if (is_created) {
            return p7TelemetryParamHandle{
                *this, param_id, std::move(param_catalog_name)
            };
        }
#endif

        return p7TelemetryParamHandle::null();
    }

    template <typename T>
    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::_create_param(T && param_catalog_name, utility::tag_wstring,
        tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        IP7_Telemetry * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

        tUINT16 param_id = 0;

#if defined(UTILITY_PLATFORM_WINDOWS)
        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        const tBOOL is_created = p->Create(utility::get_c_str(param_catalog_name), min_value, alarm_min, max_value, alarm_max, is_enabled ? TRUE : FALSE, &param_id);

        if (is_created) {
            return p7TelemetryParamHandle{
                *this, param_id, std::move(param_catalog_name)
            };
        }
#else
        auto param_catalog_name_converted{
            utility::convert_string_to_string(param_catalog_name, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{})
        };

        // CAUTION: as standalone to avoid `std::move` before the `.c_str()`!
        const tBOOL is_created = p->Create(param_catalog_name_converted.c_str(), min_value, alarm_min, max_value, alarm_max, is_enabled ? TRUE : FALSE, &param_id);

        if (is_created) {
            return p7TelemetryParamHandle{
                *this, param_id, std::move(param_catalog_name_converted)
            };
        }
#endif

        return p7TelemetryParamHandle::null();
    }

    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(std::string && param_catalog_name,
        tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_param(std::move(param_catalog_name), utility::tag_string{}, min_value, alarm_min, max_value, alarm_max, is_enabled, inline_stack);
    }

    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(const std::string & param_catalog_name,
        tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_param(param_catalog_name, utility::tag_string{}, min_value, alarm_min, max_value, alarm_max, is_enabled, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(const char (& param_catalog_name)[S],
        tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_param(param_catalog_name, utility::tag_string{}, min_value, alarm_min, max_value, alarm_max, is_enabled, inline_stack);
    }

    template <>
    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(const char * const & param_catalog_name,
        tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_param(param_catalog_name, utility::tag_string{}, min_value, alarm_min, max_value, alarm_max, is_enabled, inline_stack);
    }

    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(std::wstring && param_catalog_name,
        tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_param(std::move(param_catalog_name), utility::tag_wstring{}, min_value, alarm_min, max_value, alarm_max, is_enabled, inline_stack);
    }

    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(const std::wstring & param_catalog_name,
        tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_param(param_catalog_name, utility::tag_wstring{}, min_value, alarm_min, max_value, alarm_max, is_enabled, inline_stack);
    }

    template <size_t S>
    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(const wchar_t (& param_catalog_name)[S],
        tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_param(param_catalog_name, utility::tag_wstring{}, min_value, alarm_min, max_value, alarm_max, is_enabled, inline_stack);
    }

    template <>
    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(const wchar_t * const & param_catalog_name,
        tDOUBLE min_value, tDOUBLE alarm_min, tDOUBLE max_value, tDOUBLE alarm_max, bool is_enabled, const tackle::DebugFileLineFuncInlineStackA & inline_stack) const
    {
        return _create_param(param_catalog_name, utility::tag_wstring{}, min_value, alarm_min, max_value, alarm_max, is_enabled, inline_stack);
    }


    ////////////////////////////////////////////////////////////////////////////////

    //// globals

namespace detail {

    template <typename T>
    FORCE_INLINE p7ClientHandle _p7_create_client(T && cmd_line, utility::tag_string)
    {
        static_assert(utility::is_convertible_to_string<T>::value, "cmd_line must be convertible to a std::string type");

#if defined(UTILITY_PLATFORM_WINDOWS)
        auto cmd_line_converted{
            utility::convert_string_to_string(std::forward<T>(cmd_line), utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{})
        };

        return p7ClientHandle{
            P7_Create_Client(cmd_line_converted.c_str())
        };
#else
        return p7ClientHandle{
            P7_Create_Client(utility::get_c_str(cmd_line))
        };
#endif
    }

    template <typename T>
    FORCE_INLINE p7ClientHandle _p7_create_client(T && cmd_line, utility::tag_wstring)
    {
        static_assert(utility::is_convertible_to_wstring<T>::value, "cmd_line must be convertible to a std::wstring type");

#if defined(UTILITY_PLATFORM_WINDOWS)
        return p7ClientHandle{
            P7_Create_Client(utility::get_c_str(cmd_line))
        };
#else
        auto cmd_line_converted{
            utility::convert_string_to_string(std::forward<T>(cmd_line), utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{})
        };

        return p7ClientHandle{
            P7_Create_Client(cmd_line_converted.c_str())
        };
#endif
    }

}

    // CAUTION:
    //  Avoid usage of `const char *` or `const wchar_t *` function overloading because of not equal priority deduction between
    //  template function with `const char (&)[S]` argument and non template function with `const char *` argument!
    //

    FORCE_INLINE p7ClientHandle p7_create_client(std::string && cmd_line)
    {
        return detail::_p7_create_client(std::move(cmd_line), utility::tag_string{});
    }

    FORCE_INLINE p7ClientHandle p7_create_client(const std::string & cmd_line)
    {
        return detail::_p7_create_client(cmd_line, utility::tag_string{});
    }

    template <size_t S>
    FORCE_INLINE p7ClientHandle p7_create_client(const char (& cmd_line)[S])
    {
        return detail::_p7_create_client(cmd_line, utility::tag_string{});
    }

    FORCE_INLINE p7ClientHandle p7_create_client(std::wstring && cmd_line)
    {
        return detail::_p7_create_client(std::move(cmd_line), utility::tag_wstring{});
    }

    FORCE_INLINE p7ClientHandle p7_create_client(const std::wstring & cmd_line)
    {
        return detail::_p7_create_client(cmd_line, utility::tag_wstring{});
    }

    template <size_t S>
    FORCE_INLINE p7ClientHandle p7_create_client(const wchar_t (& cmd_line)[S])
    {
        return detail::_p7_create_client(cmd_line, utility::tag_wstring{});
    }

    // through template specialization to equalize priorities over function overloading deduction
    template <typename T>
    FORCE_INLINE p7ClientHandle p7_create_client(const T * const & cmd_line);

    template <>
    FORCE_INLINE p7ClientHandle p7_create_client(const char * const & cmd_line)
    {
        return detail::_p7_create_client(cmd_line, utility::tag_string{});
    }

    template <>
    FORCE_INLINE p7ClientHandle p7_create_client(const wchar_t * const & cmd_line)
    {
        return detail::_p7_create_client(cmd_line, utility::tag_wstring{});
    }

}
}
}

namespace utility {

    // enable through partial specializations
    template <>
    struct type_index_identity_base<log::p7logger::p7ClientHandle, 1> :
        type_index_identity<log::p7logger::p7ClientHandle, 1>
    {
    };

    template <>
    struct type_index_identity_base<log::p7logger::p7TraceHandle, 2> :
        type_index_identity<log::p7logger::p7TraceHandle, 2>
    {
    };

    template <>
    struct type_index_identity_base<log::p7logger::p7TraceModule, 3> :
        type_index_identity<log::p7logger::p7TraceModule, 3>
    {
    };

    template <>
    struct type_index_identity_base<log::p7logger::p7TelemetryHandle, 4> :
        type_index_identity<log::p7logger::p7TelemetryHandle, 4>
    {
    };

    template <>
    struct type_index_identity_base<log::p7logger::p7TelemetryParamHandle, 5> :
        type_index_identity<log::p7logger::p7TelemetryParamHandle, 5>
    {
    };

}

namespace tackle {

    using p7_client_log_handle              = t_log_handle<utility::log::p7logger::p7ClientHandle, 1>;
    using p7_trace_log_handle               = t_log_handle<utility::log::p7logger::p7TraceHandle, 2>;
    using p7_trace_log_module               = t_log_handle<utility::log::p7logger::p7TraceModule, 3>;
    using p7_telemetry_log_handle           = t_log_handle<utility::log::p7logger::p7TelemetryHandle, 4>;
    using p7_telemetry_param_log_handle     = t_log_handle<utility::log::p7logger::p7TelemetryParamHandle, 5>;

    // input only parameters

    struct p7_log_client_params_in
    {
        const p7_client_log_handle &    handle;
        const std::string               channel_name;
    };

    struct p7_log_channel_params_in
    {
        const p7_trace_log_module &     module;
        const uint32_t                  id;
    };

    struct p7_log_trace_params_in
    {
        p7_trace_log_handle &           handle;
        const p7_trace_log_module &     module; // has to be duplicated
        const uint32_t                  id;
    };

    // input/output parameters

    struct p7_log_client_params
    {
        p7_client_log_handle            handle;
        std::string                     channel_name;
    };

    struct p7_log_channel_params
    {
        p7_trace_log_module             module;
        uint32_t                        id;
    };

    struct p7_log_trace_params
    {
        p7_trace_log_handle             handle;
        p7_trace_log_module             module;
        uint32_t                        id;
    };

}

#endif
