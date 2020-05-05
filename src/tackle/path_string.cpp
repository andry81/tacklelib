#include <tacklelib/tackle/path_string.hpp>


#define TACKLELIB_PATH_STRING_IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char_, literal_separator_type_) \
    template class path_basic_string<char_, std::char_traits<char_>, std::allocator<char_>, utility::literal_separators<char_>::literal_separator_type_>

namespace tackle
{
    TACKLELIB_PATH_STRING_IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char, forward_slash_char);
    TACKLELIB_PATH_STRING_IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char, backward_slash_char);

    TACKLELIB_PATH_STRING_IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(wchar_t, forward_slash_char);
    TACKLELIB_PATH_STRING_IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(wchar_t, backward_slash_char);

    TACKLELIB_PATH_STRING_IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char16_t, forward_slash_char);
    TACKLELIB_PATH_STRING_IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char16_t, backward_slash_char);

    TACKLELIB_PATH_STRING_IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char32_t, forward_slash_char);
    TACKLELIB_PATH_STRING_IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0(char32_t, backward_slash_char);
}

#undef TACKLELIB_PATH_STRING_IMPLEMENT_TEMPLATE_INSTANCE_VARIANT_0 // just in case
