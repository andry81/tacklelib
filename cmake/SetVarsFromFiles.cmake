cmake_minimum_required(VERSION 3.13)

# at least cmake 3.13 is required for:
# * to use `\r` and `\n` escape sequence in regex expressions: (https://cmake.org/cmake/help/v3.13/command/string.html#regex-specification )
#   `[\r\n]*`
# * to use `Bracket Argument` in regex expressions: (https://cmake.org/cmake/help/v3.13/manual/cmake-language.7.html#bracket-argument )
#   `[[\+\*]]`
#

# at least cmake 3.12 is required for:
# * to use list SUBLIST command: (https://cmake.org/cmake/help/v3.12/command/list.html#sublist )
#   `list(SUBLIST <list> <begin> <length> <output variable>)`
# * to use list JOIN command: (https://stackoverflow.com/questions/7172670/best-shortest-way-to-join-a-list-in-cmake/49590183#49590183 )
#   `list(JOIN <list> <glue> <out-var>)`
#

# at least cmake 3.9 is required for:
#   * Multiconfig generator detection support: see the `GENERATOR_IS_MULTI_CONFIG` global property
#     (https://cmake.org/cmake/help/v3.9/prop_gbl/GENERATOR_IS_MULTI_CONFIG.html )
#

# at least cmake 3.7 is required for:
# * to use GREATER_EQUAL in if command: (https://cmake.org/cmake/help/v3.7/command/if.html )
#   `if(<variable|string> GREATER_EQUAL <variable|string>)`
#

# at least cmake 3.3 is required for:
# * to use IN_LIST in if command: (https://cmake.org/cmake/help/v3.3/command/if.html )
#   `if(<variable|string> IN_LIST <variable>)`
#

include(Std)
include(Version)

# TODO:
#   * The same setter but from a command line file
#

# RULES FOR VARIABLES LOAD OR SET:
#
# 1. All variables being loaded from a single load or set function is treated as constant,
#    which means the parser must throw an a warning and ignore a variable assign if a variable
#    has been set in the same load or set function AND has having exact pattern match with the
#    previous applied assignment of the same variable if has any.
#    Example:
#       AAA=10
#       AAA=20 # <- assign would be ignored with a warning
# 2. All variables being loaded in a not top package are ignored by default.
#    To allow load in a not top package a variable must be declared with the `override` attribute.
#    Example:
#       # CMAKE_CURRENT_PACKAGE_NEST_LVL=0
#       AAA=10
#       # CMAKE_CURRENT_PACKAGE_NEST_LVL=1
#       override AAA=20 # <- assignment would be applied respectively to a single load rules
#       # CMAKE_CURRENT_PACKAGE_NEST_LVL=2
#       AAA=30          # <- assignment would be silently ignored
# 3. A complete pattern matched variable is a variable which template parameters after the colon character
#    (:<os_name>:<compiler_name>:<config_name>:<arch_name>)
#    are completely (not partially) matched to the function respective input parameters.
#    Example:
#       # input: os_name=WIN compiler_name=MSVC config_name=RELEASE arch_name=*
#       AAA:WIN:MSVC:RELEASE:X86=10 # <- would be set if all template parameters are matched completely to the function input
# 4. A partially matched variable is a variable which template parameters after the colon character
#    (:<os_name>:<compiler_name>:<config_name>:<arch_name>) are matched partially
#    (either one or several parameters are matched, but not all).
#    Example:
#       # input: os_name=UNIX compiler_name=GCC config_name=* arch_name=*
#       AAA::GCC=20 # <- would be set if at least second template parameter is matched to the function input
# 5. A variable w/o explicitly declared template parameters is not applicable for a pattern match but
#    treated as always matched to any input respective parameters of the load or set function.
# 6. If before the load or set function a variable already has been set, then a
#    very first variable being assigned in the load or set function must has the same value,
#    otherwise the variable is treated as not connected to the variable has existed before
#    the call and an error would be thrown.
# 7. A complete or more specialized pattern matched variable has assign priority over a partially or less specialized pattern matched variable which
#    in turn has greater priority over a lesser specialized pattern matched variable.
#    Example:
#       # input: os_name=UNIX compiler_name=GCC config_name=* arch_name=*
#       AAA=10                  # no pattern but matched, assignment would be applied if variable either was not set before the call or was set externally to the same value
#       AAA:UNIX=20             # more specialized match over previously applied assignment, assignment would be applied
#       AAA:UNIX:GCC=30         # more specialized match over previously applied assignment, assignment would be applied
#       AAA=40                  # no pattern but matched, less priority match versus previously applied assignment, assignment would be ignored with a warning
#       AAA::GCC=50             # still less priority match versus previously applied assignment, assignment would be ignored with a warning
#       AAA:UNIX:GCC=60         # equal priority match versus previously applied assignment, assignment would be treated as a constant variable change and ignored with a warning
#       AAA:UNIX:GCC:RELEASE=70 # more specialized match over previously applied assignment, assignment would be applied
#
# All other cases is not represent above can be controlled over the command line options/parameters/flags of the load or set functions.
#

# ASSIGNMENT STRATEGY BETWEEN ASSIGNMENTS WITH VARIABLE ATTRIBUTES AT DIFFERENT CONFIGURATION LEVELS (files or packages, including of the `package` attribute presence)
#
# '.  LEVEL N+1|             |             |
#   '-------,  |             |             |
# LEVEL N    '.|  <not set>  |  override   | top
# -------------+-------------+-------------+--------
#   <not set>  |  assign     |  assign     | error
#   top        |  error      |  assign     | ignore
#              |             |             |
#

# CAUTION:
#   Function must be without arguments to avoid argument variable intersection with the parent scope!
#
# Usage:
#   [<flags>] "<file_path0>[...\;<file_pathN>]"
#
# flags:
#   The same as in `set_vars_from_files` function.
#
macro(load_vars_from_files) # WITH OUT ARGUMENTS!
  load_vars_from_files_impl_init()
  make_argn_var_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}")
  # in case of in a macro call we must pass all ARGV arguments explicitly
  set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #print_ARGV()
  make_argn_var_from_ARGV_ARGN_end()
  unset_ARGV()
  load_vars_from_files_impl()
endmacro()

macro(load_vars_from_files_impl_init)
  set_vars_from_files_impl_init()
endmacro()

function(load_vars_from_files_impl) # WITH OUT ARGUMENTS!
  list(LENGTH argn argn_len)
  set(argn_index 0)

  set(flag_args "")

  set(load_state_from_cmake_global_properties 0)
  set(save_state_into_cmake_global_properties 0)

  # copy all flag parameters into a variable without parsing them
  parse_function_optional_flags_into_vars_impl(
    argn_index
    argn
    "p;e;E;a"
    ""
    ""
    "varlines\;.\;.;vars\;.\;.;values\;.\;.;flock\;.\;.;ignore_statement_if_no_filter;\
ignore_statement_if_no_filter_config_name;\
ignore_late_expansion_statements;grant_external_vars_for_assign\;.\;.;\
grant_no_check_assign_vars_assigned_in_files\;.\;.;\
grant_assign_external_vars_assigning_in_files\;.\;.;\
grant_assign_vars_as_top_in_files\;.\;.;\
grant_assign_vars_by_override_in_files\;.\;.;\
grant_subpackage_assign_ignore_in_files\;.\;.;\
grant_assign_for_variables\;.\;.;\
grant_assign_on_variables_change\;.\;.;\
include_vars_filter\;.\;.;\
exclude_vars_filter\;.\;.;\
load_state_from_cmake_global_properties\;load_state_from_cmake_global_properties\;.;\
save_state_into_cmake_global_properties\;save_state_into_cmake_global_properties\;.;\
make_vars\;.\;.\;."
    flag_args
  )

  if (NOT argn_index LESS argn_len)
    message(FATAL_ERROR "load_vars_from_files function must be called at least with 1 variadic argument: argn_len=${argn_len} argn_index=${argn_index}")
  endif()

  # CMAKE_BUILD_TYPE consistency check
  check_CMAKE_BUILD_TYPE_vs_multiconfig()

  list(GET argn ${argn_index} file_paths) # discardes ;-escaping
  math(EXPR argn_index "${argn_index}+1")

  if (NOT load_state_from_cmake_global_properties OR save_state_into_cmake_global_properties)
    message("* Loading variables from `${file_paths}`...")
  else()
    message("* Preloading variables from `${file_paths}`...")
  endif()

  if (NOT CMAKE_BUILD_TYPE)
    list(APPEND flag_args "--ignore_statement_if_no_filter_config_name")
  endif()
  list(APPEND flag_vars "--ignore_late_expansion_statements")

  set_vars_from_files_impl_with_args(${flag_args} "${file_paths}" "" "" "${CMAKE_BUILD_TYPE}" "" "")
endfunction()

