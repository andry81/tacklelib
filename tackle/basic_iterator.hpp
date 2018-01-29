#pragma once


#include "tacklelib.hpp"

#include <utility/platform.hpp>

#include <boost/type_traits/remove_const.hpp>

#include <utility>


namespace tackle
{
    template <typename T, typename C, typename Friend>
    class basic_const_iterator;

    template <typename K, typename T, typename C, typename Friend>
    class basic_map_const_iterator;

    // externally because the MSVC2015 compiler for some reason does not want to inline it when defined inside the class!
    template <typename T, typename C, typename Friend>
    basic_const_iterator<T, C, Friend> operator ++(basic_const_iterator<T, C, Friend> & r, int);
    template <typename T, typename C, typename Friend>
    basic_const_iterator<T, C, Friend> operator --(basic_const_iterator<T, C, Friend> & r, int);

    // for not associative containers
    template <typename T, typename C, typename Friend>
    class basic_const_iterator
    {
        friend typename Friend;

        template <typename T, typename C, typename Friend>
        friend basic_const_iterator<T, C, Friend> operator ++(basic_const_iterator<T, C, Friend> & r, int);
        template <typename T, typename C, typename Friend>
        friend basic_const_iterator<T, C, Friend> operator --(basic_const_iterator<T, C, Friend> & r, int);

        FORCE_INLINE basic_const_iterator(const typename C::const_iterator & it);

    public:
        FORCE_INLINE basic_const_iterator();
        FORCE_INLINE basic_const_iterator(const basic_const_iterator & r) = default;

        FORCE_INLINE basic_const_iterator & operator=(const basic_const_iterator & r) = default;

        FORCE_INLINE const T & operator *() const;
        FORCE_INLINE const T * operator ->() const;

        FORCE_INLINE bool operator ==(const basic_const_iterator &) const;
        FORCE_INLINE bool operator !=(const basic_const_iterator &) const;

        FORCE_INLINE basic_const_iterator & operator ++();
        FORCE_INLINE basic_const_iterator & operator --();

    private:
        typename C::const_iterator m_it;
    };

    // externally because the MSVC2015 compiler for some reason does not want to inline it when defined inside the class!
    template <typename K, typename T, typename C, typename Friend>
    basic_map_const_iterator<K, T, C, Friend> operator ++(basic_map_const_iterator<K, T, C, Friend> & r, int);
    template <typename K, typename T, typename C, typename Friend>
    basic_map_const_iterator<K, T, C, Friend> operator --(basic_map_const_iterator<K, T, C, Friend> & r, int);

    // for associative map containers
    template <typename K, typename T, typename C, typename Friend>
    class basic_map_const_iterator
    {
        friend typename Friend;

        template <typename T, typename C, typename Friend>
        friend basic_const_iterator<T, C, Friend> operator ++(basic_const_iterator<T, C, Friend> & r, int);
        template <typename T, typename C, typename Friend>
        friend basic_const_iterator<T, C, Friend> operator --(basic_const_iterator<T, C, Friend> & r, int);

        FORCE_INLINE basic_map_const_iterator(const typename C::const_iterator & it);

    public:
        typedef typename boost::remove_const<K>::type key_t;
        typedef std::pair<const key_t, T> pair_t;

        FORCE_INLINE basic_map_const_iterator();
        FORCE_INLINE basic_map_const_iterator(const basic_map_const_iterator &) = default;

        FORCE_INLINE basic_map_const_iterator & operator=(const basic_map_const_iterator &) = default;

        FORCE_INLINE const pair_t & operator *() const;
        FORCE_INLINE const pair_t * operator ->() const;

        FORCE_INLINE bool operator ==(const basic_map_const_iterator &) const;
        FORCE_INLINE bool operator !=(const basic_map_const_iterator &) const;

        FORCE_INLINE basic_map_const_iterator & operator ++();
        FORCE_INLINE basic_map_const_iterator & operator --();

    private:
        typename C::const_iterator m_it;
    };

    //// basic_const_iterator friends

    template <typename T, typename C, typename Friend>
    FORCE_INLINE basic_const_iterator<T, C, Friend> operator ++(basic_const_iterator<T, C, Friend> & r, int)
    {
        const auto it = r;
        r.m_it++;
        return it;
    }

    template <typename T, typename C, typename Friend>
    FORCE_INLINE basic_const_iterator<T, C, Friend> operator --(basic_const_iterator<T, C, Friend> & r, int)
    {
        const auto it = r;
        r.m_it--;
        return it;
    }

