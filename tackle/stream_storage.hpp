#pragma once


#include "tacklelib.hpp"

#include <utility/utility.hpp>
#include <utility/assert.hpp>
#include <utility/math.hpp>
#include <utility/algorithm.hpp>

#include <tackle/aligned_storage.hpp>

#include <boost/type_traits/is_pod.hpp>

#include <boost/mpl/vector.hpp>
#include <boost/mpl/list.hpp>
#include <boost/mpl/push_front.hpp>

#include <deque>
#include <utility>
#include <algorithm>


namespace tackle
{
    namespace mpl = boost::mpl;

    template <typename T>
    class stream_storage
    {
    public:
        // up to 8MB chunks (1, 2, 4, 8, 16, ..., 4 * 1024 * 1024, 8 * 1024 * 1024)
        typedef mpl::size_t<24> num_chunk_variants_t;
        typedef mpl::size_t<(0x01U << (num_chunk_variants_t::value - 1))> max_chunk_size_t;

    private:
        static FORCE_INLINE constexpr size_t _get_chunk_size(size_t type_index)
        {
            return (0x01U << type_index);
        }

        template <size_t S>
        struct Chunk
        {
            T buf[S];
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
            friend class stream_storage;

        private:
            FORCE_INLINE ChunkBufferCRef() :
                m_buf(nullptr), m_size(0)
            {
            }

            FORCE_INLINE ChunkBufferCRef(const T * buf, size_t size) :
                m_buf(buf), m_size(size)
            {
                ASSERT_TRUE(buf && size);
            }

        public:
            FORCE_INLINE const T * get() const
            {
                return m_buf;
            }

            FORCE_INLINE size_t size() const
            {
                return m_size;
            }

        private:
            const T *   m_buf;
            size_t      m_size;
        };

        class basic_const_iterator
        {
            friend class stream_storage;

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

        FORCE_INLINE stream_storage(size_t min_chunk_size);
        FORCE_INLINE ~stream_storage();

        FORCE_INLINE void reset(size_t min_chunk_size);
        FORCE_INLINE void clear();
        FORCE_INLINE const_iterator begin() const;
        FORCE_INLINE const_iterator end() const;
        FORCE_INLINE size_t chunk_size() const;
        FORCE_INLINE size_t size() const;
        FORCE_INLINE size_t remainder() const;
        FORCE_INLINE void push_back(const T * p, size_t size);
        FORCE_INLINE T & operator[](size_t offset);
        FORCE_INLINE const T & operator[](size_t offset) const;
        FORCE_INLINE size_t copy_to(size_t offset_from, T * to_buf, size_t size) const;
        FORCE_INLINE size_t erase_front(size_t size);

    private:
        max_aligned_storage_from_mpl_container<storage_types_t> m_chunks;
        size_t                                                  m_size;
        size_t                                                  m_remainder;
    };

    //// stream_storage::basic_const_iterator

    template <typename T>
    FORCE_INLINE stream_storage<T>::basic_const_iterator::basic_const_iterator()
    {
    }

    template <typename T>
    FORCE_INLINE stream_storage<T>::basic_const_iterator::basic_const_iterator(const basic_const_iterator & it)
    {
        *this = it;
    }

    template <typename T>
    FORCE_INLINE stream_storage<T>::basic_const_iterator::basic_const_iterator(const iterator_storage_t & iterator_storage)
    {
        m_iterator_storage.construct(iterator_storage, false);
    }

    template <typename T>
    FORCE_INLINE typename stream_storage<T>::basic_const_iterator & stream_storage<T>::basic_const_iterator::operator =(const basic_const_iterator & it)
    {
        m_iterator_storage.assign(it.m_iterator_storage);

        return *this;
    }

    template <typename T>
    FORCE_INLINE typename stream_storage<T>::ChunkBufferCRef stream_storage<T>::basic_const_iterator::operator *() const
    {
        return m_iterator_storage.invoke<ChunkBufferCRef>([&](const auto & chunks_it)
        {
            return ChunkBufferCRef{ chunks_it->buf, std::size(chunks_it->buf) };
        });
    }

    template <typename T>
    FORCE_INLINE typename stream_storage<T>::ChunkBufferCRef stream_storage<T>::basic_const_iterator::operator ->() const
    {
        return this->operator *();
    }

