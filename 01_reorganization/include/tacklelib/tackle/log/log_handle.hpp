#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_LOG_LOG_HANDLE_HPP
#define TACKLE_LOG_LOG_HANDLE_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>

#include <tacklelib/tackle/interface_handle.hpp>

#include <memory>
#include <string>
#include <utility>

#undef LIBRARY_API_NAMESPACE
#define LIBRARY_API_NAMESPACE TACKLELIB
#include <tacklelib/utility/library_api_define.hpp>


// public interface class holder of private logger types

namespace tackle {

    using log_handle        = interface_handle;
    using log_handle_ptr    = std::shared_ptr<log_handle>;

    template <class TBase, int TypeIndex>
    using t_log_handle      = t_interface_handle<log_handle, TBase, TypeIndex>;

    // input only parameters

    struct LIBRARY_API_DECL log_client_params_in
    {
        const log_handle &  handle;
        const std::string   channel_name;
    };

    struct LIBRARY_API_DECL log_channel_params_in
    {
        const std::string & module_name;
        const uint32_t      id;
    };

    struct LIBRARY_API_DECL log_trace_params_in
    {
        log_handle &        handle;
        const log_handle &  module; // has to be duplicated
        const uint32_t      id;
    };

}

#endif
