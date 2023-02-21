* README_EN.txt
* 2023.02.21
* tacklelib--cmake_tests

1. DESCRIPTION
2. PREREQUISITES
3. DEPLOY
4. CATALOG CONTENT DESCRIPTION

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
CMake tests designed to test `cmake` modules from the `tacklelib` library.

-------------------------------------------------------------------------------
2. PREREQUISITES
-------------------------------------------------------------------------------
See details in the `PREREQUISITES` section in the root `README_EN.txt` file.

-------------------------------------------------------------------------------
3. DEPLOY
-------------------------------------------------------------------------------
See details in the `DEPLOY` section in the root `README_EN.txt` file.

-------------------------------------------------------------------------------
4. CATALOG CONTENT DESCRIPTION
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
