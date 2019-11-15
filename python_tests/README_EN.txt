* README_EN.txt
* 2019.11.15
* tacklelib--python_tests

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. DEPLOY
6. CATALOG CONTENT DESCRIPTION
7. KNOWN ISSUES
7.1. Python installation issues prior version 3.4:
7.1.1. No `pip` package manager and no `Scripts` directory prior Python 3.4
7.1.2. `SyntaxError: invalid syntax: return u"".join(u"\\x%x" % c for c in raw_bytes), err.end`
7.1.3. `Could not find a version that satisfies the requirement pip<8 (from versions: )`
       `No matching distribution found for pip<8`
7.1.4. Message `ImportError: No module named setuptools` while installing pip
       version `7.1.2` and lower
7.2. Python installation issues:
7.2.1. `Python 2.x/3.x installer installation has not Scripts folder` or
       `Python 3.x Installer ended prematurely (Windows msi)`
7.2.2. Some tests from `python_tests` directory fails
7.2.3. `OSError: [WinError 87] The parameter is incorrect` while try to run
       `python_tests`
7.3. pytest execution issues
7.4. fcache execution issues
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
* python 3.7.3 or 3.7.5 (3.4+ or 3.5+)
  https://python.org
  - standard implementation to run python scripts
  - 3.7.4 has a bug in the `pytest` module execution, see `KNOWN ISSUES`
    section
  - 3.5+ is required for the direct import by a file path (with any extension)
    as noted in the documentation:
    https://docs.python.org/3/library/importlib.html#importing-a-source-file-directly
* cmake 3.15.1 (3.14+):
  https://cmake.org/download/
  - to read configuration variables and run `python_tests` scripts

3. Modules

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
**  pytest 5.2.0
    - to run python tests (test*.py)

* Python testing modules:

**  tacklelib--python :
    https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/python/tacklelib/

4. Patches:

* Python site modules contains patches in the `python_patches` directory:

** fcache
   - to fix issues from the `fcache execution issues` section.

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
7.1. Python installation issues:
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
7.1.1. No `pip` package manager and no `Scripts` directory prior Python 3.4
-------------------------------------------------------------------------------
https://docs.python.org/3/installing/index.html#install-pip-in-versions-of-python-prior-to-python-3-4

```
Python only started bundling pip with Python 3.4. For earlier versions, pip
needs to be “bootstrapped” as described in the Python Packaging User Guide.
```

https://packaging.python.org/installing/#requirements-for-installing-packages

```
If pip isn’t already installed, then first try to bootstrap it from the
standard library:

`python -m ensurepip --default-pip`

If that still doesn’t allow you to run pip:

Securely Download get-pip.py:

https://bootstrap.pypa.io/get-pip.py

Run python get-pip.py. This will install or upgrade pip. Additionally, it will
install setuptools and wheel if they’re not installed already.

Warning:
  Be cautious if you’re using a Python install that’s managed by your operating
  system or another package manager. get-pip.py does not coordinate with those
  tools, and may leave your system in an inconsistent state. You can use
  `python get-pip.py --prefix=/usr/local/` to install in `/usr/local` which is
  designed for locally-installed software.
```

-------------------------------------------------------------------------------
7.1.2. `SyntaxError: invalid syntax: return u"".join(u"\\x%x" % c for c in raw_bytes), err.end`
-------------------------------------------------------------------------------

Issues:

pip no longer supports Python 3.2

Solution:

Download preciouv version of the `get-pip.py`:

https://bootstrap.pypa.io/3.2/get-pip.py

-------------------------------------------------------------------------------
7.1.3. `Could not find a version that satisfies the requirement pip<8 (from versions: )`
       `No matching distribution found for pip<8`
-------------------------------------------------------------------------------

Issue:

The `pip` package requested by the `get-pip.py` script is removed from remote
python repository.

Solution:

Download and install all required packages manually starting from here:

Setuptools of version prior 30.0.0 accepts Python 3.2:
https://github.com/pypa/setuptools/blob/master/CHANGES.rst#v3000

Pip of version prior to 8.0.0 accepts Python 3.2:
https://pip.pypa.io/en/stable/news/#id235

So, you have download these:

https://pypi.org/project/setuptools/29.0.1/#files
https://pypi.org/project/pip/7.1.2/#files

Extract them in a directory near the python installation directory, for
example, if you install python into:

`c:/python/x86/32`

Then extract archives into:

`c:/python/x86/pkg`

And run these commands in exact order:

>
cd c:/python/x86/pkg/setuptools-29.0.1
c:/python/x86/python setup.py install
cd c:/python/x86/pkg/pip-7.1.2
c:/python/x86/python setup.py install

-------------------------------------------------------------------------------
7.1.4. Message `ImportError: No module named setuptools` while installing pip
       version `7.1.2` and lower
-------------------------------------------------------------------------------

Issue:

The `setup.py` script run with the current directory not inside the directory
of extracted package.

Solution:

Reinstall python and run `setup.py` with the current directory inside an
extracted package being installed.

-------------------------------------------------------------------------------
7.2. Python installation issues:
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
7.2.1. `Python 2.x/3.x installer installation has not Scripts folder` or
       `Python 3.x Installer ended prematurely (Windows msi)`
-------------------------------------------------------------------------------

Issues:

* `Python 3.4 and 2.7 installation no Script folder and no pip installed` :
  https://bugs.python.org/issue23604
* `Python 3.4.1 Installer ended prematurely (Windows msi)` :
  https://bugs.python.org/issue22028

Solution:

Fix the broken Windows registry keys with emdedded null character.
To do so you can use several solutions described here:

http://www.swarley.me.uk/blog/2014/04/23/python-pip-and-windows-registry-corruption/

Or use a python script from here:

https://sf.net/p/contools/contools/HEAD/tree/trunk/Scripts/Tools/admin/scan_broken_reg_keys.py

-------------------------------------------------------------------------------
7.2.2. Some tests from `python_tests` directory fails
-------------------------------------------------------------------------------

Issue:

The pytest model collects all tests before run them so global data between
tests might be changed or merged. You have to run each test in a standalone
process which the pytest does not support portably even with plugins.

Solution:

To fix that case you have to run all tests by a predefined script:
`test_all.bat`

-------------------------------------------------------------------------------
7.2.3. `OSError: [WinError 87] The parameter is incorrect` while try to run
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
7.3. pytest execution issues
-------------------------------------------------------------------------------
* `xonsh incorrectly reorders the test for the pytest` :
  https://github.com/xonsh/xonsh/issues/3380
* `a test silent ignore` :
  https://github.com/pytest-dev/pytest/issues/6113
* `can not order tests by a test directory path` :
  https://github.com/pytest-dev/pytest/issues/6114

-------------------------------------------------------------------------------
7.4. fcache execution issues
-------------------------------------------------------------------------------
* `fcache is not multiprocess aware on Windows` :
  https://github.com/tsroten/fcache/issues/26
* ``_read_from_file` returns `None` instead of (re)raise an exception` :
  https://github.com/tsroten/fcache/issues/27
* `OSError: [WinError 17] The system cannot move the file to a different disk drive.` :
  https://github.com/tsroten/fcache/issues/28

-------------------------------------------------------------------------------
8. AUTHOR EMAIL
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
