#pragma once

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/assert.hpp>

#include <tackle/smart_handle.hpp>

#include <cstdio>


namespace tackle
{
    class FileHandle : public SmartHandle<FILE>
    {
        using base_type = SmartHandle;

    public:
        static const FileHandle s_null;

    private:
        FORCE_INLINE static void _deleter(void * p)
        {
            if (p) {
                fclose((FILE *)p);
            }
        }

    public:
        FORCE_INLINE FileHandle()
        {
            *this = s_null;
        }

        FORCE_INLINE FileHandle(const FileHandle &) = default;

        FORCE_INLINE FileHandle(FILE * p, const std::string & file_path) :
            base_type(p, _deleter),
            m_file_path(file_path)
        {
        }

        FORCE_INLINE void reset(const FileHandle & handle = FileHandle::s_null)
        {
            auto * deleter = DEBUG_VERIFY_TRUE(std::get_deleter<base_type::DeleterType>(handle.m_pv));
            if (!deleter) {
                // must always have a deleter
                throw std::runtime_error((boost::format("%s(%u): deleter is not allocated") %
                    UTILITY_PP_FUNCSIG % UTILITY_PP_LINE).str());
            }

            base_type::reset(handle.get(), *deleter);
            m_file_path.clear();
        }

        FORCE_INLINE const std::string & path() const
        {
            return m_file_path;
        }

        FORCE_INLINE int fileno() const
        {
#ifdef UTILITY_PLATFORM_WINDOWS
            return _fileno(get());
#elif defined(UTILITY_PLATFORM_POSIX)
            return ::fileno(get());
#else
#error platform is not implemented
#endif
        }

    private:
        std::string m_file_path;
    };
}
