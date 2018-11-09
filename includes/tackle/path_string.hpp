#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/assert.hpp>

#include <tackle/string.hpp>

#include <string>


// See details around problems related to this class implementation:
//  https://stackoverflow.com/questions/53155089/stdstring-class-inheritance-and-tedious-c-overload-resolution
//  https://godbolt.org/z/jhcWoh
//

namespace tackle
{
    template <class t_elem, class t_traits, class t_alloc>
    class path_basic_string : public std::basic_string<t_elem, t_traits, t_alloc>
    {
    public:
        using base_type = std::basic_string<t_elem, t_traits, t_alloc>;

        FORCE_INLINE path_basic_string() = default;
        FORCE_INLINE path_basic_string(const path_basic_string &) = default;
        FORCE_INLINE path_basic_string(path_basic_string &&) = default;

        FORCE_INLINE path_basic_string & operator =(path_basic_string path_str)
        {
            this->base_type::operator=(std::move(path_str));
            return *this;
        }

        FORCE_INLINE path_basic_string(base_type r) :
            base_type(std::move(r))
        {
        }

        FORCE_INLINE path_basic_string(const t_elem * p) :
            base_type(DEBUG_VERIFY_TRUE(p))
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

        FORCE_INLINE path_basic_string & operator+= (base_type r)
        {
            base_type && r_path = std::move(r);

            base_type & base_this = *this;
            if (!r.empty()) {
                if (!empty()) {
                    base_this += UTILITY_LITERAL_STRING("/", t_elem);
                }
                base_this += r_path;
            }

            return *this;
        }

        FORCE_INLINE path_basic_string & operator+= (const t_elem * p)
        {
            DEBUG_ASSERT_TRUE(p);

            base_type & base_this = *this;
            if (*p) {
                if (!empty()) {
                    base_this += UTILITY_LITERAL_STRING("/", t_elem);
                }
                base_this += p;
            }

            return *this;
        }

        friend FORCE_INLINE path_basic_string operator+ (base_type l, base_type r)
        {
            path_basic_string && l_path = std::move(l);
            path_basic_string && r_path = std::move(r);
            l_path += r_path;
            return l_path;
        }

        friend FORCE_INLINE path_basic_string operator+ (base_type l, const t_elem * p)
        {
            DEBUG_ASSERT_TRUE(p);

            path_basic_string && l_path = std::move(l);
            if (*p) {
                l_path += p;
            }
            return l_path;
        }

        friend FORCE_INLINE path_basic_string operator+ (const t_elem * p, base_type r)
        {
            DEBUG_ASSERT_TRUE(p);

            base_type && r_path = std::move(r);
            if (!r_path.empty()) {
                if (*p) {
                    // call base operator instead in case if it is specialized for this
                    return p + (UTILITY_LITERAL_STRING("/", t_elem) + r_path);
                }

                return r_path;
            }

            return p;
        }
    };

    using path_string       = path_basic_string<char, std::char_traits<char>, std::allocator<char> >;
    using path_wstring      = path_basic_string<wchar_t, std::char_traits<wchar_t>, std::allocator<wchar_t> >;

    using path_u16string    = path_basic_string<char16_t, std::char_traits<char16_t>, std::allocator<char16_t> >;
    using path_u32string    = path_basic_string<char32_t, std::char_traits<char32_t>, std::allocator<char32_t> >;
}
