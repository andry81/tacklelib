* README_EN.txt
* 2019.10.29
* tacklelib--python

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. CATALOG CONTENT DESCRIPTION
6. KNOWN ISSUES
6.1. `OSError: [WinError 87] The parameter is incorrect` while try to run
  `python_tests`
7. AUTHOR EMAIL

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
Tacklelib library python modules.

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
  * https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/python
  * https://svn.code.sf.net/p/tacklelib/tacklelib/trunk/python
First mirror:
  * https://github.com/andry81/tacklelib/tree/trunk/python
  * https://github.com/andry81/tacklelib.git
Second mirror:
  * https://bitbucket.org/andry81/tacklelib/src/trunk/python
  * https://bitbucket.org/andry81/tacklelib.git

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------

Currently tested these set of OS platforms, interpreters and modules to run
from:

1. OS platforms.

* Windows 7 (`.bat` only)

2. Interpreters:

* python 3.7.3 or 3.7.5 (3.4+, but not the 3.7.4, see `KNOWN ISSUES` section)
  https://www.python.org
  - to run python scripts

3. Modules

* Python site modules:

**  plumbum 1.6.7
    https://plumbum.readthedocs.io/en/latest/
    - to run python scripts in a shell like environment (.xsh)
**  win_unicode_console
    - to enable unicode symbols support in the Windows console
**  pyyaml 5.1.1
    - to read yaml format files (.yaml, .yml)
**  conditional 1.3
    - to support conditional `with` statements
**  pytest 5.2.0
    - to run python tests (test*.py)

-------------------------------------------------------------------------------
5. CATALOG CONTENT DESCRIPTION
-------------------------------------------------------------------------------

<root>
 |
 +- /`tacklelib`
 |    #
 |    # The core library directory used to local load all others through the
 |    # `tkl_import_module` function. Itself loads by the usual python
 |    # method, see the tests for the details.
 |
 +- /`cmdoplib`
 |    #
 |    # The command operational library directory. Contains the functionality
 |    # used in command shell-based scripts.
 |
 +- `*.py`
     #
     # The reset miscellaneous scripts.

-------------------------------------------------------------------------------
6. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1. `OSError: [WinError 87] The parameter is incorrect` while try to run
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
7. AUTHOR EMAIL
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
