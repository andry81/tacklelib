#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>

#include <string>


namespace tackle
{
    template <class t_elem, class t_traits, class t_alloc>
    class path_basic_string : public std::basic_string<t_elem, t_traits, t_alloc>
    {
    public:
        using base_type = std::basic_string<t_elem, t_traits, t_alloc>;

        FORCE_INLINE path_basic_string() = default;
        FORCE_INLINE path_basic_string(const path_basic_string & ) = default;
        FORCE_INLINE path_basic_string & operator =(const path_basic_string &) = default;

        FORCE_INLINE path_basic_string(const base_type & r) :
            base_type(r)
        {
        }

        FORCE_INLINE path_basic_string(base_type && r) :
            base_type(std::move(r))
        {
        }

        FORCE_INLINE base_type & str()
        {
            return *this;
        }

        FORCE_INLINE const base_type & str() const
        {
            return *this;
        }

        using base_type::base_type;
        using base_type::operator=;
    };

    using path_string       = path_basic_string<char, std::char_traits<char>, std::allocator<char> >;
    using path_wstring      = path_basic_string<wchar_t, std::char_traits<wchar_t>, std::allocator<wchar_t> >;

    using path_u16string    = path_basic_string<char16_t, std::char_traits<char16_t>, std::allocator<char16_t> >;
    using path_u32string    = path_basic_string<char32_t, std::char_traits<char32_t>, std::allocator<char32_t> >;

    // override operator +

    //// const std::path_basic_string &

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE path_basic_string<t_elem, t_traits, t_alloc>
        operator +(
            const path_basic_string<t_elem, t_traits, t_alloc> & l,
            const path_basic_string<t_elem, t_traits, t_alloc> & r)
    {
        const std::basic_string<t_elem, t_traits, t_alloc> & l_str = l;
        const std::basic_string<t_elem, t_traits, t_alloc> & r_str = r;

        const bool has_right = !r_str.empty();
        return path_basic_string<t_elem, t_traits, t_alloc>(
            l_str + (has_right ? "/" : "") + (has_right ? r_str : std::basic_string<t_elem, t_traits, t_alloc>{})
        );
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE path_basic_string<t_elem, t_traits, t_alloc>
        operator +(
            const path_basic_string<t_elem, t_traits, t_alloc> & l,
            const t_elem * r)
    {
        const path_basic_string<t_elem, t_traits, t_alloc> r_str{ r };
        return l + std::move(r_str);
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE path_basic_string<t_elem, t_traits, t_alloc>
        operator +(
            const t_elem * l,
            const path_basic_string<t_elem, t_traits, t_alloc> & r)
    {
        const path_basic_string<t_elem, t_traits, t_alloc> l_str{ l };
        return std::move(l_str) + r;
    }

    //// std::path_basic_string &&

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE path_basic_string<t_elem, t_traits, t_alloc>
        operator +(
            path_basic_string<t_elem, t_traits, t_alloc> && l,
            path_basic_string<t_elem, t_traits, t_alloc> && r)
    {
        std::basic_string<t_elem, t_traits, t_alloc> && l_str = std::move(l);
        std::basic_string<t_elem, t_traits, t_alloc> && r_str = std::move(r);

        const bool has_right = !r_str.empty();
        return path_basic_string<t_elem, t_traits, t_alloc>{
            std::move(l_str + (has_right ? "/" : "") + (has_right ? r_str : std::move(std::basic_string<t_elem, t_traits, t_alloc>{})))
        };
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE path_basic_string<t_elem, t_traits, t_alloc>
        operator +(
            path_basic_string<t_elem, t_traits, t_alloc> && l,
            const t_elem * r)
    {
        path_basic_string<t_elem, t_traits, t_alloc> && l_str = std::move(l);
        const path_basic_string<t_elem, t_traits, t_alloc> r_str{ r };

        return std::move(l_str + std::move(r_str));
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE path_basic_string<t_elem, t_traits, t_alloc>
        operator +(
            const t_elem * l,
            path_basic_string<t_elem, t_traits, t_alloc> && r)
    {
        const path_basic_string<t_elem, t_traits, t_alloc> l_str{ l };
        path_basic_string<t_elem, t_traits, t_alloc> && r_str = std::move(r);

        return std::move(std::move(l_str) + r_str);
    }

    //// std::path_basic_string && + std::path_basic_string &

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE path_basic_string<t_elem, t_traits, t_alloc>
        operator +(
            path_basic_string<t_elem, t_traits, t_alloc> && l,
            const path_basic_string<t_elem, t_traits, t_alloc> & r)
    {
        std::basic_string<t_elem, t_traits, t_alloc> && l_str = std::move(l);
        const std::basic_string<t_elem, t_traits, t_alloc> & r_str = r;

        const bool has_right = !r.empty();
        return path_basic_string<t_elem, t_traits, t_alloc>{
            std::move(l_str + (has_right ? "/" : "") + (has_right ? r : std::basic_string<t_elem, t_traits, t_alloc>{}))
        };
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE path_basic_string<t_elem, t_traits, t_alloc>
        operator +(
            const path_basic_string<t_elem, t_traits, t_alloc> & l,
            path_basic_string<t_elem, t_traits, t_alloc> && r)
    {
        const std::basic_string<t_elem, t_traits, t_alloc> & l_str = l;
        std::basic_string<t_elem, t_traits, t_alloc> && r_str = std::move(r);

        const bool has_right = !r_str.empty();
        return path_basic_string<t_elem, t_traits, t_alloc>{
            std::move(l_str + (has_right ? "/" : "") + (has_right ? r_str : std::move(std::basic_string<t_elem, t_traits, t_alloc>{})))
        };
    }

    //// std::path_basic_string && + std::basic_string &

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE path_basic_string<t_elem, t_traits, t_alloc>
        operator +(
            path_basic_string<t_elem, t_traits, t_alloc> && l,
            const std::basic_string<t_elem, t_traits, t_alloc> & r)
    {
        std::basic_string<t_elem, t_traits, t_alloc> && l_str = std::move(l);

        const bool has_right = !r.empty();
        return path_basic_string<t_elem, t_traits, t_alloc>{
            std::move(l_str + (has_right ? "/" : "") + (has_right ? r : std::basic_string<t_elem, t_traits, t_alloc>{}))
        };
    }

    template <class t_elem, class t_traits, class t_alloc>
    FORCE_INLINE path_basic_string<t_elem, t_traits, t_alloc>
        operator +(
            const std::basic_string<t_elem, t_traits, t_alloc> & l,
            path_basic_string<t_elem, t_traits, t_alloc> && r)
    {
        std::basic_string<t_elem, t_traits, t_alloc> && r_str = std::move(r);

        const bool has_right = !r_str.empty();
        return path_basic_string<t_elem, t_traits, t_alloc>{
            std::move(l + (has_right ? "/" : "") + (has_right ? r_str : std::move(std::basic_string<t_elem, t_traits, t_alloc>{})))
        };
    }
}