    template <typename T>
    FORCE_INLINE bool stream_storage<T>::basic_const_iterator::operator ==(const basic_const_iterator & it) const
    {
        const int left_type_index = m_iterator_storage.type_index();
        const int right_type_index = it.m_iterator_storage.type_index();
        if (left_type_index != right_type_index) {
            throw std::runtime_error(
                (boost::format(
                    BOOST_PP_CAT(__FUNCTION__, ": incompatible iterator storages: left_type_index=%i right_type_index=%i")) %
                        left_type_index % right_type_index).str());
        }

        return m_iterator_storage.invoke<bool>([&](const auto & chunks_it)
        {
            typedef decltype(chunks_it) ref_chunk_it_t;
            typedef boost::remove_reference<ref_chunk_it_t>::type chunk_it_t;

            const auto & right_chunk_it = *static_cast<const chunk_it_t *>(it.m_iterator_storage.address());

            return chunks_it == right_chunk_it;
        });
    }

    template <typename T>
    FORCE_INLINE bool stream_storage<T>::basic_const_iterator::operator !=(const basic_const_iterator & it) const
    {
        return !this->operator ==(it);
    }

    template <typename T>
    FORCE_INLINE typename  stream_storage<T>::basic_const_iterator stream_storage<T>::basic_const_iterator::operator ++(int)
    {
        const auto it = *this;

        m_iterator_storage.invoke<void>([](auto & chunks_it)
        {
            chunks_it++;
        });

        return it;
    }

    template <typename T>
    FORCE_INLINE typename  stream_storage<T>::basic_const_iterator & stream_storage<T>::basic_const_iterator::operator ++()
    {
        m_iterator_storage.invoke<void>([](auto & chunks_it)
        {
            ++chunks_it;
        });

        return *this;
    }

    template <typename T>
    FORCE_INLINE typename stream_storage<T>::basic_const_iterator stream_storage<T>::basic_const_iterator::operator --(int)
    {
        const auto it = *this;

        m_iterator_storage.invoke<void>([](auto & chunks_it)
        {
            chunks_it--;
        });

        return it;
    }

    template <typename T>
    FORCE_INLINE typename stream_storage<T>::basic_const_iterator & stream_storage<T>::basic_const_iterator::operator --()
    {
        m_iterator_storage.invoke<void>([](auto & chunks_it)
        {
            --chunks_it;
        });

        return *this;
    }

    //// stream_storage

    template <typename T>
    FORCE_INLINE stream_storage<T>::stream_storage(size_t min_chunk_size) :
        m_size(0), m_remainder(0)
    {
        reset(min_chunk_size);
    }

    template <typename T>
    FORCE_INLINE stream_storage<T>::~stream_storage()
    {
    }

    template <typename T>
    FORCE_INLINE void stream_storage<T>::reset(size_t min_chunk_size)
    {
        ASSERT_TRUE(min_chunk_size);

        const int chunk_type_index = max_chunk_size_t::value >= min_chunk_size ? math::int_log2_ceil(min_chunk_size) : math::int_log2_ceil(max_chunk_size_t::value);
        if (chunk_type_index != m_chunks.type_index()) {
            m_chunks.construct(chunk_type_index, true);
        }
        else {
            clear();
        }
    }

    template <typename T>
    FORCE_INLINE void stream_storage<T>::clear()
    {
        m_chunks.invoke<void>([this](auto & chunks)
        {
            m_size = 0;
            m_remainder = 0;
            chunks.clear(); // at last in case if throw an exception
        });
    }

    template <typename T>
    FORCE_INLINE typename stream_storage<T>::const_iterator stream_storage<T>::begin() const
    {
        return m_chunks.invoke<const_iterator>([this](const auto & chunks)
        {
            return const_iterator(basic_const_iterator::iterator_storage_t(m_chunks.type_index(), chunks.begin()));
        });
    }

    template <typename T>
    FORCE_INLINE typename stream_storage<T>::const_iterator stream_storage<T>::end() const
    {
        return m_chunks.invoke<const_iterator>([this](const auto & chunks)
        {
            return const_iterator(basic_const_iterator::iterator_storage_t(m_chunks.type_index(), chunks.end()));
        });
    }

    template <typename T>
    FORCE_INLINE size_t stream_storage<T>::chunk_size() const
    {
        return m_chunks.invoke<size_t>([this](const auto & chunks) // to throw exception on invalid type index
        {
            return _get_chunk_size(m_chunks.type_index());
        });
    }

