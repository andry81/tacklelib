#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_ALIGNED_STORAGE_DECL_HPP
#define TACKLE_ALIGNED_STORAGE_DECL_HPP

#include <utility/platform.hpp>

#include <boost/aligned_storage.hpp>


#define TACKLE_ALIGNED_STORAGE_BY_INSTANCE_TOKEN(size_of, align_of, tag_pttn_type) \
    UTILITY_PP_CONCAT6(size_, size_of, _align_, align_of, _pttn_, tag_pttn_type)


namespace tackle
{
    // public interface ONLY

    using tag_pttn_control_lifetime_t = struct tag_pttn_control_lifetime_;
    using tag_pttn_default_t = struct tag_pttn_default_;

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type = tag_pttn_default_t>
    class aligned_storage_by
    {
        boost::aligned_storage<t_size_value, t_alignment_value> m_storage;
    };
}

#endif
