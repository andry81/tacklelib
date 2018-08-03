#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_MEMORY_HPP
#define UTILITY_MEMORY_HPP

#include <tacklelib.hpp>

#include <utility/math.hpp>

#include <type_traits>

#include <cstdint>
#include <memory>


#ifndef UTILITY_PLATFORM_FEATURE_CXX_STANDARD_MAKE_UNIQUE

// std::make_unique is supported from C++14.
// implementation taken from C++ ISO papers: https://isocpp.org/files/papers/N3656.txt
//
namespace std
{
    template <typename T, typename D>
    class unique_ptr;

    namespace detail
    {
        template<class T>
        struct _unique_if
        {
            typedef unique_ptr<T> _single_object;
        };

        template<class T>
        struct _unique_if<T[]>
        {
            typedef unique_ptr<T[]> _unknown_bound;
        };

        template<class T, size_t N>
        struct _unique_if<T[N]>
        {
            typedef void _known_bound;
        };
    }

    template<class T, class... Args>
    inline typename detail::_unique_if<T>::_single_object make_unique(Args &&... args)
    {
        return unique_ptr<T>(new T(std::forward<Args>(args)...));
    }

    template<class T>
    inline typename detail::_unique_if<T>::_unknown_bound make_unique(size_t n)
    {
        typedef typename remove_extent<T>::type U;
        return unique_ptr<T>(new U[n]());
    }

    template<class T, class... Args>
    typename detail::_unique_if<T>::_known_bound make_unique(Args &&...) = delete;
}

#endif

namespace utility
{
    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(From & v)
    {
        return static_cast<To>(static_cast<void *>(std::addressof(v)));
    }

    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(const From & v)
    {
        return static_cast<To>(static_cast<const void *>(std::addressof(v)));
    }

    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(volatile From & v)
    {
        return static_cast<To>(static_cast<volatile void *>(std::addressof(v)));
    }

    template <typename To, typename From>
    FORCE_INLINE To cast_addressof(const volatile From & v)
    {
        return static_cast<To>(static_cast<const volatile void *>(std::addressof(v)));
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
