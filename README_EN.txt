* README_EN.txt
* 2023.02.21
* tacklelib

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. DEPENDENCIES
6. CATALOG CONTENT DESCRIPTION
7. PROJECT CONFIGURATION VARIABLES
8. DEPLOY
9. PRECONFIGURE
10. CONFIGURE
10.1. Generation step(s)
11.2. Configuration step
11. BUILD
11.1. From scripts
11.2. From `Visual Studio`
11.3. From `Qt Creator`
12. INSTALL
13. POSTINSTALL
14. THIRD PARTY SETUP
14.1. ssh+svn/plink setup
15. KNOWN ISSUES
15.1. CMake execution issues
15.1.1. The `CMAKE_BUILD_TYPE variable must not be set in case of a multiconfig
        generator presence and must be set if not: ...` cmake configuration
        error message
15.2. Python execution issues
15.2.1. `OSError: [WinError 6] The handle is invalid`
15.2.2. `ValueError: 'cwd' in __slots__ conflicts with class variable`
15.2.3. `TypeError: descriptor 'combine' for type 'datetime.datetime' doesn't apply to type 'datetime'`
15.3. Python modules issues
15.3.1. pytest execution issues
15.3.2. fcache execution issues
15.4. External application issues
15.4.1. svn+ssh issues
15.4.1.1. Message `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
          `svn: E170012: Can't create tunnel`
15.4.1.2. Message `Can't create session: Unable to connect to a repository at URL 'svn+ssh://...': `
          `To better debug SSH connection problems, remove the -q option from ssh' in the [tunnels] section of your Subversion configuration file. `
          `at .../Git/mingw64/share/perl5/Git/SVN.pm line 310.'`