# CAUTION:
#   Function must be without arguments to:
#   1. avoid function variables intersection with the parent scope!
#   2. support optional leading arguments like flags beginning by the `-` character
#
# Usage:
#   [<flags>] <file_paths> <os_name> <compiler_name> <config_name> <arch_name> <list_separator_char> \
#     [<out_var_config_gen_var_lines_list> <out_var_config_gen_vars_list> <out_var_config_gen_names_list> <out_var_config_gen_values_list>]
#
# flags:
#   -p - print variables set
#   -e - additionally export variables into environment
#   -E - set environment variables instead of usual set (overrides -e)
#   --varlines <varlines_file>  - instead of does set variables does save variable lines into a file each per line
#   --vars <vars_file>          - instead of does set variables does save variable names into a file each per line
#   --values <values_file>      - instead of does set variables does save variable values into a file each per line (multiline variables leaves truncated)
#   --flock <flock_file>        - file lock to lock write into `--varlines`, `--vars` and `--values` file arguments
#   -a                          - append values into `varlines_file`, `vars_file` and `values_file`
#
#   --grant_external_vars_for_assign <grant_external_vars_for_assign_list>
#                               - list of variables granted for unconditional assignment if has been assigned before the load call
#                                 (by default would be an error if a variable has been assigned before the load call and a new value is not equal to the previous)
#
#   --grant_no_check_assign_vars_assigned_in_files <grant_no_check_assign_vars_assigned_in_files_list>
#                               - list of files with assigned variables granted for assignment w/o collision check in other variable files going to be loaded
#
#   --grant_assign_external_vars_assigning_in_files <grant_assign_external_vars_assigning_in_files_list>
#                               - list of files with variables granted for unconditional assignment if variables has been assigned before a very first load call
#
#   --grant_assign_vars_as_top_in_files <grant_assign_vars_as_top_in_files_list>
#                               - List of files with variables granted for unconditional assignment as variables with `top` attribute.
#
#   --grant_assign_vars_by_override_in_files <grant_assign_vars_by_override_in_files_list>
#                               - List of files with variables w/o explicit `override` and `top` attributes granted for unconditional assignment as if variables
#                                 has been declared together with the `override` attribute. Has priority over `grant_subpackage_assign_ignore_in_files` flag.
#
#   --grant_subpackage_assign_ignore_in_files <grant_subpackage_assign_ignore_in_files_list>
#                               - List of files with variables granted for unconditional assign ignore if variables has been already assigned in previous
#                                 level(s). It does ignore files is marked by the `grant_assign_vars_by_override_in_files` flag.
#
#   --include_vars_filter <include_vars_filter_list>
#                               - list of variables included to assign
#
#   --exclude_vars_filter <exclude_vars_filter_list>
#                               - list of variables excluded to assign
#
#   --grant_assign_for_variables <grant_assign_for_variables_list>
#                               - list of variables which has ganted unconditional assignment permission without any other conditions.
#
#   --grant_assign_on_variables_change <grant_assign_on_variables_change_list>
#                               - list of variables which grants unconditional assignment permission on variables with different name if
#                                 previous assignment was with a different value to any of these variables.
#                                 Useful for unconditional assignment of variables from different packages or source directories.
#
# <file_paths>:           Sublist of file paths to load from.
#
# CONFIGURATION FILE FORMAT:
#   <variable>[:[<os_name>][:[<compiler_name>][:[<config_name>][:[<arch_name>]]]]]=<value>
#   <variable>[:[<os_name>][:[<compiler_name>][:[<config_name>][:[<arch_name>]]]]]=(<value0> [<value1> [... <valueN>]])
#
# <variable>:             Variable name corresponding to the regex: [_a-zA-Z][_a-zA-Z0-9]*
# <os_name>:              OS variant name: WIN | UNIX | ...
# <compiler_name>:        Compiler variant name with version support: <compiler_token_name>[.<compiler_version>]
#   <compiler_token_name>: MSVC | GCC | CLANG | ...
#   <compiler_version>:   <major_version>[.<minor_version>]
#     <major_version>:    an integral value corresponding to the regex: [0-9]*
#     <minor_version>:    an integral value corresponding to the regex: [0-9]*
# <config_name>:          Configuration name: RELEASE | DEBUG | RELWITHDEBINFO | MINSIZEREL | ...
# <arch_name>:            Architecture variant name: X86 | X64 | ...
#
# <value>:                Value with escaping and substitution support: `$/<escape_char>`, `$/{<variable>}`
#
# PREDEFINED BUILTIN VARIABLES ACCESIBLE FROM BEING PARSED FILE:
#
# CMAKE_CURRENT_LOAD_VARS_FILE_INDEX:     Index in a file paths list from which this file have has an ordered load.
# CMAKE_CURRENT_LOAD_VARS_FILE_DIR:       Directory path from which this file being loaded from.
# CMAKE_CURRENT_PACKAGE_NEST_LVL:         Current package nest level.
# CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX:  Current package nest level prefix string like `00` if level is `0`, or `01` if level is `1` and so on.
# CMAKE_CURRENT_PACKAGE_NAME:             Current package name this file being loaded from.
# CMAKE_CURRENT_PACKAGE_SOURCE_DIR:       Current package source directory this file being loaded from.
# CMAKE_TOP_PACKAGE_NAME:                 Top package name.
# CMAKE_TOP_PACKAGE_SOURCE_DIR:           Top package source directory.
#
macro(set_vars_from_files) # WITH OUT ARGUMENTS!
  if (NOT ${ARGC} GREATER_EQUAL 6)
    message(FATAL_ERROR "set_vars_from_files function must be called at least with 6 not optional arguments: ${ARGC}")
  endif()

  #message("ARGV=${ARGV}")
  set_vars_from_files_impl_init()
  make_argn_var_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}")
  # in case of in a macro call we must pass all ARGV arguments explicitly
  set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #print_ARGV()
  make_argn_var_from_ARGV_ARGN_end()
  unset_ARGV()
  set_vars_from_files_impl_no_args_func()
endmacro()

macro(set_vars_from_files_impl_init) # WITH OUT ARGUMENTS!
  copy_variables(parent_all_vars_list parent_vars_list parent_var_values_list _5A06EEFA_)

  #list(LENGTH parent_vars_list parent_vars_list_len)
  #list(LENGTH parent_var_values_list parent_var_values_list_len)
  #message("[${parent_vars_list_len}] parent_vars_list=${parent_vars_list}")
  #message("[${parent_var_values_list_len}] parent_var_values_list=${parent_var_values_list}")

  # Parent variable are saved, now can create local variables!
  IsCmakeRole(SCRIPT is_in_script_mode)

  if (NOT is_in_script_mode)
    # CMAKE_CONFIGURATION_TYPES consistency check, in case if not script mode
    check_CMAKE_CONFIGURATION_TYPES_vs_multiconfig()
  endif()
endmacro()

macro(set_vars_from_files_impl_with_args) # WITH OUT ARGUMENTS!
  # we must recollect arguments here, because this implementation can be used separately with standalone arguments
  make_argn_var_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}")
  # in case of in a macro call we must pass all ARGV arguments explicitly
  set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #print_ARGV()
  make_argn_var_from_ARGV_ARGN_end()
  unset_ARGV()

  set_vars_from_files_impl_no_args_macro()
endmacro()

function(set_vars_from_files_impl_no_args_func) # WITH OUT ARGUMENTS!
  set_vars_from_files_impl_no_args_macro()
endfunction()

