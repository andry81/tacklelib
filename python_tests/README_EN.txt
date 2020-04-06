* README_EN.txt
* 2020.04.06
* tacklelib--python_tests

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. DEPLOY
6. CATALOG CONTENT DESCRIPTION
7. KNOWN ISSUES
7.1. Python execution issues
7.1.1. `OSError: [WinError 87] The parameter is incorrect` while try to run
       `python_tests`
7.1.2. `OSError: [WinError 6] The handle is invalid`
7.1.3. `ValueError: 'cwd' in __slots__ conflicts with class variable`
7.1.4. `TypeError: descriptor 'combine' for type 'datetime.datetime' doesn't apply to type 'datetime'`
7.2. pytest execution issues
7.2.1. Some tests from `python_tests/01_unit` directory fails
7.2.2. Testes with `xsh` extension runs at first ignoring the predefined pytest
       order
7.2.3. Test from `python_tests/02_interactive/01_fcache_workarounds` hangs
7.3. fcache execution issues
7.3.1. fcache implementation hangs or fails in __getitem__/__setitem__
8. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
Python tests designed to test `python` modules from the `tacklelib` library,
but with support from `bash` and `cmake` modules from the `tacklelib` library
itself.

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
* python 3.7.3 or 3.7.5 (3.6.2+)
  https://python.org
  - standard implementation to run python scripts
  - 3.7.4 has a bug in the `pytest` module execution, see `KNOWN ISSUES`
    section
  - 3.5+ is required for the direct import by a file path (with any extension)
    as noted in the documentation:
    https://docs.python.org/3/library/importlib.html#importing-a-source-file-directly
* cmake 3.15.1 (3.14+):
  https://cmake.org/download/
  - to run cmake scripts and modules

4. Modules

* Python site modules:

**  xonsh/0.9.12
    https://github.com/xonsh/xonsh
    - to run python scripts and import python modules with `.xsh` file
      extension
**  plumbum 1.6.7
    https://plumbum.readthedocs.io/en/latest/
    - to run python scripts in a shell like environment
**  win_unicode_console
    - to enable unicode symbols support in the Windows console
**  pyyaml 5.1.1
    - to read yaml format files (.yaml, .yml)
**  conditional 1.3
    - to support conditional `with` statements
**  fcache 0.4.7
    - for local cache storage for python scripts
**  psutil 5.6.7
    - for processes list request
**  tzlocal 2.0.0
    - for local timezone request
**  pytest 5.2.0
    - to run python tests (test*.py)

* Python testing modules:

**  tacklelib--python :
    https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/python/tacklelib/

5. IDE's:

N/A

6. Applications:

* cygwin cygpath 1.42+
  - to run `bash_entry` script under cygwin
* msys cygpath 3.0+
  - to run `bash_entry` script under msys2
* cygwin readlink 6.10+
  - to run specific bash script functions with `readlink` calls

7. Patches:

* Python site modules contains patches in the `python_patches`
  subdirectory:

** fcache
   - to fix issues from the `fcache execution issues` section.

-------------------------------------------------------------------------------
5. DEPLOY
-------------------------------------------------------------------------------
You must use scripts inside the `/python_tests/_scripts` directory and prepared
configuration files in the `/python_tests/_config` subdirectory to run the
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

<root>/python_tests
 |
 +- /`_config`
 |  | #
 |  | # Directory with tests configuration files.
 |  |
 |  +- /`_scripts`
 |  |    #
 |  |    # Directory with text files containing command lines for scripts from
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
7.1. Python execution issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
7.1.1. `OSError: [WinError 87] The parameter is incorrect` while try to run
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
7.1.2. `OSError: [WinError 6] The handle is invalid`
-------------------------------------------------------------------------------

Issue:

  The python interpreter (3.7, 3.8, 3.9) sometimes throws this message at exit,
  see details here:

  `subprocess.Popen._cleanup() "The handle is invalid" error when some old process is gone` :
  https://bugs.python.org/issue37380