15.4.1.3. Message `Keyboard-interactive authentication prompts from server:`
          `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
          `svn: E210002: To better debug SSH connection problems, remove the -q option from 'ssh' in the [tunnels] section of your Subversion configuration file.`
          `svn: E210002: Network connection closed unexpectedly`
15.5. Build issues
15.5.1. Message `fatal error C1083: Cannot open include file: '<path-to-external-header-file>': No such file or directory`
16. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
A composite generic library consisted of various modules on different
languages:
* C++11.
  Represents the same ideas as introduced in Boost/STL/Loki C++ libraries and
  at first focused for extension of already existed C++ code.
* Bash.
  Various extension scritps/modules for the bash shell.
* CMake.
  CMake modules to support and extend a build of a c++ project under cmake
  environment.
* Python.
  Various extension scritps/modules for the python.
* VBS.
  Various extension scritps/modules for the Visual Basic Script interpreter.

-------------------------------------------------------------------------------
2. LICENSE
-------------------------------------------------------------------------------
The MIT license (see included text file "license.txt" or
https://en.wikipedia.org/wiki/MIT_License)

-------------------------------------------------------------------------------
3. REPOSITORIES
-------------------------------------------------------------------------------
Primary:
  * https://github.com/andry81/tacklelib/branches
    https://github.com/andry81/tacklelib.git
First mirror:
  * https://sf.net/p/tacklelib/tacklelib/ci/master/tree
    https://svn.code.sf.net/p/tacklelib/tacklelib
Second mirror:
  * https://bitbucket.org/andry81/tacklelib/branches
    https://bitbucket.org/andry81/tacklelib.git

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------

Currently used these set of OS platforms, compilers, interpreters, modules,
IDE's, applications and patches to run with or from:

1. OS platforms:

* Windows XP (`.vbs` only, minimal version for the Windows Script Host)
* Windows 7 (`.bat` only, minimal version for the cmake 3.14)
* Windows 8/8.1
* Windows 10

* Cygwin 1.5+ or 3.0+ (`.sh` only):
  https://cygwin.com
  - to run scripts under cygwin

* Msys2 20190524+ (`.sh` only):
  https://www.msys2.org
  - to run scripts under msys2

* Linux Mint 18.3 x64 (`.sh` only)

2. C++11 compilers:

* (primary) Microsoft Visual C++ 2015 Update 3 or Microsoft Visual C++ 2017
* (secondary) GCC 5.4+
* (experimental) Clang 3.8+

3. Interpreters:

* bash shell 3.2.48+
  - to run unix shell scripts
* perl 5.10+
  - to run specific bash script functions with `perl` calls
* python 3.7.3 or 3.7.5 (3.6.2+)
  https://python.org
  - standard implementation to run python scripts
  - 3.7.4 has a bug in the `pytest` module execution (see `KNOWN ISSUES`
    section).
  - 3.6.2+ is required due to multiple bugs in the python implementation prior
    this version (see `KNOWN ISSUES` section).
  - 3.5+ is required for the direct import by a file path (with any extension)
    as noted in the documentation:
    https://docs.python.org/3/library/importlib.html#importing-a-source-file-directly
* cmake 3.15.1 (3.14+):
  https://cmake.org/download/
  - to run cmake scripts and modules
  - 3.14+ does allow use generator expressions at install phase:
    https://cmake.org/cmake/help/v3.14/policy/CMP0087.html
* Windows Script Host 5.8+
  - standard implementation to run vbs scripts

4. Modules:

* Bash additional modules:

**  tacklelib--bash:
    /bash/tacklelib/

* CMake additional modules:

**  tacklelib--cmake:
    /cmake/tacklelib/

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

**  tacklelib--python:
    /python/tacklelib/

Temporary dropped usage:

**  prompt-toolkit 2.0.9
    - optional dependency to the Xonsh on the Windows
**  cmdix 0.2.0
    https://github.com/jaraco/cmdix
    - extension to use Unix core utils within Python environment as plain
      executable or python function

5. IDE's:

* Microsoft Visual Studio 2015 Update 3
* Microsoft Visual Studio 2017
* QtCreator 4.6+

6. Applications:

* subversion 1.8+
  https://tortoisesvn.net
  - to run svn client
* git 2.24+
  https://git-scm.com
  - to run git client
* cygwin cygpath 1.42+
  - to run `bash_tacklelib` script under cygwin
* msys cygpath 3.0+
  - to run `bash_tacklelib` script under msys2
* cygwin readlink 6.10+
  - to run specific bash script functions with `readlink` calls

7. Patches:

* Python site modules contains patches in the `python_patches`
  subdirectory:

** fcache
   - to fix issues from the `fcache execution issues` section.


Noticeable cmake changes from the version 3.14:

https://cmake.org/cmake/help/v3.14/release/3.14.html#deprecated-and-removed-features

* The FindQt module is no longer used by the find_package() command as a find
  module. This allows the Qt Project upstream to optionally provide its own
  QtConfig.cmake package configuration file and have applications use it via
  find_package(Qt) rather than find_package(Qt CONFIG). See policy CMP0084.

* Support for running CMake on Windows XP and Windows Vista has been dropped.
  The precompiled Windows binaries provided on cmake.org now require Windows 7
  or higher.

https://cmake.org/cmake/help/v3.14/release/3.14.html#id13

* The install(CODE) and install(SCRIPT) commands learned to support generator
  expressions. See policy CMP0087
  (https://cmake.org/cmake/help/v3.14/policy/CMP0087.html):

  In CMake 3.13 and earlier, install(CODE) and install(SCRIPT) did not evaluate
  generator expressions. CMake 3.14 and later will evaluate generator
  expressions for install(CODE) and install(SCRIPT).

-------------------------------------------------------------------------------
5. DEPENDENCIES
-------------------------------------------------------------------------------

Any project which is dependent on this project have has to contain the
`README_EN.deps.txt` description file for the common dependencies in the
Windows and in the Linux like platforms (see `PRECONFIGURE` section).

NOTE:
  To run bash shell scripts (`.sh` file extension) you should copy the
  `/bash/tacklelib/bash_tacklelib` module into the `/bin` directory of your
  platform.

-------------------------------------------------------------------------------
6. CATALOG CONTENT DESCRIPTION
-------------------------------------------------------------------------------

<root>
 |
 +- /`.log`
 |  #
 |  # Log files directory, where does store all log files from all scripts
 |  # including all nested projects.
 |
 +- /`_externals`
 |  #
 |  # Immediate external projects catalog could not be moved into the 3dparty
 |  # dependencies catalog.
 |
 +- /`_config`
 |  | #
 |  | # Directory with build input configuration files.
 |  |
 |  +- `config.system.vars.in`
 |  |   #
 |  |   # Template file with system set of environment variables
 |  |   # designed to be stored in a version control system.
 |  |
 |  +- `config.0.vars.in`
 |      #
 |      # Template file with user set of environment variables
 |      # designed to be stored in a version control system.
 |
 +- /`_out`
 |  | #
 |  | # Temporary directory with build output.
 |  |
 |  +- /`config`
 |     | #
 |     | # Directory with build output configuration files.
 |     |
 |     +- `config.system.vars`
 |     |   #
 |     |   # Generated temporary file from `*.in` file with set of system
 |     |   # customized environment variables to set them locally.
 |     |   # Loads after the global/3dparty environment configuration file(s)
 |     |   # but before the user customized environment variables file.
 |     |
 |     +- `config.0.vars`
 |         #
 |         # Generated temporary file with set of user customized environment
 |         # variables to set them locally.
 |         # Loads after the system customized environment variables file.
 |
 +- /`_build`
 |  | #
 |  | # Scripts to generate, configure, build, install and pack the entire
 |  | # solution.
 |  | # Contains special `__init*__` script to allocate basic environment
 |  | # variables and make common preparations.
 |  |
 |  +-/`01_generate_src.*`
 |  |   #
 |  |   # Scriptw to generate source files in the root project and local
 |  |   # 3dparty subprojects and libraries which are should not be included in
 |  |   # a version control system.
 |  |
 |  +-/`02_generate_config.*`
 |  |   #
 |  |   # Scripts to generate configuration from files in the `_config`
 |  |   # subdirectory which are should not be included in a version control
 |  |   # system.
 |  |
 |  +-/`03_configure.*`
 |  |   #
 |  |   # Scripts to call cmake configure step versus default or custom target.
 |  |
 |  +-/`04_build.*`
 |  |   #
 |  |   # Scripts to call cmake build step versus default or custom target.
 |  |
 |  +-/`05_install.*`
 |  |   #
 |  |   # Scripts to call cmake install step versus default or custom target.
 |  |
 |  +-/`06_post_install.*`
 |  |   #
 |  |   # Scripts to call post install step independently to the cmake.
 |  |
 |  +-/`07_pack.*`
 |      #
 |      # Scripts to call cmake pack step on the bundle target.
 |
 +- /`bash`
 |    #
 |    # Directory with external bash modules.
 |
 +- /`bash_tests`
 |    #
 |    # Directory with tests for bash modules from the `bash` subdirectory.
 |
 +- /`cmake`
 |    #
 |    # Directory with external cmake modules.
 |
 +- /`cmake_tests`
 |    #
 |    # Directory with tests for cmake modules from the `cmake` subdirectory.
 |
 +- /`deploy`
 |    #
 |    # Directory to deploy files in postinstall phase.
 |
 +- /`doc`
 |    #
 |    # Directory with documentation files.
 |
 +- /`include`
 |  | #
 |  | # Directory with public includes.
 |  |
 |  +-/`tacklelib/debug.hpp`
 |  | #
 |  | # the library common public debug definitions
 |  |
 |  +-/`tacklelib/optimization.hpp`
 |  | #
 |  | # the library common public optimization definitions
 |  |
 |  +-/`tacklelib/setup.hpp`
 |    #
 |    # the library common public setup definitions
 |
 +- /`src`
 |  | #
 |  | # Directory with sources to build.
 |  |
 |  +-/`debug.hpp`
 |  | #
 |  | # the library common private debug definitions
 |  |
 |  +-/`optimization.hpp`
 |  | #
 |  | # the library common private optimization definitions
 |  |
 |  +-/`setup.hpp`
 |    #
 |    # the library common private setup definitions
 |
 +- `CMakeLists.txt`
     #
     # The cmake catalog root description file.

-------------------------------------------------------------------------------
7. PROJECT CONFIGURATION VARIABLES
-------------------------------------------------------------------------------

1. `/_config/config.system.vars.in`
   `/_config/config.0.vars.in`

These files must be designed per a particular project and platform, but several
values are immutable to a project and a platform, and must always exist.

Here is the list of a most required of them (system variables):

* CMAKE_OUTPUT_ROOT, CMAKE_OUTPUT_DIR, CMAKE_OUTPUT_GENERATOR_DIR,
  CMAKE_BUILD_ROOT, CMAKE_BIN_ROOT, CMAKE_LIB_ROOT, CMAKE_INSTALL_ROOT,
  CMAKE_PACK_ROOT, CMAKE_INSTALL_PREFIX, CPACK_OUTPUT_FILE_PREFIX

Predefined set of basic roots and directories to point out the base
structure of a project directories involved in a build.

* CMAKE_BUILD_DIR, CMAKE_BIN_DIR, CMAKE_LIB_DIR, CMAKE_INSTALL_ROOT,
  CMAKE_PACK_DIR

Auto generated directory paths which does exist only after the configure step
have has to run. Can not be predefined because dependent on the generator
`multiconfig` or `singleconfig` functionality and existence of the
`CMAKE_BUILD_TYPE` dynamic variable (empty or not).

* PROJECT_NAME

Name of the project. Must contain the same value as respective `project(...)`
command in the `CMakeLists.txt` file, otherwise an error will be thrown.

* PROJECT_TOP_ROOT, PROJECT_ROOT

Optional variables to pinpoint the most top parent project root and the current
project root. Has used as base variables to point project local 3dparty
directories. Must be initialized from respective builtin
CMAKE_TOP_PACKAGE_SOURCE_DIR, CMAKE_CURRENT_PACKAGE_SOURCE_DIR
variables which does initialize after the `tkl_configure_environment`
(`/cmake/tacklelib/Project.cmake`) macro call.

* _3DPARTY_GLOBAL_ROOTS_LIST, _3DPARTY_GLOBAL_ROOTS_FILE_LIST

Optional variables which does define directories and files as a Cartesian
product and has used from the `find_global_3dparty_environments` function
(`/cmake/tacklelib/_3dparty/Global3dparty.cmake`) to search for the
`environment.vars` file to load.

Is required in case of a global or an external 3dparty project or library
which is not a local part of the project.

Loads at first before these configuration files:

  * `/_out/config/tacklelib/cmake/config.system.vars`
  * `/_out/config/tacklelib/cmake/config.0.vars`

The `environment.vars` file may define these variables to distinguish out of
sources build directories:

  * `_3DPARTY_BUILD_SOURCES_ROOT`
  * `_3DPARTY_BUILD_OUTPUT_ROOT`

* CMAKE_CONFIG_TYPES=(<space_separated_list>)

Required variable which defines predefined list of configuration names has used
from the `/_build/*_configure.*` script.

Example:
  CMAKE_CONFIG_TYPES=(Release Debug RelWithDebInfo MinSizeRel)

* CMAKE_CONFIG_ABBR_TYPES=(<semicolon_separated_list>)

An optional variable which defines a list of associated with the
CMAKE_CONFIG_TYPES variable values of abbreviated configuration names has used
from the `/_build/*_configure.*` script.
Useful to define short names for respective complete configuration names to
issue them in respective scripts from the `/_build` directory.

Example:
  CMAKE_CONFIG_ABBR_TYPES=(r d rd rm)

* CMAKE_GENERATOR

The cmake generator name does used from the `/_build/*_configure.*` script.
Can be defined multiple times for different platforms.

Example(s):
  CMAKE_GENERATOR:WIN="Visual Studio 14 2015"
  CMAKE_GENERATOR:UNIX="Unix Makefiles"

* CMAKE_GENERATOR_PLATFORM

The cmake version 3.14+ can use a separate architecture name additionally to
the generator name.

Example:
  # required for the CMAKE_OUTPUT_GENERATOR_DIR, because the architecture
  # parameter does not supported in the `config.system.vars` stage
  CMAKE_GENERATOR_PLATFORM:WIN=Win32

  # must be at least empty to avoid generation of the
  # `*:$/{CMAKE_GENERATOR_PLATFORM}` as an replacement value
  CMAKE_GENERATOR_PLATFORM:UNIX=""

-------------------------------------------------------------------------------
8. DEPLOY
-------------------------------------------------------------------------------
To run bash shell scripts (`.sh` file extension) you should copy these scripts:

* /bash/tacklelib/bash_entry
* /bash/tacklelib/bash_tacklelib

into the `/bin` directory of your platform.

In pure Linux you have additional step to make scripts executable or readable:

>
sudo chmod ug+x /bin/bash_entry
sudo chmod o+r  /bin/bash_entry
sudo chmod a+r  /bin/bash_tacklelib

-------------------------------------------------------------------------------
9. PRECONFIGURE
-------------------------------------------------------------------------------

Some of steps from this section and after will be applicable both for the
Windows platform (`.bat` file extension) and for the Linux like platform
(`.sh` file extension).

To prepare 3dparty dependencies you can:

  1. Read the root `README_EN.txt` file from the
     `tacklelib--3dparty_build_scripts` project for the 3dparty directory
     creation details:
     * https://github.com/andry81-3dparty/tacklelib--3dparty_build_scripts
     * https://sf.net/p/tacklelib/3dparty_build_scripts

  2. Download required dependencies declared in the `README_EN.deps.txt`
     file and put into the 3dparty directory as described in the previous
     step.

  3. Read nested `README_EN.txt` file from the
     `tacklelib--3dparty_build_scripts` project for instructions to run
     build scripts and build a library declared in the `README_EN.deps.txt`
     file if required a library standalone build.

-------------------------------------------------------------------------------
10. CONFIGURE
-------------------------------------------------------------------------------

NOTE:
  For the additional details related particularly to the Linux do read the
  `README_EN.linux_x86_64.txt` file.

-------------------------------------------------------------------------------
10.1. Generation step(s)
-------------------------------------------------------------------------------

To generate the source files which are not included in a version control system
do call to:

`/_build/01_generate_src.*` script.

If some from template instantiated source files has been changed before the
call, then they will be overwritten upon a call by the script unconditionally.

To generate configuration files which are not included in a version control
system do call to:

`/_build/02_generate_config.*` script.

These set of files will be generated up on a call:

  Public headers:

  * /include/tacklelib/debug.hpp
  * /include/tacklelib/optimization.hpp
  * /include/tacklelib/setup.hpp

  Private headers:

  * /src/debug.hpp
  * /src/optimization.hpp
  * /src/setup.hpp

CAUTION:
  You have to edit these files for correct values before continue with the
  next steps.

After that you should put or edit existed respective variables inside these
generated files:

* `/_out/config/tacklelib/cmake/config.system.vars`
* `/_out/config/tacklelib/cmake/config.0.vars`

The global or 3dparty dependencies which are excluded from the source files
distribution does load through the separate configuration files is pointed by
the _3DPARTY_GLOBAL_ROOTS_LIST and _3DPARTY_GLOBAL_ROOTS_FILE_LIST list
variables.

For example, if:

_3DPARTY_GLOBAL_ROOTS_LIST:WIN=("d:/3dparty1" "d:/3dparty2")
_3DPARTY_GLOBAL_ROOTS_LIST:UNIX=(/home/opt/3dparty1 /home/opt/3dparty2)
_3DPARTY_GLOBAL_ROOTS_FILE_LIST=("environment1.vars" "environment2.vars")

, then the generated file paths would be ordered like this:

For the Windows platform:

`d:/3dparty1/environment1.vars`
`d:/3dparty1/environment2.vars`
`d:/3dparty2/environment1.vars`
`d:/3dparty2/environment2.vars`

For the Linux like platform:

`/home/opt/3dparty1/environment1.vars`
`/home/opt/3dparty1/environment2.vars`
`/home/opt/3dparty2/environment1.vars`
`/home/opt/3dparty2/environment2.vars`

, and would be loaded together with the local configuration files but before
them:

For the Windows platform:

`d:/3dparty1/environment1.vars`
`d:/3dparty1/environment2.vars`
`d:/3dparty2/environment1.vars`
`d:/3dparty2/environment2.vars`
`/_out/config/tacklelib/cmake/config.system.vars`
`/_out/config/tacklelib/cmake/config.0.vars`

For the Linux like platform:

`/home/opt/3dparty1/environment1.vars`
`/home/opt/3dparty1/environment2.vars`
`/home/opt/3dparty2/environment1.vars`
`/home/opt/3dparty2/environment2.vars`
`/_out/config/tacklelib/cmake/config.system.vars`
`/_out/config/tacklelib/cmake/config.0.vars`

-------------------------------------------------------------------------------
10.2. Configuration step
-------------------------------------------------------------------------------

To make a final configuration call to:

`/_build/03_configure.* [<ConfigName>]`, where:

  <ConfigName> has any value from the `CMAKE_CONFIG_TYPES` or
  the `CMAKE_CONFIG_ABBR_TYPES` variables from the `config.system.vars`
  file or `*` to build all configurations.

NOTE:
  <ConfigName> must be used ONLY if the `CMAKE_GENERATOR` variable value is set
  to a not multiconfig generator, otherwise it must not be used.

-------------------------------------------------------------------------------
11. BUILD
-------------------------------------------------------------------------------

Does not matter which one method below would be selected when the output would
be in a directory pointed by the `CMAKE_BIN_DIR` configuration variable.

-------------------------------------------------------------------------------
11.1. From scripts
-------------------------------------------------------------------------------

1. Run `/_build/04_build.* [<ConfigName> [<TargetName>]]`, where:

  <ConfigName> has any value from the `CMAKE_CONFIG_TYPES` or
  the `CMAKE_CONFIG_ABBR_TYPES` variables from the `config.system.vars`
  file or `*` to build all configurations.

  <TargetName> has any valid target name to build.

NOTE:
  To enumerate all callable target names from the cmake you can type a special
  target - `help`.

-------------------------------------------------------------------------------
11.2. From `Visual Studio`
-------------------------------------------------------------------------------

1. Open `<PROJECT_NAME>.sln` file addressed by a directory path in the
   `CMAKE_BUILD_DIR` dynamic variable.
2. Select any build type has been declared in the `CMAKE_CONFIG_TYPES`
   variable.
3. Run build from the IDE.

-------------------------------------------------------------------------------
11.3. From `Qt Creator`
-------------------------------------------------------------------------------

1. Open `CMakeLists.txt` file.
2. Remove all unsupported configurations not declared in the
   `CMAKE_CONFIG_TYPES` variable like the `Default` from the inner
   configuration list.
3. Select any build type has been declared in the `CMAKE_CONFIG_TYPES`
   variable.
4. Run build from the IDE.

-------------------------------------------------------------------------------
12. INSTALL
-------------------------------------------------------------------------------

1. Run `/_build/05_install.* [<ConfigName> [<TargetName>]]`, where:

  <ConfigName> has any value from the `CMAKE_CONFIG_TYPES` or
  the `CMAKE_CONFIG_ABBR_TYPES` variables from the `config.system.vars`
  file or `*` to install all configurations.

  <TargetName> has any valid target name to install.

The output would be in a directory pointed by the `CMAKE_INSTALL_DIR`
configuration variable.

NOTE:
  The cmake may not support a target selection for a particular generator.

-------------------------------------------------------------------------------
13. POSTINSTALL
-------------------------------------------------------------------------------

NOTE:
  Is not required for the Windows platform.

1. Run `/_build/06_post_install.* [<ConfigName>]`, where:

  <ConfigName> has any value from the `CMAKE_CONFIG_TYPES` or
  the `CMAKE_CONFIG_ABBR_TYPES` variables from the `config.system.vars`
  file or `*` to post install all configurations.

CAUTION:
  The containment of a directory pointed by the `CMAKE_INSTALL_DIR`
  configuration variable may be changed or rearranged, so another run can
  gain different results!

-------------------------------------------------------------------------------
14. THIRD PARTY SETUP
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.1. ssh+svn/plink setup
-------------------------------------------------------------------------------
Based on: https://stackoverflow.com/questions/11345868/how-to-use-git-svn-with-svnssh-url/58641860#58641860

The svn+ssh protocol must be setuped using both the private and the public ssh
key.

In case of in the Windows usage you have to setup the ssh key before run the
svn client using these general steps related to the native Windows `svn.exe`
(should not be a ported one, for example, like the `msys` or `cygwin` tools
which is not fully native):

1. Install the `putty` client.
2. Generate the key using the `puttygen.exe` utility and the correct type of
   the key dependent on the svn hub server (Ed25519, RSA, DSA, etc).
3. Install the been generated public variant of the key into the svn hub server
   by reading the steps from the docs to the server.
4. Ensure that the `SVN_SSH` environment variable in the generated
   `config.env.yaml` file is pointing a correct path to the `plink.exe` and
   uses valid arguments. This would avoid hangs in scripts because of
   interactive login/password request and would avoid usage svn repository
   urls with the user name inside.
5. Ensure that all svn working copies and the `externals` properties in them
   contains valid svn repository urls with the `svn+ssh://` prefix. If not then
   use the `*~svn~relocate.*` scrtip(s) to switch onto it. Then fix all the
   rest urls in the `externals` properties, for example, just by remove the url
   scheme prefix and leave the `//` prefix instead.
6. Run the `pageant.exe` in the background with the previously generated
   private key (add it).
7. Test the connection to the svn hub server through the `putty.exe` client.
   The client should not ask for the password if the `pageant.exe` is up and
   running with has been correctly setuped private key. The client should not
   ask for the user name either if the `SVN_SSH` environment variable is
   declared with the user name.

The `git` client basically is a part of ported `msys` or `cygwin` tools, which
means they behaves a kind of differently.

The one of the issues with the message `Can't create session: Unable to connect
to a repository at URL 'svn+ssh://...': Error in child process: exec of ''
failed: No such file or directory at .../Git/mingw64/share/perl5/Git/SVN.pm
line 310.` is the issue with the `SVN_SSH` environment variable. The variable
should be defined with an utility from the same tools just like the `git`
itself. The attempt to use it with the standalone `plink.exe` from the `putty`
application would end with that message.

So, additionally to the steps for the `svn.exe` application you should apply,
for example, these steps:

1. Drop the usage of the `SVN_SSH` environment variable and remove it.
2. Run the `ssh-pageant` from the `msys` or `cygwin` tools (the `putty`'s
   `pageant` must be already run with the valid private key). You can read
   about it, for example, from here: https://github.com/cuviper/ssh-pageant
   ("ssh-pageant is a tiny tool for Windows that allows you to use SSH keys
   from PuTTY's Pageant in Cygwin and MSYS shell environments.")
3. Create the environment variable returned by the `ssh-pageant` from the
   stdout, for example: `SSH_AUTH_SOCK=/tmp/ssh-hNnaPz/agent.2024`.
4. Use urls in the `git svn ...` commands together with the user name as stated
   in the documentation
   (https://git-scm.com/docs/git-svn#Documentation/git-svn.txt---usernameltusergt ):
   `svn+ssh://<USERNAME>@svn.<url>.com/repo`
   ("For transports that SVN handles authentication for (http, https, and plain
   svn), specify the username. For other transports (e.g. svn+ssh://), you
   **must include the username in the URL**,
   e.g. svn+ssh://foo@svn.bar.com/project")

These instructions should help to use `git svn` commands together with the
`svn` commands.

-------------------------------------------------------------------------------
15. KNOWN ISSUES
-------------------------------------------------------------------------------
For the issues around python xonsh module see details in the
`README_EN.python_xonsh.known_issues.txt` file.

-------------------------------------------------------------------------------
15.1. CMake execution issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
15.1.1. The `CMAKE_BUILD_TYPE variable must not be set in case of a multiconfig
        generator presence and must be set if not: ...` cmake configuration
        error message
-------------------------------------------------------------------------------

The cmake configuration was generated under a cmake generator without
a multiconfig feature but the `CMAKE_BUILT_TYPE` variable was not defined, or
vice versa.

The configuration name value either must be passed explicitly into a script
from the `/_build` directory in case of not a multiconfig cmake generator or
must not in case of a multiconfig cmake generator.

Solution #1:

  Pass the configuration name value explicitly into the script or make it
  not defined.

Solution #2:

  Change the cmake generator in the `CMAKE_GENERATOR` configuration variable
  to the version with appropriate functionality.

Solution #3:

  In case of the `Qt Creator` do remove the unsupported `Default`
  configuration at `Project` pane, where the `CMAKE_BUILD_TYPE` variable value
  is not applicable.

-------------------------------------------------------------------------------
15.2. Python execution issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
15.2.1. `OSError: [WinError 6] The handle is invalid`
-------------------------------------------------------------------------------

Issue:

  The python interpreter (3.7, 3.8, 3.9) sometimes throws this message at exit,
  see details here:

  `subprocess.Popen._cleanup() "The handle is invalid" error when some old process is gone` :
  https://bugs.python.org/issue37380

Solution:

  Reinstall a different python version.

-------------------------------------------------------------------------------
15.2.2. `ValueError: 'cwd' in __slots__ conflicts with class variable`
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
15.2.3. `TypeError: descriptor 'combine' for type 'datetime.datetime' doesn't apply to type 'datetime'`
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
15.3. Python modules issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
15.3.1. pytest execution issues
-------------------------------------------------------------------------------
* `xonsh incorrectly reorders the test for the pytest` :
  https://github.com/xonsh/xonsh/issues/3380
* `a test silent ignore` :
  https://github.com/pytest-dev/pytest/issues/6113
* `can not order tests by a test directory path` :
  https://github.com/pytest-dev/pytest/issues/6114

-------------------------------------------------------------------------------
15.3.2. fcache execution issues
-------------------------------------------------------------------------------
* `fcache is not multiprocess aware on Windows` :
  https://github.com/tsroten/fcache/issues/26
* ``_read_from_file` returns `None` instead of (re)raise an exception` :
  https://github.com/tsroten/fcache/issues/27
* `OSError: [WinError 17] The system cannot move the file to a different disk drive.` :
  https://github.com/tsroten/fcache/issues/28

-------------------------------------------------------------------------------
15.4. External application issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
15.4.1. svn+ssh issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
15.4.1.1. Message `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
          `svn: E170012: Can't create tunnel`
-------------------------------------------------------------------------------

Issue #1:

  The `svn ...` command was run w/o properly configured putty plink utility or
  w/o the `SVN_SSH` environment variable with the user name parameter.

Solution:

  Carefully read the `ssh+svn/plink setup` section to fix most of the cases.

Issue #2

  The `SVN_SSH` environment variable have has the backslash characters - `\`.

Solution:

  Replace all the backslash characters by forward slash character - `/` or by
  double baskslash character - `\\`.

-------------------------------------------------------------------------------
15.4.1.2. Message `Can't create session: Unable to connect to a repository at URL 'svn+ssh://...': `
          `To better debug SSH connection problems, remove the -q option from ssh' in the [tunnels] section of your Subversion configuration file. `
          `at .../Git/mingw64/share/perl5/Git/SVN.pm line 310.'`
-------------------------------------------------------------------------------

Issue:

  The `git svn ...` command should not be called with the `SVN_SSH` variable
  declared for the `svn ...` command.

Solution:

  Read docs about the `ssh-pageant` usage from the msys tools to fix that.

  See details: https://stackoverflow.com/questions/31443842/svn-hangs-on-checkout-in-windows/58613014#58613014

-------------------------------------------------------------------------------
15.4.1.3. Message `Keyboard-interactive authentication prompts from server:`
          `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
          `svn: E210002: To better debug SSH connection problems, remove the -q option from 'ssh' in the [tunnels] section of your Subversion configuration file.`
          `svn: E210002: Network connection closed unexpectedly`
-------------------------------------------------------------------------------

Related command: `git svn ...`

Issue #1:

  Network is disabled:

Issue #2:

  The `pageant` application is not running or the private SSH key is not added.

Issue #3:

  The `ssh-pageant` utility is not running or the `git svn ...` command does
  run without the `SSH_AUTH_SOCK` environment variable properly registered.

Solution:

  Read the details in the `ssh+svn/plink setup` section.

-------------------------------------------------------------------------------
15.5. Build issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
15.5.1. Message `fatal error C1083: Cannot open include file: '<path-to-external-header-file>': No such file or directory`
-------------------------------------------------------------------------------

Issues:

  An external optional library has been excluded from the build in the cmake
  by the unset instruction of the library `*_ROOT` variable or by the variable
  not presence. But the dependentee project still using the library in the
  headers which must be disabled separately from the cmake by a header in the
  dependentee project.

  Read the `Generation step(s)` section for the details.

Solution:

  Edit respective generated files for the correct values to fix the build.

-------------------------------------------------------------------------------
16. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
