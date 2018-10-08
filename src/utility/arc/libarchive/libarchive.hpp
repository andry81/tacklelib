#pragma once

#include <tacklelib.hpp>

#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_ARC_LIBARCHIVE)

#include "libarchive/archive.h"

#include <cstdint>
#include <string>
#include <vector>


namespace utility {
namespace arc {
namespace libarchive {

    void write_archive(int filter_id, int format_code, const std::string & options,
        const std::string & out_path, const std::vector<std::string> & in_filenames, size_t read_block_size);

}
}
}

#endif
