* README_EN.txt
* 2021.09.06
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
See details in the `PREREQUISITES` section in the root `README_EN.txt` file.

-------------------------------------------------------------------------------
5. DEPLOY
-------------------------------------------------------------------------------
See details in the `DEPLOY` section in the root `README_EN.txt` file.

-------------------------------------------------------------------------------
6. CATALOG CONTENT DESCRIPTION
-------------------------------------------------------------------------------

<root>/cmake_tests
 |
 +- /`_config`
 |  | #
 |  | # Directory with tests configuration files.
 |  |
 |  +- /`_build`
 |  |    #
 |  |    # Directory with text files containing command lines for scripts from
 |  |    # `/cmake_tests/_build` directory
 |  |
 |  +- `config.system.vars.in`
 |  |   #
 |  |   # Template file with system set of environment variables
 |  |   # designed to be stored in a version control system.
 |  |
 |  +- `config.system.vars`
 |      #
 |      # Generated temporary file with set of system customized environment
 |      # variables to set them locally.
 |
 +- /`_build`
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
