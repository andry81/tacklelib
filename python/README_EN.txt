* README_EN.txt
* 2025.06.25
* tacklelib--python

1. DESCRIPTION
2. PREREQUISITES
3. CATALOG CONTENT DESCRIPTION
4. KNOWN ISSUES
4.1. Python installation issues prior version 3.4:
4.1.1. No `pip` package manager and no `Scripts` directory prior Python 3.4
4.1.2. `SyntaxError: invalid syntax: return u"".join(u"\\x%x" % c for c in raw_bytes), err.end`
4.1.3. `Could not find a version that satisfies the requirement pip<8 (from versions: )`
       `No matching distribution found for pip<8`
4.1.4. Message `ImportError: No module named setuptools` while installing pip
       version `7.1.2` and lower
4.2. Python installation issues:
4.2.1. Python 2.x/3.x installer installation has no `Scripts` folder or
       Python 3.x Installer ended prematurely (Windows msi)
4.3. Python execution issues:
4.3.1. `ValueError: 'cwd' in __slots__ conflicts with class variable`
4.3.2. `TypeError: descriptor 'combine' for type 'datetime.datetime' doesn't apply to type 'datetime'`
4.4. fcache execution issues
4.4.1. fcache implementation hangs or fails in __getitem__/__setitem__

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
The `tacklelib` library python support modules to run python scripts on
Windows and Linux platforms separately without any other extra dependencies
except those from the PREREQUISITES section below.

-------------------------------------------------------------------------------
2. PREREQUISITES
-------------------------------------------------------------------------------
See details in the `PREREQUISITES` section in the root `README_EN.txt` file.

-------------------------------------------------------------------------------
3. CATALOG CONTENT DESCRIPTION
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
4. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
4.1. Python installation issues:
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
4.1.1. No `pip` package manager and no `Scripts` directory prior Python 3.4
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
4.1.2. `SyntaxError: invalid syntax: return u"".join(u"\\x%x" % c for c in raw_bytes), err.end`
-------------------------------------------------------------------------------

Issues:

  pip no longer supports Python 3.2

Solution:

  Download previous version of the `get-pip.py`:

  https://bootstrap.pypa.io/3.2/get-pip.py

-------------------------------------------------------------------------------
4.1.3. `Could not find a version that satisfies the requirement pip<8 (from versions: )`
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
4.1.4. Message `ImportError: No module named setuptools` while installing pip
       version `7.1.2` and lower
-------------------------------------------------------------------------------

Issue:

  The `setup.py` script has been run when the current directory was not inside
  the directory of extracted package.

Solution:

  Reinstall python and run `setup.py` with in the current directory inside an
  extracted package being installed.

-------------------------------------------------------------------------------
4.2. Python installation issues:
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
4.2.1. Python 2.x/3.x installer installation has no `Scripts` folder or
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

  Or use a python script from `contools--admin` project:

  /scripts/scan_broken_reg_keys.py

-------------------------------------------------------------------------------
4.3. Python execution issues:
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
4.3.1. `ValueError: 'cwd' in __slots__ conflicts with class variable`
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
4.3.2. `TypeError: descriptor 'combine' for type 'datetime.datetime' doesn't apply to type 'datetime'`
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
4.4. fcache execution issues
-------------------------------------------------------------------------------
* `fcache is not multiprocess aware on Windows` :
  https://github.com/tsroten/fcache/issues/26
* ``_read_from_file` returns `None` instead of (re)raise an exception` :
  https://github.com/tsroten/fcache/issues/27
* `OSError: [WinError 17] The system cannot move the file to a different disk drive.` :
  https://github.com/tsroten/fcache/issues/28

-------------------------------------------------------------------------------
4.4.1. fcache implementation hangs or fails in __getitem__/__setitem__
-------------------------------------------------------------------------------

Issue:

  Module hangs on cache read/write/sync.

Solution:

  Patch python `fcache` module sources by patches from the
  `python_patches/fcache` directory.
