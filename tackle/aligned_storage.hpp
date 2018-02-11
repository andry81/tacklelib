#pragma once


#include "tacklelib.hpp"

#include "utility/platform.hpp"
#include "utility/static_assert.hpp"
#include "utility/type_traits.hpp"
#include "utility/assert.hpp"

#include <boost/preprocessor/repeat.hpp>
#include <boost/preprocessor/cat.hpp>

#include <boost/aligned_storage.hpp>

#include <boost/type_traits/alignment_of.hpp>
#include <boost/type_traits/is_same.hpp>
#include <boost/type_traits/is_convertible.hpp>
#include <boost/type_traits/remove_reference.hpp>
#include <boost/type_traits/remove_cv.hpp>

#include <boost/mpl/if.hpp>
#include <boost/mpl/less.hpp>
#include <boost/mpl/at.hpp>
#include <boost/mpl/size.hpp>
#include <boost/mpl/void.hpp>
#include <boost/mpl/find.hpp>
#include <boost/mpl/end.hpp>
#include <boost/mpl/sizeof.hpp>
#include <boost/mpl/max_element.hpp>
#include <boost/mpl/transform_view.hpp>
#include <boost/mpl/identity.hpp>

#include <boost/scope_exit.hpp>

#include <boost/format.hpp>

// alignof_ headers
#include <boost/mpl/size_t.hpp>
#include <boost/mpl/aux_/na_spec.hpp>
#include <boost/mpl/aux_/lambda_support.hpp>

#include <new>
#include <stdexcept>


#define TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES 32 // for the builtin switch-case generator


// alignof mpl style implementation (namespace injection) the same way as the `mpl::sizeof_` did
namespace boost {
namespace mpl {
    template<
        typename BOOST_MPL_AUX_NA_PARAM(T)
    >
    struct alignof_
        : mpl::size_t< boost::alignment_of<T>::value >
    {
        BOOST_MPL_AUX_LAMBDA_SUPPORT(1, alignof_, (T))
    };

    BOOST_MPL_AUX_NA_SPEC_NO_ETI(1, alignof_)
}
}

namespace tackle
{
    namespace mpl = boost::mpl;