    template <typename T>
    FORCE_INLINE size_t stream_storage<T>::size() const
    {
        return m_size;
    }

    template <typename T>
    FORCE_INLINE size_t stream_storage<T>::remainder() const
    {
        return m_remainder;
    }

    template <typename T>
    FORCE_INLINE void stream_storage<T>::push_back(const T * buf, size_t size)
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
                    auto & last_chunk = chunks.back();

                    const size_t copy_to_remainder_size = (std::min)(chunk_size - m_remainder, left_size);
                    UTILITY_COPY(buf, last_chunk.buf + m_remainder, copy_to_remainder_size);
                    left_size -= copy_to_remainder_size;
                    buf_offset += copy_to_remainder_size;
                }

                if (!left_size) break;

                const size_t num_fixed_chunks = left_size / chunk_size;
                const size_t last_fixed_chunk_remainder = left_size % chunk_size;

                for (size_t i = 0; i < num_fixed_chunks; i++) {
                    chunks.push_back(chunk_t());

                    auto & last_chunk = chunks.back();

                    UTILITY_COPY(buf + buf_offset, last_chunk.buf, chunk_size);
                    buf_offset += chunk_size;
                }

                if (last_fixed_chunk_remainder) {
                    chunks.push_back(chunk_t());

                    auto & last_chunk = chunks.back();

                    UTILITY_COPY(buf + buf_offset, last_chunk.buf, last_fixed_chunk_remainder);
                    buf_offset += last_fixed_chunk_remainder;
                }
            }

            m_size += buf_offset;
            m_remainder = (m_remainder + buf_offset) % chunk_size;
        });
    }

    template <typename T>
    FORCE_INLINE T & stream_storage<T>::operator[](size_t offset)
    {
        ASSERT_LT(offset, size());

        return m_chunks.invoke<T &>([=](auto & chunks)
        {
            const size_t chunk_size = _get_chunk_size(m_chunks.type_index());

            const auto chunk_devrem = UINT32_DIVREM_POF2(offset, chunk_size);
            auto & chunk = chunks[chunk_devrem.quot];

            return chunk.buf[chunk_devrem.rem];
        });
    }

    template <typename T>
    FORCE_INLINE const T & stream_storage<T>::operator[](size_t offset) const
    {
        ASSERT_LT(offset, size());

        return m_chunks.invoke<const T &>([=](const auto & chunks)
        {
            const size_t chunk_size = _get_chunk_size(m_chunks.type_index());

            const auto chunk_devrem = UINT32_DIVREM_POF2(offset, chunk_size);
            const auto & chunk = chunks[chunk_devrem.quot];

            return chunk.buf[chunk_devrem.rem];
        });
    }

    template <typename T>
    FORCE_INLINE size_t stream_storage<T>::copy_to(size_t offset_from, T * to_buf, size_t to_size) const
    {
        ASSERT_LT(0U, to_size);
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
                UTILITY_COPY(chunk.buf + from_buf_offset, to_buf + to_buf_offset, to_size);
                to_buf_offset += to_size;
            }
            else {
                const auto next_chunk_divrem = UINT32_DIVREM_POF2(chunk_divrem.rem + to_size, chunk_size);
                const size_t first_chunk_size = chunk_size - chunk_divrem.rem;
                UTILITY_COPY(chunk.buf + from_buf_offset, to_buf + to_buf_offset, first_chunk_size);
                to_buf_offset += first_chunk_size;

                if (next_chunk_divrem.quot >= 1) {
                    if (next_chunk_divrem.quot >= 2) {
                        for (size_t i = 0; i < next_chunk_divrem.quot - 1; i++, to_buf_offset += chunk_size) {
                            const auto & chunk2 = chunks[chunk_divrem.quot + 1 + i];
                            UTILITY_COPY(chunk2.buf, to_buf + to_buf_offset, chunk_size);
                        }
                    }
                    auto & chunk2 = chunks[chunk_divrem.quot + next_chunk_divrem.quot];
                    const size_t last_chunk_size = next_chunk_divrem.rem;
                    UTILITY_COPY(chunk2.buf, to_buf + to_buf_offset, last_chunk_size);
                    to_buf_offset += last_chunk_size;
                }
            }

            return to_buf_offset;
        });
    }

    template <typename T>
    FORCE_INLINE size_t stream_storage<T>::erase_front(size_t size)
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
