#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_ALIGNED_STORAGE_DECL_HPP
#define TACKLE_ALIGNED_STORAGE_DECL_HPP

#include <utility/platform.hpp>

#include <tackle/aligned_storage_base.hpp>

#include <boost/aligned_storage.hpp>


namespace tackle
{
    // public interface ONLY

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type = tag_pttn_default_t>
    class aligned_storage_by : public aligned_storage_base<t_tag_pttn_type>
    {
        boost::aligned_storage<t_size_value, t_alignment_value> m_storage;
    };
}

#endif
