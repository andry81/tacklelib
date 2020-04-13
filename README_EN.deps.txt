* README_EN.deps.txt
* 2020.04.12
* tacklelib

1. DESCRIPTION
2. DEPENDECIES

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------

See in `README_EN.txt` file.

-------------------------------------------------------------------------------
2. DEPENDECIES
-------------------------------------------------------------------------------

Legend:

00 demand:
    the dependency demand/optionality

01 platform:
    the dependency platform

02 version:
    the dependency base/minimal/exact version/revision/hash

03 desc:
    the dependency description

04 forked:
    the dependency forked storage or URL variants

05 original:
    the dependency original storage or URL variants

06 build:
    the dependency build variants

07 linkage:
    the dependency linkage variants

08 variables:
    the dependency configuration variables in a dependentee project

09 patched:
    the dependency has having applied patches

10 extended:
    the dependency has having wrappers, interfaces or extensions in other
    dependencies or in itself

11 included:
    the dependency sources inclusion variants into a dependentee project

12 macroses:
    a dependentee project macroses and definitions associated with the
    dependency

13 used as:
    the dependency usage variants

14 depend on:
    the dependency immediate dependent of variants from


# utility

* boost
  00 demand:    REQUIRED
  01 platform:  WINDOWS, LINUX
  02 version:   1.62+
  03 desc:      C++ generic library
  04 forked:    [01] https://github.com/andry81/tacklelib--3dparty--boost.git
  05 original:  [01] https://www.boost.org
                [02] https://github.com/boostorg/boost
                [03] https://dl.bintray.com/boostorg/release/
  06 build:     (default)   standalone build from sources
  07 linkage:   (default)   prebuilded shared libraries
                (optional)  prebuilded static libraries
  08 variables: BOOST_ROOT, Boost_ARCHITECTURE
  09 patched:   NO
  10 extended:  NO
! 11 included:  NO, must be downloaded separately
  12 macroses:
  13 used as:   headers, static libraries, shared libraries
  14 depend on: NO

