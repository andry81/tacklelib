#pragma once

#include <tacklelib_private.hpp>

#include <utility/platform.hpp>
#include <utility/debug.hpp>
#include <utility/assert.hpp>
#include <utility/locale.hpp>
#include <utility/string.hpp>

#include <tackle/smart_handle.hpp>
#include <tackle/log/log_handle.hpp>

#include <fmt/format.h>

#include "P7_Trace.h"
#include "P7_Telemetry.h"

#include <cstdio>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <sstream>
#include <istream>
#include <ios>
#include <utility>


// Some review and tests versus other loggers on russian website (RU):
//   https://habr.com/post/313686/
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

#define LOG_P7_CREATE_CLIENT(cmd_line) \
    ::utility::log::p7logger::p7_create_client(cmd_line)

#define LOG_P7_CREATE_TRACE(client, channel_name) \
    client.create_trace(channel_name)

#define LOG_P7_CREATE_TRACE2(client, channel_name, config) \
    client.create_trace(channel_name, config)

#define LOG_P7_CREATE_TELEMETRY(client, channel_name) \
    client.create_telemetry(channel_name)

#define LOG_P7_CREATE_TELEMETRY2(client, channel_name, config) \
    client.create_telemetry(channel_name, config)

#define LOG_P7_CREATE_TELEMETRY_PARAM(telemetry, param_catalog_name, min_value, max_value, alarm_value, is_enabled) \
    telemetry.create_param(param_catalog_name, min_value, max_value, alarm_value, is_enabled)


