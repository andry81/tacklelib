#pragma once

#include <boost/aligned_storage.hpp>


namespace tackle
{
    // public interface ONLY

    typedef struct tag_pttn_control_lifetime_ tag_pttn_control_lifetime_t;
    typedef struct tag_pttn_default_ tag_pttn_default_t;

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type = tag_pttn_default_t>
    class aligned_storage_by
    {
        boost::aligned_storage<t_size_value, t_alignment_value> m_storage;
    };
}