* fmt
  00 demand:    REQUIRED
  01 platform:  WINDOWS, LINUX
  02 version:   release 6.2.0
                #9bdd1596cef1b57b9556f8bef32dc4a32322ef3e (2020.04.05)
                from https://github.com/fmtlib/fmt/releases/tag/6.2.0 (https://fmt.dev/6.2.0/ )
                (https://github.com/fmtlib/fmt/commit/9bdd1596cef1b57b9556f8bef32dc4a32322ef3e )
  03 desc:      C++ string safe formatter
  04 forked:    [01] https://sf.net/p/tacklelib/3dparty--fmt
                [02] https://github.com/andry81/tacklelib--3dparty--fmt.git
  05 original:  [01] https://github.com/fmtlib/fmt
  06 build:     (default)   build from sources in a dependentee project
  07 linkage:   (default)   as a static library
  08 variables: UTILITY_FMT_ROOT
  09 patched:   NO
  10 extended:  YES:
                [01] minor, `fmt/format.hpp` in tacklelib sources, partial
                std::wstring support
! 11 included:  NO, must be downloaded separately
  12 macroses:  USE_UTILITY_UTILITY_FMT
  13 used as:   headers, static libraries
  14 depend on: NO

* pystring
  00 demand:    OPTIONAL
  01 platform:  WINDOWS, LINUX
  02 version:   above release 1.1.3
                #281419de2f91f9e0f2df6acddfea3b06a43436be (2020.02.04)
                from https://github.com/imageworks/pystring/commits/master
                (https://github.com/imageworks/pystring/commit/281419de2f91f9e0f2df6acddfea3b06a43436be )
  03 desc:      C++ python string functions
  04 forked:    [01] https://sf.net/p/tacklelib/3dparty--pystring
                [02] https://github.com/andry81/tacklelib--3dparty--pystring.git
  05 original:  [01] https://github.com/imageworks/pystring
  06 build:     (default) build from sources in a dependentee project
  07 linkage:   (default) as a static library
  08 variables: UTILITY_PYSTRING_ROOT
  09 patched:   YES
  10 extended:  YES:
                [01] `cmakelist.txt` file based on extensions from the
                tacklelib library cmake modules
                [02] partial std::wstring support
! 11 included:  NO, must be downloaded separately
  12 macroses:
  13 used as:   headers, static libraries
  14 depend on: YES:
                [01] (optional) tacklelib--cmake

* libexpat-dev:i386
  00 demand:    OPTIONAL
  01 platform:  LINUX ONLY
  02 version:   N/A
  03 desc:      stream-oriented XML parser 
  04 forked:    NO
  05 original:  UNKNOWN
  06 build:     UNKNOWN
  07 linkage:   UNKNOWN
  08 variables:
  09 patched:   UNKNOWN
  10 extended:  NO
  11 included:  N/A
  12 macroses:
  13 used as:   libarchive dependency, linux packet
  14 depend on: UNKNOWN

# log

* p7 logger
  00 demand:    OPTIONAL
  01 platform:  WINDOWS, LINUX
  02 version:   release 5.5
                (2020.03.09)
                from http://baical.net/downloads.html
  03 desc:      C++ (in C-style) client/server fast logger with support of
                logging into text/binary file or into network and gui
                application to open the binary log file or recieve log from
                network
  04 forked:    [01] https://sf.net/p/tacklelib/3dparty--p7client
                [02] https://github.com/andry81/tacklelib--3dparty--p7client.git
  05 original:  [01] http://baical.net/p7.html
                [02] http://baical.net/downloads.html
  06 build:     (default) build from sources in a dependentee project
  07 linkage:   (default) as a static library
  08 variables: LOG_P7_CLIENT_ROOT
  09 patched:   YES
  10 extended:  YES:
                [01] `cmakelist.txt` file based on extensions from the
                tacklelib library cmake modules
                [02] C++11 interface with auto handles in the tacklelib
                library: `p7_logger.hpp`
! 11 included:  NO, must be downloaded separately
  12 macroses:  USE_UTILITY_LOG_P7_LOGGER
  13 used as:   headers, static libraries
  14 depend on: YES:
                [01] (optional) tacklelib--cmake

# arc

* libarchive
  00 demand:    OPTIONAL
  01 platform:  WINDOWS, LINUX
  02 version:   release 3.4.2
                #3288ebb0353beb51dfb09d444dedbe9235ead53d (2020.02.12)
                from https://github.com/libarchive/libarchive
                (https://github.com/libarchive/libarchive/commit/3288ebb0353beb51dfb09d444dedbe9235ead53d )
  03 desc:      C archive pipeline/filter library to organize access to
                compress algorithms in 3dparty libraries which must be attached
                separately
  04 forked:    NO
  05 original:  [01] https://www.libarchive.org
                [02] https://www.libarchive.org/downloads/
                [03] https://github.com/libarchive/libarchive
  06 build:     (default) build from sources in a dependentee project
  07 linkage:   (default) as a static library
  08 variables: ARC_LIBARCHIVE_ROOT, ENABLE_LZMA
  09 patched:   YES, not published
  10 extended:  YES:
                [01] C++11 interface with auto handles in the tacklelib
                library: `libarchive.hpp`
! 11 included:  NO, must be downloaded separately
  12 macroses:  USE_UTILITY_ARC_LIBARCHIVE
  13 used as:   headers, static libraries
  14 depend on: YES:
                [01] (optional) xz utils

* xz utils
  00 demand:    OPTIONAL
  01 platform:  WINDOWS, LINUX
  02 version:   release 5.2.5
                #2327a461e1afce862c22269b80d3517801103c1b (2020.03.17)
                from https://git.tukaani.org/?p=xz.git
                (https://git.tukaani.org/?p=xz.git;a=commit;h=2327a461e1afce862c22269b80d3517801103c1b )
  03 desc:      C compress algorithms library
  04 forked:    NO
  05 original:  [01] https://tukaani.org/xz/
                [02] https://git.tukaani.org/xz.git
                [03] https://git.tukaani.org/?p=xz.git
                [04] https://sf.net/p/lzmautils
  06 build:     (default) indirectly from libarchive build
  07 linkage:   (default) indirectly from libarchive build
  08 variables: ARC_XZ_UTILS_ROOT, LIBLZMA_INCLUDE_DIR, LIBLZMA_LIBRARY,
                LIBLZMA_HAS_AUTO_DECODER, LIBLZMA_HAS_EASY_ENCODER,
                LIBLZMA_HAS_LZMA_PRESET
  09 patched:   NO
  10 extended:  YES:
                [01] `cmakelist.txt` file based on extensions from the
                tacklelib library cmake modules
! 11 included:  NO, must be downloaded separately
  12 macroses:
  13 used as:   indirectly from libarchive sources
  14 depend on: YES:
                [01] (optional) tacklelib--cmake

* 7zip
  00 demand:    OPTIONAL
  01 platform:  WINDOWS ONLY
  02 version:   18.06
                (2018.12.30)
                from https://www.7-zip.org/download.html
                (https://www.7-zip.org/a/lzma1806.7z )
  03 desc:      C/C++ compress algorithms library
  04 forked:    NO
  05 original:  [01] (windows only)  https://www.7-zip.org/sdk.html
                [02] (linux only)    http://p7zip.sourceforge.net
  06 build:     N/A
  07 linkage:   N/A
  08 variables: ARC_7ZIP_ROOT
  09 patched:   NO
  10 extended:  YES:
                [01] `cmakelist.txt` file based on extensions from the
                tacklelib library cmake modules
                [02] C++11 interface with auto handles in the tacklelib
                library: `7zip/LzmaEnc.hpp`
! 11 included:  NO, must be downloaded separately
  12 macroses:  USE_UTILITY_ARC_7ZIP_LZMA_ENCODER
  13 used as:   DEPRICATED, because of existence a not affordable variants
                between Windows and Linux: Windows has sources which does not
                build on Linux and Linux has a different major version of
                sources which has not been backported on Windows
  14 depend on: YES:
                [01] (optional) tacklelib--cmake

* libz-dev:i386
  00 demand:    OPTIONAL
  01 platform:  LINUX ONLY
  02 version:   N/A
  03 desc:      zlib linux packet
  04 forked:    NO
  05 original:  UNKNOWN
  06 build:     UNKNOWN
  07 linkage:   UNKNOWN
  08 variables:
  09 patched:   UNKNOWN
  10 extended:  NO
  11 included:  N/A
  12 macroses:
  13 used as:   libarchive dependency, linux packet
  14 depend on: UNKNOWN

# math

* qd
  00 demand:    OPTIONAL
  01 platform:  WINDOWS, LINUX
  02 version:   release 2.3.22
                (2018.11.09)
                from http://crd-legacy.lbl.gov/~dhbailey/mpdist/
  03 desc:      C++ floating point high precision extension library
                (double-double, quad-double)
  04 forked:    [01] https://sf.net/p/orbittools/qd_
                [02] https://github.com/andry81/orbittools--qd.git
  05 original:  [01] http://crd-legacy.lbl.gov/~dhbailey/mpdist/
                [02] http://crd.lbl.gov/software/applied-mathematics-software/
  06 build:     (default) build from sources in a dependentee project
  07 linkage:   (default) as a static library
  08 variables: QD_ROOT
  09 patched:   YES
  10 extended:  YES:
                [01] `cmakelist.txt` file based on extensions from the
                tacklelib library cmake modules
! 11 included:  NO, must be downloaded separately
  12 macroses:  ENABLE_QD_INTEGRATION, ENABLE_QD_DD_INTEGRATION,
                ENABLE_QD_QD_INTEGRATION
  13 used as:   headers, static libraries
  14 depend on: YES:
                [01] (optional) tacklelib--cmake

# test

* google test
  00 demand:    OPTIONAL
  01 platform:  WINDOWS, LINUX
  02 version:   release 1.10.0
                #703bd9caab50b139428cea1aaff9974ebee5742e (2019.10.03)
                from https://github.com/google/googletest/releases/tag/release-1.10.0
                (https://github.com/google/googletest/commit/703bd9caab50b139428cea1aaff9974ebee5742e )
  03 desc:      C++ test library
  04 forked:    [01] https://sf.net/p/tacklelib/3dparty--googletest
                [02] https://github.com/andry81/tacklelib--3dparty--googletest.git
  05 original:  [01] https://github.com/google/googletest
                [02] https://github.com/abseil/googletest
  06 build:     (default)   build from sources in a dependentee project
  07 linkage:   (default)   as a static library
  08 variables: GTEST_ROOT, GOOGLETEST_VERSION
  09 patched:   YES
  10 extended:  YES:
                [01] asserts replacement in the tacklelib library:
                `src/utility/assert.hpp` (but not in the `include/`)
                [02] standalone test case declaration in the tacklelib library:
                `testlib/testlib.hpp`
                [03] new expect macro with predicate function declaration
                in the tacklelib libray:
                `testlib/gtest_ext.hpp`
! 11 included:  NO, must be downloaded separately
  12 macroses:  GTEST_INCLUDE_FROM_EXTERNAL
  13 used as:   headers, static libraries
  14 depend on: NO
