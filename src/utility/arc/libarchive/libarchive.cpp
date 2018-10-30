#include <utility/arc/libarchive/libarchive.hpp>

#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_ARC_LIBARCHIVE)

#include <utility/platform.hpp>
#include <utility/debug.hpp>
#include <utility/assert.hpp>
#include <utility/memory.hpp>
#include <utility/utility.hpp>

#include <tackle/file_handle.hpp>
#include <tackle/path_string.hpp>

#include <fmt/format.h>

#include "libarchive/archive_entry.h"

#include <cstdio>
#include <cstdlib>
#include <stdexcept>

#include <fcntl.h>
#include <sys/stat.h>
#ifdef UTILITY_COMPILER_CXX_MSC
#include <io.h>
#else
#include <unistd.h>
#endif


namespace utility {
namespace arc {
namespace libarchive {

    void write_archive(const std::vector<int> & input_filter_ids, int format_code, const std::string & options,
        const std::string & out_path, const std::string & in_dir, const std::vector<std::string> & in_file_paths, size_t read_block_size)
    {
        struct archive *a;
        struct archive_entry *entry;
        struct stat st;
        utility::Buffer buf{ read_block_size };
        int len;

        a = archive_write_new();

        for (auto filter_id : input_filter_ids) {
            switch (filter_id) {
            case ARCHIVE_FILTER_NONE:
                break;
            case ARCHIVE_FILTER_GZIP:
                archive_write_add_filter_gzip(a);
                break;
            case ARCHIVE_FILTER_BZIP2:
                archive_write_add_filter_bzip2(a);
                break;
            case ARCHIVE_FILTER_COMPRESS:
                archive_write_add_filter_compress(a);
                break;
            case ARCHIVE_FILTER_LZMA:
                archive_write_add_filter_lzma(a);
                break;
            case ARCHIVE_FILTER_XZ:
                archive_write_add_filter_xz(a);
                break;
            case ARCHIVE_FILTER_UU:
                archive_write_add_filter_uuencode(a);
                break;
            case ARCHIVE_FILTER_LZIP:
                archive_write_add_filter_lzip(a);
                break;
            case ARCHIVE_FILTER_LRZIP:
                archive_write_add_filter_lrzip(a);
                break;
            case ARCHIVE_FILTER_LZOP:
                archive_write_add_filter_lzop(a);
                break;
            case ARCHIVE_FILTER_GRZIP:
                archive_write_add_filter_grzip(a);
                break;
            case ARCHIVE_FILTER_LZ4:
                archive_write_add_filter_lz4(a);
                break;
            case ARCHIVE_FILTER_ZSTD:
                archive_write_add_filter_zstd(a);
                break;

                // not supported
            default:
                DEBUG_BREAK_IN_DEBUGGER(true);
                throw std::runtime_error(
                    fmt::format("{:s}({:d}): archive filter does not supported: filter_id={:d}",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE, filter_id));
            }
        }

        if (format_code) {
            archive_write_set_format(a, format_code);
        }

        if (!options.empty()) {
            archive_write_set_options(a, options.c_str());
        }

        archive_write_open_filename(a, out_path.c_str());

        for (auto in_file_path : in_file_paths) {
            const tackle::path_string in_file = tackle::path_string{ in_dir } +in_file_path;

            stat(in_file.c_str(), &st);

            entry = archive_entry_new();

            archive_entry_set_pathname(entry, in_file_path.c_str());
            archive_entry_set_size(entry, st.st_size);
            archive_entry_set_filetype(entry, AE_IFREG);
            archive_entry_set_ctime(entry, st.st_ctime, 0);
            archive_entry_set_atime(entry, st.st_atime, 0);
            archive_entry_set_mtime(entry, st.st_mtime, 0);
            archive_entry_set_uid(entry, st.st_uid);
            archive_entry_set_dev(entry, st.st_dev);
            archive_entry_set_gid(entry, st.st_gid);
            archive_entry_set_ino(entry, st.st_ino);
            archive_entry_set_nlink(entry, st.st_nlink);
            archive_entry_set_rdev(entry, st.st_rdev);
            archive_entry_set_perm(entry, 0644);
            archive_entry_set_mode(entry, st.st_mode);
            archive_write_header(a, entry);

            const tackle::FileHandle in_file_handle = utility::open_file(in_file.c_str(), "rb", utility::SharedAccess_DenyWrite); // should not be opened for writing

            const int in_file_desc = in_file_handle.fileno();
            len = read(in_file_desc, buf.get(), buf.size());
            while (len > 0) {
                archive_write_data(a, buf.get(), len);
                len = read(in_file_desc, buf.get(), buf.size());
            }

            archive_entry_free(entry);
        }

        archive_write_close(a);
        archive_write_free(a);
    }

}
}
}

#endif
