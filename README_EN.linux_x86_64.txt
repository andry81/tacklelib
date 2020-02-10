* README_EN.linux_x86_64.txt
* 2020.02.10
* tacklelib

1. DESCRIPTION
2. DEPENDENCIES
3. PREREQUISITES
3.1. Linux Mint 18.3 x64
3.1.1. Preconfiguration
3.1.2. Locale
3.1.3. apt-get
3.1.4. GCC
3.1.5. 3dparty libraries
3.1.6. 3dparty utilities
3.1.7. VirtualBox shared folder mount
3.1.8. Postprocess files has copied into Linux directories
3.1.9. Boost library download and build
3.1.10. GoogleTest library build (optional)
3.1.11. xz library download, build and install
4. CONFIGURE
4.1. Manual copy step
4.2. Manual preparation step
5. RUN
5.1. Prepare environment variables
6. KNOWN ISSUES
6.1. Software issues
6.1.1. apt-get install issues
6.1.1.1. Message `Failed to fetch ... 404 Not Found`
6.1.2. Boost build
6.1.2.1. Boost build reports boost is not found, when the boost is completely
       built and `BOOST_ROOT` has correct path.
6.1.3. Any project build
6.1.3.1. Make complains with error
      `make: getcwd: No such file or directory`,
      `make: *** No rule to make target '...'.  Stop.`
6.1.3.2. Compilation complains with error
       `<library>.so: error adding symbols: File in wrong format`.
6.1.3.3. Compilation complains with error
       `/usr/bin/ld: <object>.o: undefined reference to symbol 'pthread_create@@GLIBC_2.1'`,
       `//lib/i386-linux-gnu/libpthread.so.0: error adding symbols: DSO missing from command line`.
6.2. Hardware issues
6.2.1. CDROM/DVDROM is empty or not unmountable
7. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
Tacklelib project, initial steps for Linux only targets and related build
issues.

Read the `README_EN.txt` file for the start details to configure and build
for both under the Windows and under the Linux platforms.

From here and after will be described ONLY additional steps to configure and
build under the Linux. All other steps which are the common here is left to the
`README_EN.txt` file.

-------------------------------------------------------------------------------
2. DEPENDENCIES
-------------------------------------------------------------------------------

Read the `README_EN.deps.txt` file for the common dependencies for the Windows
and the Linux platforms.

Additional dependencies specific to the Linux:

* libz-dev:i386     (libarchive)
* libexpat-dev:i386 (libarchive)

-------------------------------------------------------------------------------
3. PREREQUISITES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
3.1. Linux Mint 18.3 x64
-------------------------------------------------------------------------------

>
cd /home/tester

-------------------------------------------------------------------------------
3.1.1. Preconfiguration
-------------------------------------------------------------------------------

# to read the system and repository configuration
>
inxi -Sr

-------------------------------------------------------------------------------
3.1.2. Locale
-------------------------------------------------------------------------------

# update locale
>
echo "export LC_ALL=ru_RU.UTF-8" >> ~/.bash_profile

# !!! relogin !!!

>
sudo update-locale

-------------------------------------------------------------------------------
3.1.3. apt-get
-------------------------------------------------------------------------------

# prepare apt-get
>
sudo apt-get update

-------------------------------------------------------------------------------
3.1.4. GCC
-------------------------------------------------------------------------------

# prepare gcc
>
sudo apt-get install g++
sudo apt-get install gcc-multilib
sudo apt-get install g++-multilib
sudo apt-get install ia32-libs
sudo apt-get install libx32gcc-4.8-dev
sudo apt-get install libc6-dev:i386 libc6-dev-i386

-------------------------------------------------------------------------------
3.1.5. 3dparty libraries
-------------------------------------------------------------------------------

# prepare 3dparty required libs
>
sudo apt-get install libz-dev:i386      # required for libarchive 32-bit dependecy
sudo apt-get install libexpat-dev:i386  # required for libarchive 32-bit dependecy

# prepare 3dparty optional libs
>
sudo apt-get install libicu-dev

-------------------------------------------------------------------------------
3.1.6. 3dparty utilities
-------------------------------------------------------------------------------

# prepare utilities (required)
>
mkdir -p ~/Archive/Applications/Dev/CMake
cd ~/Archive/Applications/Dev/CMake

# download manually or through the wget utility
>
wget https://cmake.org/files/v3.14/cmake-3.14.0-Linux-x86_64.sh

>
sudo apt remove cmake
sudo bash ./cmake-3.14.0-Linux-x86_64.sh

