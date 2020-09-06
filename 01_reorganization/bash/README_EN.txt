* README_EN.txt
* 2020.03.08
* tacklelib--bash

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. DEPLOY
6. TESTS
7. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
The `tacklelib` library bash support modules to run bash shell scripts on
Windows and Linux platforms separately without any other extra dependencies
except those from the PREREQUISITES section below.
The entire functionality based only on the `bash` shell modules from the
`tacklelib` library without other shells or standalone script interpreters like
`python` or `cmake`, but not excluding preinstalled in the unix interpreters
like `perl` or unix utilities like `readlink`, `sed`, `grep` and so on.

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
  * https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/bash/tacklelib
  * https://svn.code.sf.net/p/tacklelib/tacklelib/trunk/bash/tacklelib
First mirror:
  * https://github.com/andry81/tacklelib/tree/trunk/bash
  * https://github.com/andry81/tacklelib.git
Second mirror:
  * https://bitbucket.org/andry81/tacklelib/src/trunk/bash
  * https://bitbucket.org/andry81/tacklelib.git

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------

Currently used these set of OS platforms, compilers, interpreters, modules,
IDE's, applications and patches to run with or from:

1. OS platforms:

* Windows 7 (`.bat` only)
* Cygwin 1.5+ or 3.0+ (`.sh` only):
  https://cygwin.com
  - to run scripts under cygwin
* Msys2 20190524+ (`.sh` only):
  https://www.msys2.org
  - to run scripts under msys2
* Linux Mint 18.3 x64 (`.sh` only)

2. Interpreters:

* bash shell 3.2.48+
  - to run unix shell scripts
* perl 5.10+
  - to run specific bash script functions with `perl` calls

3. Applications:

* cygwin cygpath 1.42+
  - to run `bash_entry` script under cygwin
* msys cygpath 3.0+
  - to run `bash_entry` script under msys2
* cygwin readlink 6.10+
  - to run specific bash script functions with `readlink` calls

-------------------------------------------------------------------------------
5. DEPLOY
-------------------------------------------------------------------------------
To run bash shell scripts (`.sh` file extension) you should copy the
`/bash/tacklelib/bash_entry` module into the `/bin` directory of your platform.

In pure Linux you have additional step to make scripts executable:

>
sudo chmod ug+x /bin/bash_entry
sudo chmod o+r /bin/bash_entry

-------------------------------------------------------------------------------
6. TESTS
-------------------------------------------------------------------------------
* bash modules tests:
  https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/bash_tests/

-------------------------------------------------------------------------------
7. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