#define LOG_P7_LOG(trace_handle, id, lvl, fmt, ...) \
    trace_handle.log(id, lvl, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOG_TRACE(trace_handle, id, fmt, ...) \
    trace_handle.log(id, EP7TRACE_LEVEL_TRACE, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOG_DEBUG(trace_handle, id, fmt, ...) \
    trace_handle.log(id, EP7TRACE_LEVEL_DEBUG, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOG_INFO(trace_handle, id, fmt, ...) \
    trace_handle.log(id, EP7TRACE_LEVEL_INFO, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOG_WARNING(trace_handle, id, fmt, ...) \
    trace_handle.log(id, EP7TRACE_LEVEL_WARNING, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOG_ERROR(trace_handle, id, fmt, ...) \
    trace_handle.log(id, EP7TRACE_LEVEL_ERROR, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOG_CRITICAL(trace_handle, id, fmt, ...) \
    trace_handle.log(id, EP7TRACE_LEVEL_CRITICAL, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

// multiline version

#define LOG_P7_LOGM(trace_handle, id, lvl, fmt, ...) \
    trace_handle.log_multiline(id, lvl, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOGM_TRACE(trace_handle, id, fmt, ...) \
    trace_handle.log_multiline(id, EP7TRACE_LEVEL_TRACE, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOGM_DEBUG(trace_handle, id, fmt, ...) \
    trace_handle.log_multiline(id, EP7TRACE_LEVEL_DEBUG, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOGM_INFO(trace_handle, id, fmt, ...) \
    trace_handle.log_multiline(id, EP7TRACE_LEVEL_INFO, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOGM_WARNING(trace_handle, id, fmt, ...) \
    trace_handle.log_multiline(id, EP7TRACE_LEVEL_WARNING, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOGM_ERROR(trace_handle, id, fmt, ...) \
    trace_handle.log_multiline(id, EP7TRACE_LEVEL_ERROR, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)

#define LOG_P7_LOGM_CRITICAL(trace_handle, id, fmt, ...) \
    trace_handle.log_multiline(id, EP7TRACE_LEVEL_CRITICAL, DEBUG_FILE_LINE_FUNCSIG_MAKE_A(), fmt, ## __VA_ARGS__)


namespace utility {
namespace log {
namespace p7logger {

    class p7ClientHandle;
    class p7TraceHandle;
    class p7TelemetryHandle;
    class p7TelemetryParamHandle;

    FORCE_INLINE p7ClientHandle p7_create_client(const std::string & cmd_line);
    FORCE_INLINE p7ClientHandle p7_create_client(const std::wstring & cmd_line);

    //// p7ClientHandle

    class p7ClientHandle : protected tackle::SmartHandle<IP7_Client>
    {
        friend p7ClientHandle p7_create_client(const std::string & cmd_line);
        friend p7ClientHandle p7_create_client(const std::wstring & cmd_line);

        using base_type = SmartHandle;

    public:
        static FORCE_INLINE const p7ClientHandle & null()
        {
            static const p7ClientHandle s_null = p7ClientHandle{ nullptr };
            return s_null;
        }

    protected:
        FORCE_INLINE static void _deleter(void * p)
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

        FORCE_INLINE IP7_Client * get() const
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

        FORCE_INLINE p7TraceHandle create_trace(const std::string & channel_name) const;
        FORCE_INLINE p7TraceHandle create_trace(const std::wstring & channel_name) const;

        FORCE_INLINE p7TraceHandle create_trace(const std::string & channel_name, const stTrace_Conf & config) const;
        FORCE_INLINE p7TraceHandle create_trace(const std::wstring & channel_name, const stTrace_Conf & config) const;

        FORCE_INLINE p7TelemetryHandle create_telemetry(const std::string & channel_name) const;
        FORCE_INLINE p7TelemetryHandle create_telemetry(const std::wstring & channel_name) const;

        FORCE_INLINE p7TelemetryHandle create_telemetry(const std::string & channel_name, const stTelemetry_Conf & config) const;
        FORCE_INLINE p7TelemetryHandle create_telemetry(const std::wstring & channel_name, const stTelemetry_Conf & config) const;
    };

    //// p7TraceHandle

    class p7TraceHandle : protected tackle::SmartHandle<IP7_Trace>
    {
        friend class p7ClientHandle;

        using base_type = SmartHandle;

    public:
        static FORCE_INLINE const p7TraceHandle & null()
        {
            static const p7TraceHandle s_null = p7TraceHandle{ nullptr };
            return s_null;
        }

    protected:
        FORCE_INLINE static void _deleter(void * p)
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
        FORCE_INLINE p7TraceHandle(IP7_Trace * p) :
            base_type(p, _deleter),
            m_hmodule(IP7_Trace::hModule{})
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
            m_hmodule = handle_rref.m_hmodule;
        }

        FORCE_INLINE IP7_Trace * get() const
        {
            return base_type::get();
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

        FORCE_INLINE bool register_thread(const std::string & thread_name, uint32_t thread_id)
        {
            IP7_Trace * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

#if defined(UTILITY_PLATFORM_WINDOWS)
            return p->Register_Thread(utility::convert_string_to_string(thread_name, utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{}).c_str(), thread_id) ? true : false;
#else
            return p->Register_Thread(thread_name.c_str(), thread_id) ? true : false;
#endif
        }

        FORCE_INLINE bool register_thread(const std::wstring & thread_name, uint32_t thread_id)
        {
            IP7_Trace * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

#if defined(UTILITY_PLATFORM_WINDOWS)
            return p->Register_Thread(thread_name.c_str(), thread_id) ? true : false;
#else
            return p->Register_Thread(utility::convert_string_to_string(thread_name, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{}).c_str(), thread_id) ? true : false;
#endif
        }

        FORCE_INLINE bool unregister_thread(uint32_t thread_id)
        {
            IP7_Trace * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            return p->Unregister_Thread(thread_id) ? true : false;
        }

        FORCE_INLINE bool register_module(const std::string & module_name, const utility::DebugFileLineFuncInlineStackA & inline_stack)
        {
            IP7_Trace * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        inline_stack.top.func, inline_stack.top.line));
            }

#if defined(UTILITY_PLATFORM_WINDOWS)
            return p->Register_Module(utility::convert_string_to_string(module_name, utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{}).c_str(), &m_hmodule) ? true : false;
#else
            return p->Register_Module(module_name.c_str(), &m_hmodule) ? true : false;
#endif
        }

        FORCE_INLINE bool register_module(const std::wstring & module_name, const utility::DebugFileLineFuncInlineStackA & inline_stack)
        {
            IP7_Trace * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        inline_stack.top.func, inline_stack.top.line));
            }

#if defined(UTILITY_PLATFORM_WINDOWS)
            return p->Register_Module(module_name.c_str(), &m_hmodule) ? true : false;
#else
            return p->Register_Module(utility::convert_string_to_string(module_name, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{}).c_str(), &m_hmodule) ? true : false;
#endif
        }

        template <typename ...Args>
        FORCE_INLINE bool log(uint16_t id, eP7Trace_Level lvl, const utility::DebugFileLineFuncInlineStackA & inline_stack, const std::string & fmt, Args... args) const
        {
            IP7_Trace * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        inline_stack.top.func, inline_stack.top.line));
            }

#if defined(UTILITY_PLATFORM_WINDOWS)
            std::wstring converted_fmt;
            std::wstring converted_args[sizeof...(args)];

            utility::convert_string_to_string(fmt, converted_fmt, utility::tag_string_conv_utf8_to_utf16{});

            size_t index = 0;
            for (const auto & arg : { args... }) {
                utility::convert_string_to_string(arg, converted_args[index], utility::tag_string_conv_utf8_to_utf16{});
                ++index;
            }

            return utility::apply_with_cast<bool>( // instead of apply
                [&](auto... converted_args)
                {
                    return p->Trace(id, lvl, m_hmodule, (tUINT16)inline_stack.top.line, inline_stack.top.file.c_str(), inline_stack.top.func.c_str(), converted_fmt.c_str(),
                        std::forward<decltype(converted_args)>(converted_args).c_str()...) ? true : false;
                },
                converted_args
            );
#else
            return p->Trace(id, lvl, m_hmodule, (tUINT16)inline_stack.top.line, inline_stack.top.file.c_str(), inline_stack.top.func.c_str(), fmt.c_str(), args...) ? true : false;
#endif
        }

        template <typename ...Args>
        FORCE_INLINE bool log_multiline(uint16_t id, eP7Trace_Level lvl, const utility::DebugFileLineFuncInlineStackA & inline_stack, const std::string & fmt, Args... args) const
        {
            IP7_Trace * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        inline_stack.top.func, inline_stack.top.line));
            }

#if defined(UTILITY_PLATFORM_WINDOWS)
            std::wstring converted_fmt;
            std::wstring converted_args[sizeof...(args)];

            utility::convert_string_to_string(fmt, converted_fmt, utility::tag_string_conv_utf8_to_utf16{});

            size_t index = 0;
            for (const auto & arg : { args... }) {
                utility::convert_string_to_string(arg, converted_args[index], utility::tag_string_conv_utf8_to_utf16{});
                ++index;
            }

            std::vector<std::wstring> && text_lines = utility::apply_with_cast<std::vector<std::wstring> >( // instead of apply
                [&](auto... converted_args)
                {
                    std::wstring text_buf = utility::string_format(1024, converted_fmt.c_str(),
                        std::forward<decltype(converted_args)>(converted_args).c_str()...);

                    std::vector<std::wstring> text_lines;

                    std::wistringstream text_stream_in{ text_buf, std::ios_base::in };

                    text_lines.reserve(64);

                    std::wstring line;

                    while (text_stream_in) {
                        if (!std::getline(text_stream_in, line)) {
                            break;
                        }
                        text_lines.push_back(line);
                    }

                    return std::move(text_lines);
                },
                converted_args
            );

            bool res_multiline = false;

            for(const auto & text_line : text_lines) {
                res_multiline |= p->Trace(id, lvl, m_hmodule, (tUINT16)inline_stack.top.line, inline_stack.top.file.c_str(), inline_stack.top.func.c_str(), L"%s",
                    text_line.c_str()) ? true : false;
            }

            return res_multiline;
#else
            return p->Trace(id, lvl, m_hmodule, (tUINT16)inline_stack.top.line, inline_stack.top.file.c_str(), inline_stack.top.func.c_str(), fmt.c_str(), args...) ? true : false;
#endif
        }

        template <typename ...Args>
        FORCE_INLINE bool log(uint16_t id, eP7Trace_Level lvl, const utility::DebugFileLineFuncInlineStackA & inline_stack, const std::wstring & fmt, Args... args) const
        {
            IP7_Trace * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        inline_stack.top.func, inline_stack.top.line));
            }

#if defined(UTILITY_PLATFORM_WINDOWS)
            return p->Trace(id, lvl, m_hmodule, (tUINT16)inline_stack.top.line, inline_stack.top.file.c_str(), inline_stack.top.func.c_str(), fmt.c_str(), args...) ? true : false;
#else
            std::string converted_fmt;
            std::string converted_args[sizeof...(args)];

            utility::convert_string_to_string(fmt, converted_fmt, utility::tag_string_conv_utf16_to_utf8{});

            size_t index = 0;
            for (const auto & arg : { args... }) {
                utility::convert_string_to_string(arg, converted_args[index], utility::tag_string_conv_utf16_to_utf8{});
                ++index;
            }

            return utility::apply_with_cast<bool>( // instead of apply
                [&](auto... converted_args)
                {
                    return p->Trace(id, lvl, m_hmodule, (tUINT16)inline_stack.top.line, inline_stack.top.file.c_str(), inline_stack.top.func.c_str(), converted_fmt.c_str(),
                        std::forward<decltype(converted_args)>(converted_args).c_str()...) ? true : false;
                },
                converted_args
            );
#endif
        }

        template <typename ...Args>
        FORCE_INLINE bool log_multiline(uint16_t id, eP7Trace_Level lvl, const utility::DebugFileLineFuncInlineStackA & inline_stack, const std::wstring & fmt, Args... args) const
        {
            IP7_Trace * p = get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        inline_stack.top.func, inline_stack.top.line));
            }

