#pragma once


#include <utility/utility.hpp>
#include <utility/assert.hpp>
#include <utility/math.hpp>

#include <tackle/aligned_storage.hpp>

#include <boost/mpl/vector.hpp>
#include <boost/mpl/list.hpp>
#include <boost/mpl/push_front.hpp>

#include <deque>
#include <utility>


#define TACKLE_PP_MAX_NUM_CHUNK_VARIANTS 24 // up to 8MB chunks (1, 2, 4, 8, 16, ..., 4 * 1024 * 1024, 8 * 1024 * 1024)

namespace tackle
{
    namespace mpl = boost::mpl;

    class StreamStorage
    {
    private:
        typedef mpl::size_t<TACKLE_PP_MAX_NUM_CHUNK_VARIANTS> num_chunk_variants_t;
        typedef mpl::size_t<(0x01U << (TACKLE_PP_MAX_NUM_CHUNK_VARIANTS - 1))> max_chunk_size_t;

        FORCE_INLINE static constexpr size_t _get_chunk_size(size_t type_index)
        {
            return (0x01U << type_index);
        }

        template <size_t S>
        struct Chunk
        {
            uint8_t buf[S];
        };

        template <size_t, typename> struct deque_chunks_pof2_generator; // generator of the deque with the power of 2 sized chunks
        template <size_t, typename> struct deque_chunk_const_iterators_pof2_generator; // generator of the deque const iterators from the power of 2 sized chunks

        template <typename V>
        struct deque_chunks_pof2_generator<0, V>
        {
            typedef typename V type;
        };

        template <size_t N, typename V>
        struct deque_chunks_pof2_generator
        {
            typedef typename std::deque<Chunk<(size_t(0x01) << (N - 1))> > next_type_t;
            typedef typename deque_chunks_pof2_generator<N - 1, typename mpl::push_front<V, next_type_t>::type>::type type;
        };

        template <typename V>
        struct deque_chunk_const_iterators_pof2_generator<0, V>
        {
            typedef typename V type;
        };

        template <size_t N, typename V>
        struct deque_chunk_const_iterators_pof2_generator
        {
            typedef typename std::deque<Chunk<(size_t(0x01) << (N - 1))> >::const_iterator next_type_t;
            typedef typename deque_chunk_const_iterators_pof2_generator<N - 1, typename mpl::push_front<V, next_type_t>::type>::type type;
        };

        typedef mpl::list<> mpl_empty_container_t; // begin of mpl container usage

        typedef typename deque_chunks_pof2_generator<num_chunk_variants_t::value, mpl_empty_container_t>::type deques_mpl_container_t;
        typedef typename deque_chunk_const_iterators_pof2_generator<num_chunk_variants_t::value, mpl_empty_container_t>::type deque_const_iterators_mpl_container_t;

    public:
        typedef typename deques_mpl_container_t storage_types_t;

    private:
        typedef typename mpl::end<storage_types_t>::type storage_types_end_it_t;
        typedef typename mpl::size<storage_types_t>::type num_types_t;

        static_assert(num_types_t::value > 0, "template must generate not empty mpl container");

    public:
        class ChunkBufferCRef
        {
            friend class StreamStorage;

        private:
            FORCE_INLINE ChunkBufferCRef() :
                m_buf(nullptr), m_size(0)
            {
            }

            FORCE_INLINE ChunkBufferCRef(const uint8_t * buf, size_t size) :
                m_buf(buf), m_size(size)
            {
                ASSERT_TRUE(buf && size);
            }

        public:
            FORCE_INLINE const uint8_t * get() const
            {
                return m_buf;
            }

            FORCE_INLINE size_t size() const
            {
                return m_size;
            }

        private:
            const uint8_t * m_buf;
            size_t          m_size;
        };

        class basic_const_iterator
        {
            friend class StreamStorage;

            typedef typename deque_const_iterators_mpl_container_t storage_types_t;
            typedef typename mpl::end<storage_types_t>::type storage_types_end_it_t;
            typedef typename mpl::size<storage_types_t>::type num_types_t;

