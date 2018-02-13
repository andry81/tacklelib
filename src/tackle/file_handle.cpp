#include <tackle/file_handle.hpp>


namespace tackle
{
    const FileHandle FileHandle::s_null = FileHandle(nullptr, "nul");
}