#if defined(UTILITY_PLATFORM_WINDOWS)
            return p->Trace(id, lvl, m_hmodule, (tUINT16)inline_stack.top.line, inline_stack.top.file.c_str(), inline_stack.top.func.c_str(), fmt.c_str(), args...) ? true : false;
#else
            std::string converted_fmt;
            std::string converted_args[sizeof...(args)];

            utility::convert_string_to_string(fmt, converted_fmt, utility::tag_string_conv_utf16_to_utf8{});

            size_t index = 0;
            for (const auto & arg : { args... }) {
                utility::convert_string_to_string(arg, converted_args[index], utility::tag_string_conv_utf16_to_utf8{});
                ++index;
            }

            std::vector<std::string> && text_lines = utility::apply_with_cast<std::vector<std::string> >( // instead of apply
                [&](auto... converted_args)
                {
                    std::string text_buf = utility::string_format(1024, converted_fmt.c_str(),
                        std::forward<decltype(converted_args)>(converted_args).c_str()...);

                    std::vector<std::string> text_lines;

                    std::istringstream text_stream_in{ text_buf, std::ios_base::in };

                    text_lines.reserve(64);

                    std::string line;

                    while (text_stream_in) {
                        if (!std::getline(text_stream_in, line)) {
                            break;
                        }
                        text_lines.push_back(line);
                    }

                    return std::move(text_lines);
                },
                converted_args
            );

            bool res_multiline = false;

            for(const auto & text_line : text_lines) {
                res_multiline |= p->Trace(id, lvl, m_hmodule, (tUINT16)inline_stack.top.line, inline_stack.top.file.c_str(), inline_stack.top.func.c_str(), "%s",
                    text_line.c_str()) ? true : false;
            }

            return res_multiline;
