* README_EN.txt
* 2020.02.10
* tacklelib--scripts

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. DEPLOY
6. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
The C++11 library support scripts to build a project from Windows (.bat) and
Linux (.sh) platforms separately but with the same configuration files and
variables.

WARNING:
  Use the SVN access to find out lastest functionality and bug fixes.
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
  * https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/_scripts/
  * https://svn.code.sf.net/p/tacklelib/tacklelib/trunk/_scripts
First mirror:
  * https://github.com/andry81/tacklelib/tree/trunk/_scripts
  * https://github.com/andry81/tacklelib.git
Second mirror:
  * https://bitbucket.org/andry81/tacklelib/src/trunk/_scripts
  * https://bitbucket.org/andry81/tacklelib.git

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------

Currently tested these set of OS platforms, compilers, IDE's and interpreters
to run from:

1. OS platforms.

* Windows 7 (`.bat` only, minimal version for the cmake 3.14)
* Cygwin 1.7.x (`.sh` only)
* Linux Mint 18.3 x64 (`.sh` only)

2. C++11 compilers.

* (primary) Microsoft Visual C++ 2015 Update 3
* (secondary) GCC 5.4+
* (experimental) Clang 3.8+

3. IDE's.

* Microsoft Visual Studio 2015 Update 3
* Microsoft Visual Studio 2017
* QtCreator 4.6+

4. Interpreters:

* bash shell 3.2.48+
  - to run unix shell scripts
* cmake 3.14+ :
  https://cmake.org/download/
  - to run cmake scripts and modules
* python 3.7.3 or 3.7.5 (3.4+ or 3.5+)
  https://python.org
  - standard implementation to run python scripts
  - 3.7.4 has a bug in the `pytest` module execution, see `KNOWN ISSUES`
    section
  - 3.5+ is required for the direct import by a file path (with any extension)
    as noted in the documentation:
    https://docs.python.org/3/library/importlib.html#importing-a-source-file-directly

Noticeable cmake changes from the version 3.14:

https://cmake.org/cmake/help/v3.14/release/3.14.html#deprecated-and-removed-features

* The FindQt module is no longer used by the find_package() command as a find
  module. This allows the Qt Project upstream to optionally provide its own
  QtConfig.cmake package configuration file and have applications use it via
  find_package(Qt) rather than find_package(Qt CONFIG). See policy CMP0084.

* Support for running CMake on Windows XP and Windows Vista has been dropped.
  The precompiled Windows binaries provided on cmake.org now require Windows 7
  or higher.

5. Modules

* Cmake additional modules:

  **  tacklelib--cmake:
      https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/cmake/tacklelib/

6. Configuration template files:

  **  _config:
      https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/_config/

-------------------------------------------------------------------------------
5. DEPLOY
-------------------------------------------------------------------------------
You must use scripts inside the `_scripts` directory and prepared
configuration files in the `_config` subdirectory to build a project.
Otherwise you have to set at least all dependent variables on yourself before
call to the cmake.

To run bash shell scripts (`.sh` file extension) you should copy the
`/_scripts/tools/bash_entry` into the `/bin` directory of your platform.

In pure Linux you have additional step to make scripts executable:

>
sudo chmod ug+x /bin/bash_entry
sudo chmod o+r /bin/bash_entry

-------------------------------------------------------------------------------
6. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
