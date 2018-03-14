#pragma once

// "tackle/aligned_storage_decl.hpp" must be already included here!


namespace tackle
{
    //// aligned_storage_by

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type>
    FORCE_INLINE aligned_storage_by<t_storage_type, t_size_value, t_alignment_value, t_tag_pttn_type>::aligned_storage_by(bool enable_unconstructed_copy_)
    {
        // prevent the linkage of invalid constructed type with inappropriate size or alignment
        STATIC_ASSERT_EQ(size_value, sizeof(storage_type_t), "the storage type size is different");
        STATIC_ASSERT_EQ(alignment_value, boost::alignment_of<storage_type_t>::value, "the storage type alignment is different");

        if (enable_unconstructed_copy_) {
            enable_unconstructed_copy();
        }
    }

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type>
    FORCE_INLINE aligned_storage_by<t_storage_type, t_size_value, t_alignment_value, t_tag_pttn_type>::aligned_storage_by(const aligned_storage_by & r) :
        aligned_storage_base(r) // binding with the base
    {
        // just in case
        ASSERT_TRUE(has_construction_flag() && r.has_construction_flag());
        ASSERT_TRUE(!is_constructed());

        // at first, check if storage is constructed
        if (!r.is_constructed()) {
            if (!is_unconstructed_copy_allowed()) {
                throw std::runtime_error((boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": reference type is not constructed"))
                        ).str());
            }
        }
        else {
            // make construction
            ::new (m_storage.address()) storage_type_t(*static_cast<const storage_type_t *>(r.m_storage.address()));

            // flag construction
            set_constructed(true);
        }
    }

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type>
    FORCE_INLINE aligned_storage_by<t_storage_type, t_size_value, t_alignment_value, t_tag_pttn_type> &
        aligned_storage_by<t_storage_type, t_size_value, t_alignment_value, t_tag_pttn_type>::operator =(const aligned_storage_by & r)
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

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type>
    FORCE_INLINE void aligned_storage_by<t_storage_type, t_size_value, t_alignment_value, t_tag_pttn_type>::construct()
    {
        ASSERT_TRUE(!has_construction_flag() || !is_constructed());

        ::new (m_storage.address()) storage_type_t();

        // flag construction
        set_constructed(true);
    }

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type>
    template <typename Ref>
    FORCE_INLINE void aligned_storage_by<t_storage_type, t_size_value, t_alignment_value, t_tag_pttn_type>::construct(Ref & r)
    {
        ASSERT_TRUE(!has_construction_flag() || !is_constructed());

        ::new (m_storage.address()) storage_type_t(r);

        // flag construction
        set_constructed(true);
    }

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type>
    FORCE_INLINE void aligned_storage_by<t_storage_type, t_size_value, t_alignment_value, t_tag_pttn_type>::destruct()
    {
        ASSERT_TRUE(!has_construction_flag() || is_constructed());

        set_constructed(false);

        static_cast<storage_type_t *>(m_storage.address())->storage_type_t::~storage_type_t();
    }

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type>
    template <typename Ref>
    FORCE_INLINE void aligned_storage_by<t_storage_type, t_size_value, t_alignment_value, t_tag_pttn_type>::assign(Ref & r)
    {
        ASSERT_TRUE(!has_construction_flag() || is_constructed());

        *static_cast<storage_type_t *>(m_storage.address()) = r;
    }

    template <typename t_storage_type, size_t t_size_value, size_t t_alignment_value, typename t_tag_pttn_type>
    template <typename Ref>
    FORCE_INLINE void aligned_storage_by<t_storage_type, t_size_value, t_alignment_value, t_tag_pttn_type>::assign(Ref & r) volatile
    {
        ASSERT_TRUE(!has_construction_flag() || is_constructed());

        *static_cast<storage_type_t *>(m_storage.address()) = r;
    }

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

    #define TACKLE_PP_CONSTRUCT_MACRO(z, n) \
        if (UTILITY_CONST_EXPR(n < num_types_t::value)) { \
            ::new (m_storage.address()) storage_type_t(); \
            m_type_index = type_index; \
        } else goto default_

    // direct construction and destruction of the storage
    template <typename t_mpl_container_types, typename t_tag_pttn_type>
    inline void max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::construct(int type_index, bool reconstruct)
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
    inline void max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::construct(int type_index, Ref & r, bool reconstruct)
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
    inline void max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::_construct(const max_aligned_storage_from_mpl_container & s, bool reconstruct)
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
    inline void max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::destruct()
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
    inline void max_aligned_storage_from_mpl_container<t_mpl_container_types, t_tag_pttn_type>::_assign(const max_aligned_storage_from_mpl_container & s, bool throw_exceptions_on_type_error)
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
    inline void assign(Ref & r, bool throw_exceptions_on_type_error)
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

    #undef TACKLE_PP_REPEAT_INVOKE_MACRO_BY_TYPE_INDEX
    #undef TACKLE_PP_REPEAT_INVOKE_RIGHT_MACRO_BY_TYPE_INDEX
}