    //// basic_const_iterator

    template <typename T, typename C, typename Friend>
    FORCE_INLINE basic_const_iterator<T, C, Friend>::basic_const_iterator() :
        m_it()
    {
    }

    template <typename T, typename C, typename Friend>
    FORCE_INLINE basic_const_iterator<T, C, Friend>::basic_const_iterator(const typename C::const_iterator & it) :
        m_it(it)
    {
    }

    template <typename T, typename C, typename Friend>
    FORCE_INLINE const T & basic_const_iterator<T, C, Friend>::operator *() const
    {
        return *m_it;
    }

    template <typename T, typename C, typename Friend>
    FORCE_INLINE const T * basic_const_iterator<T, C, Friend>::operator ->() const
    {
        return m_it.operator->();
    }

    template <typename T, typename C, typename Friend>
    FORCE_INLINE bool basic_const_iterator<T, C, Friend>::operator ==(const basic_const_iterator & it) const
    {
        return m_it == it.m_it;
    }

    template <typename T, typename C, typename Friend>
    FORCE_INLINE bool basic_const_iterator<T, C, Friend>::operator !=(const basic_const_iterator & it) const
    {
        return m_it != it.m_it;
    }

    template <typename T, typename C, typename Friend>
    FORCE_INLINE basic_const_iterator<T, C, Friend> & basic_const_iterator<T, C, Friend>::operator ++()
    {
        ++m_it;
        return *this;
    }

    template <typename T, typename C, typename Friend>
    FORCE_INLINE basic_const_iterator<T, C, Friend> & basic_const_iterator<T, C, Friend>::operator --()
    {
        --m_it;
        return *this;
    }


    //// basic_map_const_iterator friends

    template <typename K, typename T, typename C, typename Friend>
    FORCE_INLINE basic_map_const_iterator<K, T, C, Friend> operator ++(basic_map_const_iterator<K, T, C, Friend> & r, int)
    {
        const auto it = r;
        r.m_it++;
        return it;
    }

    template <typename K, typename T, typename C, typename Friend>
    FORCE_INLINE basic_map_const_iterator<K, T, C, Friend> operator --(basic_map_const_iterator<K, T, C, Friend> & r, int)
    {
        const auto it = r;
        r.m_it--;
        return it;
    }

    //// basic_map_const_iterator

    template <typename K, typename T, typename C, typename Friend>
    FORCE_INLINE basic_map_const_iterator<K, T, C, Friend>::basic_map_const_iterator() :
        m_it()
    {
    }

    template <typename K, typename T, typename C, typename Friend>
    FORCE_INLINE basic_map_const_iterator<K, T, C, Friend>::basic_map_const_iterator(const typename C::const_iterator & it) :
        m_it(it)
    {
    }

    template <typename K, typename T, typename C, typename Friend>
    FORCE_INLINE const typename basic_map_const_iterator<K, T, C, Friend>::pair_t & basic_map_const_iterator<K, T, C, Friend>::operator *() const
    {
        return *m_it;
    }

    template <typename K, typename T, typename C, typename Friend>
    FORCE_INLINE const typename basic_map_const_iterator<K, T, C, Friend>::pair_t * basic_map_const_iterator<K, T, C, Friend>::operator ->() const
    {
        return m_it.operator->();
    }

    template <typename K, typename T, typename C, typename Friend>
    FORCE_INLINE bool basic_map_const_iterator<K, T, C, Friend>::operator ==(const basic_map_const_iterator & it) const
    {
        return m_it == it.m_it;
    }

    template <typename K, typename T, typename C, typename Friend>
    FORCE_INLINE bool basic_map_const_iterator<K, T, C, Friend>::operator !=(const basic_map_const_iterator & it) const
    {
        return m_it != it.m_it;
    }

    template <typename K, typename T, typename C, typename Friend>
    FORCE_INLINE basic_map_const_iterator<K, T, C, Friend> & basic_map_const_iterator<K, T, C, Friend>::operator ++()
    {
        ++m_it;
        return *this;
    }

    template <typename K, typename T, typename C, typename Friend>
    FORCE_INLINE basic_map_const_iterator<K, T, C, Friend> & basic_map_const_iterator<K, T, C, Friend>::operator --()
    {
        --m_it;
        return *this;
    }

}
