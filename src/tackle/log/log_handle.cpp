#include <tackle/log/log_handle.hpp>

#include <utility/log/p7logger/p7_logger.hpp>


namespace tackle
{
    template class t_interface_handle<log_handle, utility::log::p7logger::p7ClientHandle, 1>;
    template class t_interface_handle<log_handle, utility::log::p7logger::p7TraceHandle, 2>;
    template class t_interface_handle<log_handle, utility::log::p7logger::p7TelemetryHandle, 3>;
    template class t_interface_handle<log_handle, utility::log::p7logger::p7TelemetryParamHandle, 4>;
}
