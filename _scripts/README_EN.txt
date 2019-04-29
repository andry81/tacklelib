* README_EN.txt
* 2019.04.29
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

The latest version is here: https://sf.net/p/tacklelib/scripts

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
  * https://svn.code.sf.net/p/tacklelib/scripts/trunk
First mirror:
  * https://github.com/andry81/tacklelib--scripts.git
Second mirror:
  * https://bitbucket.org/andry81/tacklelib-scripts.git

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------
* configuration template files:
  https://svn.code.sf.net/p/tacklelib/scripts--config/trunk
* cmake modules:
  https://svn.code.sf.net/p/tacklelib/cmake/trunk

-------------------------------------------------------------------------------
5. DEPLOY
-------------------------------------------------------------------------------
You must use scripts inside the `_scripts` directory and prepared
configuration files in the `config` subdirectory to build a project.
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
