* README_EN.txt
* 2019.11.20
* tacklelib--python

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. CATALOG CONTENT DESCRIPTION
6. KNOWN ISSUES
6.1. Python installation issues prior version 3.4:
6.1.1. No `pip` package manager and no `Scripts` directory prior Python 3.4
6.1.2. `SyntaxError: invalid syntax: return u"".join(u"\\x%x" % c for c in raw_bytes), err.end`
6.1.3. `Could not find a version that satisfies the requirement pip<8 (from versions: )`
       `No matching distribution found for pip<8`
6.1.4. Message `ImportError: No module named setuptools` while installing pip
       version `7.1.2` and lower
6.2. Python installation issues:
6.2.1. Python 2.x/3.x installer installation has no `Scripts` folder or
       Python 3.x Installer ended prematurely (Windows msi)
6.3. fcache execution issues
6.3.1. fcache implementation hangs or fails in __getitem__/__setitem__
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
**  fcache 0.4.7
    - for local cache storage for python scripts
**  psutil 5.6.7
    - for processes list request
**  tzlocal 2.0.0
    - for local timezone request
**  pytest 5.2.0
    - to run python tests (test*.py)

4. Patches:

* Python site modules contains patches in the `python_patches` directory:

** fcache
   - to fix issues from the `fcache execution issues` section.

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
6.1. Python installation issues:
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1.1. No `pip` package manager and no `Scripts` directory prior Python 3.4
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
6.1.2. `SyntaxError: invalid syntax: return u"".join(u"\\x%x" % c for c in raw_bytes), err.end`
-------------------------------------------------------------------------------

Issues:

pip no longer supports Python 3.2

Solution:

Download previous version of the `get-pip.py`:

https://bootstrap.pypa.io/3.2/get-pip.py

-------------------------------------------------------------------------------
6.1.3. `Could not find a version that satisfies the requirement pip<8 (from versions: )`
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
6.1.4. Message `ImportError: No module named setuptools` while installing pip
       version `7.1.2` and lower
-------------------------------------------------------------------------------

Issue:

The `setup.py` script has been run when the current directory was not inside
the directory of extracted package.

Solution:

Reinstall python and run `setup.py` with in the current directory inside an
extracted package being installed.

-------------------------------------------------------------------------------
6.2. Python installation issues:
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.2.1. Python 2.x/3.x installer installation has no `Scripts` folder or
       Python 3.x Installer ended prematurely (Windows msi)
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
6.3. fcache execution issues
-------------------------------------------------------------------------------
* `fcache is not multiprocess aware on Windows` :
  https://github.com/tsroten/fcache/issues/26
* ``_read_from_file` returns `None` instead of (re)raise an exception` :
  https://github.com/tsroten/fcache/issues/27
* `OSError: [WinError 17] The system cannot move the file to a different disk drive.` :
  https://github.com/tsroten/fcache/issues/28

-------------------------------------------------------------------------------
6.3.1. fcache implementation hangs or fails in __getitem__/__setitem__
-------------------------------------------------------------------------------

Issue:

Module hangs on cache read/write/sync.

Solution:

Patch python `fcache` module sources by patches from the
`python_patches/fcache` directory.

-------------------------------------------------------------------------------
7. AUTHOR EMAIL
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