    // CAUTION:
    //  Special tag pattern type to use the aligned storage with enabled (not deleted) copy constructor and assignment operator
    //  with explicit flag of constructed state (it is dengerous w/o the flag because being copied or assigned type can be not yet constructed!).
    //
    typedef struct tag_pttn_control_lifetime_ tag_pttn_control_lifetime_t;
    typedef struct tag_pttn_default_ tag_pttn_default_t;

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
            return true; // external control, always treats as constructed
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
    };

    template <>
    class aligned_storage_base<tag_pttn_control_lifetime_t>
    {
    public:
        FORCE_INLINE aligned_storage_base() :
            m_is_constructed(false)
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
            return m_is_constructed;
        }

        FORCE_INLINE bool has_construction_flag() const
        {
            return true;
        }

    protected:
        FORCE_INLINE void set_constructed(bool is_constructed)
        {
            m_is_constructed = is_constructed;
        }

    protected:
        bool m_is_constructed;
    };

    // special designed class to store type which size and alignment is known (for example, type with deleted initialization constructor)
    template <typename t_storage_type, typename t_tag_pttn_type = tag_pttn_default_t>
    class aligned_storage_from : public aligned_storage_base<t_tag_pttn_type>
    {
    public:
        typedef t_storage_type storage_type_t;

        static const size_t size_value = sizeof(storage_type_t);
        static const size_t alignment_value = boost::alignment_of<storage_type_t>::value;

        FORCE_INLINE aligned_storage_from()
        {
        }

        FORCE_INLINE ~aligned_storage_from()
        {
            // auto destruct ONLY if has lifetime control enabled
            if (has_construction_flag() && is_constructed()) {
                destruct();
            }
        }

        FORCE_INLINE aligned_storage_from(const aligned_storage_from & r) :
            aligned_storage_base(r) // binding with the base
        {
            // just in case
            ASSERT_TRUE(has_construction_flag() && r.has_construction_flag());
            ASSERT_TRUE(!is_constructed());

            // at first, check if storage is constructed
            if (!r.is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": reference type is not constructed"))
                        ).str());
            }

            // make construction
            ::new (m_storage.address()) storage_type_t(*static_cast<const storage_type_t *>(r.m_storage.address()));

            // flag construction
            set_constructed(true);
        }

        FORCE_INLINE aligned_storage_from & operator =(const aligned_storage_from & r)
        {
            this->aligned_storage_base::operator =(r); // binding with the base

            // just in case
            ASSERT_TRUE(has_construction_flag() && r.has_construction_flag());

            // at first, check if both storages are constructed
            if (!is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            if (!r.is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": reference type is not constructed"))
                        ).str());
            }

            // make assignment
            *static_cast<storage_type_t *>(m_storage.address()) = *static_cast<const storage_type_t *>(r.m_storage.address());

            return *this;
        }

        // direct construction and destruction of the storage
        FORCE_INLINE void construct()
        {
            ASSERT_TRUE(!has_construction_flag() || !is_constructed());

            ::new (m_storage.address()) storage_type_t();

            // flag construction
            set_constructed(true);
        }

        template <typename Ref>
        FORCE_INLINE void construct(Ref & r)
        {
            ASSERT_TRUE(!has_construction_flag() || !is_constructed());

            ::new (m_storage.address()) storage_type_t(r);

            // flag construction
            set_constructed(true);
        }

        FORCE_INLINE void destruct()
        {
            ASSERT_TRUE(!has_construction_flag() || is_constructed());

            static_cast<storage_type_t *>(m_storage.address())->storage_type_t::~storage_type_t();
        }

        template <typename Ref>
        FORCE_INLINE void assign(Ref & r)
        {
            ASSERT_TRUE(!has_construction_flag() || is_constructed());

            *static_cast<storage_type_t *>(m_storage.address()) = r;
        }

        template <typename Ref>
        FORCE_INLINE void assign(Ref & r) volatile
        {
            ASSERT_TRUE(!has_construction_flag() || is_constructed());

            *static_cast<storage_type_t *>(m_storage.address()) = r;
        }

        // storage redirection
        FORCE_INLINE storage_type_t * this_()
        {
            if (!is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            return static_cast<storage_type_t *>(m_storage.address());
        }

        FORCE_INLINE const storage_type_t * this_() const
        {
            if (!is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            return reinterpret_cast<const storage_type_t *>(m_storage.address());
        }

        FORCE_INLINE volatile storage_type_t * this_() volatile
        {
            if (!is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            return reinterpret_cast<volatile storage_type_t *>(m_storage.address());
        }

        FORCE_INLINE const volatile storage_type_t * this_() const volatile
        {
            if (!is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            return reinterpret_cast<const volatile storage_type_t *>(m_storage.address());
        }

        FORCE_INLINE void * address()
        {
            return m_storage.address();
        }

        FORCE_INLINE const void * address() const
        {
            return m_storage.address();
        }

    private:
        boost::aligned_storage<size_value, alignment_value> m_storage;
    };

    // special designed class to store type with not yet known size and alignment (for example, forward type with implementation in a .cpp file)
    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type = tag_pttn_default_t>
    class aligned_storage_by : public aligned_storage_base<t_tag_pttn_type>
    {
    public:
        typedef t_storage_type storage_type_t;

        static const size_t size_value = t_size_value;
        static const size_t alignment_value = t_alignment_value;

        STATIC_ASSERT_GT(size_value, 1, "size_value must be strictly positive value");
        STATIC_ASSERT_TRUE2(alignment_value > 1 && size_value >= alignment_value,
            alignment_value, size_value,
            "alignment_value must be strictly positive value and not greater than size_value");

        FORCE_INLINE aligned_storage_by()
        {
            // prevent the linkage of invalid constructed type with inappropriate size or alignment
            STATIC_ASSERT_EQ(size_value, sizeof(storage_type_t), "the storage type size is different");
            STATIC_ASSERT_EQ(alignment_value, boost::alignment_of<storage_type_t>::value, "the storage type alignment is different");
        }

        FORCE_INLINE ~aligned_storage_by()
        {
            // auto destruct ONLY if has lifetime control enabled
            if (has_construction_flag() && is_constructed()) {
                destruct();
            }
        }

        FORCE_INLINE aligned_storage_by(const aligned_storage_by & r) :
            aligned_storage_base(r) // binding with the base
        {
            // just in case
            ASSERT_TRUE(has_construction_flag() && r.has_construction_flag());
            ASSERT_TRUE(!is_constructed());

            // at first, check if storage is constructed
            if (!r.is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": reference type is not constructed"))
                        ).str());
            }

            // make construction
            ::new (m_storage.address()) storage_type_t(*static_cast<const storage_type_t *>(r.m_storage.address()));

            // flag construction
            set_constructed(true);
        }

        FORCE_INLINE aligned_storage_by & operator =(const aligned_storage_by & r)
        {
            this->aligned_storage_base::operator =(r); // binding with the base

            // just in case
            ASSERT_TRUE(has_construction_flag() && r.has_construction_flag());

            // at first, check if both storages are constructed
            if (!is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            if (!r.is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": reference type is not constructed"))
                        ).str());
            }

            // make assignment
            *static_cast<storage_type_t *>(m_storage.address()) = *static_cast<const storage_type_t *>(r.m_storage.address());

            return *this;
        }

        // direct construction and destruction of the storage
        FORCE_INLINE void construct()
        {
            ASSERT_TRUE(!has_construction_flag() || !is_constructed());

            ::new (m_storage.address()) storage_type_t();

            // flag construction
            set_constructed(true);
        }

        template <typename Ref>
        FORCE_INLINE void construct(Ref & r)
        {
            ASSERT_TRUE(!has_construction_flag() || !is_constructed());

            ::new (m_storage.address()) storage_type_t(r);

            // flag construction
            set_constructed(true);
        }

        FORCE_INLINE void destruct()
        {
            ASSERT_TRUE(!has_construction_flag() || is_constructed());

            static_cast<storage_type_t *>(m_storage.address())->storage_type_t::~storage_type_t();
        }

        template <typename Ref>
        FORCE_INLINE void assign(Ref & r)
        {
            ASSERT_TRUE(!has_construction_flag() || is_constructed());

            *static_cast<storage_type_t *>(m_storage.address()) = r;
        }

        template <typename Ref>
        FORCE_INLINE void assign(Ref & r) volatile
        {
            ASSERT_TRUE(!has_construction_flag() || is_constructed());

            *static_cast<storage_type_t *>(m_storage.address()) = r;
        }

        // storage redirection
        FORCE_INLINE storage_type_t * this_()
        {
            if (!is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            return static_cast<storage_type_t *>(m_storage.address());
        }

        FORCE_INLINE const storage_type_t * this_() const
        {
            if (!is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            return reinterpret_cast<const storage_type_t *>(m_storage.address());
        }

        FORCE_INLINE volatile storage_type_t * this_() volatile
        {
            if (!is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            return reinterpret_cast<volatile storage_type_t *>(m_storage.address());
        }

        FORCE_INLINE const volatile storage_type_t * this_() const volatile
        {
            if (!is_constructed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            return reinterpret_cast<const volatile storage_type_t *>(m_storage.address());
        }

        FORCE_INLINE void * address()
        {
            return m_storage.address();
        }

        FORCE_INLINE const void * address() const
        {
            return m_storage.address();
        }

    private:
        boost::aligned_storage<size_value, alignment_value> m_storage;
    };

    // The `max_aligned_storage_from_mpl_container` already stores construction state through the `type_index` variable.
    // We only need to enable copy constructor and assign operator if appropriate tag has declared.
    template <typename tag_pttn>
    class max_aligned_storage_from_mpl_container_base
    {
    public:
        FORCE_INLINE max_aligned_storage_from_mpl_container_base()
        {
        }

        max_aligned_storage_from_mpl_container_base(const max_aligned_storage_from_mpl_container_base &) = delete; // use explicit `construct` instead
        max_aligned_storage_from_mpl_container_base & operator =(const max_aligned_storage_from_mpl_container_base &) = delete; // use explicit `assign` instead
    };

    template <>
    class max_aligned_storage_from_mpl_container_base<tag_pttn_control_lifetime_t>
    {
        // MUST BE EMPTY
    };

    // special designed class to make maximal size and alignment for a storage to construct/destruct it explicitly by the type index
    template <typename t_mpl_container_types, typename t_tag_pttn_type = tag_pttn_default_t>
    class max_aligned_storage_from_mpl_container : public max_aligned_storage_from_mpl_container_base<t_tag_pttn_type>
    {
    public:
        typedef typename t_mpl_container_types storage_types_t;

    private:
        // as reference
        template<typename Ret>
        static FORCE_INLINE Ret & _default_construct_dummy(mpl::identity<Ret &>)
        {
            static typename boost::remove_cv<Ret>::type default_constructed_dummy;
            return default_constructed_dummy;
        }

        // as void
        static FORCE_INLINE void _default_construct_dummy(mpl::identity<void>)
        {
            return;
        }

        // as value
        template<typename Ret>
        static FORCE_INLINE Ret _default_construct_dummy(mpl::identity<Ret>)
        {
            return Ret();
        }

        template <typename Type, bool Convertable>
        struct construct_if_convertible
        {
            template <typename Ref>
            static FORCE_INLINE bool construct(void * storage_ptr, Ref & r, const char * error_msg_fmt)
            {
                ::new (storage_ptr) Type(r);

                return true;
            }
        };

        template <typename Type>
        struct construct_if_convertible<Type, false>
        {
            template <typename Ref>
            static FORCE_INLINE bool construct(void * storage_ptr, Ref & r, const char * error_msg_fmt)
            {
                throw std::runtime_error(
                    (boost::format(
                        error_msg_fmt) %
                            typeid(Type).raw_name() % typeid(Ref).raw_name()).str());

                return false;
            }
        };

        template <int TypeIndex, typename Type, bool IsEnabled>
        struct construct_dispatcher
        {
            template <typename Ref>
            static FORCE_INLINE bool construct(void * storage_ptr, Ref & r, const char * error_msg_fmt)
            {
                return construct_if_convertible<Type, boost::is_convertible<Ref, Type>::value>::construct(storage_ptr, r, error_msg_fmt);
            }
        };

        template <int TypeIndex, typename Type>
        struct construct_dispatcher<TypeIndex, Type, false>
        {
            template <typename Ref>
            static FORCE_INLINE bool construct(void * storage_ptr, Ref & r, const char * error_msg_fmt)
            {
                return false;
            }
        };

        template <typename Ret, typename From, typename To, bool Convertable>
        struct invoke_if_convertible
        {
            template <typename F, typename Ref>
            static FORCE_INLINE Ret call(F & f, Ref & r, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
            {
                return f(r);
            }
        };

        template <typename Ret, typename From, typename To>
        struct invoke_if_convertible<Ret, From, To, false>
        {
            template <typename F, typename Ref>
            static FORCE_INLINE Ret call(F & f, Ref & r, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
            {
                if(throw_exceptions_on_type_error) {
                    throw std::runtime_error(
                        (boost::format(
                            error_msg_fmt) %
                                typeid(From).raw_name() % typeid(To).raw_name()).str());
                }

                return _default_construct_dummy(mpl::identity<Ret>());
            }
        };

        template <int TypeIndex, typename Ret, typename TypeList, typename EndIt, bool IsEnabled, bool IsExtractable>
        struct invoke_dispatcher
        {
            template <typename F, typename Ref>
            static FORCE_INLINE Ret call(F & f, Ref & r, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
            {
                typedef typename boost::remove_cv<typename boost::remove_reference<typename utility::function_traits<F>::arg<0>::type>::type >::type unqual_arg0_type;

                typedef typename mpl::find<TypeList, unqual_arg0_type>::type found_it_t;

                static_assert(!boost::is_same<found_it_t, EndIt>::value,
                    "functor first unqualified parameter type is not declared by storage types list");

                return invoke_if_convertible<Ret, Ref, unqual_arg0_type, boost::is_convertible<Ref, unqual_arg0_type>::value>::call(f, r, error_msg_fmt, throw_exceptions_on_type_error);
            }
        };

        template <int TypeIndex, typename Ret, typename TypeList, typename EndIt>
        struct invoke_dispatcher<TypeIndex, Ret, TypeList, EndIt, true, false>
        {
            template <typename F, typename Ref>
            static FORCE_INLINE Ret call(F & f, Ref & r, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
            {
                UTILITY_UNUSED_STATEMENT2(error_msg_fmt, throw_exceptions_on_type_error);
                return f(r); // call as generic or cast
            }
        };

        template <int TypeIndex, typename Ret, typename TypeList, typename EndIt, bool IsExtractable>
        struct invoke_dispatcher<TypeIndex, Ret, TypeList, EndIt, false, IsExtractable>
        {
            template <typename F, typename Ref>
            static FORCE_INLINE Ret call(F & f, Ref & r, const char * error_msg_fmt, bool throw_exceptions_on_type_error)
            {
                UTILITY_UNUSED_STATEMENT4(f, r, error_msg_fmt, throw_exceptions_on_type_error);
                return _default_construct_dummy(mpl::identity<Ret>()); // disabled call
            }
        };

    private:
        typedef typename mpl::end<storage_types_t>::type storage_types_end_it_t;
        typedef typename mpl::size<storage_types_t>::type num_types_t;

        STATIC_ASSERT_GT(num_types_t::value, 0, "template must be specialized with not empty mpl container");
        STATIC_ASSERT_GE(TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES, num_types_t::value,
            "TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES has not enough value or storage_types_t is too big");

        typedef typename mpl::deref<
            typename mpl::max_element<
                mpl::transform_view<storage_types_t, mpl::sizeof_<mpl::_1> >
            >::type
        >::type max_size_t;

        typedef typename mpl::deref<
            typename mpl::max_element<
                mpl::transform_view<storage_types_t, mpl::alignof_<mpl::_1> >
            >::type
        >::type max_alignment_t;

    public:
        // use maximals
        static const size_t max_size_value = max_size_t::value;
        static const size_t max_alignment_value = max_alignment_t::value;

        STATIC_ASSERT_GE(max_size_value, 1, "size_value must be strictly positive value");
        STATIC_ASSERT_TRUE2(max_alignment_value >= 1 && max_size_value >= max_alignment_value,
            max_alignment_value, max_size_value,
            "max_alignment_value must be strictly positive value and not greater than max_size_value");

        typedef boost::aligned_storage<max_size_value, max_alignment_value> max_aligned_storage_t;

        FORCE_INLINE max_aligned_storage_from_mpl_container(int type_index = -1);
        template <typename Ref>
        FORCE_INLINE max_aligned_storage_from_mpl_container(int type_index, Ref & r);
        FORCE_INLINE ~max_aligned_storage_from_mpl_container();

        FORCE_INLINE max_aligned_storage_from_mpl_container(const max_aligned_storage_from_mpl_container & r) :
            max_aligned_storage_from_mpl_container_base(r) // binding with the base
        {
            // just in case
            ASSERT_LT(type_index(), 0);

            // at first, check if storage is constructed
            if (r.type_index() < 0) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": reference type is not constructed"))
                        ).str());
            }

            // make construction
            _construct(r, false);
        }

        FORCE_INLINE max_aligned_storage_from_mpl_container & operator =(const max_aligned_storage_from_mpl_container & r)
        {
            this->max_aligned_storage_from_mpl_container_base::operator =(r); // binding with the base

            // at first, check if both storages are constructed
            if (type_index() < 0) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": this type is not constructed"))
                        ).str());
            }

            if (r.type_index() < 0) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": reference type is not constructed"))
                        ).str());
            }

            // make assignment
            _assign(r);

            return *this;
        }

        // direct construction and destruction of the storage
        FORCE_INLINE void construct(int type_index, bool reconstruct);
        template <typename Ref>
        FORCE_INLINE void construct(int type_index, Ref & r, bool reconstruct);

    private:
        FORCE_INLINE void _construct(const max_aligned_storage_from_mpl_container & s, bool reconstruct);

    public:
        FORCE_INLINE void destruct();

        FORCE_INLINE int type_index() const;

        template <typename Ref>
        FORCE_INLINE void assign(Ref & r, bool throw_exceptions_on_type_error = true);

    private:
        FORCE_INLINE void _assign(const max_aligned_storage_from_mpl_container & s, bool throw_exceptions_on_type_error = true);

    public:
        template <typename R, typename F>
        FORCE_INLINE R invoke(F && functor, bool throw_exceptions_on_type_error = true);
        template <typename R, typename F>
        FORCE_INLINE R invoke(F && functor, bool throw_exceptions_on_type_error = true) const;

        FORCE_INLINE void * address();
        FORCE_INLINE const void * address() const;

    private:
        int m_type_index;
        max_aligned_storage_t m_storage;
    };

    //// max_aligned_storage_from_mpl_container

    //#undef UTILITY_PP_LINE_TERMINATOR
    #define TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX(z, n, macro_text) \
        case n: { UTILITY_PP_LINE_TERMINATOR\
            typedef mpl::if_<mpl::less<mpl::size_t<n>, mpl::size_t<num_types_t::value> >, mpl::at<storage_types_t, mpl::int_<n> >, mpl::void_>::type::type storage_type_t; UTILITY_PP_LINE_TERMINATOR\
            macro_text(z, n); UTILITY_PP_LINE_TERMINATOR\
        } break; UTILITY_PP_LINE_TERMINATOR

    // for binary operators
    #define TACKLE_PP_REPEAT_INVOKE_RIGHT_MACRO_BY_TYPE_INDEX(z, n, macro_text) \
        case n: { UTILITY_PP_LINE_TERMINATOR\
            typedef mpl::if_<mpl::less<mpl::size_t<n>, mpl::size_t<num_types_t::value> >, mpl::at<storage_types_t, mpl::int_<n> >, mpl::void_>::type::type right_storage_type_t; UTILITY_PP_LINE_TERMINATOR\
            macro_text(z, n); UTILITY_PP_LINE_TERMINATOR\
        } break; UTILITY_PP_LINE_TERMINATOR

    template <typename t_mpl_container_types, typename t_tag_pttn_type>
    FORCE_INLINE max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::max_aligned_storage_from_mpl_container(int type_index) :
        m_type_index(-1) // as not constructed
    {
        if (type_index >= 0) {
            construct(type_index, false);
        }
    }

    template <typename t_mpl_container_types, typename t_tag_pttn_type> template <typename Ref>
    FORCE_INLINE max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::max_aligned_storage_from_mpl_container(int type_index, Ref & r) :
        m_type_index(-1) // as not constructed
    {
        if (VERIFY_TRUE(type_index >= 0)) {
            construct(type_index, r, false);
        }
    }

    template <typename t_mpl_container_types, typename t_tag_pttn_type>
    FORCE_INLINE max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::~max_aligned_storage_from_mpl_container()
    {
        if (m_type_index >= 0) {
            destruct();
        }
    }

    #define TACKLE_PP_CONSTRUCT_MACRO(z, n) \
        if (UTILITY_CONST_EXPR(n < num_types_t::value)) { \
            ::new (m_storage.address()) storage_type_t(); \
            m_type_index = type_index; \
        } else goto default_

    // direct construction and destruction of the storage
    template <typename t_mpl_container_types, typename t_tag_pttn_type>
    FORCE_INLINE void max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::construct(int type_index, bool reconstruct)
    {
        if (reconstruct && m_type_index >= 0) { // if already been constructed
            destruct();
        }

        switch (type_index)
        {
            BOOST_PP_REPEAT(TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES, TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX, TACKLE_PP_CONSTRUCT_MACRO)

        default_:;
            default: {
                throw std::runtime_error(
                    (boost::format(
                        BOOST_PP_CAT(__FUNCTION__, ": invalid type index: type_index=%i"))
                            ).str());
            }
        }
    }

    #undef TACKLE_PP_CONSTRUCT_MACRO

    #define TACKLE_PP_CONSTRUCT_MACRO(z, n) \
        if (UTILITY_CONST_EXPR(n < num_types_t::value)) { \
            if (construct_dispatcher<n, storage_type_t, (n < num_types_t::value)>:: \
                construct(m_storage.address(), r, BOOST_PP_CAT(__FUNCTION__, ": storage type is not constructable by reference value: Type=\"%s\" Ref=\"%s\""))) { \
                m_type_index = type_index; \
            } \
        } else goto default_

    template <typename t_mpl_container_types, typename t_tag_pttn_type> template <typename Ref>
    FORCE_INLINE void max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::construct(int type_index, Ref & r, bool reconstruct)
    {
        if (reconstruct && m_type_index >= 0) { // if already been constructed
            destruct();
        }

        switch (type_index)
        {
            BOOST_PP_REPEAT(TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES, TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX, TACKLE_PP_CONSTRUCT_MACRO)

        default_:;
            default: {
                throw std::runtime_error(
                    (boost::format(
                        BOOST_PP_CAT(__FUNCTION__, ": invalid type index: type_index=%i"))
                            ).str());
            }
        }
    }

    #undef TACKLE_PP_CONSTRUCT_MACRO

    #define TACKLE_PP_CONSTRUCT_MACRO(z, n) \
        if (UTILITY_CONST_EXPR(n < num_types_t::value)) { \
            ::new (m_storage.address()) storage_type_t(*static_cast<const storage_type_t *>(s.address())); \
            m_type_index = s.m_type_index; \
        } else goto default_

    template <typename t_mpl_container_types, typename t_tag_pttn_type>
    FORCE_INLINE void max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::_construct(const max_aligned_storage_from_mpl_container & s, bool reconstruct)
    {
        if (s.m_type_index < 0) goto default_;

        if (reconstruct && m_type_index >= 0) { // if already been constructed
            destruct();
        }

        switch (s.m_type_index)
        {
            BOOST_PP_REPEAT(TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES, TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX, TACKLE_PP_CONSTRUCT_MACRO)

        default_:;
            default: {
                throw std::runtime_error(
                    (boost::format(
                        BOOST_PP_CAT(__FUNCTION__, ": invalid storage construction: to_type_index=%i from_type_index=%i")) %
                            m_type_index % s.m_type_index).str());
            }
        }
    }

    #undef TACKLE_PP_CONSTRUCT_MACRO

    #define TACKLE_PP_DESTRUCT_MACRO(z, n) \
        if (UTILITY_CONST_EXPR(n < num_types_t::value)) { \
            m_type_index = -1; \
            static_cast<storage_type_t *>(m_storage.address())->storage_type_t::~storage_type_t(); \
        } else goto default_

    template <typename t_mpl_container_types, typename t_tag_pttn_type>
    FORCE_INLINE void max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::destruct()
    {
        switch (m_type_index)
        {
            BOOST_PP_REPEAT(TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES, TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX, TACKLE_PP_DESTRUCT_MACRO)

        default_:;
            default: {
                throw std::runtime_error(
                    (boost::format(
                        BOOST_PP_CAT(__FUNCTION__, ": invalid type index: type_index=%i")) %
                            m_type_index).str());
            }
        }
    }

    #undef TACKLE_PP_DESTRUCT_MACRO

    template <typename t_mpl_container_types, typename t_tag_pttn_type>
    FORCE_INLINE int max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::type_index() const
    {
        return m_type_index;
    }

    #define TACKLE_PP_ASSIGN_MACRO_LEFT(z, n) \
        if (UTILITY_CONST_EXPR(n < num_types_t::value)) { \
            auto & left_value = *static_cast<storage_type_t *>(m_storage.address()); \
            switch (s.type_index()) \
            { \
                BOOST_PP_CAT(BOOST_PP_REPEAT_, z)(TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES, TACKLE_PP_REPEAT_INVOKE_RIGHT_MACRO_BY_TYPE_INDEX, TACKLE_PP_ASSIGN_MACRO_RIGHT) \
                \
                default: goto default_; \
            } \
        } else goto default_

    #define TACKLE_PP_ASSIGN_MACRO_RIGHT(z, n) \
        if (UTILITY_CONST_EXPR(n < num_types_t::value)) { \
            auto & right_value = *static_cast<const right_storage_type_t *>(s.address()); \
            left_value = right_value; \
        } \
        else goto default_

    template <typename t_mpl_container_types, typename t_tag_pttn_type>
    FORCE_INLINE void max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::_assign(const max_aligned_storage_from_mpl_container & s, bool throw_exceptions_on_type_error)
    {
        // containers must be already constructed before the assign
        if (m_type_index < 0 || s.m_type_index < 0) goto default_;

        switch (m_type_index)
        {
            BOOST_PP_REPEAT(TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES, TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX, TACKLE_PP_ASSIGN_MACRO_LEFT)

        default_:;
            default: if(throw_exceptions_on_type_error) {
                throw std::runtime_error(
                    (boost::format(
                        BOOST_PP_CAT(__FUNCTION__, ": invalid storage assign: to_type_index=%i from_type_index=%i")) %
                            m_type_index % s.m_type_index).str());
            }
        }
    }

    #undef TACKLE_PP_ASSIGN_MACRO_LEFT
    #undef TACKLE_PP_ASSIGN_MACRO_RIGHT

    #define TACKLE_PP_ASSIGN_MACRO_LEFT(z, n) \
        if (UTILITY_CONST_EXPR(n < num_types_t::value)) { \
            auto & left_value = *static_cast<storage_type_t *>(m_storage.address()); \
            left_value = r; \
        } else goto default_


    template <typename Ref>
    FORCE_INLINE void assign(Ref & r, bool throw_exceptions_on_type_error)
    {
        // container must be already constructed before the assign
        if (m_type_index < 0) goto default_;

        switch (m_type_index)
        {
            BOOST_PP_REPEAT(TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES, TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX, TACKLE_PP_ASSIGN_MACRO_LEFT)

        default_:;
            default: if(throw_exceptions_on_type_error) {
                throw std::runtime_error(
                    (boost::format(
                        BOOST_PP_CAT(__FUNCTION__, ": invalid storage assign: type_index=%i")) %
                            m_type_index).str());
            }
        }
    }

    #undef TACKLE_PP_ASSIGN_MACRO_LEFT

    #define TACKLE_PP_INVOKE_MACRO(z, n) \
        if (UTILITY_CONST_EXPR(n < num_types_t::value)) { \
            return invoke_dispatcher<n, R, storage_types_t, storage_types_end_it_t, n < num_types_t::value, utility::is_function_traits_extractable<decltype(functor)>::value>:: \
                call(functor, *static_cast<storage_type_t *>(m_storage.address()), BOOST_PP_CAT(__FUNCTION__, ": functor has not convertible first parameter type: From=\"%s\" To=\"%s\""), throw_exceptions_on_type_error); \
        } else goto default_

    template <typename t_mpl_container_types, typename t_tag_pttn_type> template <typename R, typename F>
    FORCE_INLINE R max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::invoke(F && functor, bool throw_exceptions_on_type_error)
    {
        switch (m_type_index)
        {
            BOOST_PP_REPEAT(TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES, TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX, TACKLE_PP_INVOKE_MACRO)

        default_:;
            default: if(throw_exceptions_on_type_error) {
                throw std::runtime_error(
                    (boost::format(
                        BOOST_PP_CAT(__FUNCTION__, ": invalid type index: type_index=%i")) %
                            m_type_index).str());
            }
        }

        return R();
    }

    #undef TACKLE_PP_INVOKE_MACRO

    #define TACKLE_PP_INVOKE_MACRO(z, n) \
        if (UTILITY_CONST_EXPR(n < num_types_t::value)) { \
            return invoke_dispatcher<n, R, storage_types_t, storage_types_end_it_t, n < num_types_t::value, utility::is_function_traits_extractable<decltype(functor)>::value>:: \
                call(functor, *static_cast<const storage_type_t *>(m_storage.address()), BOOST_PP_CAT(__FUNCTION__, ": functor has not convertible first parameter type: From=\"%s\" To=\"%s\""), throw_exceptions_on_type_error); \
        } else goto default_

    template <typename t_mpl_container_types, typename t_tag_pttn_type> template <typename R, typename F>
    FORCE_INLINE R max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::invoke(F && functor, bool throw_exceptions_on_type_error) const
    {
        switch (m_type_index)
        {
            BOOST_PP_REPEAT(TACKLE_PP_MAX_NUM_ALIGNED_STORAGE_TYPES, TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX, TACKLE_PP_INVOKE_MACRO)

        default_:;
            default: if(throw_exceptions_on_type_error) {
                throw std::runtime_error(
                    (boost::format(
                        BOOST_PP_CAT(__FUNCTION__, ": invalid type index: type_index=%i")) %
                            m_type_index).str());
            }
        }

        return R();
    }

    #undef TACKLE_PP_INVOKE_MACRO

    template <typename t_mpl_container_types, typename t_tag_pttn_type>
    FORCE_INLINE void * max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::address()
    {
        return m_storage.address();
    }

    template <typename t_mpl_container_types, typename t_tag_pttn_type>
    FORCE_INLINE const void * max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::address() const
    {
        return m_storage.address();
    }

    #undef TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX
    #undef TACKLE_PP_REPEAT_INVOKE_RIGHT_MACRO_BY_TYPE_INDEX
}