macro(set_vars_from_files_impl_no_args_macro) # WITH OUT ARGUMENTS!
  list(LENGTH argn argn_len)
  set(argn_index 0)

  set(print_vars_set 0)
  set(set_vars 1)
  set(set_env_vars 0) # exclusive set, usual variable set is replaced by environment variable set, all attributes will be ignored
  set(append_to_files 0)
  set(ignore_statement_if_no_filter 0)              # ignore specialized statements if it does not have a configuration name filter
  set(ignore_statement_if_no_filter_config_name 0)  # ignore specialized statements if it does not have a filter specification
  set(ignore_late_expansion_statements 0)           # ignore statements with late expansion feature

  # parameterized flag argument values
  unset(var_lines_file_path)
  unset(var_names_file_path)
  unset(var_values_file_path)
  unset(flock_file_path)
  unset(grant_external_vars_for_assign_list)
  unset(grant_no_check_assign_vars_assigned_in_files_list)
  unset(grant_assign_external_vars_assigning_in_files_list)
  unset(grant_assign_vars_as_top_in_files_list)
  unset(grant_assign_vars_by_override_in_files_list)
  unset(grant_subpackage_assign_ignore_in_files_list)
  unset(grant_assign_for_variables)
  unset(grant_assign_on_variables_change_list)
  unset(include_vars_filter_list)
  unset(exclude_vars_filter_list)
  unset(load_state_from_cmake_global_properties_prefix)
  unset(save_state_into_cmake_global_properties_prefix)
  unset(make_vars_names)
  unset(make_vars_values)

  # parse flags until no flags
  parse_function_optional_flags_into_vars(
    argn_index
    argn
    "p;e;E;a"
    "E\;set_vars"
    "p\;print_vars_set;e\;set_env_vars;E\;set_env_vars;a\;append_to_files"
    "varlines\;.\;var_lines_file_path;vars\;.\;var_names_file_path;values\;.\;var_values_file_path;\
flock\;.\;flock_file_path;ignore_statement_if_no_filter\;ignore_statement_if_no_filter;\
ignore_statement_if_no_filter_config_name\;ignore_statement_if_no_filter_config_name;\
ignore_late_expansion_statements\;ignore_late_expansion_statements;\
grant_external_vars_for_assign\;.\;grant_external_vars_for_assign_list;\
grant_no_check_assign_vars_assigned_in_files\;.\;grant_no_check_assign_vars_assigned_in_files_list;\
grant_assign_external_vars_assigning_in_files\;.\;grant_assign_external_vars_assigning_in_files_list;\
grant_assign_vars_as_top_in_files\;.\;grant_assign_vars_as_top_in_files_list;\
grant_assign_vars_by_override_in_files\;.\;grant_assign_vars_by_override_in_files_list;\
grant_subpackage_assign_ignore_in_files\;.\;grant_subpackage_assign_ignore_in_files_list;\
grant_assign_for_variables\;.\;grant_assign_for_variables_list;\
grant_assign_on_variables_change\;.\;grant_assign_on_variables_change_list;\
include_vars_filter\;.\;include_vars_filter_list;exclude_vars_filter\;.\;exclude_vars_filter_list;\
load_state_from_cmake_global_properties\;.\;load_state_from_cmake_global_properties_prefix;\
save_state_into_cmake_global_properties\;.\;save_state_into_cmake_global_properties_prefix;\
make_vars\;.\;make_vars_names\;make_vars_values"
  )

  if (DEFINED var_lines_file_path)
    get_filename_component(var_lines_file_path_abs "${var_lines_file_path}" ABSOLUTE)
    get_filename_component(var_lines_dir_path "${var_lines_file_path_abs}" DIRECTORY)
    if (NOT IS_DIRECTORY "${var_lines_dir_path}")
      message(FATAL_ERROR "--varlines argument must be path to a file in existed directory: `${var_lines_file_path_abs}`")
    endif()
  endif()
  if (DEFINED var_names_file_path)
    get_filename_component(var_names_file_path_abs "${var_names_file_path}" ABSOLUTE)
    get_filename_component(var_names_dir_path "${var_names_file_path_abs}" DIRECTORY)
    if (NOT IS_DIRECTORY "${var_names_dir_path}")
      message(FATAL_ERROR "--vars argument must be path to a file in existed directory: `${var_names_file_path_abs}`")
    endif()
  endif()
  if (DEFINED var_values_file_path)
    get_filename_component(var_values_file_path_abs "${var_values_file_path}" ABSOLUTE)
    get_filename_component(var_values_dir_path "${var_values_file_path_abs}" DIRECTORY)
    if (NOT IS_DIRECTORY "${var_values_dir_path}")
      message(FATAL_ERROR "--values argument must be path to a file in existed directory: `${var_values_file_path_abs}`")
    endif()
  endif()
  if (DEFINED flock_file_path)
    get_filename_component(flock_file_path_abs "${flock_file_path}" ABSOLUTE)
    get_filename_component(flock_dir_path "${flock_file_path_abs}" DIRECTORY)
    if (NOT IS_DIRECTORY "${flock_dir_path}")
      message(FATAL_ERROR "--flock argument must be path to a file in existed directory: `${flock_file_path_abs}`")
    endif()
  endif()

  # always used set of arguments
  math(EXPR args_max_size "${argn_index}+6")
  if (argn_len LESS args_max_size)
    message(FATAL_ERROR "set_vars_from_files_impl_no_args function must be called with at least ${args_max_size} arguments: argn_len=${argn_len} ARGC=${ARGC} argn_index=${argn_index}")
  endif()

  list(GET argn ${argn_index} file_paths) # discardes ;-escaping
  math(EXPR argn_index "${argn_index}+1")

  ListGet(os_name argn ${argn_index})
  math(EXPR argn_index "${argn_index}+1")

  ListGet(compiler_name argn ${argn_index})
  math(EXPR argn_index "${argn_index}+1")

  ListGet(config_name argn ${argn_index})
  math(EXPR argn_index "${argn_index}+1")

  ListGet(arch_name argn ${argn_index})
  math(EXPR argn_index "${argn_index}+1")

  ListGet(list_separator_char argn ${argn_index})
  math(EXPR argn_index "${argn_index}+1")

  set(use_vars_late_expansion 0)

  if (NOT argn_len EQUAL argn_index)
    # set of trailing optional arguments either not used or used all together
    math(EXPR args_max_size "${argn_index}+4")

    if (argn_len LESS args_max_size)
      message(FATAL_ERROR "set_vars_from_files_impl_no_args function must be called with all at least ${args_max_size} arguments: argn_len=${argn_len} ARGC=${ARGC} argn_index=${argn_index}")
    endif()

    set(use_vars_late_expansion 1)

    ListGet(out_var_config_gen_var_lines_list argn ${argn_index})
    math(EXPR argn_index "${argn_index}+1")

    ListGet(out_var_config_gen_vars_list argn ${argn_index})
    math(EXPR argn_index "${argn_index}+1")

    ListGet(out_var_config_gen_names_list argn ${argn_index})      # single ;-escaped configuration names list per variable, the `*` name means `all others`
    math(EXPR argn_index "${argn_index}+1")

    ListGet(out_var_config_gen_values_list argn ${argn_index})     # double ;-escaped values list per configuration name per variable
    math(EXPR argn_index "${argn_index}+1")
  endif()

  if (NOT config_name STREQUAL "")
    set(is_config_name_value_can_late_expand 0)
  else()
    set(is_config_name_value_can_late_expand 1)
  endif()

  # config_name consistency check
  if(use_vars_late_expansion AND is_config_name_value_can_late_expand)
    if (CMAKE_CONFIGURATION_TYPES STREQUAL "")
      message(FATAL_ERROR "CMAKE_CONFIGURATION_TYPES variable must contain configuration names in case of empty config_name argument to construct complement generator expressions: CMAKE_CONFIGURATION_TYPES=`${CMAKE_CONFIGURATION_TYPES}`")
    endif()
  endif()

  # process some predefined placeholders
  if ((os_name STREQUAL ".") OR (os_name STREQUAL "*"))
    set(os_name "")
  endif()
  if ((compiler_name STREQUAL ".") OR (compiler_name STREQUAL "*"))
    set(compiler_name "")
  endif()
  if ((config_name STREQUAL ".") OR (config_name STREQUAL "*"))
    set(config_name "")
  endif()
  if ((arch_name STREQUAL ".") OR (arch_name STREQUAL "*"))
    set(arch_name "")
  endif()

  # condition properties are case insensitive
  string(TOUPPER "${os_name}" os_name_upper)
  string(TOUPPER "${compiler_name}" compiler_name_upper)
  string(TOUPPER "${compiler_config}" compiler_config_upper)
  string(TOUPPER "${config_name}" config_name_upper)
  string(TOUPPER "${arch_name}" arch_name_upper)

  IsCmakeRole(SCRIPT is_in_script_mode)

  set(compare_var_path_values_as_case_sensitive 1)

  if (os_name STREQUAL "" AND NOT is_in_script_mode)
    if (WIN32 OR WIN64)
      set(os_name_to_filter WIN)
    elseif (UNIX OR LINUX)
      set(os_name_to_filter UNIX)
    elseif (APPLE)
      set(os_name_to_filter APPLE)
    else()
      message(FATAL_ERROR "OS is not supported")
    endif()
  else()
    set(os_name_to_filter "${os_name_upper}")
  endif()

  if (os_name_to_filter STREQUAL "WIN")
    set(compare_var_path_values_as_case_sensitive 0) # treats all Windows file systems as case insensitive
  endif()

  if (list_separator_char STREQUAL "")
    set(list_separator_char ";")  # builtin list separator in the cmake
  endif()

  if (compiler_name STREQUAL "" AND NOT is_in_script_mode)
    if (MSVC)
      get_msvc_version_token(compiler_name_to_filter)
    elseif (GCC)
      get_gcc_version_token(compiler_name_to_filter)
    elseif (CLANG)
      get_clang_version_token(compiler_name_to_filter)
    else()
      message(FATAL_ERROR "compiler is not supported")
    endif()
  else()
    set(compiler_name_to_filter "${compiler_name_upper}")
  endif()

  if (NOT config_name STREQUAL "")
    string(SUBSTRING "${config_name_upper}" 0 1 char)
    if (NOT char MATCHES "[_A-Z]")
      message(FATAL_ERROR "invalid configuration name: `${config_name}`")
    endif()

    if (config_name_upper MATCHES "[^_A-Z0-9]")
      message(FATAL_ERROR "invalid configuration name: `${config_name}`")
    endif()
  endif()

  set(config_name_to_filter "${config_name_upper}")

  if (arch_name STREQUAL "" AND NOT is_in_script_mode)
    if (CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(arch_name_to_filter X64)
    elseif (CMAKE_SIZEOF_VOID_P EQUAL 4)
      set(arch_name_to_filter X86)
    else()
      message(FATAL_ERROR "architecture is not supported")
    endif()
  else()
    set(arch_name_to_filter "${arch_name_upper}")
  endif()

  # list of variables with generator expression values, will be processed at the end
  set(config_gen_var_lines_list "")
  set(config_gen_vars_list "")
  set(config_gen_names_list "")
  set(config_gen_values_list ";") # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!

  # load state
  set(config_load_index -1)
  set(config_package_nest_lvl -1)
  if (DEFINED CMAKE_CURRENT_PACKAGE_NEST_LVL)
    set(config_package_nest_lvl ${CMAKE_CURRENT_PACKAGE_NEST_LVL})
  endif()

  if (load_state_from_cmake_global_properties_prefix)
    get_property(is_config_load_index_set
      GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_load_index SET)
    if (is_config_load_index_set)
      get_property(config_load_index
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_load_index)
    endif()

    get_property(config_var_names GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_var_names)
    #message("loading: vars: ${config_var_names}")

    foreach(config_var_name IN LISTS config_var_names)
      get_property(config_${config_var_name}
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name})

      get_property(config_${config_var_name}_defined
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_defined)

      get_property(config_${config_var_name}_load_index
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_load_index)
      get_property(config_${config_var_name}_package_nest_lvl
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_package_nest_lvl)

      get_property(config_${config_var_name}_file_path_c
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_file_path_c)
      get_property(config_${config_var_name}_file_index
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_file_index)
      get_property(config_${config_var_name}_line
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_line)
      get_property(config_${config_var_name}_os_name
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_os_name)
      get_property(config_${config_var_name}_compiler_name
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_compiler_name)
      get_property(config_${config_var_name}_config_name
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_config_name)
      get_property(config_${config_var_name}_arch_name
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_arch_name)

      get_property(config_${config_var_name}_top_var
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_top_var)

      get_property(config_${config_var_name}_has_values_onchange_list
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_has_values_onchange_list)
      get_property(config_${config_var_name}_var_values_onchange_list
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_var_values_onchange_list)

      #message("config_var_name=${config_var_name} -> `${config_${config_var_name}_file_path_c}`")
    endforeach()
  else()
    set(config_var_names "")
  endif()

  math(EXPR config_load_index "${config_load_index}+1")

  # special injected variables
  set(injected_vars_list
    CMAKE_CURRENT_LOAD_VARS_FILE_INDEX;CMAKE_CURRENT_LOAD_VARS_FILE_DIR
    CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX
    CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR
    CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR)

  foreach (injected_var_name IN LISTS injected_vars_list)
    if (injected_var_name STREQUAL "")
      message(FATAL_ERROR "must be a builtin variable name")
    endif()

    if (NOT DEFINED ${injected_var_name})
      continue()
    endif()

    set(config_${injected_var_name} "${${injected_var_name}}")
    set(config_${injected_var_name}_defined 1)

    set(config_${injected_var_name}_load_index ${config_load_index})
    set(config_${injected_var_name}_package_nest_lvl ${config_package_nest_lvl})

    set(config_${injected_var_name}_file_path_c "") # does not have associated comparable file path
    set(config_${injected_var_name}_file_index -1)  # does not have associated file index
    set(config_${injected_var_name}_line 0)         # does not have associated file line
    set(config_${injected_var_name}_os_name "")
    set(config_${injected_var_name}_compiler_name "")
    set(config_${injected_var_name}_config_name "")
    set(config_${injected_var_name}_arch_name "")

    set(config_${injected_var_name}_top_var 0)

    set(config_${injected_var_name}_has_values_onchange_list 0)
    set(config_${injected_var_name}_var_values_onchange_list "")
  endforeach()

  # make variables explicitly
  set(make_var_name_index -1)
  list(LENGTH make_vars_values make_vars_values_len)

  foreach (make_var_name IN LISTS make_vars_names)
    math(EXPR make_var_name_index "${make_var_name_index}+1")

    if (make_var_name STREQUAL "")
      message(FATAL_ERROR "--make_vars must not use empty variable names")
    endif()

    if (make_var_name_index LESS make_vars_values_len)
      list(GET make_vars_values ${make_var_name_index} make_var_value)
      # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
      string(REGEX REPLACE "\;" "\\\;" make_var_value "${make_var_value}")

      set(config_${make_var_name} "${make_var_value}")
    else()
      # use special unexisted directory value to differentiate it from the defined empty value
      set(config_${make_var_name} "*\$/{${make_var_name}}")
    endif()
    set(config_${make_var_name}_defined 1)

    set(config_${make_var_name}_load_index ${config_load_index})
    set(config_${make_var_name}_package_nest_lvl ${config_package_nest_lvl})

    set(config_${make_var_name}_file_path_c "") # does not have associated comparable file path
    set(config_${make_var_name}_file_index -1)  # does not have associated file index
    set(config_${make_var_name}_line 0)         # does not have associated file line
    set(config_${make_var_name}_os_name "")
    set(config_${make_var_name}_compiler_name "")
    set(config_${make_var_name}_config_name "")
    set(config_${make_var_name}_arch_name "")

    set(config_${make_var_name}_top_var 0)

    set(config_${make_var_name}_has_values_onchange_list 0)
    set(config_${make_var_name}_var_values_onchange_list "")
  endforeach()

  # update all input paths to make them comparable
  foreach (file_path_list_name
    grant_no_check_assign_vars_assigned_in_files_list;grant_assign_external_vars_assigning_in_files_list;
    grant_assign_vars_as_top_in_files_list;grant_assign_vars_by_override_in_files_list;grant_subpackage_assign_ignore_in_files_list)
    set(${file_path_list_name}_c "")

    foreach (file_path IN LISTS ${file_path_list_name})
      get_filename_component(file_path_c "${file_path}" ABSOLUTE)

      if (NOT compare_var_path_values_as_case_sensitive)
        string(TOUPPER "${file_path_c}" file_path_c)
      endif()

      list(APPEND ${file_path_list_name}_c "${file_path_c}")
    endforeach()
  endforeach()

  # create create/truncate output files under flock
  if (DEFINED flock_file_path)
    FileLockFile("${flock_file_path}" FILE)
  endif()
  if (NOT append_to_files)
    if (DEFINED var_lines_file_path)
      file(WRITE "${var_lines_file_path}" "")
    endif()
    if (DEFINED var_names_file_path)
      file(WRITE "${var_names_file_path}" "")
    endif()
    if (DEFINED var_values_file_path)
      file(WRITE "${var_values_file_path}" "")
    endif()
  endif()

  set(file_path_index -1)

  foreach (file_path IN LISTS file_paths)
    math(EXPR file_path_index "${file_path_index}+1")

    # reset special injected variables
    get_filename_component(file_path_abs "${file_path}" ABSOLUTE)
    get_filename_component(file_dir_path "${file_path_abs}" DIRECTORY)

    set(config_CMAKE_CURRENT_LOAD_VARS_FILE_DIR "${file_dir_path}")
    set(config_CMAKE_CURRENT_LOAD_VARS_FILE_INDEX "${file_path_index}")

    if (compare_var_path_values_as_case_sensitive)
      set (file_path_c "${file_path_abs}")
    else()
      string(TOUPPER "${file_path_abs}" file_path_c)
    endif()

    if ((NOT make_vars_names) OR (NOT "CMAKE_CURRENT_PACKAGE_NAME" IN_LIST make_vars_names))
      if (DEFINED CMAKE_CURRENT_PACKAGE_NAME)
        set(config_CMAKE_CURRENT_PACKAGE_NAME "${CMAKE_CURRENT_PACKAGE_NAME}")
      else()
        # use special unexisted directory value to differentiate it from the defined empty value
        set(config_CMAKE_CURRENT_PACKAGE_NAME "*\$/{CMAKE_CURRENT_PACKAGE_NAME}")
      endif()
    endif()
    if ((NOT make_vars_names) OR (NOT "CMAKE_CURRENT_PACKAGE_SOURCE_DIR" IN_LIST make_vars_names))
      if (DEFINED CMAKE_CURRENT_PACKAGE_SOURCE_DIR)
        set(config_CMAKE_CURRENT_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
      else()
        # use special unexisted directory value to differentiate it from the defined empty value
        set(config_CMAKE_CURRENT_PACKAGE_SOURCE_DIR "*\$/{CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
      endif()
    endif()

    # with out any filter here to enable to use of the line number to reference it in a parse error
    file(STRINGS "${file_path_abs}" file_content)

    # CAUTION:
    #   The `file(STRINGS` and some other functions has deep sitting issues which prevents to write reliable and consistent parsers:
    #   https://gitlab.kitware.com/cmake/cmake/issues/19156: `Not paired `]` or `[` characters breaks "file(STRINGS"`
    #   https://gitlab.kitware.com/cmake/cmake/issues/18946: `;-escape list implicit unescaping`
    #   To bypass the first issue we have to replace all `[` and `]` characters by a special sequence to enclose single standing characters
    #   by respective opposite character in a pair.
    #

    # WORKAROUND: we have to replace because `file(STRINGS` does a break on not closed `]` or `[` characters
    string(REGEX REPLACE "\\?" "?0?" file_content "${file_content}")
    string(REGEX REPLACE "\\[" "?1?" file_content "${file_content}")
    string(REGEX REPLACE "\\]" "?2?" file_content "${file_content}")

    set(var_file_content_line 0)

    foreach (var_line IN LISTS file_content)
      math(EXPR var_file_content_line "${var_file_content_line}+1")

      # WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
      string(REGEX REPLACE "\;" "\\\;" var_line "${var_line}")
      string(REGEX REPLACE "\\?0\\?" "?" var_line "${var_line}")
      string(REGEX REPLACE "\\?1\\?" "[" var_line "${var_line}")
      string(REGEX REPLACE "\\?2\\?" "]" var_line "${var_line}")

      if((NOT var_line MATCHES "^[^#\"]+=") OR (NOT var_line MATCHES "([^=]+)=(.*)"))
        continue()
      endif()

      string(STRIP "${CMAKE_MATCH_1}" var_token)
      string(STRIP "${CMAKE_MATCH_2}" var_value)
      string(LENGTH "${var_token}" var_token_len)
      string(LENGTH "${var_value}" var_value_len)

      # parse variable name at first
      if (NOT var_token MATCHES "([^:]+):?([^:]*)?:?([^:]*)?:?([^:]*)?:?([^:]*)?")
        message(WARNING "invalid variable token: [${var_file_content_line}] `${var_token}`")
        continue()
      endif()

      string(STRIP "${CMAKE_MATCH_1}" var_name_token)
      string(STRIP "${CMAKE_MATCH_2}" var_os_name)
      string(STRIP "${CMAKE_MATCH_3}" var_compiler_name)
      string(STRIP "${CMAKE_MATCH_4}" var_config_name)
      string(STRIP "${CMAKE_MATCH_5}" var_arch_name)

      # extract name attributes (leading name tokens) from name token
      string(REGEX REPLACE "[ \t]+" ";" var_name_token_list "${var_name_token}")

      list(LENGTH var_name_token_list var_name_token_list_len)
      math(EXPR var_name_token_list_last_index "${var_name_token_list_len}-1")

      list(GET var_name_token_list ${var_name_token_list_last_index} var_name)

      if (NOT var_name)
        message(FATAL_ERROR "invalid variable token: [${var_file_content_line}] `${var_token}`")
      endif()

      set(var_type "")

      # non exclusive cmake cache set, not cache value does set too
      set(use_cache_var 0)

      # exclusive cmake cache set, a not cache value does remove, all other variable types must not be declared
      set(use_only_cache_var 0)

      # cache with force, has meaning only together with the cache attribute
      set(use_force_cache_var 0)

      # force to set a value without a check on collision or assign validation
      set(use_force_var 0)

      # non exclusive cmake environment variable set, all other variable types does set too
      set(use_env_var 0)

      # exclusive cmake environment variable set, not environment variable does remove, all other variable types must not be declared
      set(use_only_env_var 0)

      # Use top level variable to warn a variable assignment out of top level.
      # If a variable has having the `package` attrubute, then top level to the package granulation (all load files from the first package).
      # If a variable has not having the `package` attrubute, then top level to the load file granulation (first load file).
      set(use_top_attr_var 0) # if actually declared with `top` attribute
      set(use_top_cast_var 0) # if externally casted to a top variable (can have no `top` attribute)

      # use variable overriding to the previous level variable
      set(use_override_attr_var 0)  # if actually declared with `override` attribute
      set(use_override_cast_var 0)  # if externally casted to a override variable (can have no `override` attribute)

      if (var_name_token_list_len GREATER 1)
        list(SUBLIST var_name_token_list 0 ${var_name_token_list_last_index} var_name_attr_list)
        string(TOUPPER "${var_name_attr_list}" var_name_attr_list_upper)

        if (var_name_attr_list)
          list(JOIN var_name_attr_list " " var_set_msg_name_attr_prefix_str)
          set(var_set_msg_name_attr_prefix_str "${var_set_msg_name_attr_prefix_str} ")
        else()
          set(var_set_msg_name_attr_prefix_str "")
        endif()

        # extract variable attributes
        if ("BOOL" IN_LIST var_name_attr_list_upper)
          set(var_type "bool")
        elseif ("PATH" IN_LIST var_name_attr_list_upper)
          set(var_type "path")
        endif()

        if ("CACHE_ONLY" IN_LIST var_name_attr_list_upper)
          set(use_only_cache_var 1)
        elseif ("CACHE" IN_LIST var_name_attr_list_upper)
          set(use_cache_var 1)
        endif()

        if ("FORCE_CACHE" IN_LIST var_name_attr_list_upper)
          set(use_force_cache_var 1)
        endif()

        if ("FORCE" IN_LIST var_name_attr_list_upper)
          set(use_force_var 1)
        endif()

        if ("ENV_ONLY" IN_LIST var_name_attr_list_upper)
          set(use_only_env_var 1)
        elseif ("ENV" IN_LIST var_name_attr_list_upper)
          set(use_env_var 1)
        endif()

        if ("TOP" IN_LIST var_name_attr_list_upper)
          set(use_top_attr_var 1)
        endif()

        if (grant_assign_vars_as_top_in_files_list_c AND file_path_c IN_LIST grant_assign_vars_as_top_in_files_list_c)
          set(use_top_cast_var 1)
        endif()

        if ("OVERRIDE" IN_LIST var_name_attr_list_upper)
          set(use_override_attr_var 1)
        endif()

        if (grant_assign_vars_by_override_in_files_list_c AND file_path_c IN_LIST grant_assign_vars_by_override_in_files_list_c)
          set(use_override_cast_var 1)
        endif()
      else()
        set(var_name_attr_list "")
        set(var_set_msg_name_attr_prefix_str "")
      endif()

      if (use_only_cache_var AND use_only_env_var)
        message(FATAL_ERROR "The variable *_ONLY attribute must be declared only in a single variant: [${var_file_content_line}] `${var_token}`")
      endif()

      if (use_force_cache_var AND NOT use_cache_var AND NOT use_only_cache_var)
        message(FATAL_ERROR "The variable FORCE_CACHE attribute must be declared only together with the cache attribute (CACHE or CACHE_ONLY): [${var_file_content_line}] `${var_token}`")
      endif()

      string(TOUPPER "${var_os_name}" var_os_name_upper)
      string(TOUPPER "${var_compiler_name}" var_compiler_name_upper)
      string(TOUPPER "${var_config_name}" var_config_name_upper)
      string(TOUPPER "${var_arch_name}" var_arch_name_upper)

      # not silent variable name ignore checks...

      # check variable token consistency
      if (var_name STREQUAL "")
        message(WARNING "invalid variable token: [${var_file_content_line}] `${var_token}`")
        continue()
      endif()

      string(SUBSTRING "${var_name}" 0 1 char)
      if (NOT char MATCHES "[_A-Za-z]")
        message(WARNING "invalid variable token: [${var_file_content_line}] `${var_token}`")
        continue()
      endif()

      if (var_name MATCHES "[^_A-Za-z0-9]")
        message(WARNING "invalid variable token: [${var_file_content_line}] `${var_token}`")
        continue()
      endif()

      # silent variable name filter checks...

      # variable names include filter
      if (include_vars_filter_list)
        if (NOT var_name IN_LIST include_vars_filter_list)
          # silent ignore not included variables
          continue()
        endif()
      endif()

      # variable names exclude filter
      if (exclude_vars_filter_list)
        if (var_name IN_LIST exclude_vars_filter_list)
          # silent ignore excluded variables
          continue()
        endif()
      endif()

      # check variable on a collision with builtin variable
      foreach (injected_var_name IN LISTS injected_vars_list)
        if (var_name STREQUAL injected_var_name)
          message(FATAL_ERROR "The variable is a builtin variable which can not be changed: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${var_os_name_upper}:${var_compiler_name_upper}:${var_config_name_upper}:${var_arch_name_upper}] -> [${var_token_suffix_to_process}]")
        endif()
      endforeach()

      # other not silent ignore checks...

      if (var_os_name STREQUAL "")
        set(var_os_name_to_process "${os_name_to_filter}")
      elseif ((var_os_name_upper STREQUAL "WIN") OR
              (var_os_name_upper STREQUAL "UNIX") OR
              (var_os_name_upper STREQUAL "APPLE"))
        set(var_os_name_to_process "${var_os_name_upper}")
      else()
        message("warning: unsupported variable token: [${var_file_content_line}] `${var_token}`")
        continue()
      endif()

      if (var_compiler_name_upper STREQUAL "")
        set(var_compiler_name_to_process "${compiler_name_to_filter}")
      elseif (var_compiler_name_upper MATCHES "([_A-Z]+)([0-9]+)?\\.?([0-9]+)?")
        if ((CMAKE_MATCH_1 STREQUAL "MSVC") OR
            (CMAKE_MATCH_1 STREQUAL "GCC") OR
            (CMAKE_MATCH_1 STREQUAL "CLANG"))
          set(var_compiler_name_to_process "${var_compiler_name_upper}")
        else()
          message(WARNING "unsupported variable token: [${var_file_content_line}] `${var_token}`")
          continue()
        endif()
      else()
        message(WARNING "unsupported variable token: [${var_file_content_line}] `${var_token}`")
        continue()
      endif()

      if (var_config_name STREQUAL "")
        set(var_config_name_to_process "${config_name_to_filter}")
      else()
        string(SUBSTRING "${var_config_name_upper}" 0 1 char)
        if (NOT char MATCHES "[_A-Z]")
          message(WARNING "invalid variable token: [${var_file_content_line}] `${var_token}`")
          continue()
        endif()

        if (var_name MATCHES "[^_A-Z0-9]")
          message(WARNING "invalid variable token: [${var_file_content_line}] `${var_token}`")
          continue()
        endif()

        set(var_config_name_to_process "${var_config_name_upper}")
      endif()

      if (var_arch_name STREQUAL "")
        set(var_arch_name_to_process "${arch_name_to_filter}")
      elseif ((var_arch_name_upper STREQUAL "X86") OR
              (var_arch_name_upper STREQUAL "X64"))
        set(var_arch_name_to_process "${var_arch_name_upper}")
      else()
        message("warning: unsupported variable token: [${var_file_content_line}] `${arch_token}`")
        continue()
      endif()

      # other silent ignore checks...

      # os name filter is always defined even if was empty
      if (NOT var_os_name_to_process STREQUAL "")
        if (NOT os_name_to_filter STREQUAL "")
          if(NOT var_os_name_to_process STREQUAL os_name_to_filter)
            # silently ignore valid tokens that didn't pass the filter
            continue()
          endif()
        elseif (ignore_statement_if_no_filter)
          # silently ignore specialized tokens that does not have a filter specification
          continue()
        endif()
      endif()

      if (NOT var_compiler_name_to_process STREQUAL "")
        if (NOT compiler_name_to_filter STREQUAL "")
          compare_compiler_tokens("${var_compiler_name_to_process}" "${compiler_name_to_filter}" is_equal_config_compilers)
          if (NOT is_equal_config_compilers)
            # silently ignore valid tokens that didn't pass the filter
            continue()
          endif()
        elseif (ignore_statement_if_no_filter)
          # silently ignore specialized tokens that does not have a filter specification
          continue()
        endif()
      endif()

      if (NOT is_config_name_value_can_late_expand)
        if (NOT var_config_name_to_process STREQUAL "")
          if (NOT config_name_to_filter STREQUAL "")
            if (NOT var_config_name_to_process STREQUAL config_name_to_filter)
              # silently ignore valid tokens that didn't pass the filter
              continue()
            endif()
          elseif (ignore_statement_if_no_filter OR ignore_statement_if_no_filter_config_name)
            # silently ignore specialized tokens that does not have a filter specification
            continue()
          endif()
        endif()
      elseif (NOT var_config_name_to_process STREQUAL "" AND ignore_late_expansion_statements)
        # ignore tokens with late expansion
        continue()
      endif()

      if (NOT var_arch_name_to_process STREQUAL "")
        if (NOT arch_name_to_filter STREQUAL "")
          if (NOT var_arch_name_to_process STREQUAL arch_name_to_filter)
            # silently ignore valid tokens that didn't pass the filter
            continue()
          endif()
        elseif (ignore_statement_if_no_filter)
          # silently ignore specialized tokens that does not have a filter specification
          continue()
        endif()
      endif()

      # save current processing variable token
      set(var_token_suffix_to_process "${var_os_name_to_process}:${var_compiler_name_to_process}:${var_config_name_to_process}:${var_arch_name_to_process}")
      set(var_token_suffix "${var_os_name}:${var_compiler_name}:${var_config_name}:${var_arch_name}")

      if (config_${var_name}_defined AND NOT use_override_attr_var)
        # is another package variable?
        if (NOT config_package_nest_lvl EQUAL config_${var_name}_package_nest_lvl)
          # variable is not from top level package, ignore it

          if (config_${var_name}_top_var AND NOT use_top_attr_var)
            # error if a variable is assigned w/o `override` attribute in a not top level configuration but has been declared as a top level variable
            message(FATAL_ERROR "The top level variable is assigned w/o `override` attribute in a not top level configuration: `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
          elseif (NOT config_${var_name}_top_var AND use_top_attr_var)
            # error if a variable is assigned w/o `override` attribute in a not top level configuration but has been declared as a top level variable
            message(FATAL_ERROR "The not top level variable is assigned w/ `top` attribute (and w/o `override` attribute) but has been declared w/o `top` attribute: `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
          endif()

          if (NOT use_override_cast_var)
            if (config_${var_name}_top_var AND use_top_attr_var AND config_package_nest_lvl)
              # a top only variable is not from a top level package, ignore it
              continue()
            endif()

            # assignment implicit ignore through an external condition
            if (grant_subpackage_assign_ignore_in_files_list_c AND file_path_c IN_LIST grant_subpackage_assign_ignore_in_files_list_c)
              continue()
            endif()
          endif()
        endif()
      endif()

      set(is_var_in_ODR_check_list 0)

      # check variable on a collision to prevent the assignment
      set(do_collision_check 1)

      if (grant_assign_for_variables_list)
        foreach(grant_var_name IN LISTS grant_assign_for_variables_list)
          if (grant_var_name STREQUAL var_name)
            set(do_collision_check 0)
            break()
          endif()
        endforeach()
      endif()

      if (do_collision_check AND config_${var_name}_has_values_onchange_list AND
          grant_assign_on_variables_change_list AND NOT var_name IN_LIST grant_assign_on_variables_change_list)
        set(onchange_var_name_index -1)
        list(LENGTH config_${var_name}_var_values_onchange_list onchange_var_values_len)

        foreach(onchange_var_name IN LISTS grant_assign_on_variables_change_list)
          math(EXPR onchange_var_name_index "${onchange_var_name_index}+1")

          if (onchange_var_name_index LESS onchange_var_values_len)
            ListGet(onchange_var_prev_value config_${var_name}_var_values_onchange_list ${onchange_var_name_index})
          else()
            set(onchange_var_prev_value "")
          endif()

          if (DEFINED config_${onchange_var_name})
            set(onchange_var_value "${config_${onchange_var_name}}")
          else()
            set(onchange_var_value "*\$/{${onchange_var_name}}")
          endif()

          #message("${onchange_var_name} => `${onchange_var_prev_value}` -> `${onchange_var_value}`")

          if (NOT onchange_var_value STREQUAL onchange_var_prev_value)
            set(do_collision_check 0) # has changed
            break()
          endif()
        endforeach()
      endif()

      if (do_collision_check)
        if (config_${var_name}_defined)
          #message("[${var_name}:${var_os_name}:${var_compiler_name}:${var_config_name}:${arch_name}] config_${var_name}_config_name=${config_${var_name}_config_name}")

          # A variable is already assigned, but we have to check whether we can allow to specialize a variable, in case if the assignment is not explicitly granted.

          if (grant_no_check_assign_vars_assigned_in_files_list_c AND config_${var_name}_file_path_c IN_LIST grant_no_check_assign_vars_assigned_in_files_list_c)
            set(do_collision_check 0)
          endif()

          if (do_collision_check)
            if (((config_${var_name}_os_name STREQUAL "") OR (NOT var_os_name STREQUAL "" AND config_${var_name}_os_name STREQUAL var_os_name)) AND
                ((config_${var_name}_compiler_name STREQUAL "") OR (NOT var_compiler_name STREQUAL "" AND config_${var_name}_compiler_name STREQUAL var_compiler_name)) AND
                ((config_${var_name}_config_name STREQUAL "") OR (NOT var_config_name STREQUAL "" AND config_${var_name}_config_name STREQUAL var_config_name)) AND
                ((config_${var_name}_arch_name STREQUAL "") OR (NOT var_arch_name STREQUAL "" AND config_${var_name}_arch_name STREQUAL var_arch_name)) AND
                # but in case of specialization something must be set to not empty and not equal with the previous
                ((NOT var_os_name STREQUAL "" AND NOT config_${var_name}_os_name STREQUAL var_os_name) OR
                 (NOT var_compiler_name STREQUAL "" AND NOT config_${var_name}_compiler_name STREQUAL var_compiler_name) OR
                 (NOT var_config_name STREQUAL "" AND NOT config_${var_name}_config_name STREQUAL var_config_name) OR
                 (NOT var_arch_name STREQUAL "" AND NOT config_${var_name}_arch_name STREQUAL var_arch_name)))
              # is specialization, allow to change
            else()
              # is not specialization, deny change
              message(WARNING "The variable is already assigned and can be subsequently changed only through the specialization: `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
              continue()
            endif()
          endif()
        elseif (var_name IN_LIST parent_vars_list)
          if (grant_assign_external_vars_assigning_in_files_list_c AND file_path_c IN_LIST grant_assign_external_vars_assigning_in_files_list_c)
            set (do_collision_check 0)
          elseif (grant_external_vars_for_assign_list AND var_name IN_LIST grant_external_vars_for_assign_list)
            set (do_collision_check 0)
          endif()

          if (do_collision_check)
            # we must check the variable's value on equality with outside value in case if no `force` attribute declared
            if (NOT use_force_var)
              set(is_var_in_ODR_check_list 1)
            endif()
          endif()
        endif()
      endif()

      # state machine value parser
      set(is_invalid_var_line 0)
      set(is_str_quote_open 0)      # "..."
      set(is_list_bracket_open 0)   # bash shell style: (...)
      set(is_list_value 0)
      set(is_next_char_to_escape 0) # `$/<char>`
      set(is_subst_open 0)          # after `$/{`
      set(value_from_index 0)
      set(prev_char "")
      set(prev_char_escaped 0)
      set(last_record_char_index -1) # last record character index after which a record was added to the values's list

      # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
      set(var_values_list ";")        # collect all values as a list by default

      set(var_last_substed_value "")  # last substitued variable's value

      unset(this_file_line)

      if (var_value_len)
        math(EXPR var_value_len_range_max "${var_value_len}-1")

        foreach (index RANGE ${var_value_len_range_max})
          string(SUBSTRING "${var_value}" ${index} 1 char)

          #message(" - [${index}] `${prev_char}`->`${char}`: fi=${value_from_index} lri=${last_record_char_index} `\"`->${is_str_quote_open} `(`->${is_list_bracket_open} `\$/`->${is_next_char_to_escape} `\$/{`->${is_subst_open}")

          if (NOT is_next_char_to_escape)
            # special cases, must be processed separately
            if (NOT is_str_quote_open)
              if (index AND (NOT char STREQUAL " " AND NOT char STREQUAL "\t"))
                math(EXPR last_record_char_offset "${index}-${last_record_char_index}")
                if (NOT prev_char_escaped AND ((last_record_char_offset EQUAL 1) OR (prev_char STREQUAL " " OR prev_char STREQUAL "\t")))
                  # a list item start
                  set(var_last_substed_value "")
                  set(value_from_index ${index})
                endif()
              endif()
            endif()

            if ((char STREQUAL " ") OR (char STREQUAL "\t")) # not quoted separator characters
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                break()
              endif()

              if (NOT is_str_quote_open)
                if (last_record_char_index LESS index AND
                    NOT prev_char STREQUAL " " AND NOT prev_char STREQUAL "\t")
                  math(EXPR last_record_char_offset "${index}-${last_record_char_index}")
                  if (last_record_char_offset GREATER 1)
                    # a list item end, record a value
                    math(EXPR value_len "${index}-${value_from_index}")
                    string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)
                    string(REGEX REPLACE "\;" "\\\;" value "${value}") # WORKAROUND: fix ;-escape implicit unescaping
                    set(var_last_substed_value "${var_last_substed_value}${value}")
                    list(APPEND var_values_list "${var_last_substed_value}")
                    set(last_record_char_index ${index})
                    set(var_last_substed_value "")
                    math(EXPR value_from_index "${index}+1") # next value start index
                  endif()
                endif()
              endif()
            elseif (char STREQUAL "\"")
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                break()
              endif()

              if (NOT is_str_quote_open)
                set(is_str_quote_open 1)
                set(var_last_substed_value "")
              else()
                # record a value
                set(is_str_quote_open 0)
                math(EXPR value_len "${index}-${value_from_index}")
                string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)
                string(REGEX REPLACE "\;" "\\\;" value "${value}") # WORKAROUND: fix ;-escape implicit unescaping
                set(var_last_substed_value "${var_last_substed_value}${value}")
                list(APPEND var_values_list "${var_last_substed_value}")
                set(last_record_char_index ${index})
                set(var_last_substed_value "")
              endif()

              math(EXPR value_from_index "${index}+1") # next value start index
            elseif (char STREQUAL "(")
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                break()
              endif()

              if (NOT is_str_quote_open)
                if (NOT is_list_bracket_open)
                  # must at beginning of value list
                  if (index)
                    set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                    set(is_invalid_var_line 1)
                    break()
                  endif()

                  set(is_list_bracket_open 1)
                  set(is_list_value 1)
                  set(var_last_substed_value "")
                  math(EXPR value_from_index "${index}+1") # next value start index
                else()
                  set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                  set(is_invalid_var_line 1)
                  break()
                endif()
              endif()
            elseif (char STREQUAL "\$")
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                break()
              endif()
            elseif (char STREQUAL "/")
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                break()
              endif()

              if (NOT prev_char_escaped AND prev_char STREQUAL "\$")
                set(is_next_char_to_escape 1)
              endif()
            elseif (char STREQUAL "}")
              if (is_subst_open)
                set(is_subst_open 0)
                # make a substitution
                math(EXPR value_len "${index}-${value_from_index}")
                string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)
                if (DEFINED "config_${value}")
                  set(var_last_substed_value "${var_last_substed_value}${config_${value}}")
                else()
                  # not found, replace by a placeholder
                  set(var_last_substed_value "${var_last_substed_value}*\$/{${value}}")
                endif()

                math(EXPR value_from_index "${index}+1")
              endif()
            elseif (char STREQUAL ")")
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                break()
              endif()

              if (NOT is_str_quote_open)
                if (is_list_bracket_open)
                  set(is_list_bracket_open 0)
                  if (prev_char_escaped OR (NOT prev_char STREQUAL " " AND NOT prev_char STREQUAL "\t"))
                    math(EXPR last_record_char_offset "${index}-${last_record_char_index}")
                    if (last_record_char_offset GREATER 1)
                      set(var_value_len ${index})
                      # record a value
                      set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                      math(EXPR value_len "${index}-${value_from_index}")
                      string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)
                      string(REGEX REPLACE "\;" "\\\;" value "${value}") # WORKAROUND: fix ;-escape implicit unescaping
                      set(var_last_substed_value "${var_last_substed_value}${value}")
                      list(APPEND var_values_list "${var_last_substed_value}")
                      set(last_record_char_index ${index})
                      set(var_last_substed_value "")
                    endif()
                  endif()
                  break()
                else()
                  set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                  set(is_invalid_var_line 1)
                  break()
                endif()
              endif()
            elseif (char STREQUAL "#")  # comment
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                break()
              endif()

              if (NOT is_str_quote_open)
                # end of processing
                if (NOT is_list_bracket_open)
                  # truncate a variable's value length
                  set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                  set(var_value_len ${index})
                else()
                  set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                  set(is_invalid_var_line 1)
                endif()

                break()
              endif()
            endif()

            set(prev_char_escaped 0)
          else()
            set(is_next_char_to_escape 0)

            # insert a value before an escape sequence or a substitution start sequence
            math(EXPR value_len "${index}-${value_from_index}-2")
            if (value_len GREATER_EQUAL 0)
              string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)
              string(REGEX REPLACE "\;" "\\\;" value "${value}") # WORKAROUND: fix ;-escape implicit unescaping
              set(var_last_substed_value "${var_last_substed_value}${value}")
            endif()

            if (NOT char STREQUAL "{")
              # insert escaped character
              if (NOT char STREQUAL ";")
                set(var_last_substed_value "${var_last_substed_value}${char}")
              else()
                set(var_last_substed_value "${var_last_substed_value}\;")
              endif()
            else()
              # start record a substitution sequence
              set(is_subst_open 1)
            endif()

            math(EXPR value_from_index "${index}+1")

            set(prev_char_escaped 1)
          endif()

          set(prev_char "${char}")
        endforeach()
      else()
        set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
        set(is_invalid_var_line 1)
      endif()

      # finalization
      if (NOT is_invalid_var_line)
        # all explicit state flags and values must be already unflagged, closed or processed
        #message("== ${var_value_len} AND NOT ${is_str_quote_open} AND NOT ${is_list_bracket_open} AND NOT ${is_subst_open}")
        if (var_value_len AND NOT is_next_char_to_escape AND NOT is_str_quote_open AND NOT is_list_bracket_open AND NOT is_subst_open)
          # all implicit state flags and values must finalize the processing in here

          if (NOT is_list_value AND NOT var_last_substed_value STREQUAL "")
            # save single value here if not empty
            list(APPEND var_values_list "${var_last_substed_value}")
          endif()

          math(EXPR value_len "${var_value_len}-${value_from_index}")
          if (value_len GREATER 0) # GREATER - just in case
            math(EXPR last_record_char_offset "${value_len}-${last_record_char_index}")
            if (last_record_char_offset GREATER 1)
              string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)
              set(var_last_substed_value "${var_last_substed_value}${value}")
              list(APPEND var_values_list "${var_last_substed_value}")
            endif()
          endif()

          # remove 2 first dummy empty strings
          ListRemoveSublist(var_values_list 0 2 var_values_list)

          ListJoin(var_values_joined_list var_values_list "${list_separator_char}")

          set(set_vars_to_files -1) # unknown or not need to know
          if ((NOT is_config_name_value_can_late_expand) OR (var_config_name STREQUAL ""))
            if (NOT DEFINED var_names_file_path AND NOT DEFINED var_values_file_path)
              set(set_vars_to_files 0)
            else()
              set(set_vars_to_files 1)
            endif()
          endif()

          set(is_bool_var_value 0)
          set(is_path_var_value -1) # unknown or not need to know

          if (is_var_in_ODR_check_list OR ((set_vars_to_files LESS 1) AND set_vars))
            if (var_type STREQUAL "bool")
              set(is_bool_var_value 1)
            elseif (var_type STREQUAL "path")
              set(is_path_var_value 1)
            elseif (NOT compare_var_path_values_as_case_sensitive)
              # detect variable type by variable name variants
              is_path_variable_by_name(is_path_var_value "${var_name}")
            endif()
          endif()

          # set validated variable
          if (is_list_value)
            # set as list
            set(var_parsed_value "${var_values_joined_list}")

            # validate if variable has already existed and is an ODR variable
            if (is_var_in_ODR_check_list)
              list(FIND parent_vars_list "${var_name}" parent_var_index)
              if (parent_var_index GREATER_EQUAL 0) # still can be less
                list(GET parent_var_values_list ${parent_var_index} parent_var_value) # discardes ;-escaping
              else()
                set(parent_var_value "")
              endif()

              if (is_bool_var_value)
                # make values boolean
                if (parent_var_value)
                  set(parent_var_value_boolean 1)
                else()
                  set(parent_var_value_boolean 0)
                endif()
                if (var_parsed_value)
                  set(var_parsed_value_boolean 1)
                else()
                  set(var_parsed_value_boolean 0)
                endif()
              elseif (is_path_var_value GREATER 0)
                # make values upper case
                string(TOUPPER "${parent_var_value}" parent_var_value_upper)
                string(TOUPPER "${var_parsed_value}" var_parsed_value_upper)
              endif()

              if ((is_bool_var_value AND parent_var_value_boolean EQUAL var_parsed_value_boolean) OR
                  (NOT is_bool_var_value AND
                    ((is_path_var_value GREATER 0 AND NOT parent_var_value_upper STREQUAL var_parsed_value_upper) OR
                    (NOT is_path_var_value GREATER 0 AND (NOT parent_var_value STREQUAL var_parsed_value)))))
                message(FATAL_ERROR "ODR violation, variable must define the same value: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${var_os_name_upper}:${var_compiler_name_upper}:${var_config_name_upper}:${var_arch_name_upper}] -> [${var_token_suffix_to_process}]: `(${var_values_joined_list})` != `${parent_var_value}` (is_path=`${is_path_var_value}`)")
                continue()
              endif()
            endif()
          else()
            # validate if variable has already existed and is an ODR variable
            ListGet(var_first_value var_values_list 0)

            set(var_parsed_value "${var_first_value}")

            if (is_var_in_ODR_check_list)
              list(FIND parent_vars_list "${var_name}" parent_var_index)
              if (parent_var_index GREATER_EQUAL 0) # still can be less
                list(GET parent_var_values_list ${parent_var_index} parent_var_value) # discardes ;-escaping
              else()
                set(parent_var_value "")
              endif()

              if (is_bool_var_value)
                # make values boolean
                if (parent_var_value)
                  set(parent_var_value_boolean 1)
                else()
                  set(parent_var_value_boolean 0)
                endif()
                if (var_parsed_value)
                  set(var_parsed_value_boolean 1)
                else()
                  set(var_parsed_value_boolean 0)
                endif()
              elseif (is_path_var_value GREATER 0)
                # make values upper case
                string(TOUPPER "${parent_var_value}" parent_var_value_upper)
                string(TOUPPER "${var_parsed_value}" var_parsed_value_upper)
              endif()

              if ((is_bool_var_value AND NOT parent_var_value_boolean EQUAL var_parsed_value_boolean) OR
                  (NOT is_bool_var_value AND
                    ((is_path_var_value GREATER 0 AND NOT parent_var_value_upper STREQUAL var_parsed_value_upper) OR
                    (NOT is_path_var_value GREATER 0 AND (NOT parent_var_value STREQUAL var_parsed_value)))))
                if (var_first_value STREQUAL var_parsed_value)
                  message(FATAL_ERROR "ODR violation, variable must define the same value: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${var_os_name_upper}:${var_compiler_name_upper}:${var_config_name_upper}:${var_arch_name_upper}] -> [${var_token_suffix_to_process}]: `${var_first_value}` != `${parent_var_value}` (is_path=`${is_path_var_value}`)")
                else()
                  message(FATAL_ERROR "ODR violation, variable must define the same value: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${var_os_name_upper}:${var_compiler_name_upper}:${var_config_name_upper}:${var_arch_name_upper}] -> [${var_token_suffix_to_process}]: `${var_first_value}` (`${var_values_joined_list}`) != `${parent_var_value}` (is_path=`${is_path_var_value}`)")
                endif()
                continue()
              endif()
            endif()
          endif()

          # Variable with not late expansion expression or
          # variable with configuration specialized late expansion (generator) expression (`var_config_name` is empty)
          if ((NOT is_config_name_value_can_late_expand) OR (var_config_name STREQUAL ""))
            if (set_vars_to_files LESS 1)
              if (set_vars)
                # cache always must be set at first
                if (use_only_cache_var OR use_cache_var)
                  if (is_bool_var_value)
                    set(cache_var_type "BOOL")
                  elseif (is_path_var_value GREATER 0)
                    set(cache_var_type "PATH")
                  else()
                    set(cache_var_type "STRING")
                  endif()

                  # use original help string
                  get_property(cache_var_desc CACHE "${var_name}" PROPERTY HELPSTRING)

                  if (use_force_cache_var)
                    # in quotes to enable a save variable's type as a list
                    set(${var_name} "${var_parsed_value}" CACHE ${cache_var_type} "${cache_var_desc}" FORCE)
                  else()
                    # in quotes to enable a save variable's type as a list
                    set(${var_name} "${var_parsed_value}" CACHE ${cache_var_type} "${cache_var_desc}")
                  endif()
                endif()

                if (NOT use_only_cache_var AND NOT use_only_env_var)
                  # in quotes to enable a save variable's type as a list
                  set(${var_name} "${var_parsed_value}" PARENT_SCOPE)
                endif()

                if (use_only_cache_var OR use_only_env_var)
                  unset(${var_name} PARENT_SCOPE)
                endif()

                if (use_only_env_var OR use_env_var)
                  # in quotes to enable a save variable's type as a list
                  set(ENV{${var_name}} "${var_parsed_value}")
                endif()
              elseif (set_env_vars)
                # in quotes to enable a save variable's type as a list
                set(ENV{${var_name}} "${var_parsed_value}")
              endif()
            else()
              if (DEFINED var_lines_file_path)
                file(APPEND "${var_lines_file_path}" "${var_file_content_line}\n")
              endif()
              if (DEFINED var_names_file_path)
                file(APPEND "${var_names_file_path}" "${var_name}\n")
              endif()
              if (DEFINED var_values_file_path)
                # truncate by line return
                if (var_parsed_value MATCHES "([^\r\n]*)")
                  file(APPEND "${var_values_file_path}" "${CMAKE_MATCH_1}\n")
                else()
                  file(APPEND "${var_values_file_path}" "${var_parsed_value}\n")
                endif()
              endif()
            endif()

            # duplicate variable's value here as we can't directly (re)read a parent scope variable which was set from a child scope
            set(config_${var_name} "${var_parsed_value}")

            if (print_vars_set)
              if (var_os_name OR var_compiler_name OR var_config_name OR var_arch_name)
                set(var_token_suffix_note "${var_os_name_upper}:${var_compiler_name_upper}:${var_config_name_upper}:${var_arch_name_upper}")
              else()
                set(var_token_suffix_note "")
              endif()

              if (config_${var_name} STREQUAL var_values_joined_list)
                set(var_set_msg_suffix_str "")
              else()
                set(var_set_msg_suffix_str " (`${var_values_joined_list}`)")
              endif()

              message("[${config_load_index}:${file_path_index}:${var_file_content_line}] [${var_token_suffix_note}] ${var_set_msg_name_attr_prefix_str}${var_name}=`${config_${var_name}}`${var_set_msg_suffix_str}")
            endif()

            # save variable token suffix and other parameter to compare it later
            set(config_${var_name}_load_index "${config_load_index}")
            set(config_${var_name}_package_nest_lvl "${config_package_nest_lvl}")

            set(config_${var_name}_file_path_c "${file_path_c}")
            set(config_${var_name}_file_index "${file_path_index}")
            set(config_${var_name}_line "${var_file_content_line}")
            set(config_${var_name}_os_name "${var_os_name_upper}")
            set(config_${var_name}_compiler_name "${var_compiler_name_upper}")
            set(config_${var_name}_config_name "${var_config_name_upper}")
            set(config_${var_name}_arch_name "${var_arch_name_upper}")

            if (use_top_attr_var OR use_top_cast_var)
              set(config_${var_name}_top_var 1)
            elseif (NOT config_${var_name}_defined)
              set(config_${var_name}_top_var 0)
            endif()

            if (grant_assign_on_variables_change_list AND NOT var_name IN_LIST grant_assign_on_variables_change_list)
              # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
              set(config_${var_name}_var_values_onchange_list ";")
              set(config_${var_name}_has_values_onchange_list 1)

              foreach (onchange_var_name IN LISTS grant_assign_on_variables_change_list)
                if (DEFINED config_${onchange_var_name})
                  list(APPEND config_${var_name}_var_values_onchange_list "${config_${onchange_var_name}}")
                else()
                  # use special unexisted directory value to differentiate it from the defined empty value
                  list(APPEND config_${var_name}_var_values_onchange_list "*\$/{${onchange_var_name}}")
                endif()
              endforeach()

              # remove 2 first dummy empty strings
              ListRemoveSublist(config_${var_name}_var_values_onchange_list 0 2 config_${var_name}_var_values_onchange_list)
            endif()

            set(config_${var_name}_defined 1)

            # append variable to the state list
            if (NOT var_name IN_LIST config_var_names)
              list(APPEND config_var_names "${var_name}")
            endif()
          endif()

          # Variable with potential late expansion expression
          if (use_vars_late_expansion AND is_config_name_value_can_late_expand)
            list(FIND config_gen_vars_list "${var_name}" config_gen_var_index)
            if (config_gen_var_index LESS 0)
              # not found, create
              list(APPEND config_gen_var_lines_list "${var_file_content_line}")
              list(APPEND config_gen_vars_list "${var_name}")
            endif()

            if(NOT DEFINED config_gen_is_defined_forall_${var_name})
              set(config_gen_is_defined_forall_${var_name} 0)
            endif()
            if(NOT DEFINED config_gen_names_for_${var_name})
              set(config_gen_names_for_${var_name} "")
            endif()

            # save variable's value as a generator expression
            if (var_config_name STREQUAL "")
              # special syntax to hold an unescaped value for "all others" configurations
              set(config_gen_forall_${var_name} "${var_parsed_value}")
              set(config_gen_is_defined_forall_${var_name} 1)
            else()
              set(config_gen_for_${var_config_name}_${var_name} "${var_parsed_value}")
              list(FIND config_gen_names_for_${var_name} "${var_config_name}" config_gen_name_index) # just in case
              if (config_gen_name_index LESS 0)
                list(APPEND config_gen_names_for_${var_name} "${var_config_name}")
              endif()
            endif()
          endif()
        else()
          #message("== ${var_value_len} OR ${is_str_quote_open} OR ${is_list_bracket_open} OR ${is_subst_open}")
          set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
          set(is_invalid_var_line 1)
        endif()
      endif()

      if (is_invalid_var_line)
        message(WARNING "invalid variable line: `${file_path_abs}`(${var_file_content_line})(${this_file_line}): `${var_token_suffix_to_process}`: [${var_file_content_line}] `${var_line}`")
        continue()
      endif()
    endforeach()
  endforeach()

  if (DEFINED flock_file_path)
    file(LOCK "${flock_file_path}" RELEASE)
    file(REMOVE "${flock_file_path}")
  endif()

  # save state
  if (save_state_into_cmake_global_properties_prefix)
    set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_load_index
      "${config_load_index}")

    #message("saving: vars: ${config_var_names}")
    set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_var_names "${config_var_names}")

    foreach(config_var_name IN LISTS config_var_names)
      #message("config_var_name=${config_var_name} -> `${config_${config_var_name}_file_path_c}`")

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}
        "${config_${config_var_name}}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_defined
        "${config_${config_var_name}_defined}")

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_load_index
        "${config_${config_var_name}_load_index}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_package_nest_lvl
        "${config_${config_var_name}_package_nest_lvl}")

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_file_path_c
        "${config_${config_var_name}_file_path_c}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_file_index
        "${config_${config_var_name}_file_index}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_line
        "${config_${config_var_name}_line}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_os_name
        "${config_${config_var_name}_os_name}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_compiler_name
        "${config_${config_var_name}_compiler_name}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_config_name
        "${config_${config_var_name}_config_name}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_arch_name
        "${config_${config_var_name}_arch_name}")

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_top_var
        "${config_${config_var_name}_top_var}")

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_has_values_onchange_list
        "${config_${config_var_name}_has_values_onchange_list}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_var_values_onchange_list
        "${config_${config_var_name}_var_values_onchange_list}")
    endforeach()
  endif()

  # copy generator expressions into output list variables with nested ;-escaping
  if (config_gen_vars_list)
    #set(gen_var_index 1) # including 2 empty values in the begginning: -1 + 2
    foreach (gen_var_name IN LISTS config_gen_vars_list)
      set(gen_var_values "")
      set(gen_var_names "")
      set(gen_var_escaped_values "")

      foreach (gen_config_name IN LISTS config_gen_names_for_${gen_var_name})
        #message("${gen_var_name} -> ${gen_config_name} -> ${config_gen_for_${gen_config_name}_${gen_var_name}}")
        string(REGEX REPLACE "\;" "\\\;" gen_var_escaped_value "${config_gen_for_${gen_config_name}_${gen_var_name}}")
        list(APPEND gen_var_escaped_values "${gen_var_escaped_value}")
      endforeach()
      set(gen_var_names "${config_gen_names_for_${gen_var_name}}")

      if (config_gen_is_defined_forall_${gen_var_name})
        list(APPEND gen_var_names "*")
        string(REGEX REPLACE "\;" "\\\;" gen_var_escaped_value "${config_gen_forall_${gen_var_name}}")
        list(APPEND gen_var_escaped_values "${gen_var_escaped_value}")
      endif()

      string(REGEX REPLACE "\;" "\\\;" gen_var_escaped_names "${gen_var_names}")
      string(REGEX REPLACE "\;" "\\\;" gen_var_dbl_escaped_values "${gen_var_escaped_values}")

      list(APPEND config_gen_names_list "${gen_var_escaped_names}")
      list(APPEND config_gen_values_list "${gen_var_dbl_escaped_values}")
    endforeach()

    # remove 2 first dummy empty strings
    ListRemoveSublist(config_gen_values_list 0 2 config_gen_values_list1)
  else()
    # reset to 0 length
    set(config_gen_values_list "")
  endif()

  if (use_vars_late_expansion)
    set(${out_var_config_gen_var_lines_list} "${config_gen_var_lines_list}" PARENT_SCOPE)
    set(${out_var_config_gen_vars_list} "${config_gen_vars_list}" PARENT_SCOPE)
    set(${out_var_config_gen_names_list} "${config_gen_names_list}" PARENT_SCOPE)
    set(${out_var_config_gen_values_list} "${config_gen_values_list}" PARENT_SCOPE)
  endif()