#endif
        }

    private:
        IP7_Trace::hModule  m_hmodule;
    };

    //// p7TelemetryHandle

    class p7TelemetryHandle : protected tackle::SmartHandle<IP7_Telemetry>
    {
        friend class p7ClientHandle;

        using base_type = SmartHandle;

    public:
        static FORCE_INLINE const p7TelemetryHandle & null()
        {
            static const p7TelemetryHandle s_null = p7TelemetryHandle{ nullptr };
            return s_null;
        }

    protected:
        FORCE_INLINE static void _deleter(void * p)
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
        FORCE_INLINE p7TelemetryHandle(IP7_Telemetry * p) :
            base_type(p, _deleter)
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

        FORCE_INLINE IP7_Telemetry * get() const
        {
            return base_type::get();
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

        FORCE_INLINE p7TelemetryParamHandle create_param(const std::string & param_catalog_name, int64_t min_value, int64_t max_value, int64_t alarm_value, bool is_enabled) const;
        FORCE_INLINE p7TelemetryParamHandle create_param(const std::wstring & param_catalog_name, int64_t min_value, int64_t max_value, int64_t alarm_value, bool is_enabled) const;
    };

    //// p7TelemetryParamHandle

    class p7TelemetryParamHandle : protected p7TelemetryHandle
    {
        friend class p7TelemetryHandle;

        using base_type = p7TelemetryHandle;

    public:
        static FORCE_INLINE const p7TelemetryParamHandle & null()
        {
            static const p7TelemetryParamHandle s_null = p7TelemetryParamHandle{ p7TelemetryHandle::null(), 0 };
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
        FORCE_INLINE p7TelemetryParamHandle(p7TelemetryHandle telemetry_handle, uint8_t param_id) :
            base_type(std::move(telemetry_handle)),
            m_param_id(param_id)
        {
        }

    public:
        FORCE_INLINE void reset(p7TelemetryParamHandle handle = p7TelemetryParamHandle::null())
        {
            base_type::reset(std::move(handle));
            m_param_id = handle.m_param_id;
        }

        FORCE_INLINE bool add(int64_t value)
        {
            IP7_Telemetry * p = base_type::get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
                    fmt::format("{:s}({:d}): null pointer dereference",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            return p->Add(m_param_id, value) ? true : false;
        }

        FORCE_INLINE uint8_t id() const
        {
            return m_param_id;
        }

    private:
        uint8_t m_param_id;
    };

    //// globals

    FORCE_INLINE p7ClientHandle p7_create_client(const std::string & cmd_line)
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        return p7ClientHandle{ P7_Create_Client(utility::convert_string_to_string(cmd_line, utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{}).c_str()) };
#else
        return p7ClientHandle{ P7_Create_Client(cmd_line.c_str()) };
#endif
    }

    FORCE_INLINE p7ClientHandle p7_create_client(const std::wstring & cmd_line)
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        return p7ClientHandle{ P7_Create_Client(cmd_line.c_str()) };
#else
        return p7ClientHandle{ P7_Create_Client(utility::convert_string_to_string(cmd_line, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{}).c_str()) };
#endif
    }

    //// p7ClientHandle

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const std::string & channel_name) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        return P7_Create_Trace(p, utility::convert_string_to_string(channel_name, utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{}).c_str());
#else
        return P7_Create_Trace(p, channel_name.c_str());
