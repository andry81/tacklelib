#include <utility/memory.hpp>

#include <tackle/file_handle.hpp>

#include <boost/scope_exit.hpp>

#include "inttypes.h"

#if defined(UTILITY_PLATFORM_WINDOWS)
#include "windows.h"
#include "psapi.h"
#elif defined(UTILITY_PLATFORM_POSIX)
#include "<cstdlib>"
#include "<cstdio>"
#include "<string>"
#else
#error platform is not implemented
#endif


namespace utility {

    const char Buffer::s_guard_sequence_str[49] = "XYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZXYZ";
    const size_t Buffer::s_guard_max_len;

    // for details: https://stackoverflow.com/questions/63166/how-to-determine-cpu-and-memory-consumption-from-inside-a-process
    //
    uint64_t get_process_memory_size(MemoryType mem_type, size_t proc_id)
    {
        switch(mem_type) {
        case MemType_VirtualMemory: {
#if defined(UTILITY_PLATFORM_WINDOWS)
            PROCESS_MEMORY_COUNTERS_EX pmc;
            HANDLE proc_handle = {};

            BOOST_SCOPE_EXIT(&proc_handle, &proc_id) {
                if (proc_id) {
                    CloseHandle(proc_handle);
                    proc_handle = HANDLE{}; // just in case
                }
            } BOOST_SCOPE_EXIT_END

            if (proc_id) {
                proc_handle = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, proc_id);
            }
            else {
                proc_handle = GetCurrentProcess();
            }
            if (VERIFY_TRUE(GetProcessMemoryInfo(proc_handle, (PROCESS_MEMORY_COUNTERS *)&pmc, sizeof(pmc)))) {
                return pmc.PrivateUsage;
            }
#elif defined(UTILITY_PLATFORM_POSIX)
            char tmp_buf[256];
            if (proc_id) {
                snprintf(UTILITY_STR_WITH_STATIC_SIZE_TUPLE(tmp_buf), "/proc/%zu/status", proc_id);
            }
            else {
                strncpy(tmp_buf, UTILITY_STR_WITH_STATIC_SIZE_TUPLE("/proc/self/status"));
            }
            const tackle::FileHandle proc_file_handle = utility::open_file(tmp_buf, "r", utility::SharedAccess_DenyNone);

            uint64_t mem_size = 0;

            while (fgets(tmp_buf, utility::static_size(tmp_buf), proc_file_handle.get())) {
                if (!strncmp(tmp_buf, UTILITY_STR_WITH_STATIC_SIZE_TUPLE("VmSize:"))) {
                    mem_size = strlen(tmp_buf);
                    const char* p = tmp_buf;
                    while (*p <'0' || *p > '9') p++;
                    tmp_buf[mem_size - 3] = '\0';
                    mem_size = atoi(p);
                    break;
                }
            }

            return mem_size * 1024; // to bytes
#endif
        } break;

        case MemType_PhysicalMemory: {
            DEBUG_ASSERT_TRUE(0); // not implemented
        } break;

        default:
            DEBUG_ASSERT_TRUE(0);
        }

        return 0;
    }

    void Buffer::check_buffer_guards()
    {
        if (m_size < m_reserve) {
            CONSTEXPR const size_t guard_sequence_str_len = utility::static_size(s_guard_sequence_str) - 1;

            uint8_t * buf_ptr = m_buf_ptr.get();

            {
                const size_t guard_size = m_offset;

                const size_t num_whole_chunks = guard_size / guard_sequence_str_len;
                const size_t chunks_remainder = guard_size % guard_sequence_str_len;

                for (size_t i = 0; i < num_whole_chunks; i++) {
                    if (VERIFY_FALSE(std::memcmp(&buf_ptr[i * guard_sequence_str_len], s_guard_sequence_str, guard_sequence_str_len))) {
                        goto _error;
                    }
                }
                if (chunks_remainder) {
                    if (std::memcmp(&buf_ptr[num_whole_chunks * guard_sequence_str_len], s_guard_sequence_str, chunks_remainder)) {
                        goto _error;
                    }
                }
            }

            {
                const size_t offset = m_offset + m_size;
                const size_t guard_size = m_reserve - offset;

                const size_t num_whole_chunks = guard_size / guard_sequence_str_len;
                const size_t chunks_remainder = guard_size % guard_sequence_str_len;

                for (size_t i = 0; i < num_whole_chunks; i++) {
                    if (VERIFY_FALSE(std::memcmp(&buf_ptr[offset + i * guard_sequence_str_len], s_guard_sequence_str, guard_sequence_str_len))) {
                        goto _error;
                    }
                }
                if (chunks_remainder) {
                    if (std::memcmp(&buf_ptr[offset + num_whole_chunks * guard_sequence_str_len], s_guard_sequence_str, chunks_remainder)) {
                        goto _error;
                    }
                }
            }

            return;

        _error:;
            DEBUG_BREAK_IN_DEBUGGER(true);
            throw std::out_of_range(
                (boost::format("%s : out of buffer write: reserve=%u size=%u buffer=%p") %
                    UTILITY_PP_FUNCSIG % m_reserve % m_size % buf_ptr).str());
        }
    }

    void Buffer::_fill_buffer_guards()
    {
        if (m_size < m_reserve) {
            CONSTEXPR const size_t guard_sequence_str_len = utility::static_size(s_guard_sequence_str) - 1;

            uint8_t * buf_ptr = m_buf_ptr.get();

            {
                const size_t guard_size = m_offset;

                const size_t num_whole_chunks = guard_size / guard_sequence_str_len;
                const size_t chunks_remainder = guard_size % guard_sequence_str_len;

                for (size_t i = 0; i < num_whole_chunks; i++) {
                    memcpy(&buf_ptr[i * guard_sequence_str_len], s_guard_sequence_str, guard_sequence_str_len);
                }
                if (chunks_remainder) {
                    memcpy(&buf_ptr[num_whole_chunks * guard_sequence_str_len], s_guard_sequence_str, chunks_remainder);
                }
            }

            {
                const size_t offset = m_offset + m_size;
                const size_t guard_size = m_reserve - offset;

                const size_t num_whole_chunks = guard_size / guard_sequence_str_len;
                const size_t chunks_remainder = guard_size % guard_sequence_str_len;

                for (size_t i = 0; i < num_whole_chunks; i++) {
                    memcpy(&buf_ptr[offset + i * guard_sequence_str_len], s_guard_sequence_str, guard_sequence_str_len);
                }
                if (chunks_remainder) {
                    memcpy(&buf_ptr[offset + num_whole_chunks * guard_sequence_str_len], s_guard_sequence_str, chunks_remainder);
                }
            }
        }
    }

}
