* README_EN.txt
* 2019.10.06
* tacklelib--scripts

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. DEPLOY
6. AUTHOR EMAIL

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
The C++11 library support scripts to build a project from Windows (.bat) and
Linux (.sh) platforms separately but with the same configuration files and
variables.

WARNING:
  Use the SVN access to find out new functionality and bug fixes.
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

Currently tested these set of OS platforms, interpreters and modules to run
from:

1. OS platforms.

* Windows 7 (`.bat` only)

2. Interpreters:

* bash shell 3.2.48+
  - to run unix shell scripts

* cmake 3.15.1 (3.14+):
  https://cmake.org/download/
  - to run `cmake_tests` scripts

3. Modules

* Cmake additional modules:

  **  tacklelib--cmake:
      https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/cmake/tacklelib/

4. Configuration template files:

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
`/_scripts/bash_entry` into the `/bin` directory of your platform.

In pure Linux you have additional step to make scripts executable:

>
sudo chmod ug+x /bin/bash_entry
sudo chmod o+r /bin/bash_entry

-------------------------------------------------------------------------------
6. AUTHOR EMAIL
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
