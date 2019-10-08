* README_EN.txt
* 2019.10.08
* tacklelib--python_tests

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. DEPLOY
6. CATALOG CONTENT DESCRIPTION
7. KNOWN ISSUES
7.1. `OSError: [WinError 87] The parameter is incorrect` while try to run
  `python_tests`
8. AUTHOR EMAIL

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
Python tests designed to test python modules from the tacklelib library.

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
  * https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/python_tests
  * https://svn.code.sf.net/p/tacklelib/tacklelib/trunk/python_tests
First mirror:
  * https://github.com/andry81/tacklelib/tree/trunk/python_tests
  * https://github.com/andry81/tacklelib.git
Second mirror:
  * https://bitbucket.org/andry81/tacklelib/src/trunk/python_tests
  * https://bitbucket.org/andry81/tacklelib.git

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------

Currently tested these set of OS platforms, interpreters and modules to run
from:

1. OS platforms.

* Windows 7 (`.bat` only)

2. Interpreters:

* bash shell 3.2.48+
  - to run unix shell scripts
* python 3.7.3 or 3.7.5 (3.4+, but not the 3.7.4, see `KNOWN ISSUES` section)
  https://www.python.org
  - to run python scripts
* cmake 3.15.1 (3.14+):
  https://cmake.org/download/
  - to read configuration variables and run `python_tests` scripts

3. Modules

* Python site modules:

**  plumbum 1.6.7
    https://plumbum.readthedocs.io/en/latest/
    - to run python scripts in a shell like environment (.xsh)
**  win_unicode_console
    - to enable unicode symbols support in the Windows console
**  pyyaml 5.1.1
    - to read yaml format files (.yaml, .yml)
**  pytest 5.2.0
    - to run python tests (test*.py)

* Python testing modules:

**  tacklelib--python :
    https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/python/tacklelib/

-------------------------------------------------------------------------------
5. DEPLOY
-------------------------------------------------------------------------------
You must use scripts inside the `/python_tests/_scripts` directory and prepared
configuration files in the `/python_tests/_config` subdirectory to run the
tests.

Otherwise you have to set at least all dependent variables on yourself before
call to tests scripts.

To run bash shell scripts (`.sh` file extension) you should copy the
`/_scripts/tools/bash_entry` into the `/bin` directory of your platform.

In pure Linux you have additional step to make scripts executable:

>
sudo chmod ug+x /bin/bash_entry
sudo chmod o+r /bin/bash_entry

-------------------------------------------------------------------------------
6. CATALOG CONTENT DESCRIPTION
-------------------------------------------------------------------------------

<root>/python_tests
 |
 +- /`_config`
 |  | #
 |  | # Directory with tests configuration files.
 |  |
 |  +- /`_scripts`
 |  |    #
 |  |    # Directory with text files conaining command lines for scripts from
 |  |    # `/python_tests/_scripts` directory
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
 +- `test_all.py`, `tests_*.py`
     #
     # The python entry point into respective tests group.

-------------------------------------------------------------------------------
7. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
7.1. `OSError: [WinError 87] The parameter is incorrect` while try to run
  `python_tests`
-------------------------------------------------------------------------------

Issue:

The `python_tests` scripts fails with the titled message.

Reason:

Python version 3.7.4 is broken on Windows 7:
https://bugs.python.org/issue37549 :
`os.dup() fails for standard streams on Windows 7`

Solution:

Reinstall the different python version.

-------------------------------------------------------------------------------
8. AUTHOR EMAIL
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
