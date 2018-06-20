#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_VARIANT_DECL_HPP
#define TACKLE_VARIANT_DECL_HPP

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/type_traits.hpp>
#include <utility/assert.hpp>
#include <utility/memory.hpp>

#include <tackle/variant.hpp>

#include <boost/mpl/vector.hpp>

#include <stdexcept>
#include <typeinfo>


namespace tackle
{
    namespace mpl = boost::mpl;

    //// variant

    template <typename T0, typename T1>
    class variant
    {
    private:
        using storage_types_t           = mpl::vector<T0, T1>;

    public:
        using max_aligned_storage_t     = max_aligned_storage_from_mpl_container<storage_types_t, tag_pttn_control_lifetime_t>;

        FORCE_INLINE variant()
        {
        }

        FORCE_INLINE variant(const T0 & v0)
        {
            reset(v0);
        }

        FORCE_INLINE variant(const T1 & v1)
        {
            reset(v1);
        }

        FORCE_INLINE variant(const variant & variant)
        {
            reset(variant);
        }

        FORCE_INLINE variant & operator =(const variant & variant)
        {
            reset(variant);
            return *this;
        }

        FORCE_INLINE bool is_constructed() const
        {
            return m_aligned_storage.is_constructed();
        }

        FORCE_INLINE int type_index() const
        {
            return m_aligned_storage.type_index();
        }

        FORCE_INLINE void reset(const T0 & v0)
        {
            const int type_index = m_aligned_storage.type_index();
            if (type_index != -1 && type_index != 0) {
                m_aligned_storage.destruct();
            }

            if (m_aligned_storage.is_constructed()) {
                m_aligned_storage.assign(v0);
            } else {
                m_aligned_storage.construct(0, v0, false);
            }
        }

        FORCE_INLINE void reset(const T1 & v1)
        {
            const int type_index = m_aligned_storage.type_index();
            if (type_index != -1 && type_index != 1) {
                m_aligned_storage.destruct();
            }

            if (m_aligned_storage.is_constructed()) {
                m_aligned_storage.assign(v1);
            }
            else {
                m_aligned_storage.construct(1, v1, false);
            }
        }

        FORCE_INLINE void reset(const variant & variant)
        {
            if (this == &variant) {
                return;
            }

            switch (type_index()) {
            case -1: {
                switch (variant.type_index()) {
                case 0: {
                    const auto & ref0 = variant.get(utility::int_identity<0>());
                    m_aligned_storage.construct(0, ref0, false);
                } break;

                case 1: {
                    const auto & ref1 = variant.get(utility::int_identity<1>());
                    m_aligned_storage.construct(1, ref1, false);
                } break;

                default:
                    DEBUG_ASSERT_TRUE(false);
                }
            } break;

            case 0: {
                const int type_index = variant.type_index();
                if (type_index != -1 && type_index != 0) {
                    m_aligned_storage.destruct();
                }

                const auto & ref0 = variant.get(utility::int_identity<0>());

                if (m_aligned_storage.is_constructed()) {
                    m_aligned_storage.assign(ref0);
                }
                else {
                    m_aligned_storage.construct(0, ref0, false);
                }
            } break;

            case 1: {
                const int type_index = variant.type_index();
                if (type_index != -1 && type_index != 1) {
                    m_aligned_storage.destruct();
                }

                const auto & ref1 = variant.get(utility::int_identity<1>());

                if (m_aligned_storage.is_constructed()) {
                    m_aligned_storage.assign(ref1);
                }
                else {
                    m_aligned_storage.construct(1, ref1, false);
                }
            } break;

            default:
                DEBUG_ASSERT_TRUE(false);
            }
        }

        FORCE_INLINE T0 & get(utility::int_identity<0>)
        {
            if (m_aligned_storage.type_index() != 0) {
                throw std::bad_cast();
            }

            // CAUTION:
            //  After this point if lambda return parameter is not convertible to declared return type, then return value does return as unconstructed!
            //

            return m_aligned_storage.template invoke_if_returnable<T0 &>([=](auto & v0) -> T0 &
            {
                return v0;
            });
        }

        FORCE_INLINE const T0 & get(utility::int_identity<0>) const
        {
            if (m_aligned_storage.type_index() != 0) {
                throw std::bad_cast();
            }

            // CAUTION:
            //  After this point if lambda return parameter is not convertible to declared return type, then return value does return as unconstructed!
            //

            return m_aligned_storage.template invoke_if_returnable<const T0 &>([=](const auto & v0) -> const T0 &
            {
                return v0;
            });
        }

        FORCE_INLINE T1 & get(utility::int_identity<1>)
        {
            if (m_aligned_storage.type_index() != 1) {
                throw std::bad_cast();
            }

            // CAUTION:
            //  After this point if lambda return parameter is not convertible to declared return type, then return value does return as unconstructed!
            //

            return m_aligned_storage.template invoke_if_returnable<T1 &>([=](auto & v1) -> T1 &
            {
                return v1;
            });
        }

        FORCE_INLINE const T1 & get(utility::int_identity<1>) const
        {
            if (m_aligned_storage.type_index() != 1) {
                throw std::bad_cast();
            }

            // CAUTION:
            //  After this point if lambda return parameter is not convertible to declared return type, then return value does return as unconstructed!
            //

            return m_aligned_storage.template invoke_if_returnable<const T1 &>([=](const auto & v1) -> const T1 &
            {
                return v1;
            });
        }

        FORCE_INLINE max_aligned_storage_t & get()
        {
            return m_aligned_storage;
        }

        FORCE_INLINE const max_aligned_storage_t & get() const
        {
            return m_aligned_storage;
        }

    private:
        max_aligned_storage_t   m_aligned_storage;
    };
}

#endif
