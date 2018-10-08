#include <utility/arc/7zip/LzmaEnc.hpp>


#if ERROR_IF_EMPTY_PP_DEF(USE_UTILITY_ARC_7ZIP_LZMA_ENCODER)

namespace utility {
namespace arc {
namespace _7zip {

    const LzmaEncoderHandle LzmaEncoderHandle::s_null           = LzmaEncoderHandle::null();

}
}
}

#endif
