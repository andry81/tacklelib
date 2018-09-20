#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_ALIGNED_STORAGE_BASE_HPP
#define TACKLE_ALIGNED_STORAGE_BASE_HPP

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/utility.hpp>

#include <cstdio>
#include <stdexcept>


#define TACKLE_ALIGNED_STORAGE_BY_INSTANCE_TOKEN(size_of, align_of, tag_pttn_type) \
    UTILITY_PP_CONCAT6(size_, size_of, _align_, align_of, _pttn_, tag_pttn_type)


namespace tackle
{
    // CAUTION:
    //  Special tag pattern type to use the aligned storage with enabled (not deleted) copy constructor and assignment operator
    //  with explicit flag of constructed state (it is dangerous w/o the flag because being copied or assigned type can be not yet constructed!).
    //
    using tag_pttn_control_lifetime_t   = struct tag_pttn_control_lifetime_;
    using tag_pttn_default_t            = struct tag_pttn_default_;

    template <typename tag_pttn>
    class aligned_storage_base
    {
    public:
        FORCE_INLINE aligned_storage_base()
        {
        }

        aligned_storage_base(const aligned_storage_base &) = delete; // use explicit `construct` instead
        aligned_storage_base & operator =(const aligned_storage_base &) = delete; // use explicit `assign` instead

        FORCE_INLINE bool is_constructed() const
        {
            return true;    // external control, always treats as constructed
        }

        FORCE_INLINE bool is_constructed() const volatile
        {
            return true;    // external control, always treats as constructed
        }

        FORCE_INLINE bool is_unconstructed_copy_allowed() const
        {
            return false;   // must be always constructed
        }

        FORCE_INLINE bool has_construction_flag() const
        {
            return false;
        }

    protected:
        FORCE_INLINE void set_constructed(bool is_constructed)
        {
            // DO NOTHING
            UTILITY_UNUSED_STATEMENT(is_constructed);
        }

        // unsafe
        FORCE_INLINE void enable_unconstructed_copy()
        {
            char fmt_buf[256];
            snprintf(fmt_buf, utility::static_size(fmt_buf), "%s: not implemented", UTILITY_PP_FUNCSIG);
            DEBUG_BREAK_IN_DEBUGGER(true);
            throw std::runtime_error(fmt_buf);
        }
    };

    template <>
    class aligned_storage_base<tag_pttn_control_lifetime_t>
    {
        enum Flags
        {
            Flag_None                       = 0,
            Flag_IsConstructed              = 0x01,
            Flag_IsUnconstractedCopyAllowed = 0x02  // unsafe
        };

    public:
        FORCE_INLINE aligned_storage_base() :
            m_flags(Flag_None)
        {
        }

        FORCE_INLINE aligned_storage_base(const aligned_storage_base &)
        {
            // DO NOT COPY FLAG HERE!
        }

        FORCE_INLINE aligned_storage_base & operator =(const aligned_storage_base &)
        {
            // DO NOT COPY FLAG HERE!
            return *this;
        }

        FORCE_INLINE bool is_constructed() const
        {
            return (m_flags & Flag_IsConstructed) ? true : false;
        }

        FORCE_INLINE bool is_constructed() const volatile
        {
            return (m_flags & Flag_IsConstructed) ? true : false;
        }

        FORCE_INLINE bool is_unconstructed_copy_allowed() const
        {
            return (m_flags & Flag_IsUnconstractedCopyAllowed) ? true : false;
        }

        FORCE_INLINE bool has_construction_flag() const
        {
            return true;
        }

    protected:
        FORCE_INLINE void set_constructed(bool is_constructed_)
        {
            m_flags = Flags(m_flags | (is_constructed_ ? Flag_IsConstructed : Flag_None));
        }

        // unsafe
        FORCE_INLINE void enable_unconstructed_copy()
        {
            m_flags = Flags(m_flags | Flag_IsUnconstractedCopyAllowed);
        }

    protected:
        Flags m_flags;
    };
}

#endif
