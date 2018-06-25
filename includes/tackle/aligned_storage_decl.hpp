#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_ALIGNED_STORAGE_DECL_HPP
#define TACKLE_ALIGNED_STORAGE_DECL_HPP

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/type_traits.hpp>
#include <utility/assert.hpp>
#include <utility/memory.hpp>

#include <tackle/aligned_storage_base.hpp>

#include <type_traits>


namespace tackle
{
    // public interface ONLY

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type = tag_pttn_default_t>
    class aligned_storage_by : public aligned_storage_base<t_tag_pttn_type>
    {
    private:
        typename std::aligned_storage<t_size_value, t_alignment_value>::type m_storage;
    };
}

#endif
