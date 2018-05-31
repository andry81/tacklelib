#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_MEMORY_HPP
#define UTILITY_MEMORY_HPP

#include <tacklelib.hpp>

#include <utility/math.hpp>

#include <cstdint>
#include <memory>


namespace utility
{
    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(From & v)
    {
        return static_cast<To>((void *)std::addressof(v));
    }

    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(const From & v)
    {
        return static_cast<To>((const void *)std::addressof(v));
    }

    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(volatile From & v)
    {
        return static_cast<To>((volatile void *)std::addressof(v));
    }

    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(const volatile From & v)
    {
        return static_cast<To>((const volatile void *)std::addressof(v));
    }

    enum MemoryType
    {
        MemType_VirtualMemory   = 1,
        MemType_PhysicalMemory  = 2
    };

    // proc_id:
    //  0               - current process
    //  *               - target process
    uint64_t get_process_memory_size(MemoryType mem_type, size_t proc_id);
}

#endif