#endif
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const std::wstring & channel_name) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        return P7_Create_Trace(p, channel_name.c_str());
#else
        return P7_Create_Trace(p, utility::convert_string_to_string(channel_name, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{}).c_str());
#endif
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const std::string & channel_name, const stTrace_Conf & config) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        return P7_Create_Trace(p, utility::convert_string_to_string(channel_name, utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{}).c_str(), &config);
#else
        return P7_Create_Trace(p, channel_name.c_str(), &config);
#endif
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const std::wstring & channel_name, const stTrace_Conf & config) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        return P7_Create_Trace(p, channel_name.c_str(), &config);
#else
        return P7_Create_Trace(p, utility::convert_string_to_string(channel_name, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{}).c_str(), &config);
#endif
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const std::string & channel_name) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        return P7_Create_Telemetry(p, utility::convert_string_to_string(channel_name, utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{}).c_str());
#else
        return P7_Create_Telemetry(p, channel_name.c_str());
#endif
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const std::wstring & channel_name) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        return P7_Create_Telemetry(p, channel_name.c_str());
#else
        return P7_Create_Telemetry(p, utility::convert_string_to_string(channel_name, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{}).c_str());
#endif
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const std::string & channel_name, const stTelemetry_Conf & config) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        return P7_Create_Telemetry(p, utility::convert_string_to_string(channel_name, utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{}).c_str(), &config);
#else
        return P7_Create_Telemetry(p, channel_name.c_str(), &config);