>
mkdir -p ~/Applications/Dev/CMake
sudo mv ~/Archive/Applications/Dev/CMake/cmake-3.14.0-Linux-x86_64 ~/Applications/Dev/CMake

>
echo "export PATH=\$PATH:/home/tester/Applications/Dev/CMake/cmake-3.14.0-Linux-x86_64/bin" >> ~/.bash_profile

# !!! relogin !!!

# prepare utilities (optional)
>
sudo apt-get install git
sudo apt-get install git-flow
sudo apt-get install mono-complete

# prepare direct executable patch utility (required in an application post build stage)
>
sudo apt-get install patchelf:i386

-------------------------------------------------------------------------------
3.1.7. VirtualBox shared folder mount
-------------------------------------------------------------------------------

# To auto mount shared folder at boot:

# 1. Install Guest additions for VirtualBox.
# 2. Create persistent shared directory `common_rw` in the VirtualBox with
#    auto-mount option enabled.
# 3. Add user `tester` into `vboxsf` group:
>
sudo gpasswd -a <username> vboxsf

# hint: after boot the folder will be created in the `/media` directory.

# To mount a shared folder explicitly:

>
mkdir ~/common_rw
sudo mount -t vboxsf common_rw ~/common_rw

-------------------------------------------------------------------------------
3.1.8. Postprocess files has copied into Linux directories
-------------------------------------------------------------------------------

After files has copied into `/media/sf_common_rw` or whatever else, you have to
grant permissions on the files recursively:

# for not executable files:
>
chown -R tester:tester /media/sf_common_rw
chmod -R ug+rw /media/sf_common_rw

