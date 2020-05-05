#include <tacklelib/tackle/path_string.hpp>


#define IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char_) \
    template class path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char>; \
    template class path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::backward_slash_char>

#if 0
    template path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> operator+ ( \
        path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> l, \
        std::basic_string<char_, std::char_traits<char_>, std::allocator<char_> > r); \
    \
    template path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> operator+ ( \
        std::basic_string<char_, std::char_traits<char_>, std::allocator<char_>> l, \
        path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> r); \
    \
    template path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> operator+ ( \
        path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> l, \
        path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> r); \
    \
    template path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> LIBRARY_API_DECL operator+ ( \
        path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> l, \
        const char_ * p); \
    \
    template path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> LIBRARY_API_DECL operator+ ( \
        const char_ * p, \
        path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::forward_slash_char> r)
#endif

namespace tackle
{
    IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char);
    IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(wchar_t);
    IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char16_t);
    IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char32_t);
}