Solution:

  Reinstall the different python version.

-------------------------------------------------------------------------------
7.1.3. `ValueError: 'cwd' in __slots__ conflicts with class variable`
-------------------------------------------------------------------------------

Stack trace example:

  File ".../python/tacklelib/tacklelib.py", line 265, in tkl_classcopy
    cls_copy = type(x.__name__, x.__bases__, dict(x.__dict__))

Issue:

  Bug in the python implementation prior version 3.5.4 or 3.6.2:

  https://stackoverflow.com/questions/45864273/slots-conflicts-with-a-class-variable-in-a-generic-class/45868049#45868049
  `typing module conflicts with __slots__-classes` :
  https://bugs.python.org/issue31272

Solution:

  Upgrade python version at least up to 3.5.4 or 3.6.2.

-------------------------------------------------------------------------------
7.1.4. `TypeError: descriptor 'combine' for type 'datetime.datetime' doesn't apply to type 'datetime'`
-------------------------------------------------------------------------------

Stack trace example:

  File ".../python/tacklelib/tacklelib.py", line 278, in tkl_classcopy
    for key, value in dict(inspect.getmembers(x)).items():
  File ".../python/x86/35/lib/python3.5/inspect.py", line 309, in getmembers
    value = getattr(object, key)

Issue:

  Bug in the python implementation prior version 3.6.2:

Solution:

  Upgrade python version at least up to 3.6.2.

-------------------------------------------------------------------------------
7.2. pytest execution issues
-------------------------------------------------------------------------------
* `xonsh incorrectly reorders the test for the pytest` :
  https://github.com/xonsh/xonsh/issues/3380
* `a test silent ignore` :
  https://github.com/pytest-dev/pytest/issues/6113
* `can not order tests by a test directory path` :
  https://github.com/pytest-dev/pytest/issues/6114

-------------------------------------------------------------------------------
7.2.1. Some tests from `python_tests/01_unit` directory fails
-------------------------------------------------------------------------------

Issue:

  The pytest model collects all tests before run them so global data between
  tests might be changed or merged. You have to run each test in a standalone
  process which the pytest does not support portably even with plugins.

Solution:

  To fix that case you have to run all tests by a predefined script:
  `test_all.bat`

-------------------------------------------------------------------------------
7.2.2. Testes with `xsh` extension runs at first ignoring the predefined pytest
       order
-------------------------------------------------------------------------------

Issue:

  The python xonsh plugin breaks tests run order:
  `xonsh incorrectly reorders the test for the pytest` :
  https://github.com/xonsh/xonsh/issues/3380
  `Remove test reordering in pytest plugin` :
  https://github.com/xonsh/xonsh/pull/3468

Solution:

  To fix that case you have to run all tests by a predefined script:
  `test_all.*`

-------------------------------------------------------------------------------
7.2.3. Test from `python_tests/02_interactive/01_fcache_workarounds` hangs
-------------------------------------------------------------------------------

Issue:

  Test hangs on cache read/write/sync.

Solution:

  Patch python `fcache` module sources by patches from the
  `python_patches/fcache` directory.

-------------------------------------------------------------------------------
7.3. fcache execution issues
-------------------------------------------------------------------------------
* `fcache is not multiprocess aware on Windows` :
  https://github.com/tsroten/fcache/issues/26
* ``_read_from_file` returns `None` instead of (re)raise an exception` :
  https://github.com/tsroten/fcache/issues/27
* `OSError: [WinError 17] The system cannot move the file to a different disk drive.` :
  https://github.com/tsroten/fcache/issues/28

-------------------------------------------------------------------------------
7.3.1. fcache implementation hangs or fails in __getitem__/__setitem__
-------------------------------------------------------------------------------

Issue:

  Module hangs on cache read/write/sync.

Solution:

  Patch python `fcache` module sources by patches from the
  `python_patches/fcache` directory.

-------------------------------------------------------------------------------
8. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
