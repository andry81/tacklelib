#include <tacklelib/tackle/file_handle.hpp>


namespace tackle
{
    template class basic_file_handle<char, std::char_traits<char>, std::allocator<char>, utility::literal_separators<char>::forward_slash_char>;
    template class basic_file_handle<wchar_t, std::char_traits<wchar_t>, std::allocator<wchar_t>, utility::literal_separators<wchar_t>::forward_slash_char>;

    template class basic_file_handle<char, std::char_traits<char>, std::allocator<char>, utility::literal_separators<char>::backward_slash_char>;
    template class basic_file_handle<wchar_t, std::char_traits<wchar_t>, std::allocator<wchar_t>, utility::literal_separators<wchar_t>::backward_slash_char>;
}