            static_assert(num_types_t::value > 0, "template must generate not empty mpl container");

            typedef max_aligned_storage_from_mpl_container<storage_types_t> iterator_storage_t;

            
        public:
            FORCE_INLINE basic_const_iterator();
            FORCE_INLINE basic_const_iterator(const basic_const_iterator & it);

        private:
            FORCE_INLINE basic_const_iterator(const iterator_storage_t & iterator_storage);

        public:
            FORCE_INLINE basic_const_iterator & operator =(const basic_const_iterator & it);

            FORCE_INLINE ChunkBufferCRef operator *() const;
            FORCE_INLINE ChunkBufferCRef operator ->() const;

            FORCE_INLINE bool operator ==(const basic_const_iterator &) const;
            FORCE_INLINE bool operator !=(const basic_const_iterator &) const;

            FORCE_INLINE basic_const_iterator operator ++(int);
            FORCE_INLINE basic_const_iterator & operator ++();
            FORCE_INLINE basic_const_iterator operator --(int);
            FORCE_INLINE basic_const_iterator & operator --();

        private:
            iterator_storage_t m_iterator_storage;
        };

    public:
        typedef basic_const_iterator const_iterator;

        FORCE_INLINE StreamStorage(size_t min_chunk_size);
        FORCE_INLINE ~StreamStorage();

        FORCE_INLINE void reset(size_t min_chunk_size);
        FORCE_INLINE void clear();
        FORCE_INLINE const_iterator begin() const;
        FORCE_INLINE const_iterator end() const;
        FORCE_INLINE size_t chunk_size() const;
        FORCE_INLINE size_t size() const;
        FORCE_INLINE size_t remainder() const;
        FORCE_INLINE void push_back(const uint8_t * p, size_t size);
        FORCE_INLINE uint8_t operator[](size_t offset) const;
        FORCE_INLINE size_t copy_to(size_t offset_from, void * to_buf, size_t size) const;
        FORCE_INLINE size_t erase_front(size_t size);

    private:
        max_aligned_storage_from_mpl_container<storage_types_t> m_chunks;
        size_t                                                  m_size;
        size_t                                                  m_remainder;
    };

    //// StreamStorage::basic_const_iterator

    //#undef UTILITY_PP_LINE_TERMINATOR
    #define TACKLE_REPEAT_PP_INVOKE_MACRO_BY_TYPE_INDEX(z, n, macro_text) \
        case n: { UTILITY_PP_LINE_TERMINATOR\
            typedef mpl::if_<mpl::less<mpl::size_t<n>, mpl::size_t<num_types_t::value> >, mpl::at<storage_types_t, mpl::int_<n> >, mpl::void_>::type::type storage_type_t; UTILITY_PP_LINE_TERMINATOR\
            macro_text(z, n); UTILITY_PP_LINE_TERMINATOR\
        } break; UTILITY_PP_LINE_TERMINATOR

    #define TACKLE_REPEAT_PP_INVOKE_MACRO_BY_TYPE_INDEX_POF2(z, n, macro_text) \
        case (0x01U << n): { UTILITY_PP_LINE_TERMINATOR\
            typedef mpl::if_<mpl::less<mpl::size_t<n>, mpl::size_t<num_types_t::value> >, mpl::at<storage_types_t, mpl::int_<n> >, mpl::void_>::type::type storage_type_t; UTILITY_PP_LINE_TERMINATOR\
            macro_text(z, n); UTILITY_PP_LINE_TERMINATOR\
        } break; UTILITY_PP_LINE_TERMINATOR

    FORCE_INLINE StreamStorage::basic_const_iterator::basic_const_iterator()
    {
    }

    FORCE_INLINE StreamStorage::basic_const_iterator::basic_const_iterator(const basic_const_iterator & it)
    {
        *this = it;
    }

