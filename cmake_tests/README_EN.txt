* README_EN.txt
* 2020.04.06
* tacklelib--cmake_tests

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. DEPLOY
6. CATALOG CONTENT DESCRIPTION
7. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
CMake tests designed to test `cmake` modules from the `tacklelib` library.

WARNING:
  Use the SVN access to find out latest functionality and bug fixes.
  See the REPOSITORIES section.

-------------------------------------------------------------------------------
2. LICENSE
-------------------------------------------------------------------------------
The MIT license (see included text file "license.txt" or
https://en.wikipedia.org/wiki/MIT_License)

-------------------------------------------------------------------------------
3. REPOSITORIES
-------------------------------------------------------------------------------
Primary:
  * https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/cmake_tests
  * https://svn.code.sf.net/p/tacklelib/tacklelib/trunk/cmake_tests
First mirror:
  * https://github.com/andry81/tacklelib/tree/trunk/cmake_tests
  * https://github.com/andry81/tacklelib.git
Second mirror:
  * https://bitbucket.org/andry81/tacklelib/src/trunk/cmake_tests
  * https://bitbucket.org/andry81/tacklelib.git

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------

Currently used these set of OS platforms, compilers, interpreters, modules,
IDE's, applications and patches to run with or from:

1. OS platforms:

* Windows 7 (`.bat` only, minimal version for the cmake 3.14)
* Cygwin 1.5+ or 3.0+ (`.sh` only):
  https://cygwin.com
  - to run scripts under cygwin
* Msys2 20190524+ (`.sh` only):
  https://www.msys2.org
  - to run scripts under msys2
* Linux Mint 18.3 x64 (`.sh` only)

2. C++11 compilers:

N/A

3. Interpreters:

* bash shell 3.2.48+
  - to run unix shell scripts
* perl 5.10+
  - to run specific bash script functions with `perl` calls
* cmake 3.15.1 (3.14+):
  https://cmake.org/download/
  - to run cmake scripts and modules

4. Modules:

* CMake testing modules:

**  tacklelib--cmake:
    https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/cmake/tacklelib/

-------------------------------------------------------------------------------
5. DEPLOY
-------------------------------------------------------------------------------
You must use scripts inside the `/cmake_tests/_scripts` directory and prepared
configuration files in the `/cmake_tests/_config` subdirectory to run the
tests.

Otherwise you have to set at least all dependent variables on yourself before
call to test scripts.

To run bash shell scripts (`.sh` file extension) you should copy the
`/bash/tacklelib/bash_entry` module into the `/bin` directory of your platform.

In pure Linux you have additional step to make scripts executable:

>
sudo chmod ug+x /bin/bash_entry
sudo chmod o+r /bin/bash_entry

-------------------------------------------------------------------------------
6. CATALOG CONTENT DESCRIPTION
-------------------------------------------------------------------------------

<root>/cmake_tests
 |
 +- /`_config`
 |  | #
 |  | # Directory with tests configuration files.
 |  |
 |  +- /`_scripts`
 |  |    #
 |  |    # Directory with text files containing command lines for scripts from
 |  |    # `/cmake_tests/_scripts` directory
 |  |
 |  +- `environment_system.vars.in`
 |  |   #
 |  |   # Template file with system set of environment variables
 |  |   # designed to be stored in a version control system.
 |  |
 |  +- `environment_system.vars`
 |      #
 |      # Generated temporary file with set of system customized environment
 |      # variables to set them locally.
 |
 +- /`_scripts`
 |  | #
 |  | # Scripts to generate configuration and run tests.
 |  | # Contains special `__init*__` script to allocate basic environment
 |  | # variables and make common preparations.
 |  |
 |  +-/`01_generate_config.*`
 |  |   #
 |  |   # Script to generate configuration files in the `_config` subdirectory
 |  |   # which are should not be included in a version control system.
 |  |
 |  +-/`test_all.*`
 |  |   #
 |  |   # Script to run all tests together.
 |  |
 |  +-/`tests_*.*`
 |      #
 |      # Script to run a predefined tests group.
 |
 +- `test_all.cmake`, `tests_*.cmake`
     #
     # The cmake entry point into respective tests group.

-------------------------------------------------------------------------------
7. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
