#include <tackle/path_string.hpp>


namespace tackle
{
    template class path_basic_string<char, std::char_traits<char>, std::allocator<char> >;
    template class path_basic_string<wchar_t, std::char_traits<wchar_t>, std::allocator<wchar_t> >;

    template class path_basic_string<char16_t, std::char_traits<char16_t>, std::allocator<char16_t> >;
    template class path_basic_string<char32_t, std::char_traits<char32_t>, std::allocator<char32_t> >;
}