#endif
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const std::wstring & channel_name, const stTelemetry_Conf & config) const
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

#if defined(UTILITY_PLATFORM_WINDOWS)
        return P7_Create_Telemetry(p, channel_name.c_str(), &config);
#else
        return P7_Create_Telemetry(p, utility::convert_string_to_string(channel_name, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{}).c_str(), &config);
#endif
    }

    //// p7TelemetryHandle

    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(const std::string & param_catalog_name, int64_t min_value, int64_t max_value, int64_t alarm_value, bool is_enabled) const
    {
        IP7_Telemetry * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

        tUINT8 param_id = 0;

#if defined(UTILITY_PLATFORM_WINDOWS)
        if (p->Create(utility::convert_string_to_string(param_catalog_name, utility::tag_wstring{}, utility::tag_string_conv_utf8_to_utf16{}).c_str(),
            min_value, max_value, alarm_value, is_enabled ? TRUE : FALSE, &param_id) ? true : false) {
            return p7TelemetryParamHandle{ *this, param_id };
        }
#else
        if (p->Create(param_catalog_name.c_str(), min_value, max_value, alarm_value, is_enabled ? TRUE : FALSE, &param_id) ? true : false) {
            return p7TelemetryParamHandle{ *this, param_id };
        }
#endif

        return p7TelemetryParamHandle::null();
    }

    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(const std::wstring & param_catalog_name, int64_t min_value, int64_t max_value, int64_t alarm_value, bool is_enabled) const
    {
        IP7_Telemetry * p = base_type::get();
        if (!p) {
            DEBUG_BREAK_THROW(true) std::runtime_error(
                fmt::format("{:s}({:d}): null pointer dereference",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
        }

        tUINT8 param_id = 0;

#if defined(UTILITY_PLATFORM_WINDOWS)
        if (p->Create(param_catalog_name.c_str(), min_value, max_value, alarm_value, is_enabled ? TRUE : FALSE, &param_id) ? true : false) {
            return p7TelemetryParamHandle{ *this, param_id };
        }
#else
        if (p->Create(utility::convert_string_to_string(channel_name, utility::tag_string{}, utility::tag_string_conv_utf16_to_utf8{}).c_str(),
            min_value, max_value, alarm_value, is_enabled ? TRUE : FALSE, &param_id) ? true : false) {
            return p7TelemetryParamHandle{ *this, param_id };
        }
#endif

        return p7TelemetryParamHandle::null();
    }

}
}
}

namespace tackle {

    using p7_client_log_handle              = t_log_handle<utility::log::p7logger::p7ClientHandle, 1>;
    using p7_trace_log_handle               = t_log_handle<utility::log::p7logger::p7TraceHandle, 2>;
    using p7_telemetry_log_handle           = t_log_handle<utility::log::p7logger::p7TelemetryHandle, 3>;
    using p7_telemetry_param_log_handle     = t_log_handle<utility::log::p7logger::p7TelemetryParamHandle, 4>;

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
    struct type_index_identity_base<log::p7logger::p7TelemetryHandle, 3> :
        type_index_identity<log::p7logger::p7TelemetryHandle, 3>
    {
    };

    template <>
    struct type_index_identity_base<log::p7logger::p7TelemetryParamHandle, 4> :
        type_index_identity<log::p7logger::p7TelemetryParamHandle, 4>
    {
    };

}