endmacro()

# CAUTION:
#   Function must be without arguments to:
#   1. support optional leading arguments like flags beginning by the `-` character
#
# Usage:
#   [<flags>] <file_path> <os_name> <compiler_name> <config_name> <arch_name> <list_separator_char> \
#     [<out_var_config_gen_var_lines_list> <out_var_config_gen_vars_list> <out_var_config_gen_names_list> <out_var_config_gen_values_list>]
#
# flags:
#   The same as in `set_vars_from_files` function plus these:
#   -F - additionally set full complement variables (if instead of multi variant configuration set has used only the all placeholder - `*`,
#        this means `all configurations` (these kind of variables does not need to be set in this stage because already has been set in previous))
#
function(set_multigen_vars_from_lists) # WITH OUT ARGUMENTS!
  if (NOT ${ARGC} GREATER_EQUAL 4)
    message(FATAL_ERROR "set_vars_from_files function must be called at least with 4 not optional arguments: ${ARGC}")
  endif()

  # CMAKE_CONFIGURATION_TYPES consistency check
  check_CMAKE_CONFIGURATION_TYPES_vs_multiconfig()

  make_argn_var_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}")
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  make_argn_var_from_ARGV_ARGN_end()

  set(argn_index 0)

  set(print_vars_set 0)
  set(set_vars 1)
  set(set_env_vars 0)
  set(set_on_full_complement_config 0)
  set(append_to_files 0)

  unset(var_lines_file_path)
  unset(var_names_file_path)
  unset(var_values_file_path)
  unset(flock_file_path)

  # parse flags until no flags
  parse_function_optional_flags_into_vars(
    argn_index
    argn
    "p;e;E;F;a"
    "E\;set_vars"
    "p\;print_vars_set;e\;set_env_vars;E\;set_env_vars;F\;set_on_full_complement_config;a\;append_to_files"
    "varlines\;.\;var_lines_file_path;vars\;.\;var_names_file_path;values\;.\;var_values_file_path;flock\;.\;flock_file_path;\
ignore_statement_if_no_filter;ignore_statement_if_no_filter_config_name;ignore_late_expansion_statements;\
grant_external_vars_for_assign\;.\;.;\
grant_no_check_assign_vars_assigned_in_files\;.\;.;\
grant_assign_external_vars_assigning_in_files\;.\;.;\
grant_assign_vars_as_top_in_files\;.\;.;\
grant_assign_vars_by_override_in_files\;.\;.;\
grant_subpackage_assign_ignore_in_files\;.\;.;\
grant_assign_for_variables\;.\;.;\
grant_assign_on_variables_change\;.\;.;\
include_vars_filter\;.\;.;\
exclude_vars_filter\;.\;.;\
load_state_from_cmake_global_properties\;.\;.;\
save_state_into_cmake_global_properties\;.\;.;\
make_vars\;.\;.\;."
  )

  if (DEFINED var_lines_file_path)
    get_filename_component(var_lines_file_path_abs "${var_lines_file_path}" ABSOLUTE)
    get_filename_component(var_lines_dir_path "${var_lines_file_path_abs}" DIRECTORY)
    if (NOT IS_DIRECTORY "${var_lines_dir_path}")
      message(FATAL_ERROR "--varlines argument must be path to a file in existed directory: `${var_lines_file_path_abs}`")
    endif()
  endif()
  if (DEFINED var_names_file_path)
    get_filename_component(var_names_file_path_abs "${var_names_file_path}" ABSOLUTE)
    get_filename_component(var_names_dir_path "${var_names_file_path_abs}" DIRECTORY)
    if (NOT IS_DIRECTORY "${var_names_dir_path}")
      message(FATAL_ERROR "--vars argument must be path to a file in existed directory: `${var_names_file_path_abs}`")
    endif()
  endif()
  if (DEFINED var_values_file_path)
    get_filename_component(var_values_file_path_abs "${var_values_file_path}" ABSOLUTE)
    get_filename_component(var_values_dir_path "${var_values_file_path_abs}" DIRECTORY)
    if (NOT IS_DIRECTORY "${var_values_dir_path}")
      message(FATAL_ERROR "--values argument must be path to a file in existed directory: `${var_values_file_path_abs}`")
    endif()
  endif()
  if (DEFINED flock_file_path)
    get_filename_component(flock_file_path_abs "${flock_file_path}" ABSOLUTE)
    get_filename_component(flock_dir_path "${flock_file_path_abs}" DIRECTORY)
    if (NOT IS_DIRECTORY "${flock_dir_path}")
      message(FATAL_ERROR "--flock argument must be path to a file in existed directory: `${flock_file_path_abs}`")
    endif()
  endif()

  ListGet(config_gen_var_lines_list_var argn ${argn_index})
  math(EXPR argn_index "${argn_index}+1")

  ListGet(config_gen_vars_list_var argn ${argn_index})
  math(EXPR argn_index "${argn_index}+1")

  ListGet(config_gen_names_list_var argn ${argn_index})
  math(EXPR argn_index "${argn_index}+1")

  ListGet(config_gen_values_list_var argn ${argn_index})
  math(EXPR argn_index "${argn_index}+1")

  set(config_gen_var_lines_list "${${config_gen_var_lines_list_var}}")
  set(config_gen_vars_list "${${config_gen_vars_list_var}}")
  set(config_gen_names_list "${${config_gen_names_list_var}}")
  set(config_gen_values_list "${${config_gen_values_list_var}}")

  list(LENGTH config_gen_var_lines_list config_gen_var_lines_list_len)
  list(LENGTH config_gen_vars_list config_gen_vars_list_len)
  list(LENGTH config_gen_names_list config_gen_names_list_len)
  list(LENGTH config_gen_values_list config_gen_values_list_len)

  if ((NOT config_gen_var_lines_list_len EQUAL config_gen_vars_list_len) OR
      (NOT config_gen_vars_list_len EQUAL config_gen_names_list_len) OR
      (NOT config_gen_names_list_len EQUAL config_gen_values_list_len))
    message(FATAL_ERROR "all input lists must be the same length")
  endif()

  # create create/truncate output files and append values under flock
  if (DEFINED flock_file_path)
    FileLockFile("${flock_file_path}" FILE)
  endif()
  if (NOT append_to_files)
    if (DEFINED var_lines_file_path)
      file(WRITE "${var_lines_file_path}" "")
    endif()
    if (DEFINED var_names_file_path)
      file(WRITE "${var_names_file_path}" "")
    endif()
    if (DEFINED var_values_file_path)
      file(WRITE "${var_values_file_path}" "")
    endif()
  endif()

  set(var_index -1)

  foreach(var_name IN LISTS config_gen_vars_list)
    math(EXPR var_index "${var_index}+1")

    list(GET config_gen_var_lines_list ${var_index} var_line)
    list(GET config_gen_names_list ${var_index} var_config_names)
    list(GET config_gen_values_list ${var_index} var_values) # discardes ;-escaping

    set(var_multigen_value "")

    set(var_complement_config_names "${CMAKE_CONFIGURATION_TYPES}")
    string(TOUPPER "${var_complement_config_names}" var_complement_config_names)

    set(var_complement_value "")
    set(has_complement_config_names 0)
    set(has_target_config_names 0)

    set(var_config_name_index -1)

    foreach(var_config_name IN LISTS var_config_names)
      math(EXPR var_config_name_index "${var_config_name_index}+1")

      list(GET var_values ${var_config_name_index} var_value) # discardes ;-escaping

      if (NOT var_config_name STREQUAL "*")
        string(REGEX REPLACE "([;\\$\"])" "\\\\\\1" var_escaped_value "${var_value}")

        #message("[${var_config_name}] `${var_value}` -> `${var_escaped_value}`")

        if (var_config_name_index)
          set(var_multigen_value "${var_multigen_value}\$<\$<CONFIG:${var_config_name}>:\"${var_escaped_value}\">")
        else()
          set(var_multigen_value "\$<\$<CONFIG:${var_config_name}>:\"${var_escaped_value}\">")
        endif()

        list(REMOVE_ITEM var_complement_config_names "${var_config_name}")
        set(has_target_config_names 1)
      else()
        # use CMAKE_CONFIGURATION_TYPES to insert complement configurations
        set(var_complement_value "${var_value}")
        set(has_complement_config_names 1)
      endif()
    endforeach()

    if (NOT has_target_config_names)
      if (NOT set_on_full_complement_config)
        # must be already set in `set_multigen_vars_from_file` function, just ignore
        continue()
      endif()

      # all configurations are complement
      set(var_multigen_value "${var_value}")
    elseif (has_complement_config_names)
      # process complement configurations
      set(var_config_name_index -1)

      foreach(var_config_name IN LISTS var_complement_config_names)
        math(EXPR var_config_name_index "${var_config_name_index}+1")

        string(REGEX REPLACE "([;\\$\"])" "\\\\\\1" var_escaped_value "${var_complement_value}")

        if (has_target_config_names OR var_config_name_index)
          set(var_multigen_value "${var_multigen_value}\$<\$<CONFIG:${var_config_name}>:\"${var_escaped_value}\">")
        else()
          set(var_multigen_value "\$<\$<CONFIG:${var_config_name}>:\"${var_escaped_value}\">")
        endif()
      endforeach()
    endif()

    if (print_vars_set)
      message("[${var_line}] ${var_name}=`${var_multigen_value}`")
    endif()

    if (NOT DEFINED var_names_file_path AND NOT DEFINED var_values_file_path)
      if (set_vars)
        set(${var_name} "${var_multigen_value}" PARENT_SCOPE)
      endif()
      if (set_env_vars)
        set(ENV{${var_name}} "${var_multigen_value}")
      endif()
    else()
      if (DEFINED var_lines_file_path)
        file(APPEND "${var_lines_file_path}" "${var_line}\n")
      endif()
      if (DEFINED var_names_file_path)
        file(APPEND "${var_names_file_path}" "${var_name}\n")
      endif()
      if (DEFINED var_values_file_path)
        # truncate by line return
        if (var_multigen_value MATCHES "([^\r\n]*)")
          file(APPEND "${var_values_file_path}" "${CMAKE_MATCH_1}\n")
        else()
          file(APPEND "${var_values_file_path}" "${var_multigen_value}\n")
        endif()
      endif()
    endif()
  endforeach()

  if (DEFINED flock_file_path)
    file(LOCK "${flock_file_path}" RELEASE)
    file(REMOVE "${flock_file_path}")
  endif()
endfunction()
