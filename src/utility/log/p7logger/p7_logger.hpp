#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/debug.hpp>
#include <utility/assert.hpp>

#include <tackle/smart_handle.hpp>

#include <boost/format.hpp>

#include "P7_Trace.h"
#include "P7_Telemetry.h"

#include <cstdio>
#include <cstdint>
#include <stdexcept>
#include <string>


#define LOG_P7_APP_INIT() \
    {{ P7_Set_Crash_Handler(); }} (void)0

#define LOG_P7_CREATE_CLIENT(cmd_line_w) \
    ::p7logger::p7_create_client(cmd_line_w)

#define LOG_P7_CREATE_TRACE(client, channel_name_w) \
    client.create_trace(channel_name_w)

#define LOG_P7_CREATE_TRACE2(client, channel_name_w, config) \
    client.create_trace(channel_name_w, config)

#define LOG_P7_CREATE_TELEMETRY(client, channel_name_w) \
    client.create_telemetry(channel_name_w)

#define LOG_P7_CREATE_TELEMETRY2(client, channel_name_w, config) \
    client.create_telemetry(channel_name_w, config)

#define LOG_P7_CREATE_TELEMETRY_PARAM(telemetry, param_catalog_name_w, min_value, max_value, alarm_value, is_enabled) \
    telemetry.create_param(param_catalog_name_w, min_value, max_value, alarm_value, is_enabled)


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


namespace utility {
namespace log {
namespace p7logger {

    class p7ClientHandle;
    class p7TraceHandle;
    class p7TelemetryHandle;
    class p7TelemetryParamHandle;

    FORCE_INLINE p7ClientHandle p7_create_client(const std::wstring & cmd_line);

    //// p7ClientHandle

    class p7ClientHandle : protected tackle::SmartHandle<IP7_Client>
    {
        friend p7ClientHandle p7_create_client(const std::wstring & cmd_line);

        using base_type = SmartHandle;

    public:
        static const p7ClientHandle s_null;

    private:
        FORCE_INLINE static void _deleter(void * p)
        {
            if (p) {
                static_cast<IP7_Client *>(p)->Release();
            }
        }

    public:
        FORCE_INLINE p7ClientHandle()
        {
            *this = s_null;
        }

        FORCE_INLINE p7ClientHandle(const p7ClientHandle &) = default;

    private:
        FORCE_INLINE p7ClientHandle(IP7_Client * p) :
            base_type(p, _deleter)
        {
        }

    public:
        static FORCE_INLINE p7ClientHandle null()
        {
            return p7ClientHandle{ nullptr };
        }

