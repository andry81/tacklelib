* README_EN.txt
* 2019.03.19
* tacklelib

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. DEPENDENCIES
6. CATALOG CONTENT DESCRIPTION
7. PROJECT CONFIGURATION VARIABLES
8. CONFIGURE
8.1. Manual copy step
8.2. Generation step(s)
8.3. Configuration step
9. BUILD
9.1. From scripts
9.2. From `Visual Studio`
9.3. From `Qt Creator`
10. INSTALL
11. POSTINSTALL
12. KNOWN ISSUES
12.1. The `variable must not be set in case of a multiconfig generator presence
      and must be set if not: ...` cmake configuration error message
13. AUTHOR EMAIL

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
The C++11 generic library which may respresents the same ideas as introduced in
Boost/STL/Loki C++ libraries and at first focused for extension of already
existed C++ code. Sources has been written under MSVC2015 Update 3 and
recompiled in GCC v5.4. As a backbone build system the cmake v3 is used.

In next sections will be introduced common steps to build the project under
Windows AND Linux together. But, to build particularly under Linux you have to
read additionally another readme files:

`README_EN.linux_x86_64.txt`

The latest version is here: https://sf.net/p/tacklelib

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
  * https://svn.code.sf.net/p/tacklelib/tacklelib/trunk
First mirror:
  * https://github.com/andry81/tacklelib.git