# for executable files:
>
chown -R tester:tester /media/sf_common_rw
chmod -R ug+rwx /media/sf_common_rw/*.sh

# For the project root exists special script for such things:

>
cd .../_script/admin
sudo bash ./chown_mod.sh [<user> [<group>]]

-------------------------------------------------------------------------------
3.1.9. Boost library download and build
-------------------------------------------------------------------------------

>
mkdir /home/opt
mkdir -p ~/_3dparty/linux_mint_gcc_x86/boost
cd ~/_3dparty/linux_mint_gcc_x86/boost

# download manually or through the wget utility
>
wget -O boost_1_69_0.tar.bz2 http://sourceforge.net/projects/boost/files/boost/1.69.0/boost_1_69_0.tar.bz2/download

>
tar xvfo boost_1_69_0.tar.bz2

# configure
>
cd boost_1_69_0
./bootstrap.sh

# CAUTION
#   1. THE PREFIX ARGUMENT IS IMPORTANT HERE, OTHERWISE THE CMAKE `FindBoost` FUNCTION
#     WOULD NOT FIND THE REQUIRED BOOST LIBRARIES LOCATED NOT IN THE BUILTIN PREFIX.
#   2. DO USE `-m32` on both compiler and linker, otherwise
#     linkage with libraries will throw `error adding symbols: File in wrong format`
#     error.
#

## full build, all static
##>
##./bjam --reconfigure --prefix=/home/opt/_3dparty/linux_mint_gcc_x86/boost/boost_1_69_0 --layout=versioned --build-type=complete "variant=release,debug" toolset=gcc address-model=32 architecture=x86 link=static runtime-link=static threading=multi debug-symbols=on --build-dir=__build-gcc-32 \
##stage
#
## full build, all shared
##>
##./bjam --reconfigure --prefix=/home/opt/_3dparty/linux_mint_gcc_x86/boost/boost_1_69_0 --layout=versioned --build-type=complete "variant=release,debug" toolset=gcc address-model=32 architecture=x86 link=shared runtime-link=shared threading=multi debug-symbols=on --build-dir=__build-gcc-32 \
##stage

# partial build, all static
>
./bjam --reconfigure --prefix=/home/opt/_3dparty/linux_mint_gcc_x86/boost/boost_1_69_0 --layout=versioned "variant=release,debug" toolset=gcc address-model=32 architecture=x86 link=static runtime-link=static threading=multi debug-symbols=on --build-dir=__build-gcc-32 \
--with-atomic --with-chrono --with-date_time --with-filesystem --with-system --with-iostreams --with-program_options --with-random --with-regex --with-serialization --with-thread --with-timer \
stage

# partial build, all shared
>
./bjam --reconfigure --prefix=/home/opt/_3dparty/linux_mint_gcc_x86/boost/boost_1_69_0 --layout=versioned "variant=release,debug" toolset=gcc address-model=32 architecture=x86 link=shared runtime-link=shared threading=multi debug-symbols=on --build-dir=__build-gcc-32 \
--with-atomic --with-chrono --with-date_time --with-filesystem --with-system --with-iostreams --with-program_options --with-random --with-regex --with-serialization --with-thread --with-timer \
stage

# install, all static
>
sudo ./bjam --reconfigure --prefix=/home/opt/_3dparty/linux_mint_gcc_x86/boost/boost_1_69_0 --layout=versioned "variant=release,debug" toolset=gcc address-model=32 architecture=x86 link=static runtime-link=static threading=multi debug-symbols=on --build-dir=__build-gcc-32 \
--with-atomic --with-chrono --with-date_time --with-filesystem --with-system --with-iostreams --with-program_options --with-random --with-regex --with-serialization --with-thread --with-timer \
install

# install, all shared
>
sudo ./bjam --reconfigure --prefix=/home/opt/_3dparty/linux_mint_gcc_x86/boost/boost_1_69_0 --layout=versioned "variant=release,debug" toolset=gcc address-model=32 architecture=x86 link=shared runtime-link=shared threading=multi debug-symbols=on --build-dir=__build-gcc-32 \
--with-atomic --with-chrono --with-date_time --with-filesystem --with-system --with-iostreams --with-program_options --with-random --with-regex --with-serialization --with-thread --with-timer \
install

-------------------------------------------------------------------------------
3.1.10. GoogleTest library build (optional)
-------------------------------------------------------------------------------

# CHANGE DIRECTORY INTO UNPACKED `googletest` DIRECTORY BEFORE TYPE ANY COMMANDS
# >
# cd .../googletest-1.8.0

>
mkdir lib
mkdir linux_mint_gcc_x86
cd linux_mint_gcc_x86

# enable c++ standard usage for all targets, basically to avoid the default `-std=gnu++11` parameter for the GCC compiler
>
cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=OFF "-DCMAKE_CXX_FLAGS=-m32" "-DCMAKE_CXX_STANDARD=11" "-DCMAKE_CXX_STANDARD_REQUIRED=ON" ..

>
cmake --build . --config Debug
mv libgtest_main.a libgtest_maind.a
mv libgtest.a libgtestd.a
cp libgtest_maind.a ../lib
cp libgtestd.a ../lib

>
cmake --build . --config Release
cp libgtest_main.a ../lib
cp libgtest.a ../lib

-------------------------------------------------------------------------------
3.1.11. xz library download, build and install
-------------------------------------------------------------------------------

>
mkdir /home/opt
mkdir -p ~/_3dparty/linux_mint_gcc_x86/xz
cd ~/_3dparty/linux_mint_gcc_x86/xz

# download manually or through the wget utility
>
wget -O xz-5.2.4.tar.bz2 https://sourceforge.net/projects/lzmautils/files/xz-5.2.4.tar.bz2/download

>
tar xvfo xz-5.2.4.tar.bz2

>
mv xz-5.2.4 xz-5.2.4-src

# configure for 32-bit libraries build
>
mkdir xz-5.2.4-build
cd xz-5.2.4-build
../xz-5.2.4-src/configure --prefix=/home/opt/_3dparty/linux_mint_gcc_x86/xz/xz-5.2.4 CFLAGS=-m32 CPPFLAGS=-m32 LDFLAGS=-m32

# to build
>
make 

# to install
>
make install

-------------------------------------------------------------------------------
4. CONFIGURE
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
4.1. Manual copy step
-------------------------------------------------------------------------------

To run bash shell scripts (`.sh` file extension) you should copy the
`/_scripts/tools/bash_entry` into the `/bin` directory of your platform:

>
sudo cp .../_script/tools/bash_entry /bin

-------------------------------------------------------------------------------
4.2. Manual preparation step
-------------------------------------------------------------------------------

# To make scripts executable:

>
sudo chmod ug+x /bin/bash_entry
sudo chmod o+r /bin/bash_entry

>
cd .../_scripts
sudo chmod ug+x *.sh
sudo chmod -R ug+rw

-------------------------------------------------------------------------------
5. RUN
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
5.1. Prepare environment variables
-------------------------------------------------------------------------------

Because the current directory path is not in the search paths for shared
objects to load then you have to setup it explicitly before run the
executable:

export LD_LIBRARY_PATH=.:./lib

-------------------------------------------------------------------------------
6. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1. Software issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1.1. apt-get install issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1.1.1. Message `Failed to fetch ... 404 Not Found`
-------------------------------------------------------------------------------

Cause:

  1. Repository paths is invalid or has changed.

Solution #1:

  https://superuser.com/questions/1004008/linux-mint-sudo-apt-get-update-404-errors/1009807#1009807

  Update repository sources:

  1. Backup directory `/etc/apt/sources.list.d`
  2. Delete content of the directory `/etc/apt/sources.list.d`
  3. `sudo software-sources`
  4. Press button `Restore the default settings`
  5. Press button `Update cache`

Solution #2:

  Run the apt update:

  >
  sudo apt-get update

-------------------------------------------------------------------------------
6.1.2. Boost build
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1.2.1. Boost build reports boost is not found, when the boost is completely
       built and `BOOST_ROOT` has correct path.
-------------------------------------------------------------------------------

This may happend because:

1. The cmake version does not have appropriate implementation in the
   `FindBoost.cmake` module to find required version of the boost library.
   For example, the cmake of version 3.5 does not implement search for the
   boost library of the version 1.63 and higher. So, you have to update the
   cmake by yourself to enable the search for the appropriate library version.

2. Boost is built for one prefix path but located in another one. This can
   break the search in the cmake. The solution is to rebuild and reinstall the
   boost to the same path there the `BOOST_ROOT` variable would point it.

3. Boost built with the wrong architecture variant. Try to analyze name
   components in the boost stage directory to find out the differences.

4. Missed to use the correct version of the `Boost_ARCHITECTURE` configuration
   variable (for the boost 1.66+ only).

-------------------------------------------------------------------------------
6.1.3. Any project build
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1.3.1. Make complains with error
      `make: getcwd: No such file or directory`,
      `make: *** No rule to make target '...'.  Stop.`
-------------------------------------------------------------------------------

The issue:

Directory has deleted in another process while running current shell instance.

Solution #1:

If directory is recreated or exists, then update the current working directory
file handle in the current shell instance:

>
cd .

Solution #2:

Restart terminal application.

-------------------------------------------------------------------------------
6.1.3.2. Compilation complains with error
       `<library>.so: error adding symbols: File in wrong format`.
-------------------------------------------------------------------------------

The issue #1:

Project has been linking without `-m32` flag.

See details here: https://stackoverflow.com/questions/5805874/the-proper-way-of-forcing-a-32-bit-compile-using-cmake/19310455#19310455

Solution:

Use flag `-m32` both for compiler and linker.

The issue #2:

Library `<library>.so` has linked with different address model or platform.

Solution:

Check the library format by the command:

>
objdump -f <library>.so

Get or rebuild the correct version of the library.

-------------------------------------------------------------------------------
6.1.3.3. Compilation complains with error
       `/usr/bin/ld: <object>.o: undefined reference to symbol 'pthread_create@@GLIBC_2.1'`,
       `//lib/i386-linux-gnu/libpthread.so.0: error adding symbols: DSO missing from command line`.
-------------------------------------------------------------------------------

The issue #1:

The target required to be linked with the `pthread` library.

Solution:

Use flag `-pthread` in the compiler and linker.

The issue #2:

The flag `-lpthread` has used before objects linked versus `pthread` on the
linker command line instead after.

See details here:
https://stackoverflow.com/questions/19901934/strange-linking-error-dso-missing-from-command-line/19905704#19905704
https://stackoverflow.com/questions/24814698/how-can-i-add-a-flag-at-the-end-of-the-linking-command-line-using-cmake

Solution:

Move the flag to the end of the linker command line.

OR

Use flag `-pthread` both for the compiler and linker instead the `-lpthread`
flag.

-------------------------------------------------------------------------------
6.2. Hardware issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.2.1. CDROM/DVDROM is empty or not unmountable
-------------------------------------------------------------------------------

Can happens because:

1. The guest is running under VirtualBox 5.x and the previous cdrom image was
  not properly unmounted before install a new version of the VirtualBox.

Solution #1:

Try to eject the disk by using one of these commands:

  * `sudo eject -T`
  * `sudo eject -r`
  * `sudo eject -s`

  From the command manual (http://man7.org/linux/man-pages/man1/eject.1.html ):

       -r, --cdrom
              This option specifies that the drive should be ejected using a
              CDROM eject command.

       -s, --scsi
              This option specifies that the drive should be ejected using
              SCSI commands.

       -T, --traytoggle
              With this option the drive is given a CD-ROM tray close
              command if it's opened, and a CD-ROM tray eject command if
              it's closed.  Not all devices support this command, because it
              uses the above CD-ROM tray close command.

       -t, --trayclose
              With this option the drive is given a CD-ROM tray close
              command.  Not all devices support this command.

-------------------------------------------------------------------------------
7. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