        FORCE_INLINE void reset(const p7ClientHandle & handle = p7ClientHandle::s_null)
        {
            auto * deleter = DEBUG_VERIFY_TRUE(std::get_deleter<base_type::DeleterType>(handle.m_pv));
            if (!deleter) {
                // must always have a deleter
                throw std::runtime_error((boost::format("%s(%u): deleter is not allocated") %
                    UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
            }

            base_type::reset(handle.get(), *deleter);
        }

        FORCE_INLINE IP7_Client * get() const
        {
            return base_type::get();
        }

        FORCE_INLINE IP7_Client * operator ->() const
        {

            IP7_Client * p = get();
            if (!p) {
                throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                    UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
            }

            return p;
        }

        FORCE_INLINE IP7_Client & operator *() const
        {
            return *this->operator->();
        }

        FORCE_INLINE p7TraceHandle create_trace(const std::wstring & channel_name);
        FORCE_INLINE p7TraceHandle create_trace(const std::wstring & channel_name, const stTrace_Conf & config);

        FORCE_INLINE p7TelemetryHandle create_telemetry(const std::wstring & channel_name);
        FORCE_INLINE p7TelemetryHandle create_telemetry(const std::wstring & channel_name, const stTelemetry_Conf & config);
    };

    //// p7TraceHandle

    class p7TraceHandle : protected tackle::SmartHandle<IP7_Trace>
    {
        friend class p7ClientHandle;

        using base_type = SmartHandle;

    public:
        static const p7TraceHandle s_null;

    private:
        FORCE_INLINE static void _deleter(void * p)
        {
            if (p) {
                static_cast<IP7_Trace *>(p)->Release();
            }
        }

    public:
        FORCE_INLINE p7TraceHandle()
        {
            *this = s_null;
        }

        FORCE_INLINE p7TraceHandle(const p7TraceHandle &) = default;

    private:
        FORCE_INLINE p7TraceHandle(IP7_Trace * p) :
            base_type(p, _deleter),
            m_hmodule(IP7_Trace::hModule{})
        {
        }

    public:
        static FORCE_INLINE p7TraceHandle null()
        {
            return p7TraceHandle{ nullptr };
        }

        FORCE_INLINE void reset(const p7TraceHandle & handle = p7TraceHandle::s_null)
        {
            auto * deleter = DEBUG_VERIFY_TRUE(std::get_deleter<base_type::DeleterType>(handle.m_pv));
            if (!deleter) {
                // must always have a deleter
                throw std::runtime_error((boost::format("%s(%u): deleter is not allocated") %
                    UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
            }

            base_type::reset(handle.get(), *deleter);
            m_hmodule = handle.m_hmodule;
        }

        FORCE_INLINE IP7_Trace * get() const
        {
            return base_type::get();
        }

        FORCE_INLINE IP7_Trace * operator ->() const
        {

            IP7_Trace * p = get();
            if (!p) {
                throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                    UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
            }

            return p;
        }

        FORCE_INLINE IP7_Trace & operator *() const
        {
            return *this->operator->();
        }

        FORCE_INLINE bool register_thread(const std::wstring & thread_name, uint32_t thread_id)
        {
            IP7_Trace * p = get();
            if (!p) {
                throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                    UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
            }

            return p->Register_Thread(thread_name.c_str(), thread_id) ? true : false;
        }

        FORCE_INLINE bool unregister_thread(uint32_t thread_id)
        {
            IP7_Trace * p = get();
            if (!p) {
                throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                    UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
            }

            return p->Unregister_Thread(thread_id) ? true : false;
        }

        FORCE_INLINE bool register_module(const std::wstring & module_name, const utility::DebugFileLineFuncInlineStackA & inline_stack)
        {
            IP7_Trace * p = get();
            if (!p) {
                throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                    UTILITY_PP_FUNCSIG % inline_stack.top.line).str());
            }

            return p->Register_Module(module_name.c_str(), &m_hmodule) ? true : false;
        }

        template <typename ...Args>
        FORCE_INLINE bool log(uint16_t id, eP7Trace_Level lvl, const utility::DebugFileLineFuncInlineStackA & inline_stack, const std::wstring & fmt, Args... args)
        {
            IP7_Trace * p = get();
            if (!p) {
                throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                    inline_stack.top.func % inline_stack.top.line).str());
            }

            return p->Trace(id, lvl, m_hmodule, (tUINT16)inline_stack.top.line, inline_stack.top.file, inline_stack.top.func, fmt.c_str(), args...);
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
        static const p7TelemetryHandle s_null;

    private:
        FORCE_INLINE static void _deleter(void * p)
        {
            if (p) {
                static_cast<IP7_Telemetry *>(p)->Release();
            }
        }

    public:
        FORCE_INLINE p7TelemetryHandle()
        {
            *this = s_null;
        }

        FORCE_INLINE p7TelemetryHandle(const p7TelemetryHandle &) = default;

    private:
        FORCE_INLINE p7TelemetryHandle(IP7_Telemetry * p) :
            base_type(p, _deleter)
        {
        }

    public:
        static FORCE_INLINE p7TelemetryHandle null()
        {
            return p7TelemetryHandle{ nullptr };
        }

        FORCE_INLINE void reset(const p7TelemetryHandle & handle = p7TelemetryHandle::s_null)
        {
            auto * deleter = DEBUG_VERIFY_TRUE(std::get_deleter<base_type::DeleterType>(handle.m_pv));
            if (!deleter) {
                // must always have a deleter
                throw std::runtime_error((boost::format("%s(%u): deleter is not allocated") %
                    UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
            }

            base_type::reset(handle.get(), *deleter);
        }

        FORCE_INLINE IP7_Telemetry * get() const
        {
            return base_type::get();
        }

        FORCE_INLINE IP7_Telemetry * operator ->() const
        {

            IP7_Telemetry * p = get();
            if (!p) {
                throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                    UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
            }

            return p;
        }

        FORCE_INLINE IP7_Telemetry & operator *() const
        {
            return *this->operator->();
        }

        FORCE_INLINE p7TelemetryParamHandle create_param(const std::wstring & param_catalog_name, int64_t min_value, int64_t max_value, int64_t alarm_value, bool is_enabled);
    };

    //// p7TelemetryParamHandle

    class p7TelemetryParamHandle : protected p7TelemetryHandle
    {
        friend class p7TelemetryHandle;

        using base_type = p7TelemetryHandle;

    public:
        static const p7TelemetryParamHandle s_null;

    public:
        FORCE_INLINE p7TelemetryParamHandle()
        {
            *this = s_null;
        }

        FORCE_INLINE p7TelemetryParamHandle(const p7TelemetryParamHandle &) = default;

    private:
        FORCE_INLINE p7TelemetryParamHandle(const p7TelemetryHandle & telemetry_handle, uint8_t param_id) :
            base_type(telemetry_handle),
            m_param_id(param_id)
        {
        }

    public:
        static FORCE_INLINE p7TelemetryParamHandle null()
        {
            return p7TelemetryParamHandle{ p7TelemetryHandle::s_null, 0 };
        }

        FORCE_INLINE void reset(const p7TelemetryParamHandle & handle = p7TelemetryParamHandle::s_null)
        {
            base_type::reset(handle);
            m_param_id = handle.m_param_id;
        }

        FORCE_INLINE bool add(int64_t value)
        {
            IP7_Telemetry * p = base_type::get();
            if (!p) {
                throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                    UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
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

    FORCE_INLINE p7ClientHandle p7_create_client(const std::wstring & cmd_line)
    {
        return p7ClientHandle{ P7_Create_Client(cmd_line.c_str()) };
    }

    //// p7ClientHandle

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const std::wstring & channel_name)
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
        }

        return P7_Create_Trace(p, channel_name.c_str());
    }

    FORCE_INLINE p7TraceHandle p7ClientHandle::create_trace(const std::wstring & channel_name, const stTrace_Conf & config)
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
        }

        return P7_Create_Trace(p, channel_name.c_str(), &config);
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const std::wstring & channel_name)
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
        }

        return P7_Create_Telemetry(p, channel_name.c_str());
    }

    FORCE_INLINE p7TelemetryHandle p7ClientHandle::create_telemetry(const std::wstring & channel_name, const stTelemetry_Conf & config)
    {
        IP7_Client * p = base_type::get();
        if (!p) {
            throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
        }

        return P7_Create_Telemetry(p, channel_name.c_str(), &config);
    }

    //// p7TelemetryHandle

    FORCE_INLINE p7TelemetryParamHandle p7TelemetryHandle::create_param(const std::wstring & param_catalog_name, int64_t min_value, int64_t max_value, int64_t alarm_value, bool is_enabled)
    {
        IP7_Telemetry * p = base_type::get();
        if (!p) {
            throw std::runtime_error((boost::format("%s(%u): null pointer dereference") %
                UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
        }

        tUINT8 param_id = 0;
        if (p->Create(param_catalog_name.c_str(), min_value, max_value, alarm_value, is_enabled ? TRUE : FALSE, &param_id) ? true : false) {
            return p7TelemetryParamHandle{ *this, param_id };
        }

        return p7TelemetryParamHandle::s_null;
    }
}
}
}