    FORCE_INLINE StreamStorage::basic_const_iterator::basic_const_iterator(const iterator_storage_t & iterator_storage)
    {
        m_iterator_storage.construct(iterator_storage, false);
    }

    FORCE_INLINE StreamStorage::basic_const_iterator & StreamStorage::basic_const_iterator::operator =(const basic_const_iterator & it)
    {
        m_iterator_storage.assign(it.m_iterator_storage);

        return *this;
    }

    #define TACKLE_PP_OPERATOR_MACRO(z, n) \
        if (n < num_types_t::value) { \
            const auto & chunk = **static_cast<const storage_type_t *>(m_iterator_storage.address()); \
            return ChunkBufferCRef{chunk.buf, std::size(chunk.buf)}; \
        } else goto default_

    FORCE_INLINE StreamStorage::ChunkBufferCRef StreamStorage::basic_const_iterator::operator *() const
    {
        const int type_index = m_iterator_storage.type_index();

        switch (type_index)
        {
            BOOST_PP_REPEAT(TACKLE_PP_MAX_NUM_CHUNK_VARIANTS, TACKLE_REPEAT_PP_INVOKE_MACRO_BY_TYPE_INDEX, TACKLE_PP_OPERATOR_MACRO)

        default_:;
            default: {
                throw std::runtime_error(
                    (boost::format(
                        BOOST_PP_CAT(__FUNCTION__, ": invalid type index: type_index=%i")) %
                            type_index).str());
            }
        }

        return ChunkBufferCRef{};
    }

    #undef TACKLE_PP_OPERATOR_MACRO

    FORCE_INLINE StreamStorage::ChunkBufferCRef StreamStorage::basic_const_iterator::operator ->() const
    {
        return this->operator *();
    }

    #define TACKLE_PP_OPERATOR_MACRO(z, n) \
        if (n < num_types_t::value) { \
            const auto & left_it = *static_cast<const storage_type_t *>(m_iterator_storage.address()); \
            const auto & right_it = *static_cast<const storage_type_t *>(it.m_iterator_storage.address()); \
            return left_it == right_it; \
        } else goto default_

