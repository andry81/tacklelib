#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_ALIGNED_STORAGE_FROM_HPP
#define TACKLE_ALIGNED_STORAGE_FROM_HPP

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/type_traits.hpp>
#include <utility/assert.hpp>
#include <utility/memory.hpp>
#include <utility/utility.hpp>

#include <tackle/aligned_storage/aligned_storage_base.hpp>

#include <fmt/format.h>

#include <type_traits>
#include <new>
#include <stdexcept>
#include <typeinfo>


namespace tackle
{
    template <typename t_storage_type, typename t_tag_pttn_type = tag_pttn_default_t>
    class aligned_storage_from;

    // special designed class to store type which size and alignment is known (for example, type with deleted initialization constructor)
    template <typename t_storage_type, typename t_tag_pttn_type>
    class aligned_storage_from : public aligned_storage_base<t_storage_type, t_tag_pttn_type>
    {
    public:
        using base_t            = aligned_storage_base<t_storage_type, t_tag_pttn_type>;
        using storage_type_t    = t_storage_type;

        static const size_t size_value      = sizeof(storage_type_t);
        static const size_t alignment_value = std::alignment_of<storage_type_t>::value;

        using aligned_storage_t = typename std::aligned_storage<size_value, alignment_value>::type;

        FORCE_INLINE aligned_storage_from(bool enable_unconstructed_copy_ = false)
        {
            if (enable_unconstructed_copy_) {
                base_t::enable_unconstructed_copy();
            }
        }

        FORCE_INLINE ~aligned_storage_from()
        {
            // auto destruct ONLY if has lifetime control enabled
            if (base_t::has_construction_flag() && base_t::is_constructed()) {
                destruct();
            }
        }

        FORCE_INLINE aligned_storage_from(const aligned_storage_from & r) :
            base_t(r) // binding with the base
        {
            // just in case
            DEBUG_ASSERT_TRUE(base_t::has_construction_flag() && r.has_construction_flag());
            DEBUG_ASSERT_TRUE(!base_t::is_constructed());

            // at first, check if storage is constructed
            if (!r.is_constructed()) {
                if (!base_t::is_unconstructed_copy_allowed()) {
                    DEBUG_BREAK_IN_DEBUGGER(true);
                    throw std::runtime_error(fmt::format("{:s}({:d}): reference type is not constructed",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
                }
            }
            else {
                // make construction
                ::new (std::addressof(m_storage)) storage_type_t(*utility::cast_addressof<const storage_type_t *>(r.m_storage));

                // flag construction
                base_t::set_constructed(true);
            }
        }

        FORCE_INLINE aligned_storage_from & operator =(const aligned_storage_from & r)
        {
            this->base_t::operator =(r); // binding with the base

            // just in case
            DEBUG_ASSERT_TRUE(base_t::has_construction_flag() && r.has_construction_flag());

            // at first, check if both storages are constructed
            if (!base_t::is_constructed()) {
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::runtime_error(fmt::format("{:s}({:d}): this type is not constructed",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            if (!r.is_constructed()) {
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::runtime_error(fmt::format("{:s}({:d}): reference type is not constructed",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            // make assignment
            *utility::cast_addressof<storage_type_t *>(m_storage) = *utility::cast_addressof<const storage_type_t *>(r.m_storage);

            return *this;
        }

        // direct construction and destruction of the storage
        FORCE_INLINE void construct_default()
        {
            DEBUG_ASSERT_TRUE(!base_t::has_construction_flag() || !base_t::is_constructed());

            ::new (std::addressof(m_storage)) storage_type_t();

            // flag construction
            base_t::set_constructed(true);
        }

        template <typename Ref>
        FORCE_INLINE void construct(Ref & r)
        {
            DEBUG_ASSERT_TRUE(!base_t::has_construction_flag() || !base_t::is_constructed());

            ::new (std::addressof(m_storage)) storage_type_t(r);

            // flag construction
            base_t::set_constructed(true);
        }

        template <typename Ref>
        FORCE_INLINE void construct(const Ref & r)
        {
            DEBUG_ASSERT_TRUE(!base_t::has_construction_flag() || !base_t::is_constructed());

            ::new (std::addressof(m_storage)) storage_type_t(r);

            // flag construction
            base_t::set_constructed(true);
        }

        FORCE_INLINE void destruct()
        {
            DEBUG_ASSERT_TRUE(!base_t::has_construction_flag() || base_t::is_constructed());

            base_t::set_constructed(false);

            utility::cast_addressof<storage_type_t *>(m_storage)->storage_type_t::~storage_type_t();
        }

        template <typename Ref>
        FORCE_INLINE aligned_storage_from & assign(Ref & r)
        {
            DEBUG_ASSERT_TRUE(!base_t::has_construction_flag() || base_t::is_constructed());

            return *utility::cast_addressof<storage_type_t *>(m_storage) = r;
        }

        template <typename Ref>
        FORCE_INLINE aligned_storage_from & assign(const Ref & r)
        {
            DEBUG_ASSERT_TRUE(!base_t::has_construction_flag() || base_t::is_constructed());

            return *utility::cast_addressof<storage_type_t *>(m_storage) = r;
        }

        template <typename Ref>
        FORCE_INLINE aligned_storage_from & assign(Ref & r) volatile
        {
            DEBUG_ASSERT_TRUE(!base_t::has_construction_flag() || base_t::is_constructed());

            return *utility::cast_addressof<storage_type_t *>(m_storage) = r;
        }

        template <typename Ref>
        FORCE_INLINE aligned_storage_from & assign(const Ref & r) volatile
        {
            DEBUG_ASSERT_TRUE(!base_t::has_construction_flag() || base_t::is_constructed());

            return *utility::cast_addressof<storage_type_t *>(m_storage) = r;
        }

        // storage redirection
        FORCE_INLINE storage_type_t * this_()
        {
            if (!base_t::is_constructed()) {
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::runtime_error(fmt::format("{:s}({:d}): this type is not constructed",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            return static_cast<storage_type_t *>(address());
        }

        FORCE_INLINE const storage_type_t * this_() const
        {
            if (!base_t::is_constructed()) {
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::runtime_error(fmt::format("{:s}({:d}): this type is not constructed",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            return reinterpret_cast<const storage_type_t *>(address());
        }

        FORCE_INLINE volatile storage_type_t * this_() volatile
        {
            if (!base_t::is_constructed()) {
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::runtime_error(fmt::format("{:s}({:d}): this type is not constructed",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            return reinterpret_cast<volatile storage_type_t *>(address());
        }

        FORCE_INLINE const volatile storage_type_t * this_() const volatile
        {
            if (!base_t::is_constructed()) {
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::runtime_error(fmt::format("{:s}({:d}): this type is not constructed",
                    UTILITY_PP_FUNCSIG, UTILITY_PP_LINE));
            }

            return reinterpret_cast<const volatile storage_type_t *>(address());
        }

        FORCE_INLINE void * address()
        {
            return std::addressof(m_storage);
        }

        FORCE_INLINE const void * address() const
        {
            return std::addressof(m_storage);
        }

        FORCE_INLINE volatile void * address() volatile
        {
            return std::addressof(m_storage);
        }

        FORCE_INLINE const volatile void * address() const volatile
        {
            return std::addressof(m_storage);
        }

    private:
        aligned_storage_t m_storage;
    };
}

#endif