Second mirror:
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
* cmake 3.14+ (https://cmake.org/download/ )

Noticeable cmake changes from the version 3.14:

https://cmake.org/cmake/help/v3.14/release/3.14.html#deprecated-and-removed-features

* The FindQt module is no longer used by the find_package() command as a find
  module. This allows the Qt Project upstream to optionally provide its own
  QtConfig.cmake package configuration file and have applications use it via
  find_package(Qt) rather than find_package(Qt CONFIG). See policy CMP0084.

* Support for running CMake on Windows XP and Windows Vista has been dropped.
  The precompiled Windows binaries provided on cmake.org now require Windows 7
  or higher.

-------------------------------------------------------------------------------
5. DEPENDENCIES
-------------------------------------------------------------------------------

Read the `README_EN.deps.txt` file for the common dependencies for the Windows
and the Linux platforms.

-------------------------------------------------------------------------------
6. CATALOG CONTENT DESCRIPTION
-------------------------------------------------------------------------------

<root>
 |
 +- /"_3dparty"
 |  #
 |  # Local 3dparty dependencies catalog.
 |
 +- /"_out"
 |  #
 |  # Temporary directory with build output.
 |
 +- /"_scripts"
 |  | #
 |  | # Scripts to generate, configure, build, install and pack the entire
 |  | # solution.
 |  | # Contains special `__init__` script to allocate basic environment
 |  | # variables and make common preparations.
 |  |
 |  +-/"bash_entry"
 |  |   #
 |  |   # Script for inclusion into all unix bash shell scripts a basic
 |  |   # functionality directly from the root `/bin` directory. Must be
 |  |   # appropriately copied into the `/bin` directory before the usage any
 |  |   # of below unix bash shell scripts.
 |  |
 |  +-/"01_generate_src.*"
 |  |   #
 |  |   # Script to generate source files in root project and local 3dparty
 |  |   # subprojects and libraries which are should not be included in a
 |  |   # version control system.
 |  |
 |  +-/"02_generate_config.*"
 |  |   #
 |  |   # Script to generate configuration files in the `config` subdirectory
 |  |   # which are should not be included in a version control system.
 |  |
 |  +-/"03_configure.*"
 |  |   #
 |  |   # Script to call cmake configure step.
 |  |
 |  +-/"04_build.*"
 |  |   #
 |  |   # Script to call cmake build step on an arbitrary target.
 |  |
 |  +-/"05_install.*"
 |  |   #
 |  |   # Script to call cmake install step on the install target.
 |  |
 |  +-/"06_post_install.*"
 |  |   #
 |  |   # Script to call not cmake post install step.
 |  |
 |  +-/"06_pack.*"
 |      #
 |      # Script to call cmake pack step on the bundle target.
 |
 +- /"cmake"
 |    #
 |    # Directory with external cmake modules.
 |
 +- /"config"
 |  | #
 |  | # Directory with configuration files.
 |  |
 |  +- /"_scripts
 |  |    #
 |  |    # Directory with text files conaining command lines for scripts from
 |  |    # `/_scripts` directory
 |  |
 |  +- "environment_system.vars.in"
 |  |   #
 |  |   # Template file with system set of environment variables
 |  |   # designed to be stored in version control system.
 |  |
 |  +- "environment_system.vars"
 |  |   #
 |  |   # Generated temporary file with set of system customized environment
 |  |   # variables to set them locally. Loads at first.
 |  |
 |  +- "environment_user.vars.in"
 |  |   #
 |  |   # Template file with user set of environment variables
 |  |   # designed to be stored in version control system.
 |  |
 |  +- "environment_user.vars"
 |      #
 |      # Generated temporary file with set of user customized environment
 |      # variables to set them locally. Loads at second.
 |
 +- /"deploy"
 |    #
 |    # Directory to deploy files in postinstall phase.
 |
 +- /"doc"
 |    #
 |    # Directory with documentation files.
 |
 +- /"include"
 |    #
 |    # Directory with public includes.
 |
 +- /"src"
 |    #
 |    # Directory with sources to build.
 |
 |
 +- "CMakeLists.txt" 
     #
     # The cmake catalog root description file.

-------------------------------------------------------------------------------
7. PROJECT CONFIGURATION VARIABLES
-------------------------------------------------------------------------------

* config/environment_system.vars
* config/environment_user.vars

These files must be designed per a particular project and platform, but several
values is immutable to project and platform, and must always exist.

Here the list of most required of them (system variables):

* CMAKE_OUTPUT_ROOT, CMAKE_OUTPUT_DIR, CMAKE_BUILD_ROOT, CMAKE_BIN_ROOT,
  CMAKE_LIB_ROOT, CMAKE_INSTALL_ROOT, CMAKE_CPACK_ROOT, CMAKE_INSTALL_PREFIX,
  CPACK_OUTPUT_FILE_PREFIX

Predefined set of basic roots and directories to point out the base
construction of a project directories involved in a build.

* CMAKE_BUILD_DIR, CMAKE_BIN_DIR, CMAKE_LIB_DIR, CMAKE_CPACK_DIR

Autogenerated directory paths which does exist only after the configure step
has run. Can not be predefined because dependent on the generator `multiconfig`
functionality and existence of the CMAKE_BUILD_TYPE dynamic variable.

* PROJECT_NAME

Name of the project. Must contain the same value as respective project()
command in the `CMakeLists.txt` file, otherwise the error will be thrown.

* PROJECT_TOP_ROOT, PROJECT_ROOT

Optional variables to pinpoint the most top parent project root and the current
project root. Has used as base variables to point project local 3dparty
directories. Must be initialized from respective builtin
CMAKE_CURRENT_TOP_PACKAGE_SOURCE_DIR, CMAKE_CURRENT_PACKAGE_SOURCE_DIR
variables which does initialize after the `configure_environment`
(`/cmake/Common.cmake`) macro call.

* _3DPARTY_GLOBAL_ROOTS_LIST, _3DPARTY_GLOBAL_ROOTS_FILE_LIST

Optional variables which defines directories and files as a Cartesian product
and uses from the `FindGlobal3dpartyEnvironments` function
(`/cmake/FindGlobal3dpartyEnvironments.cmake`).
Required in case of global or external 3dparty projects or libraries which is
not a local part of the project.
Loads before the `/config/environment_system.vars` or
`/config/environment_user.vars`.

* _3DPARTY_LOCAL_ROOT

Optional variable which defines a directory with local 3dparty projects or
libraries.

* CMAKE_CONFIG_TYPES=(<semicolon_separated_list>)

Required variable which defines predefined list of configuration names has used
from the `/_scripts/*_configure.*` script.

* CMAKE_CONFIG_ABBR_TYPES=(<semicolon_separated_list>)

Optional variable which defines a list of associated with the
CMAKE_CONFIG_TYPES variable values of abbreviated configuration names does used
from the `/_scripts/*_configure.*` script.
Useful to define short names for respective complete configuration names to
issue them into respective scripts from `/_scripts` directory.

* CMAKE_GENERATOR

The cmake generator name has used from the `/_scripts/*_configure.*` script.
Can be defined multiple times for different platforms.

* CMAKE_GENERATOR_PLATFORM

The cmake version 3.14+ can use a separate architecture name additionally to
the generator name.

-------------------------------------------------------------------------------
8. CONFIGURE
-------------------------------------------------------------------------------

NOTE:
  Some steps from this section and after will be applicable both for the
  Windows platform (`.bat` file extension) and for the Linux like platform
  (`.sh` file extension).

  For the additional details related particularly to the Linux do read the
  `README_EN.linux_x86_64.txt` file.

-------------------------------------------------------------------------------
10.1. Manual copy step
-------------------------------------------------------------------------------

To run bash shell scripts (`.sh` file extension) you should copy the
`/_scripts/bash_entry` into the `/bin` directory of your platform.

-------------------------------------------------------------------------------
10.2. Generation step(s)
-------------------------------------------------------------------------------

To generate sources which are not included in a version control system call the

`/_scripts/01_generate_src.*` script.

If some template source files has been changed before the call then they will
be overriten upon a call unconditionally.

To generate configuration files which are not included in a version control
system call the

`/_scripts/02_generate_config.*` script.

If some template configuration files has been changed before the call and a
version of template files (at the first line) has changed too, then the script
will try to check that and would throw an error if versions are different.
You must then merge respective configuration files manually before continue or
run the script again.

CAUTION:
  If versions between a template and being generated file are equal then the
  generating file will be overwriten!

After that you should put or edit existed respective variables inside these
generated files:

* `/config/environment_system.vars`
* `/config/environment_user.vars`

Global or external dependencies which are excluded from source
distribution does load through the separate configuration files pointed by
the _3DPARTY_GLOBAL_ROOTS_LIST and _3DPARTY_GLOBAL_ROOTS_FILE_LIST list
variables.

For example, if:

_3DPARTY_GLOBAL_ROOTS_LIST=("d:/3dparty1" "d:/3dparty1")
_3DPARTY_GLOBAL_ROOTS_FILE_LIST=("environment1.vars" "environment2.vars")

, then the generated file paths would be ordered like this:

`d:/3dparty1/environment1.vars`
`d:/3dparty1/environment2.vars`
`d:/3dparty2/environment1.vars`
`d:/3dparty2/environment2.vars`

, and would be loaded together with the local configuration files but before
them:

`d:/3dparty1/environment1.vars`
`d:/3dparty1/environment2.vars`
`d:/3dparty2/environment1.vars`
`d:/3dparty2/environment2.vars`
`/config/environment_system.vars`
`/config/environment_user.vars`

To start use external 3dparty project directories you can take as a basic
example the 3dparty project structure from these links:

Primary:
  * https://svn.code.sf.net/p/contools/3dparty/trunk
First mirror:
  * https://github.com/andry81/contools--3dparty.git

-------------------------------------------------------------------------------
10.3. Configuration step
-------------------------------------------------------------------------------

To make a final configuration call the

`/_scripts/03_configure.*` script.

-------------------------------------------------------------------------------
9. BUILD
-------------------------------------------------------------------------------

Does not matter which one method below is selected the output would be in a
directory pointed by the `CMAKE_BIN_DIR` configuration variable.

-------------------------------------------------------------------------------
9.1. From scripts
-------------------------------------------------------------------------------

1. Run `/_scripts/04_build_x86.* [<ConfigName> [<TargetName>]]`, where:

  <ConfigName> has any value from the `CMAKE_CONFIG_TYPES` or
  `CMAKE_CONFIG_TYPES` variables in the `environment_system.vars` file or
  `*` to build all configurations.

  <TargetName> has any valid target value to build.

-------------------------------------------------------------------------------
9.2. From `Visual Studio`
-------------------------------------------------------------------------------

1. Open `<PROJECT_NAME>.sln` file addressed by directory path in the
   CMAKE_BUILD_DIR dynamic variable.
2. Select any build type has been declared in the CMAKE_CONFIG_TYPES variable.
3. Run build from the IDE.

-------------------------------------------------------------------------------
9.3. From `Qt Creator`
-------------------------------------------------------------------------------

1. Open `CMakeLists.txt` file.
2. Select any build type has been declared in the CMAKE_CONFIG_TYPES variable.
3. Run build from the IDE.

-------------------------------------------------------------------------------
10. INSTALL
-------------------------------------------------------------------------------

1. Run `/_scripts/05_install_x86.* [<ConfigName>]`, where:

  <ConfigName> has any value from the `CMAKE_CONFIG_TYPES` or
  `CMAKE_CONFIG_TYPES` variables in the `environment_system.vars` file or
  `*` to install all configurations.

The output would be in a directory pointed by the `CMAKE_INSTALL_DIR`
configuration variable.

-------------------------------------------------------------------------------
11. POSTINSTALL
-------------------------------------------------------------------------------

NOTE:
  Does not require for the Windows platform.

1. Run `/_scripts/06_post_install_x86.* [<ConfigName>]`, where:

  <ConfigName> has any value from the `CMAKE_CONFIG_TYPES` or
  `CMAKE_CONFIG_TYPES` variables in the `environment_system.vars` file or
  `*` to post install all configurations.

-------------------------------------------------------------------------------
12. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
12.1. The `variable must not be set in case of a multiconfig generator presence
      and must be set if not: ...` cmake configuration error message
-------------------------------------------------------------------------------

The cmake configuration was generated under a cmake generator w/o
multiconfig feature but CMAKE_BUILT_TYPE was not defined, or vice versa.

The configuration name value either must be passed explicitly into a script
from the `/_scripts` directory in case of not multiconfig cmake generator or
must not in case of multiconfig cmake generator.

Solution #1:

1. Pass the configuration name value explicitly into the script or make it
   not defined.

Solution #2:

1. Change the cmake generator in the `CMAKE_GENERATOR` configuration variable
   to the version with appropriate functionality.

Solution #3:

1. In case of the `Qt Creator` do remove the unsupported `Default`
   configuration at `Project` pane, where the `CMAKE_BUILD_TYPE` variable is
   not issued.

-------------------------------------------------------------------------------
13. AUTHOR EMAIL
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
