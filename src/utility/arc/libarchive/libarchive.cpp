#include <utility/arc/libarchive/libarchive.hpp>


#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_ARC_LIBARCHIVE)

#include <utility/platform.hpp>
#include <utility/debug.hpp>
#include <utility/assert.hpp>
#include <utility/memory.hpp>
#include <utility/utility.hpp>

#include <tackle/file_handle.hpp>

#include <boost/format.hpp>

#include "libarchive/archive_entry.h"

#include <cstdio>
#include <cstdlib>
#include <stdexcept>

#include <fcntl.h>


namespace utility {
namespace arc {
namespace libarchive {

    void write_archive(int filter_id, int format_code, const std::string & options,
        const std::string & out_path, const std::vector<std::string> & in_filenames, size_t read_block_size)
    {
        struct archive *a;
        struct archive_entry *entry;
        struct stat st;
        utility::Buffer buf{ read_block_size };
        int len;

        a = archive_write_new();

        switch (filter_id) {
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
            throw std::runtime_error((boost::format("%s(%u): archive filter does not supported: filter_id=%u") %
                UTILITY_PP_FUNCSIG % UTILITY_PP_LINE % filter_id).str());
        }

        if (format_code) {
            archive_write_set_format(a, format_code);
        }

        if (!options.empty()) {
            archive_write_set_options(a, options.c_str());
        }

        archive_write_open_filename(a, out_path.c_str());

        for (auto in_file_name : in_filenames) {
            stat(in_file_name.c_str(), &st);

            entry = archive_entry_new();

            archive_entry_set_pathname(entry, in_file_name.c_str());
            archive_entry_set_size(entry, st.st_size);
            archive_entry_set_filetype(entry, AE_IFREG);
            archive_entry_set_perm(entry, 0644);
            archive_write_header(a, entry);

            const tackle::FileHandle in_file_handle = utility::open_file(in_file_name, "rb", utility::SharedAccess_DenyWrite); // should not be opened for writing

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
