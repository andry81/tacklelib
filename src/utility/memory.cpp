#include <utility/memory.hpp>
#include <utility/assert.hpp>
#include <utility/utility.hpp>

#include <tackle/file_handle.hpp>

#include <boost/scope_exit.hpp>

#include "inttypes.h"

#if defined(UTILITY_PLATFORM_WINDOWS)
#include "windows.h"
#include "psapi.h"
#elif defined(UTILITY_PLATFORM_POSIX)
#include "stdlib.h"
#include "stdio.h"
#include "string.h"
#else
#error platform is not implemented
#endif


namespace utility
{
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
                snprintf(tmp_buf, utility::static_size(tmp_buf), "/proc/%zu/status", proc_id);
            }
            else {
                strncpy(tmp_buf, "/proc/self/status", utility::static_size("/proc/self/status"));
            }
            const tackle::FileHandle proc_file_handle = utility::open_file(tmp_buf, "r", utility::SharedAccess_DenyNone);

            uint64_t mem_size = 0;

            while (fgets(tmp_buf, utility::static_size(tmp_buf), proc_file_handle.get())) {
                if (!strncmp(tmp_buf, "VmSize:", utility::static_size("VmSize:"))) {
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
            ASSERT_TRUE(0); // not implemented
        } break;

        default:
            ASSERT_TRUE(0);
        }

        return 0;
    }
}
