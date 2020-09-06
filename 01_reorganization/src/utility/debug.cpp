#include <tacklelib/utility/debug.hpp>
#include <tacklelib/utility/platform.hpp>

#if defined(UTILITY_PLATFORM_WINDOWS)
// windows includes must be ordered here!
#   include <windef.h>
#   include <winbase.h>
//#   include <winnt.h>
#   include <intrin.h>
#elif defined(UTILITY_PLATFORM_POSIX)
#   if !defined(UTILITY_PLATFORM_MINGW)
#       include <sys/ptrace.h>
#   else
  #       include <w32api/debugapi.h>
//#      include <sys/stat.h>
//#      include <string.h>
//#      include <fcntl.h>
#   endif
#   include <signal.h>
//static void signal_handler(int) { }
#else
#   error is_under_debugger is not supported for this platform
#endif


namespace utility {

void debug_break(bool condition)
{
    DEBUG_BREAK_IN_DEBUGGER(condition); // avoid signal if not under debugger
}

bool is_under_debugger()
{
#if defined(UTILITY_PLATFORM_WINDOWS)
    return ::IsDebuggerPresent() ? true : false;
#elif defined(UTILITY_PLATFORM_POSIX)
#   if !defined(UTILITY_PLATFORM_MINGW)
    return ptrace(PTRACE_TRACEME, 0, NULL, 0) == -1;
#   else
    return ::IsDebuggerPresent() ? true : false;
    //// base on: http://stackoverflow.com/questions/3596781/detect-if-gdb-is-running
    ////
    //bool debugger_present = false;
    //
    //int status_fd = open("/proc/self/status", O_RDONLY);
    //if (status_fd == -1) {
    //    return false;
    //}
    //
    //ssize_t num_read = read(status_fd, buf, sizeof(buf));
    //
    //if (num_read > 0) {
    //    static const char TracerPid[] = "TracerPid:";
    //
    //    char buf[1024];
    //    char *tracer_pid = strstr(buf, TracerPid);
    //
    //    if (tracer_pid)
    //        debugger_present = atoi(tracer_pid + sizeof(TracerPid) - 1) ? true : false;
    //}
    //
    //return debugger_present;
#   endif
#endif
}

}
