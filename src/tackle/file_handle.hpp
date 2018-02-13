#pragma once

#include <tacklelib.hpp>

#include <tackle/smart_handle.hpp>


namespace tackle
{
    class FileHandle : public SmartHandle<FILE>
    {
        typedef SmartHandle base_type;

    public:
        static const FileHandle s_null;

    private:
        static void _deleter(void * p)
        {
            if (p) {
                fclose((FILE *)p);
            }
        }

    private:
        std::string m_file_path;

    public:
        FileHandle()
        {
            *this = s_null;
        }

        FileHandle(const FileHandle &) = default;

        FileHandle(FILE * p, const std::string & file_path) :
            base_type(p, _deleter),
            m_file_path(file_path)
        {
        }

        void reset(const FileHandle & handle = FileHandle::s_null)
        {
            base_type::reset(handle.get(), _deleter);
            m_file_path.clear();
        }

        const std::string & path() const
        {
            return m_file_path;
        }
    };
}
