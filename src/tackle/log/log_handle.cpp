#include <src/tacklelib_private.hpp>

#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_LOG_P7_LOGGER)

#include <tacklelib/tackle/log/log_handle.hpp>

#include <src/utility/log/p7logger/p7_logger.hpp>

namespace tackle
{
    template class t_interface_handle<log_handle, utility::log::p7logger::p7ClientHandle, 1>;
    template class t_interface_handle<log_handle, utility::log::p7logger::p7TraceHandle, 2>;
    template class t_interface_handle<log_handle, utility::log::p7logger::p7TraceModule, 3>;
    template class t_interface_handle<log_handle, utility::log::p7logger::p7TelemetryHandle, 4>;
    template class t_interface_handle<log_handle, utility::log::p7logger::p7TelemetryParamHandle, 5>;
}

#endif
