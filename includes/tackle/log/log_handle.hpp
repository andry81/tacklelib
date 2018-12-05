#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>

#include <tackle/interface_handle.hpp>

#include <utility>


// public interface class holder of private logger types

namespace tackle {

    using log_handle = interface_handle;

    template <class TBase, int TypeIndex>
    using t_log_handle = t_interface_handle<log_handle, TBase, TypeIndex>;

}