    FORCE_INLINE bool StreamStorage::basic_const_iterator::operator ==(const StreamStorage::basic_const_iterator & it) const
    {
        const int left_type_index = m_iterator_storage.type_index();
        const int right_type_index = it.m_iterator_storage.type_index();
        if (left_type_index != right_type_index) {
            throw std::runtime_error(
                (boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": incompatible iterator storages: left_type_index=%i right_type_index=%i")) %
                        left_type_index % right_type_index).str());
        }

        switch (left_type_index)
        {
            BOOST_PP_REPEAT(TACKLE_PP_MAX_NUM_CHUNK_VARIANTS, TACKLE_REPEAT_PP_INVOKE_MACRO_BY_TYPE_INDEX, TACKLE_PP_OPERATOR_MACRO)

        default_:;
            default: {
                throw std::runtime_error(
                    (boost::format(
                        BOOST_PP_CAT(__FUNCTION__, ": invalid type index: left_type_index=%i")) %
                            left_type_index).str());
            }
        }

        return false;
    }

    #undef TACKLE_PP_OPERATOR_MACRO

    FORCE_INLINE bool StreamStorage::basic_const_iterator::operator !=(const basic_const_iterator & it) const
    {
        return !this->operator ==(it);
    }

    FORCE_INLINE StreamStorage::basic_const_iterator StreamStorage::basic_const_iterator::operator ++(int)
    {
        const auto it = *this;

        m_iterator_storage.invoke<void>([](auto & chunks_it)
        {
            chunks_it++;
        });

        return it;
    }

    FORCE_INLINE StreamStorage::basic_const_iterator & StreamStorage::basic_const_iterator::operator ++()
    {
        m_iterator_storage.invoke<void>([](auto & chunks_it)
        {
            ++chunks_it;
        });

        return *this;
    }

    FORCE_INLINE StreamStorage::basic_const_iterator StreamStorage::basic_const_iterator::operator --(int)
    {
        const auto it = *this;

        m_iterator_storage.invoke<void>([](auto & chunks_it)
        {
            chunks_it--;
        });

        return it;
    }

    FORCE_INLINE StreamStorage::basic_const_iterator & StreamStorage::basic_const_iterator::operator --()
    {
        m_iterator_storage.invoke<void>([](auto & chunks_it)
        {
            --chunks_it;
        });

        return *this;
    }

    //// StreamStorage

    FORCE_INLINE StreamStorage::StreamStorage(size_t min_chunk_size) :
        m_size(0), m_remainder(0)
    {
        reset(min_chunk_size);
    }

    FORCE_INLINE StreamStorage::~StreamStorage()
    {
    }

    FORCE_INLINE void StreamStorage::reset(size_t min_chunk_size)
    {
        ASSERT_TRUE(min_chunk_size);

        const size_t chunk_type_index = max_chunk_size_t::value >= min_chunk_size ? math::int_log2_ceil(min_chunk_size) : math::int_log2_ceil(max_chunk_size_t::value);
        if (chunk_type_index != m_chunks.type_index()) {
            m_chunks.construct(chunk_type_index, true);
        }
        else {
            clear();
        }
    }

    FORCE_INLINE void StreamStorage::clear()
    {
        m_chunks.invoke<void>([this](auto & chunks)
        {
            m_size = 0;
            m_remainder = 0;
            chunks.clear(); // at last in case if throw an exception
        });
    }

    FORCE_INLINE StreamStorage::const_iterator StreamStorage::begin() const
    {
        return m_chunks.invoke<const_iterator>([this](const auto & chunks)
        {
            return const_iterator(basic_const_iterator::iterator_storage_t(m_chunks.type_index(), chunks.begin()));
        });
    }

    FORCE_INLINE StreamStorage::const_iterator StreamStorage::end() const
    {
        return m_chunks.invoke<const_iterator>([this](const auto & chunks)
        {
            return const_iterator(basic_const_iterator::iterator_storage_t(m_chunks.type_index(), chunks.end()));
        });
    }

    FORCE_INLINE size_t StreamStorage::chunk_size() const
    {
        return m_chunks.invoke<size_t>([this](const auto & chunks) // to throw exception on invalid type index
        {
            return _get_chunk_size(m_chunks.type_index());
        });
    }

    FORCE_INLINE size_t StreamStorage::size() const
    {
        return m_size;
    }

    FORCE_INLINE size_t StreamStorage::remainder() const
    {
        return m_remainder;
    }

    FORCE_INLINE void StreamStorage::push_back(const uint8_t * buf, size_t size)
    {
        ASSERT_TRUE(buf && size);

        m_chunks.invoke<void>([=](auto & chunks)
        {
            typedef decltype(chunks[0]) ref_chunk_t;
            typedef boost::remove_reference<ref_chunk_t>::type chunk_t;

            const size_t chunk_size = _get_chunk_size(m_chunks.type_index());
            ASSERT_LT(m_remainder, chunk_size);

            size_t buf_offset = 0;
            size_t left_size = size;

            if_break(1) {
                if (m_remainder) {
                    const size_t copy_to_remainder_size = (std::min)(chunk_size - m_remainder, left_size);
                    memcpy(chunks.back().buf + m_remainder, buf, copy_to_remainder_size);
                    left_size -= copy_to_remainder_size;
                    buf_offset += copy_to_remainder_size;
                }

                if (!left_size) break;

                const size_t num_fixed_chunks = left_size / chunk_size;
                const size_t last_fixed_chunk_remainder = left_size % chunk_size;
                for (size_t i = 0; i < num_fixed_chunks; i++) {
                    chunks.push_back(chunk_t());
                    memcpy(chunks.back().buf, buf + buf_offset, chunk_size * sizeof(chunk_t().buf[0]));
                    buf_offset += chunk_size;
                }
                if (last_fixed_chunk_remainder) {
                    chunks.push_back(chunk_t());
                    memcpy(chunks.back().buf, buf + buf_offset, last_fixed_chunk_remainder);
                    buf_offset += last_fixed_chunk_remainder;
                }
            }

            m_size += buf_offset;
            m_remainder = (m_remainder + buf_offset) % chunk_size;
        });
    }

    FORCE_INLINE uint8_t StreamStorage::operator[](size_t offset) const
    {
        ASSERT_LT(offset, size());

        return m_chunks.invoke<uint8_t>([=](const auto & chunks)
        {
            const size_t chunk_size = _get_chunk_size(m_chunks.type_index());

            const auto chunk_devrem = UINT32_DIVREM_POF2(offset, chunk_size);
            auto & chunk = chunks[chunk_devrem.quot];

            return chunk.buf[chunk_devrem.rem];
        });
    }

    FORCE_INLINE size_t StreamStorage::copy_to(size_t offset_from, void * to_buf, size_t to_size) const
    {
        ASSERT_LT(offset_from, size());
        ASSERT_GE(size(), offset_from + to_size);

        return m_chunks.invoke<size_t>([=](const auto & chunks)
        {
            const size_t chunk_size = _get_chunk_size(m_chunks.type_index());

            const auto chunk_divrem = UINT32_DIVREM_POF2(offset_from, chunk_size);
            auto & chunk = chunks[chunk_divrem.quot];
            size_t to_buf_offset = 0;
            size_t from_buf_offset = chunk_divrem.rem;
            if (chunk_size >= from_buf_offset + to_size) {
                for (; to_buf_offset < to_size; to_buf_offset++, from_buf_offset++) {
                    ((uint8_t *)to_buf)[to_buf_offset] = chunk.buf[from_buf_offset];
                }
            }
            else {
                const auto next_chunk_divrem = UINT32_DIVREM_POF2(chunk_divrem.rem + to_size, chunk_size);
                const size_t first_chunk_size = chunk_size - chunk_divrem.rem;
                for (size_t i = 0; i < first_chunk_size; i++, to_buf_offset++, from_buf_offset++) {
                    ((uint8_t *)to_buf)[to_buf_offset] = chunk.buf[from_buf_offset];
                }
                if (next_chunk_divrem.quot >= 1) {
                    if (next_chunk_divrem.quot >= 2) {
                        DEBUG_BREAK(true); // needs debug
                        for (size_t i = 0; i < next_chunk_divrem.quot - 1; i++, to_buf_offset += chunk_size) {
                            auto & chunk2 = chunks[chunk_divrem.quot + 1 + i];
                            memcpy(((uint8_t *)to_buf) + to_buf_offset, chunk2.buf, chunk_size);
                        }
                    }
                    auto & chunk2 = chunks[chunk_divrem.quot + next_chunk_divrem.quot];
                    const size_t last_chunk_size = next_chunk_divrem.rem;
                    for (size_t i = 0; i < last_chunk_size; i++, to_buf_offset++) {
                        ((uint8_t *)to_buf)[to_buf_offset] = chunk2.buf[i];
                    }
                }
            }

            return to_buf_offset;
        });
    }

    FORCE_INLINE size_t StreamStorage::erase_front(size_t size)
    {
        ASSERT_GE(m_size, size);

        return m_chunks.invoke<size_t>([=](auto & chunks)
        {
            const size_t chunk_size = _get_chunk_size(m_chunks.type_index());

            size_t erased_size;

            if (size < m_size) {
                size_t chunk_index = 0;
                const size_t num_chunks = size / chunk_size;
                for (; chunk_index < num_chunks; chunk_index++) {
                    chunks.pop_front();
                }

                erased_size = chunk_index * chunk_size;

                ASSERT_GE(m_size, erased_size);
                m_size -= erased_size;
            }
            else {
                erased_size = m_size;

                clear();
            }

            return erased_size;
        });
    }
}
