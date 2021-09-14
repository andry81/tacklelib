# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_SET_VARS_FROM_FILES_INCLUDE_DEFINED)
set(TACKLELIB_SET_VARS_FROM_FILES_INCLUDE_DEFINED 1)

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

include(tacklelib/Std)
include(tacklelib/Checks)
include(tacklelib/ForwardVariables)
include(tacklelib/ForwardArgs)
include(tacklelib/Eval)
include(tacklelib/Version)
include(tacklelib/String)
include(tacklelib/Utility)

# THE DEFAULT ASSIGNMENT RULES LIST WHICH ARE USED EACH TIME WHEN A VARIABLE BEING DECLARED (can be ignored by the `force` attribute):
#
# 1. A variables which being set a first time in the load or set function should not exist before.
#    Otherwise a variable must be declared with the same value as been before. If not then an error would be thrown.
#    The meaning is that a variable value type declared before is not quite known and is not constant nor mutable,
#    so any value change is an error because the availability to change is dependent to a first time declared variable.
#    For example:
#       The `PROJECT_NAME` variable can be created by the cmake `project(...)` command are immutable and must not change.
#       So a variable declaration in that case can only be allowed for the same value and so the parser can allow to assign the same value
#       (actually ignore the assignment) and all other values would be an error.
# 2. If a variable being set not a first time in the load or set function, then the assignment attempt should be applied to a specialized
#    form of a variable, otherwise the parser would throw an error and ignore a variable assignment.
#    The meaning is that all variables in the sequence of assignments must be unique because all being assigned variables are the declarations
#    and so must be constant. But because a variable reassignment is useful in the case of testing, then only a warning are issued.
#

# A BRIEF EXAMPLES OF RULES FOR VARIABLES TO LOAD OR TO SET:
#
# 1. All variables being loaded from the load or set function is treated as a constant variable declaration assignment,
#    which means the parser must throw an a warning and ignore a variable assignment if a variable
#    has been already declared AND has having exact specialization match with the previous applied assignment of the same
#    variable if has any.
#    Example:
#       AAA=10
#       AAA=20 # <- specialization matched, constant redeclaration attempt, assignment would be ignored with a warning
# 2. All less or equal specialization match variable assignments by default are ignored with a warning about as a change of constant variable.
#    To redeclare a variable w/o any checks (including warning suppression) do declare it with the `force` attribute.
#    Example:
#       # CMAKE_CURRENT_PACKAGE_NEST_LVL=0
#       AAA=10
#       # CMAKE_CURRENT_PACKAGE_NEST_LVL=1
#       force AAA=20 # <- declaration enforcement, assignment would be applied irrespectively to assignment rules
#       # CMAKE_CURRENT_PACKAGE_NEST_LVL=2
#       AAA=30          # <- specialization matched, constant redeclaration attempt, assignment would be ignored with a warning
# 3. A complete or greater or equal specialization match variable is a variable which template parameters after the colon character
#    (:<os_name>:<compiler_name>:<config_name>:<arch_name>) are matched completely or greater or equal to the function input parameters or previously assigned variable parameters.
#    Example #1:
#       # input: os_name=WIN compiler_name=MSVC config_name=RELEASE arch_name=*
#       AAA::MSVC:RELEASE:X86=10    # <- assignment would be allowed if all parameters would have greater or equal specialization match to the function input
#                                   # DESCRIPTION:
#                                   #   os_name - any input if not specialized before or equal (not less)
#                                   #   compiler_name - equal, config_name - equal, arch_name - specialized or greater
#    Example #2:
#       AAA:WIN::RELEASE=10
#       AAA:WIN:GCC:RELEASE=20      # <- assignment would be allowed if all parameters would have greater or equal specialization match from previous variable assignment
#                                   # DESCRIPTION:
#                                   #   os_name - equal, compiler_name - specialized or greater
#                                   #   config_name - any input if not specialized before or equal, arch_name - any input if not specialized before or equal
# 4. A partial or less specialization match variable is a variable which template parameters after the colon character
#    (:<os_name>:<compiler_name>:<config_name>:<arch_name>) are matched partially or lesser to the function input parameters or previously assigned variable parameters.
#    Example #1:
#       # input: os_name=UNIX compiler_name=GCC config_name=* arch_name=*
#       AAA:WIN:MSVC=20             # <- assignment would be allowed if all parameters would have greater or equal specialization match from previous variable assignment
#                                   # DESCRIPTION:
#                                   #   os_name - not equal, compiler_name - not equal
#                                   #   config_name - any input if not specialized before or equal, arch_name - any input if not specialized before or equal
#    Example #2:
#       AAA:WIN::RELEASE=10
#       AAA::GCC:RELEASE=20         # <- assignment would be allowed if all parameters would have greater or equal specialization match from previous variable assignment
#                                   # DESCRIPTION:
#                                   #   os_name - any input if not specialized before or less (because specialized), compiler_name - specialized or greater
#                                   #   config_name - equal, arch_name - any input if not specialized before or equal
# 5. A variable w/o explicitly declared template parameters is not applicable for a specialization match but
#    treated as always matched to any input respective parameters of the load or set function.
# 6. If before the load or set function a variable already has been set, then a
#    very first variable being assigned in the load or set function must has the same value,
#    otherwise the variable is treated as not connected to the variable has existed before
#    the call and an error would be thrown.
# 7. A complete or more specialized variable has assignment priority over a partially or less specialized variable which
#    in turn has greater priority over a lesser specialized variable.
#    Example:
#       # input: os_name=UNIX compiler_name=GCC config_name=* arch_name=*
#       AAA=10                  # no specialization but matched, assignment would be applied if variable either was not set before the call or was set externally to the same value
#       AAA:UNIX=20             # more specialized match over previously applied assignment, assignment would be applied
#       AAA:UNIX:GCC=30         # more specialized match over previously applied assignment, assignment would be applied
#       AAA=40                  # no specialization but matched, less priority match versus previously applied assignment, assignment would be treated as a constant variable change and ignored with a warning
#       AAA::GCC=50             # still less priority match versus previously applied assignment, assignment would be ignored with a warning
#       AAA:UNIX:GCC=60         # equal priority match versus previously applied assignment, assignment would be treated as a constant variable change and ignored with a warning
#       AAA:UNIX:GCC:RELEASE=70 # more specialized match over previously applied assignment, assignment would be applied
#
# All other cases is not represented above can be overrided by the command line options/parameters/flags of the load or set functions.
#

# VARIABLE CLASS ATTRIBUTES:
#
# <none>:
#   Default assignment rules described above.
#
# `global`:
#   Special variable class which value must stay the same between all packages, otherwise an error will be thrown.
#   If a variable has been assigned at least in one package with the `global` attribute, then the same variable
#   must be assigned with the `global` attribute in all packages referenced from or to that package, otherwise an error will be thrown.
#   Basically used for global 3dparty variables referenced from different packages with the same value.
#   Can be declared only once per a package, can be specialized by a new assignment, but can not be reassigned by the same specialization,
#   otherwise an error (instead of a warning) will be thrown.
#
# `top`:
#   A top level package variable in a global scope if `package` attribute is not set or in a package scope if set.
#   If a variable has been assigned at least in one package with the `top` attribute, then the same variable
#   must be assigned with the `top` attribute in all packages referenced from or to that package, otherwise an error will be thrown.
#   Only a top level package would allow assignment of a top level package variable using the rules and then
#   all not top level packages would silently ignore the assignment of the same variable.
#   All assignments after the first assignment with the `top` attribute must use additionally the `override` attribute to declare intention to
#   override an assignment of a top level package variable in any package, otherwise an error will be thrown.
#
# `local`:
#   Defines a local context variable, which can override a global variable.
#   If a variable has been assigned at least in one package with the `local` attribute, then the same variable
#   must be assigned with the `local` attribute in all packages referenced from or to that package, otherwise an error will be thrown.
#   A global variable with the same name may not exist before the assignment.
#
# All 3 classes excludes each other and must not be mixed.
#

# VARIABLE TYPE ATTRIBUTES:
#
# <none>:
#   A case sensitive string variable.
#
# `bool`:
#   A variable declared and interpreted as a boolean type.
#   Possible values: 1, 0, ON, OFF, YES, NO, TRUE, FALSE
#
# `path`:
#   A variable declared and interpreted as a string with case sensitivity dependent on the file system.
#   Linux - case sensitive, Window - case insensitive.
#

# VARIABLE STORAGE ATTRIBUTES:
#
# <none>:
#   Store a variable as is in a first class storage (not in the cache or environment).
#
# `cache_only`:
#   Store a variable only in the cache (second class storage).
#
# `cache`:
#   Store a variable additionally in the cache.
#
# `env_only`:
#   Store a variable only in the environment (third class storage).
#
# `env`:
#   Store a variable additionally in the environment.
#

# VARIABLE MODIFICATOR ATTRIBUTES:
#
# `force_cache`:
#   Applicable only to the cache storage variables. Declares a forced cache variable with the inner `FORCE` attribute in a cmake `set` command.
#   Must be used with an assignment.
#
# `force`:
#   Forces a variable assignment where it can be assigned w/o an error (described above).
#   Must be used with an assignment.
#
# `override`:
#   Overrides an assignment in not top level packages.
#   Must be used ONLY to override an assignment of a top level package variable in a not top level package.
#   Must be used with an assignment.
#
# `unset`:
#   Removes a variable not losing the state versus other attributes.
#   Can be used with other required attributes.
#   Can be set later under the same attributes if was not finalized for the same context in the previous instruction with the variable.
#   Must be used without an assignment.
#
# `hide`:
#   Hides a variable not losing the state versus other attributes.
#   Can be used with other required attributes.
#   Can be set later with a value, but a value is not visible until unhided back if was not finalized for the same context in the previous instruction with the variable.
#   Must be used without an assignment.
#   Can be applied respectively per variable storage (first class/cache/environment).
#
# `unhide`:
#   Unhides a variable.
#   Can be used with other required attributes.
#   Can be hided later under the same attributes if was not finalized for the same context in the previous instruction with the variable.
#   Must be used without an assignment.
#   Can be applied respectively per variable storage (first class/cache/environment).
#
# `package`:
#   Applicable only to variables with the `final` or the `hide` attribute. Declares a finalized or a hided variable in a package scope.
#
# `final`:
#   A variable with sealed or finalized assignment or instruction.
#   Must be always final, otherwise an error will be thrown.
#   Without the `package` attribute applies to a last assignment or instruction irrespective to the package.
#   With the `package` attribute applies only to the current package, in a next level package can be reassigned, issued with unset/hided/unhided or finilized again.
#
# `exist`:
#   An existed path value.
#   Must be declared together with the `path` attribute.
#   Must be used with an assignment.
#
# `canonical`:
#   A canonical path value.
#   Must be declared together with the `path` attribute.
#   Must be used with an assignment.
#

# CURRENT STATE: BETA, not all attributes are implemented properly, TODO: TESTS!

# Incompatible attribute compositions:
#   * global + override
#   * global + top
#   * global + local
#   * global + package
#   * force + override
#   * force + top (limitly applicable)
#   * force + package (if have no `final` attribute)
#   * unset/hide/unhide + <other modificator except `top`, `final`, `package`>
#   * unset/hide/unhide + <any type attribute>
#   * unset/hide/unhide + <specialization>
#   * unset/hide/unhide + global
#   * top + local
#
# Available attribute compositions:
#   * top + override
#   * top + unset/hide/unhide
#   * global + unset/hide/unhide
#   * local + unset/hide/unhide
#   * final + <any except top/global>

# Package entity description:
#   Package is a virtual entity created by these set of cmake functions
#   maintained by hooks:
#   * `find_package`
#   * `add_subdirectory` followed by call to the `project` function.
#      Set of calls to the nested `add_subdirectory` functions under the same
#      `project` does not create a new package!

# ASSIGNMENT RULES FOR ATTRIBUTES BETWEEN CLOSEST ASSIGNMENTS OF THE SAME VARIABLE IN THE SAME PACKAGE
#
# Legend:
#   OK          - conditionally applicable respective to the rules: warning on specialization less or equal match
#   OK,uncond   - unconditionally applicable irrespective to rules
#   OK,cond1    - conditionally applicable in case if a variable was not defined before (useful to bypass ODR violation)
#   warning     - ignores with warning
#   <empty>     - not applicable or not defined, must throw an error
#
# '. ASSIGN N+1        |             |             |             |             |             |             |             |             
#   '--------------,   |             |             |             |             |             |  force      |  force      |  force      
# ASSIGN N          '. |  <not set>  |  top        |  global     |  local      |  force      |  top        |  global     |  local      
# ---------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------
# <not set>            |  warning    |             |             |             |  OK,uncond  |             |             |             
# global               |             |             |  warning    |  OK         |             |             |  OK,uncond  |  OK,uncond  
# top                  |             |  warning    |             |             |             |  OK*cond1   |             |             
# local                |             |             |             |             |             |             |             |  OK,uncond  
#
# '. ASSIGN N+1        |             |             |             |             |             |             |             |             
#   '--------------,   |             |  override   |  override   |  override   |             |  final      |  final      |  final      
# ASSIGN N          '. |  override   |  top        |  global     |  local      |  final      |  top        |  global     |  local      
# ---------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------
# <not set>            |             |             |             |             |  OK         |             |             |             
# global               |             |             |             |             |             |             |             |             
# top                  |             |             |             |             |             |             |             |             
# local                |             |             |             |             |             |             |             |  OK         
#
# '. ASSIGN N+1        |             |             |             |             |             |             |             |             
#   '--------------,   |             |             |  force      |  force      |  override   |  override   |  final      |  final      
# ASSIGN N          '. |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   
# ---------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------
# <not set>            |  warning    |  OK         |  OK,uncond  |  OK,uncond  |             |             |  warning    |  OK         
# global               |             |             |             |             |             |             |             |             
# top                  |             |             |             |             |             |             |             |             
# local                |             |             |             |             |             |             |             |             
#
# '. ASSIGN N+1        |             |             |  force      |  force      |  override   |  override   |  final      |  final      
#   '--------------,   |  global     |  global     |  global     |  global     |  global     |  global     |  global     |  global     
# ASSIGN N          '. |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   
# ---------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------
# <not set>            |             |             |             |             |             |             |             |             
# global               |  warning    |  OK         |  OK,uncond  |  OK,uncond  |             |             |             |             
# top                  |             |             |             |             |             |             |             |             
# local                |             |             |             |             |             |             |             |             
#
# '. ASSIGN N+1        |             |             |  force      |  force      |  override   |  override   |  final      |  final      
#   '--------------,   |  top        |  top        |  top        |  top        |  top        |  top        |  top        |  top        
# ASSIGN N          '. |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   
# ---------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------
# <not set>            |             |             |             |             |             |             |             |             
# global               |             |             |             |             |             |             |             |             
# top                  |  warning    |  OK         |  OK,uncond  |  OK,uncond  |             |             |  warning    |  OK         
# local                |             |             |             |             |             |             |             |             
#

# ASSIGNMENT RULES FOR ATTRIBUTES BETWEEN CLOSEST ASSIGNMENTS OF THE SAME VARIABLE AT DIFFERENT PACKAGE LEVELS
#
# Legend:
#   OK          - conditionally applicable respective to the rules: warning on specialization less or equal match
#   OK,uncond   - unconditionally applicable irrespective to rules
#   OK,cond1    - conditionally applicable in case if a variable was not defined before (useful to bypass ODR violation)
#   OK,equal    - value must stay the same
#   warning     - ignores with warning
#   ignore      - ignores w/o warning (silent ignore)
#   <empty>     - not applicable or not defined, must throw an error
#
# '. LEVEL N+K         |             |             |             |             |             |             |             |             
#   '--------------,   |             |             |             |             |             |  force      |  force      |  force      
# LEVEL N           '. |  <not set>  |  top        |  global     |  local      |  force      |  top        |  global     |  local      
# ---------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------
# <not set>            |  OK         |             |             |             |  OK,uncond  |             |             |             
# global               |             |             |  OK,equal   |             |             |             |  OK,uncond  |             
# top                  |             |  ignore     |             |             |             |  OK*cond1   |             |             
# local                |             |             |             |  OK         |             |             |             |  OK,uncond  
#
# '. LEVEL N+K         |             |             |             |             |             |             |             |             
#   '--------------,   |             |  override   |  override   |  override   |             |  final      |  final      |  final      
# LEVEL N           '. |  override   |  top        |  global     |  local      |  final      |  top        |  global     |  local      
# ---------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------
# <not set>            |             |             |             |             |  OK         |             |             |             
# global               |             |             |             |             |             |             |             |             
# top                  |             |  OK,uncond  |             |             |             |             |             |             
# local                |             |             |             |             |             |             |             |  OK         
#
# '. LEVEL N+K         |             |             |             |             |             |             |             |             
#   '--------------,   |             |             |  force      |  force      |  override   |  override   |  final      |  final      
# LEVEL N           '. |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   
# ---------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------
# <not set>            |  OK         |  OK         |  OK,uncond  |  OK,uncond  |             |             |  OK         |  OK         
# global               |             |             |             |             |             |             |             |             
# top                  |             |             |             |             |             |             |             |             
# local                |             |             |             |             |             |             |             |             
#
# '. LEVEL N+K         |             |             |  force      |  force      |  override   |  override   |  final      |  final      
#   '--------------,   |  global     |  global     |  global     |  global     |  global     |  global     |  global     |  global     
# LEVEL N           '. |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   
# ---------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------
# <not set>            |             |             |             |             |             |             |             |             
# global               |  OK,equal   |  OK         |  OK,uncond  |  OK,uncond  |             |             |  OK         |  OK         
# top                  |             |             |             |             |             |             |             |             
# local                |             |             |             |             |             |             |             |             
#
# '. LEVEL N+K         |             |             |  force      |  force      |  override   |  override   |  final      |  final      
#   '--------------,   |  top        |  top        |  top        |  top        |  top        |  top        |  top        |  top        
# LEVEL N           '. |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   |  unset      |  (un)hide   
# ---------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------
# <not set>            |             |             |             |             |             |             |             |             
# global               |             |             |             |             |             |             |             |             
# top                  |  OK         |  OK         |  OK,uncond  |  OK,uncond  |  OK         |  OK         |  OK         |  OK         
# local                |             |             |             |             |             |             |             |             
#

# CAUTION:
#   Function must be without arguments to avoid argument variable intersection with the parent scope!
#
# Usage:
#   [<flags>] "<file_path0>[...\;<file_pathN>]"
#
# flags:
#   The same as in `tkl_set_vars_from_files` function.
#
macro(tkl_load_vars_from_files) # WITH OUT ARGUMENTS!
  if (${ARGC} GREATER 32)
    message(FATAL_ERROR "maximum 32 arguments is supported")
  endif()

  tkl_load_vars_from_files_impl_init()
  tkl_make_var_from_ARGV_begin("${ARGN}" _50FABB52_argn)
  # in case of in a macro call we must pass all ARGV arguments explicitly
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGVn()
  tkl_make_var_from_ARGV_end(_50FABB52_argn)
  tkl_pop_ARGVn_from_stack()
  tkl_load_vars_from_files_impl()

  unset(_50FABB52_argn)

  tkl_load_vars_from_files_impl_uninit()
endmacro()

macro(tkl_load_vars_from_files_impl_init)
  tkl_set_vars_from_files_impl_init()
endmacro()

macro(tkl_load_vars_from_files_impl_uninit)
  tkl_set_vars_from_files_impl_uninit()
endmacro()

function(tkl_load_vars_from_files_impl) # WITH OUT ARGUMENTS!
  list(LENGTH _50FABB52_argn argn_len)
  set(argn_index 0)

  set(flag_args "")

  set(silent_mode 0)
  set(load_state_from_cmake_global_properties 0)
  set(save_state_into_cmake_global_properties 0)

  # copy all flag parameters into a variable without parsing them
  tkl_parse_function_optional_flags_into_vars_impl(
    argn_index
    _50FABB52_argn
    "p;e;E;a;S;s"
    ""
    "s\;silent_mode"
    "\
varlines\;.\;.;\
vars\;.\;.;\
values\;.\;.;\
flock\;.\;.;\
ignore_statement_if_no_filter;\
ignore_statement_if_no_filter_config_name;\
ignore_late_expansion_statements;\
grant_external_vars_for_assign\;.\;.;\
grant_external_vars_assign_in_files\;.\;.;\
grant_assign_for_vars\;.\;.;\
grant_assign_on_vars_change\;.\;.;\
include_vars_filter\;.\;.;\
exclude_vars_filter\;.\;.;\
load_state_from_cmake_global_properties\;load_state_from_cmake_global_properties\;.;\
save_state_into_cmake_global_properties\;save_state_into_cmake_global_properties\;.;\
make_vars\;.\;.\;."
    flag_args
  )

  if (NOT argn_index LESS argn_len)
    message(FATAL_ERROR "function function must be called at least with 1 variadic argument: argn_len=`${argn_len}` argn_index=`${argn_index}`")
  endif()

  # Parent variable are saved, now can create local variables!
  if (script_mode)
    set(is_in_script_mode 1)
  else()
    tkl_get_cmake_role(is_in_script_mode SCRIPT)
  endif()

  if (NOT is_in_script_mode)
    # CMAKE_BUILD_TYPE consistency check, in case if not script mode
    tkl_check_CMAKE_BUILD_TYPE_vs_multiconfig()
  endif()

  list(GET _50FABB52_argn ${argn_index} file_paths) # discardes ;-escaping
  math(EXPR argn_index ${argn_index}+1)

  if ("${file_paths}" STREQUAL "")
    message(FATAL_ERROR "file_paths argument is not defined")
  endif()

  if (NOT silent_mode)
    if (NOT load_state_from_cmake_global_properties OR save_state_into_cmake_global_properties)
      message("* Loading variables from `${file_paths}`...")
    else()
      message("* Preloading variables from `${file_paths}`...")
    endif()
  endif()

  if (NOT CMAKE_BUILD_TYPE)
    list(APPEND flag_args "--ignore_statement_if_no_filter_config_name")
  endif()
  list(APPEND flag_vars "--ignore_late_expansion_statements")

  tkl_escape_list_expansion_as_cmdline(flag_args_cmdline "${flag_args}")

  # Note:
  #   Make fast evaluation here
  #

  tkl_macro_fast_eval("tkl_set_vars_from_files_impl_with_args(${flag_args_cmdline} \"${file_paths}\" \"\" \"\" \"${CMAKE_BUILD_TYPE}\" \"\" \"\")")
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
#     out_var_config_gen_var_lines_list - list of text line numbers from the source, where a variable has been declared
#     out_var_config_gen_vars_list      - list of variable names
#     out_var_config_gen_names_list     - list of variable configuration names (RELEASE/DEBUG/...)
#     out_var_config_gen_values_list    - list of variable values
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
#   -S                          - script mode
#   -s                          - silent mode
#
#   --grant_external_vars_for_assign <grant_external_vars_for_assign_list>
#                               - list of variables granted for unconditional assignment for case if has been assigned before the first load call
#                                 (by default would be an error if a variable has been assigned before the load call and a new value is not equal to the previous)
#
#   --grant_external_vars_assign_in_files <grant_external_vars_assign_in_files_list>
#                               - list of files with variables granted for unconditional assignment if a variable has been assigned before the first load call
#                                 (by default would be an error if a variable has been assigned before the load call and a new value is not equal to the previous)
#
#   --include_vars_filter <include_vars_filter_list>
#                               - list of variables included to assign
#
#   --exclude_vars_filter <exclude_vars_filter_list>
#                               - list of variables excluded to assign
#
#   --grant_assign_for_vars <grant_assign_for_vars_list>
#                               - list of variables which has ganted unconditional assignment permission without any other conditions.
#
#   --grant_assign_on_vars_change <grant_assign_on_vars_change_list>
#                               - list of variables which are does grant permission of unconditional assignment of other variables if
#                                 previous values of those other variables has assigned under different values from variable values in this list.
#                                 Useful for unconditional assignment of variables from different packages or source directories.
#
# <file_paths>:           Sublist of file paths to load from.
#
# CONFIGURATION FILE FORMAT:
#   [<attributes>] <variable>[:[<os_name>][:[<compiler_name>][:[<config_name>][:[<arch_name>]]]]][=<value>]
#   [<attributes>] <variable>[:[<os_name>][:[<compiler_name>][:[<config_name>][:[<arch_name>]]]]][=(<value0> [<value1> [... <valueN>]])]
#
# <attributes>:           Variable space separated attributes: global | top | local | bool | path | exist | canonical | uncache | cache_only | cache | env_only | env | force_cache | force | override | unset | (un)hide | package | final
# <variable>:             Variable name corresponding to the regex: [_a-zA-Z][_a-zA-Z0-9]*
# <os_name>:              OS variant name: WIN | UNIX | ...
# <compiler_name>:        Compiler variant name with version support: <compiler_token_name>[<compiler_version>]
#   <compiler_token_name>: MSVC | GCC | CLANG | ...
#   <compiler_version>:   <major_version>[*+] | <major_version>.<minor_version>[*+]
#     <major_version>:    an integral value corresponding to the regex: [0-9]*
#     <minor_version>:    an integral value corresponding to the regex: [0-9]*
# <config_name>:          Configuration name: RELEASE | DEBUG | RELWITHDEBINFO | MINSIZEREL | ...
# <arch_name>:            Architecture variant name: X86 | X64 | ...
#
# <value>:                Value with escaping and substitution support: `$/<escape_char>`, `$/{<variable>}`
#
# PREDEFINED BUILTIN VARIABLES ACCESIBLE FROM BEING PARSED FILE:
#
# CMAKE_CURRENT_LOAD_VARS_FILE_INDEX:         Index in a file paths list from which this file have has an ordered load.
# CMAKE_CURRENT_LOAD_VARS_FILE_DIR:           Directory path from which this file being loaded from.
# CMAKE_CURRENT_PACKAGE_NEST_LVL:             Current package nest level.
# CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX:      Current package nest level prefix string like `00` if level is `0`, or `01` if level is `1` and so on.
# CMAKE_CURRENT_PACKAGE_NAME:                 Current package name this file being loaded from.
# CMAKE_CURRENT_PACKAGE_SOURCE_DIR:           Current package source directory this file being loaded from.
# CMAKE_TOP_PACKAGE_NAME:                     Top package name.
# CMAKE_TOP_PACKAGE_SOURCE_DIR:               Top package source directory.
#
macro(tkl_set_vars_from_files) # WITH OUT ARGUMENTS!
  if (${ARGC} GREATER 32)
    message(FATAL_ERROR "maximum 32 arguments is supported")
  endif()

  if (NOT ${ARGC} GREATER_EQUAL 6)
    message(FATAL_ERROR "function must be called at least with 6 not optional arguments: `${ARGC}`")
  endif()

  #message("ARGV=`${ARGV}`")
  tkl_set_vars_from_files_impl_init()
  tkl_make_var_from_ARGV_begin("${ARGN}" _50FABB52_argn)
  # in case of in a macro call we must pass all ARGV arguments explicitly
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGVn()
  tkl_make_var_from_ARGV_end(_50FABB52_argn)
  tkl_pop_ARGVn_from_stack()
  tkl_set_vars_from_files_impl_no_args_func()

  unset(_50FABB52_argn)

  tkl_set_vars_from_files_impl_uninit()
endmacro()

macro(tkl_set_vars_from_files_impl_init) # WITH OUT ARGUMENTS!
  tkl_copy_vars(_5A06EEFA_previous_all_vars_list _5A06EEFA_previous_vars_list _5A06EEFA_previous_var_values_list _5A06EEFA_)

  #list(LENGTH _5A06EEFA_previous_vars_list _5A06EEFA_previous_vars_list_len)
  #list(LENGTH _5A06EEFA_previous_var_values_list _5A06EEFA_previous_var_values_list_len)
  #message("[${_5A06EEFA_previous_vars_list_len}] _5A06EEFA_previous_vars_list=`${_5A06EEFA_previous_vars_list}`")
  #message("[${_5A06EEFA_previous_var_values_list_len}] _5A06EEFA_previous_var_values_list=`${_5A06EEFA_previous_var_values_list}`")

  # Parent variable are saved, now can create local variables!
  tkl_get_cmake_role(_5A06EEFA_is_in_script_mode SCRIPT)

  if (NOT _5A06EEFA_is_in_script_mode)
    # CMAKE_CONFIGURATION_TYPES consistency check, in case if not script mode
    tkl_check_CMAKE_CONFIGURATION_TYPES_vs_multiconfig()
  endif()

  unset(_5A06EEFA_is_in_script_mode)
endmacro()

macro(tkl_set_vars_from_files_impl_uninit) # WITH OUT ARGUMENTS!
  unset(_5A06EEFA_previous_all_vars_list)
  unset(_5A06EEFA_previous_vars_list)
  unset(_5A06EEFA_previous_var_values_list)
endmacro()

macro(tkl_set_vars_from_files_impl_with_args) # WITH OUT ARGUMENTS!
  if (${ARGC} GREATER 32)
    message(FATAL_ERROR "maximum 32 arguments is supported")
  endif()

  # we must recollect arguments here, because this implementation can be used separately with standalone arguments
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" . _50FABB52_argn)
  # in case of in a macro call we must pass all ARGV arguments explicitly
  tkl_pushset_ARGVn_to_stack(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGVn()
  tkl_make_vars_from_ARGV_ARGN_end(. _50FABB52_argn)
  tkl_pop_ARGVn_from_stack()
  tkl_set_vars_from_files_impl_no_args_macro()
  unset(_50FABB52_argn)
endmacro()

function(tkl_set_vars_from_files_impl_no_args_func) # WITH OUT ARGUMENTS!
  tkl_set_vars_from_files_impl_no_args_macro()
endfunction()

macro(tkl_set_vars_from_files_impl_no_args_macro) # WITH OUT ARGUMENTS!
  list(LENGTH _50FABB52_argn argn_len)
  set(argn_index 0)

  set(print_vars_set 0)
  set(set_vars 1)
  set(set_env_vars 0) # exclusive set, usual variable set is replaced by environment variable set, all attributes will be ignored
  set(append_to_files 0)
  set(ignore_statement_if_no_filter 0)              # ignore specialized statements if it does not have a configuration name filter
  set(ignore_statement_if_no_filter_config_name 0)  # ignore specialized statements if it does not have a filter specification
  set(ignore_late_expansion_statements 0)           # ignore statements with late expansion feature
  set(script_mode 0)
  set(silent_mode 0)

  # parameterized flag argument values
  unset(var_lines_file_path)
  unset(var_names_file_path)
  unset(var_values_file_path)
  unset(flock_file_path)
  unset(grant_external_vars_for_assign_list)
  unset(grant_external_vars_assign_in_files_list)
  unset(grant_assign_for_vars)
  unset(grant_assign_on_vars_change_list)
  unset(include_vars_filter_list)
  unset(exclude_vars_filter_list)
  unset(load_state_from_cmake_global_properties_prefix)
  unset(save_state_into_cmake_global_properties_prefix)
  unset(make_vars_names)
  unset(make_vars_values)

  # parse flags until no flags
  tkl_parse_function_optional_flags_into_vars(
    argn_index
    _50FABB52_argn
    "p;e;E;a;S;s"
    "E\;set_vars"
    "p\;print_vars_set;e\;set_env_vars;E\;set_env_vars;a\;append_to_files;S\;script_mode;s\;silent_mode"
    "varlines\;.\;var_lines_file_path;vars\;.\;var_names_file_path;values\;.\;var_values_file_path;\
flock\;.\;flock_file_path;ignore_statement_if_no_filter\;ignore_statement_if_no_filter;\
ignore_statement_if_no_filter_config_name\;ignore_statement_if_no_filter_config_name;\
ignore_late_expansion_statements\;ignore_late_expansion_statements;\
grant_external_vars_for_assign\;.\;grant_external_vars_for_assign_list;\
grant_external_vars_assign_in_files\;.\;grant_external_vars_assign_in_files_list;\
grant_assign_for_vars\;.\;grant_assign_for_vars_list;\
grant_assign_on_vars_change\;.\;grant_assign_on_vars_change_list;\
include_vars_filter\;.\;include_vars_filter_list;exclude_vars_filter\;.\;exclude_vars_filter_list;\
load_state_from_cmake_global_properties\;.\;load_state_from_cmake_global_properties_prefix;\
save_state_into_cmake_global_properties\;.\;save_state_into_cmake_global_properties_prefix;\
make_vars\;.\;make_vars_names\;make_vars_values"
  )

  if (silent_mode AND print_vars_set)
    message(FATAL_ERROR "print_vars_set flag (-p) can not be used together with the silent_mode flag (-s)")
  endif()

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
  math(EXPR args_max_size ${argn_index}+6)
  if (argn_len LESS args_max_size)
    message(FATAL_ERROR "set_vars_from_files_impl_no_args function must be called with at least ${args_max_size} arguments: argn_len=`${argn_len}` ARGC=`${ARGC}` argn_index=`${argn_index}`")
  endif()

  list(GET _50FABB52_argn ${argn_index} file_paths) # discardes ;-escaping
  math(EXPR argn_index ${argn_index}+1)

  if ("${file_paths}" STREQUAL "")
    message(FATAL_ERROR "file_paths argument is not defined")
  endif()

  list(GET _50FABB52_argn ${argn_index} os_name) # discardes ;-escaping
  math(EXPR argn_index ${argn_index}+1)

  list(GET _50FABB52_argn ${argn_index} compiler_name) # discardes ;-escaping
  math(EXPR argn_index ${argn_index}+1)

  list(GET _50FABB52_argn ${argn_index} config_name) # discardes ;-escaping
  math(EXPR argn_index ${argn_index}+1)

  list(GET _50FABB52_argn ${argn_index} arch_name) # discardes ;-escaping
  math(EXPR argn_index ${argn_index}+1)

  list(GET _50FABB52_argn ${argn_index} list_separator_char) # discardes ;-escaping
  math(EXPR argn_index ${argn_index}+1)

  set(use_vars_late_expansion 0)

  if (NOT argn_len EQUAL argn_index)
    # set of trailing optional arguments either not used or used all together
    math(EXPR args_max_size ${argn_index}+4)

    if (argn_len LESS args_max_size)
      message(FATAL_ERROR "set_vars_from_files_impl_no_args function must be called with all at least ${args_max_size} arguments: argn_len=`${argn_len}` ARGC=`${ARGC}` argn_index=`${argn_index}`")
    endif()

    set(use_vars_late_expansion 1)

    tkl_list_get(out_var_config_gen_var_lines_list _50FABB52_argn ${argn_index})
    math(EXPR argn_index ${argn_index}+1)

    tkl_list_get(out_var_config_gen_vars_list _50FABB52_argn ${argn_index})
    math(EXPR argn_index ${argn_index}+1)

    tkl_list_get(out_var_config_gen_names_list _50FABB52_argn ${argn_index})      # single ;-escaped configuration names list per variable, the `*` name means `all others`
    math(EXPR argn_index ${argn_index}+1)

    tkl_list_get(out_var_config_gen_values_list _50FABB52_argn ${argn_index})     # double ;-escaped values list per configuration name per variable
    math(EXPR argn_index ${argn_index}+1)
  endif()

  if (NOT "${config_name}" STREQUAL "")
    set(is_config_name_value_can_late_expand 0)
  else()
    set(is_config_name_value_can_late_expand 1)
  endif()

  # config_name consistency check
  if(use_vars_late_expansion AND is_config_name_value_can_late_expand)
    if ("${CMAKE_CONFIGURATION_TYPES}" STREQUAL "")
      message(FATAL_ERROR "CMAKE_CONFIGURATION_TYPES variable must contain configuration names in case of empty config_name argument to construct complement generator expressions: CMAKE_CONFIGURATION_TYPES=`${CMAKE_CONFIGURATION_TYPES}`")
    endif()
  endif()

  # process some predefined placeholders
  if (("${os_name}" STREQUAL ".") OR ("${os_name}" STREQUAL "*"))
    set(os_name "")
  endif()
  if (("${compiler_name}" STREQUAL ".") OR ("${compiler_name}" STREQUAL "*"))
    set(compiler_name "")
  endif()
  if (("${config_name}" STREQUAL ".") OR ("${config_name}" STREQUAL "*"))
    set(config_name "")
  endif()
  if (("${arch_name}" STREQUAL ".") OR ("${arch_name}" STREQUAL "*"))
    set(arch_name "")
  endif()

  # condition properties are case insensitive
  string(TOUPPER "${os_name}" os_name_upper)
  string(TOUPPER "${compiler_name}" compiler_name_upper)
  string(TOUPPER "${compiler_config}" compiler_config_upper)
  string(TOUPPER "${config_name}" config_name_upper)
  string(TOUPPER "${arch_name}" arch_name_upper)

  if (script_mode)
    set(is_in_script_mode 1)
  else()
    tkl_get_cmake_role(is_in_script_mode SCRIPT)
  endif()

  set(compare_var_paths_as_case_sensitive 1)

  if ("${os_name}" STREQUAL "" AND NOT is_in_script_mode)
    if (WIN32 OR WIN64)
      set(os_name_to_filter WIN)
    elseif (MSYS)
      set(os_name_to_filter MSYS)
    elseif (MINGW)
      set(os_name_to_filter MINGW)
    elseif (CYGWIN)
      set(os_name_to_filter CYGWIN)
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

  if ("${os_name_to_filter}" STREQUAL "WIN" OR
      "${os_name_to_filter}" STREQUAL "MSYS" OR
      "${os_name_to_filter}" STREQUAL "MINGW" OR
      "${os_name_to_filter}" STREQUAL "CYGWIN")
    set(compare_var_paths_as_case_sensitive 0) # treats all Windows file systems as case insensitive
  endif()

  if ("${list_separator_char}" STREQUAL "")
    set(list_separator_char ";")  # builtin list separator in the cmake
  endif()

  if ("${compiler_name}" STREQUAL "" AND NOT is_in_script_mode)
    if (MSVC)
      tkl_get_msvc_version_token(compiler_name_to_filter)
    elseif (GCC)
      tkl_get_gcc_version_token(compiler_name_to_filter)
    elseif (CLANG)
      tkl_get_clang_version_token(compiler_name_to_filter)
    else()
      message(FATAL_ERROR "compiler is not supported")
    endif()
  else()
    set(compiler_name_to_filter "${compiler_name_upper}")
  endif()

  if (NOT "${config_name}" STREQUAL "")
    string(SUBSTRING "${config_name_upper}" 0 1 char)
    if (NOT char MATCHES "[_A-Z]")
      message(FATAL_ERROR "Invalid configuration name: `${config_name}`")
    endif()

    if (config_name_upper MATCHES "[^_A-Z0-9]")
      message(FATAL_ERROR "Invalid configuration name: `${config_name}`")
    endif()
  endif()

  set(config_name_to_filter "${config_name_upper}")

  if ("${arch_name}" STREQUAL "" AND NOT is_in_script_mode)
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
  if (DEFINED TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL)
    set(config_package_nest_lvl ${TACKLELIB_CMAKE_CURRENT_PACKAGE_NEST_LVL})
  endif()

  if (load_state_from_cmake_global_properties_prefix)
    get_property(is_config_load_index_set
      GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_load_index SET)
    if (is_config_load_index_set)
      get_property(config_load_index
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_load_index)
    endif()

    get_property(config_var_names GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_var_names)
    #message("loading: vars: `${config_var_names}`")

    foreach(config_var_name IN LISTS config_var_names)
      get_property(config_${config_var_name}
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name})

      get_property(config_${config_var_name}_defined
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_defined)
      get_property(config_${config_var_name}_package_defined
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_package_defined)

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

      get_property(config_${config_var_name}_hidden_var
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_hidden_var)
      get_property(config_${config_var_name}_hidden_var_value
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_value)

      get_property(config_${config_var_name}_hidden_var_cache
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_cache)
      get_property(config_${config_var_name}_hidden_var_cache_value
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_cache_value)
      get_property(config_${config_var_name}_hidden_var_cache_type
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_cache_type)
      get_property(config_${config_var_name}_hidden_var_cache_docstring
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_cache_docstring)
      get_property(config_${config_var_name}_hidden_var_cache_with_force
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_cache_with_force)

      get_property(config_${config_var_name}_hidden_var_env
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_env)
      get_property(config_${config_var_name}_hidden_var_env_value
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_env_value)

      get_property(config_${config_var_name}_global_var
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_global_var)
      get_property(config_${config_var_name}_top_package_var
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_top_package_var)
      get_property(config_${config_var_name}_local_var
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_local_var)
      get_property(config_${config_var_name}_final_var
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_final_var)
      get_property(config_${config_var_name}_package_scope_var
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_package_scope_var)

      get_property(config_${config_var_name}_has_values_onchange_list
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_has_values_onchange_list)
      get_property(config_${config_var_name}_var_values_onchange_list
        GLOBAL PROPERTY ${load_state_from_cmake_global_properties_prefix}config_${config_var_name}_var_values_onchange_list)

      #message("config_var_name=`${config_var_name}` -> `${config_${config_var_name}_file_path_c}`")
    endforeach()
  else()
    set(config_var_names "")
  endif()

  math(EXPR config_load_index ${config_load_index}+1)

  # special injected variables
  set(injected_vars_list
    CMAKE_CURRENT_LOAD_VARS_FILE_INDEX;CMAKE_CURRENT_LOAD_VARS_FILE_DIR
    CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX
    CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR
    CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR)

  foreach (injected_var_name IN LISTS injected_vars_list)
    if ("${injected_var_name}" STREQUAL "")
      message(FATAL_ERROR "must be a builtin variable name")
    endif()

    if (NOT DEFINED TACKLELIB_${injected_var_name})
      continue()
    endif()

    set(config_${injected_var_name} "${TACKLELIB_${injected_var_name}}")
    set(config_${injected_var_name}_defined 1)          # global definition counter
    set(config_${injected_var_name}_package_defined 1)  # package definition counter

    set(config_${injected_var_name}_load_index ${config_load_index})
    set(config_${injected_var_name}_package_nest_lvl ${config_package_nest_lvl})

    set(config_${injected_var_name}_file_path_c "")     # does not have associated comparable file path
    set(config_${injected_var_name}_file_index -1)      # does not have associated file index
    set(config_${injected_var_name}_line 0)             # does not have associated file line
    set(config_${injected_var_name}_os_name "")
    set(config_${injected_var_name}_compiler_name "")
    set(config_${injected_var_name}_config_name "")
    set(config_${injected_var_name}_arch_name "")

    set(config_${injected_var_name}_hidden_var 0)
    unset(config_${injected_var_name}_hidden_var_value)

    set(config_${injected_var_name}_hidden_var_cache 0)
    unset(config_${injected_var_name}_hidden_var_cache_value)
    unset(config_${injected_var_name}_hidden_var_cache_type)
    unset(config_${injected_var_name}_hidden_var_cache_docstring)
    unset(config_${injected_var_name}_hidden_var_cache_with_force)

    set(config_${injected_var_name}_hidden_var_env 0)
    unset(config_${injected_var_name}_hidden_var_env_value)

    set(config_${injected_var_name}_global_var 1)   # always global
    set(config_${injected_var_name}_top_package_var 0)
    set(config_${injected_var_name}_local_var 0)
    set(config_${injected_var_name}_final_var 0)
    set(config_${injected_var_name}_package_scope_var 0)

    set(config_${injected_var_name}_has_values_onchange_list 0)
    set(config_${injected_var_name}_var_values_onchange_list "")
  endforeach()

  # make variables explicitly
  set(make_var_name_index -1)
  list(LENGTH make_vars_values make_vars_values_len)

  foreach (make_var_name IN LISTS make_vars_names)
    math(EXPR make_var_name_index ${make_var_name_index}+1)

    if ("${make_var_name}" STREQUAL "")
      message(FATAL_ERROR "--make_vars must not use empty variable names")
    endif()

    if (make_var_name_index LESS make_vars_values_len)
      list(GET make_vars_values ${make_var_name_index} make_var_value)

      # unescape values
      string(REGEX REPLACE "\\\\(.)?" "\\1" make_var_value "${make_var_value}")

      # WORKAROUND: we have to replace because `list(GET` discardes ;-escaping
      tkl_escape_string_after_list_get(make_var_value "${make_var_value}")

      set(config_${make_var_name} "${make_var_value}")
    else()
      # use special unexisted directory value to differentiate it from the defined empty value

      # CAUTION:
      #   `:` after `*` to workaround issue with the `os.path.abspath`: `os.path.abspath('$/{aa}/../bb')` would expand into invalid absolute path
      #
      set(config_${make_var_name} "*:\$/{${make_var_name}}")
    endif()
    set(config_${make_var_name}_defined 1)          # global definition counter
    set(config_${make_var_name}_package_defined 1)  # package definition counter

    set(config_${make_var_name}_load_index ${config_load_index})
    set(config_${make_var_name}_package_nest_lvl ${config_package_nest_lvl})

    set(config_${make_var_name}_file_path_c "")     # does not have associated comparable file path
    set(config_${make_var_name}_file_index -1)      # does not have associated file index
    set(config_${make_var_name}_line 0)             # does not have associated file line
    set(config_${make_var_name}_os_name "")
    set(config_${make_var_name}_compiler_name "")
    set(config_${make_var_name}_config_name "")
    set(config_${make_var_name}_arch_name "")

    set(config_${make_var_name}_hidden_var 0)
    unset(config_${make_var_name}_hidden_var_value)

    set(config_${make_var_name}_hidden_var_cache 0)
    unset(config_${make_var_name}_hidden_var_cache_value)
    unset(config_${make_var_name}_hidden_var_cache_type)
    unset(config_${make_var_name}_hidden_var_cache_docstring)
    unset(config_${make_var_name}_hidden_var_cache_with_force)

    set(config_${make_var_name}_hidden_var_env 0)
    unset(config_${make_var_name}_hidden_var_env_value)

    set(config_${make_var_name}_global_var 0)
    set(config_${make_var_name}_top_package_var 0)
    set(config_${make_var_name}_local_var 0)
    set(config_${make_var_name}_final_var 0)
    set(config_${make_var_name}_package_scope_var 0)

    set(config_${make_var_name}_has_values_onchange_list 0)
    set(config_${make_var_name}_var_values_onchange_list "")
  endforeach()

  # update all input paths to make them comparable
  foreach (file_path_list_name
    grant_external_vars_assign_in_files_list)
    set(${file_path_list_name}_c "")

    foreach (file_path IN LISTS ${file_path_list_name})
      tkl_make_comparable_path(file_path_c "${file_path}" ABSOLUTE compare_var_paths_as_case_sensitive 1)
      list(APPEND ${file_path_list_name}_c "${file_path_c}")
    endforeach()
  endforeach()

  # create create/truncate output files under flock
  if (DEFINED flock_file_path)
    tkl_file_lock("${flock_file_path}" FILE)
  endif()
  if (NOT append_to_files)
    if (DEFINED var_lines_file_path)
      tkl_file_write("${var_lines_file_path}" "")
    endif()
    if (DEFINED var_names_file_path)
      tkl_file_write("${var_names_file_path}" "")
    endif()
    if (DEFINED var_values_file_path)
      tkl_file_write("${var_values_file_path}" "")
    endif()
  endif()

  set(file_path_index -1)

  foreach (file_path IN LISTS file_paths)
    math(EXPR file_path_index ${file_path_index}+1)

    if ("${file_path}" STREQUAL "")
      message(FATAL_ERROR "file_paths contains an empty path: file_paths=`${file_paths}`")
    endif()

    # reset special injected variables
    get_filename_component(file_path_abs "${file_path}" ABSOLUTE)
    get_filename_component(file_dir_path "${file_path_abs}" DIRECTORY)

    set(config_CMAKE_CURRENT_LOAD_VARS_FILE_DIR "${file_dir_path}")
    set(config_CMAKE_CURRENT_LOAD_VARS_FILE_INDEX "${file_path_index}")

    tkl_make_comparable_path(file_path_c "${file_path_abs}" . compare_var_paths_as_case_sensitive 1)

    # update attributes per file basis
    if ((NOT make_vars_names) OR (NOT "CMAKE_CURRENT_PACKAGE_NAME" IN_LIST make_vars_names))
      if (DEFINED TACKLELIB_CMAKE_CURRENT_PACKAGE_NAME)
        set(config_CMAKE_CURRENT_PACKAGE_NAME "${TACKLELIB_CMAKE_CURRENT_PACKAGE_NAME}")
      else()
        # use special unexisted directory value to differentiate it from the defined empty value

        # CAUTION:
        #   `:` after `*` to workaround issue with the `os.path.abspath`: `os.path.abspath('$/{aa}/../bb')` would expand into invalid absolute path
        #
        set(config_CMAKE_CURRENT_PACKAGE_NAME "*:\$/{TACKLELIB_CMAKE_CURRENT_PACKAGE_NAME}")
      endif()
    endif()
    if ((NOT make_vars_names) OR (NOT "CMAKE_CURRENT_PACKAGE_SOURCE_DIR" IN_LIST make_vars_names))
      if (DEFINED TACKLELIB_CMAKE_CURRENT_PACKAGE_SOURCE_DIR)
        set(config_CMAKE_CURRENT_PACKAGE_SOURCE_DIR "${TACKLELIB_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
      else()
        # use special unexisted directory value to differentiate it from the defined empty value

        # CAUTION:
        #   `:` after `*` to workaround issue with the `os.path.abspath`: `os.path.abspath('$/{aa}/../bb')` would expand into invalid absolute path
        #
        set(config_CMAKE_CURRENT_PACKAGE_SOURCE_DIR "*:\$/{TACKLELIB_CMAKE_CURRENT_PACKAGE_SOURCE_DIR}")
      endif()
    endif()

    # with out any filter here to enable to use of the line number to reference it in a parse error
    tkl_file_encode_strings(file_content "${file_path_abs}")

    set(var_file_content_line 0)

    # to track not closed character sequences
    set(open_sequence_var_file_content_line 0)
    set(open_sequence_var_token_suffix_to_process "")
    set(open_sequence_var_line "")
    set(open_sequence_this_file_line "")

    # state machine parser flags and intermediate values for multiline variables
    set(is_continue_parse_var_value 0)

    foreach (var_line IN LISTS file_content)
      # We have to continue parse a variable expression because it can be multiline, so
      # the flag indicates to not parse variable's value assignment while searching the end of a variable expression
      # (just `continue()` will drop the search a variable expression end and will lead to other errors).
      set(var_assign_ignore 0)

      # other flags to ignore
      set(var_unsupported_token_ignore 0)
      set(var_invalid_token_ignore 0)
      set(var_specialization_ignore 0)

      math(EXPR var_file_content_line ${var_file_content_line}+1)

      tkl_file_decode_string(var_line "${var_line}")

      #message("[${var_file_content_line}] {${is_continue_parse_var_value}}  => `${var_line}`")

      # skip empty lines
      if ("${var_line}" STREQUAL "" OR var_line MATCHES "^[ \t]*\$")
        continue()
      endif()

      # skip full comment lines
      if (var_line MATCHES "^[ \t]*#")
        continue()
      endif()

      # NOTE:
      #   We have to skip all variable name and related specialization checks here,
      #   if we already checked that and just continue to parse a variable's value.
      #

      if (NOT is_continue_parse_var_value)
        if(var_line MATCHES "^[ \t]*([^\"=]+)[ \t]*=[ \t]*(.*)[ \t]*\$")
          set(var_has_value 1)
        else()
          set(var_has_value 0)
          if(NOT var_line MATCHES "^[ \t]*([^\"=]+)[ \t]*\$")
            # empty or incomplete variable line declaration is an error
            message(WARNING "Invalid variable line declaration: `${file_path_abs}`(${var_file_content_line}): `${CMAKE_MATCH_1}`")
            continue()
          endif()
        endif()

        set(var_token "${CMAKE_MATCH_1}")
        if (var_has_value)
          set(var_value "${CMAKE_MATCH_2}")
          string(LENGTH "${var_value}" var_value_len)
        else()
          set(var_value "")
          set(var_value_len 0)
        endif()

        string(LENGTH "${var_token}" var_token_len)

        # parse variable name at first
        if (NOT var_token MATCHES "([^:]+):?([^:]*)?:?([^:]*)?:?([^:]*)?:?([^:]*)?")
          message(WARNING "Invalid variable token: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          continue()
        endif()

        string(STRIP "${CMAKE_MATCH_1}" var_name_token)
        string(STRIP "${CMAKE_MATCH_2}" var_os_name)
        string(STRIP "${CMAKE_MATCH_3}" var_compiler_name)
        string(STRIP "${CMAKE_MATCH_4}" var_config_name)
        string(STRIP "${CMAKE_MATCH_5}" var_arch_name)

        # extract name attributes (tokens before a variable name) from name token
        string(REGEX REPLACE "[ \t]+" ";" var_name_token_list "${var_name_token}")

        list(LENGTH var_name_token_list var_name_token_list_len)
        math(EXPR var_name_token_list_last_index ${var_name_token_list_len}-1)

        list(GET var_name_token_list ${var_name_token_list_last_index} var_name)

        string(REGEX REPLACE "[_a-zA-Z0-9]" "" var_name_valid_chars_filtered "${var_name}")

        if ("${var_name}" STREQUAL "" OR (NOT "${var_name_valid_chars_filtered}" STREQUAL ""))
          message(FATAL_ERROR "Invalid variable token: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        endif()

        if (NOT DEFINED config_${var_name}_defined)
          set(config_${var_name}_defined 0)
        endif()
        set(config_${var_name}_package_defined 0)

        set(var_type "")

        # use global variable
        set(use_global_var 0)

        # use top level variable
        set(use_top_package_var 0)

        # use local variable
        set(use_local_var 0)

        # use variable overriding
        set(use_override_var 0)

        # use variable unset
        set(use_unset_var 0)

        # unset cache value on set not cache value
        set(use_uncache_var 0)

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

        # use final variable assignment to throw an error on next variable assignment, or use final variable disable to ignore next variable assignment or redisable
        set(use_final_var 0)

        # hide variable's value (until unhided, ignores the same variable hide)
        set(use_hide_var 0)

        # unhine variable's value (until hided, ignores the same variable unhide)
        set(use_unhide_var 0)

        # use package scope variable
        set(use_package_scope_var 0)

        # use existed variable's value, applicaible to the path ONLY
        set(use_existed_value 0)

        # use canonical variable's value, applicaible to the path ONLY
        set(use_canonical_value 0)

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
          if (NOT use_global_var AND "GLOBAL" IN_LIST var_name_attr_list_upper)
            set(use_global_var 1)
          endif()

          if (NOT use_top_package_var AND "TOP" IN_LIST var_name_attr_list_upper)
            set(use_top_package_var 1)
          endif()

          if (NOT use_local_var AND "LOCAL" IN_LIST var_name_attr_list_upper)
            set(use_local_var 1)
          endif()

          if (NOT use_override_var AND "OVERRIDE" IN_LIST var_name_attr_list_upper)
            set(use_override_var 1)
          endif()

          if (NOT use_unset_var AND "UNSET" IN_LIST var_name_attr_list_upper)
            set(use_unset_var 1)
          endif()

          if (NOT use_hide_var AND "HIDE" IN_LIST var_name_attr_list_upper)
            set(use_hide_var 1)
          endif()

          if (NOT use_unhide_var AND "UNHIDE" IN_LIST var_name_attr_list_upper)
            set(use_unhide_var 1)
          endif()

          if ("BOOL" IN_LIST var_name_attr_list_upper)
            set(var_type "bool")
          endif()
          if ("PATH" IN_LIST var_name_attr_list_upper)
            if (var_type)
              message(FATAL_ERROR "A variable should have maximum one type attribute: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()
            set(var_type "path")
          endif()

          if ("UNCACHE" IN_LIST var_name_attr_list_upper)
            set(use_uncache_var 1)
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

          if (NOT use_final_var AND "FINAL" IN_LIST var_name_attr_list_upper)
            set(use_final_var 1)
          endif()

          if (NOT use_package_scope_var AND "PACKAGE" IN_LIST var_name_attr_list_upper)
            set(use_package_scope_var 1)
          endif()

          if ("EXIST" IN_LIST var_name_attr_list_upper)
            set(use_existed_value 1)
          endif()

          if ("CANONICAL" IN_LIST var_name_attr_list_upper)
            set(use_canonical_value 1)
          endif()
        else()
          set(var_name_attr_list "")
          set(var_set_msg_name_attr_prefix_str "")
        endif()

        # unconditionally applicable checks before any filter...

        # hide + unhide
        if (use_hide_var AND use_unhide_var)
          message(FATAL_ERROR "The variable HIDE and UNHIDE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        endif()

        # 1. unset + <other modificator except `final` or `package`>
        # 2. hide/unhide + <other modificator except `final` or `package`>
        if (use_unset_var OR use_hide_var OR use_unhide_var)
          if (use_unset_var)
            if (use_hide_var OR use_unhide_var)
              message(FATAL_ERROR "The variable UNSET and HIDE/UNHIDE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            elseif (use_override_var)
              message(FATAL_ERROR "The variable UNSET and OVERRIDE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            elseif (use_force_cache_var)
              message(FATAL_ERROR "The variable UNSET and FORCE_CACHE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            elseif (use_force_var)
              message(FATAL_ERROR "The variable UNSET and FORCE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            elseif (use_existed_value)
              message(FATAL_ERROR "The variable UNSET and EXIST attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            elseif (use_canonical_value)
              message(FATAL_ERROR "The variable UNSET and CANONICAL attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()

            # unset + global
            if (use_global_var)
              message(FATAL_ERROR "The variable UNSET and GLOBAL attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()

            # unset + <any type attribute>
            if (NOT "${var_type}" STREQUAL "")
              message(FATAL_ERROR "The variable UNSET and type attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()

            # unset in assignment
            if (var_has_value)
              message(FATAL_ERROR "The variable UNSET must be issued without assignment: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()

            # unset + <specialization>
            if ((NOT "${var_os_name}" STREQUAL "") OR
                (NOT "${var_compiler_name}" STREQUAL "") OR
                (NOT "${var_config_name}" STREQUAL "") OR
                (NOT "${var_arch_name}" STREQUAL ""))
              message(FATAL_ERROR "The variable UNSET must be issued without variable specialization: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()
          elseif (use_hide_var OR use_unhide_var)
            if (use_override_var)
              message(FATAL_ERROR "The variable HIDE/UNHIDE and OVERRIDE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            elseif (use_force_cache_var)
              message(FATAL_ERROR "The variable HIDE/UNHIDE and FORCE_CACHE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            elseif (use_force_var)
              message(FATAL_ERROR "The variable HIDE/UNHIDE and FORCE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            elseif (use_existed_value)
              message(FATAL_ERROR "The variable HIDE/UNHIDE and EXIST attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            elseif (use_canonical_value)
              message(FATAL_ERROR "The variable HIDE/UNHIDE and CANONICAL attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()

            # hide/unhide + global
            if (use_global_var)
              message(FATAL_ERROR "The variable HIDE/UNHIDE and GLOBAL attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()

            # hide/unhide + <any type attribute>
            if (NOT "${var_type}" STREQUAL "")
              message(FATAL_ERROR "The variable HIDE/UNHIDE and type attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()

            # hide/unhide in assingment
            if (var_has_value)
              message(FATAL_ERROR "The variable HIDE/UNHIDE must be issued without assignment: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()

            # hide/unhide + <specialization>
            if ((NOT "${var_os_name}" STREQUAL "") OR
                (NOT "${var_compiler_name}" STREQUAL "") OR
                (NOT "${var_config_name}" STREQUAL "") OR
                (NOT "${var_arch_name}" STREQUAL ""))
              message(FATAL_ERROR "The variable HIDE/UNHIDE must be issued without variable specialization: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
            endif()
          endif()
        elseif (NOT var_has_value)
          # variable assignment expression without a value is an error
          message(WARNING "Invalid variable assignment expression without a value: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          continue()
        endif()

        # global + ...
        if (use_global_var)
          if (use_override_var)
            message(FATAL_ERROR "The variable GLOBAL and OVERRIDE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          elseif (use_top_package_var)
            message(FATAL_ERROR "The variable GLOBAL and TOP attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          elseif (use_local_var)
            message(FATAL_ERROR "The variable GLOBAL and LOCAL attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          elseif (use_package_var)
            message(FATAL_ERROR "The variable GLOBAL and PACKAGE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          endif()
        endif()

        # uncache + cache/cache_only
        if (use_uncache_var AND (use_cache_var OR use_only_cache_var))
          message(FATAL_ERROR "The variable UNCACHE and CACHE* attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        endif()

        # cache_only + env_only
        if (use_only_cache_var AND use_only_env_var)
          message(FATAL_ERROR "The variable *_ONLY attribute must be declared only in a single variant: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        endif()

        # force_cache without cache and cache_only
        if (use_force_cache_var AND NOT use_cache_var AND NOT use_only_cache_var)
          message(FATAL_ERROR "The variable FORCE_CACHE attribute must be declared only together with the cache attribute (CACHE or CACHE_ONLY): `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        endif()

        # force + override/top
        if (use_force_var)
          if (use_override_var)
            message(FATAL_ERROR "The variable FORCE and OVERRIDE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          elseif (use_top_package_var AND config_${make_var_name}_defined)
            message(FATAL_ERROR "The variable FORCE attribute at first time must be used without the TOP attribute: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          endif()
        endif()

        # final + top/global
        if (use_final_var)
          if (use_top_var)
            message(FATAL_ERROR "The variable FINAL and TOP attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          elsif (use_global_var)
            message(FATAL_ERROR "The variable FINAL and GLOBAL attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          endif()
        endif()

        # override w/o top
        if (use_override_var)
          if (NOT use_top_package_var)
            message(FATAL_ERROR "The variable OVERRIDE attribute must be used together with the TOP attribute: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          elseif(NOT config_${make_var_name}_defined)
            message(FATAL_ERROR "The variable TOP attribute at first time must be used without the OVERRIDE attribute: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          endif()
        endif()

        # package w/o final or hide
        if (use_package_scope_var AND NOT use_final_var AND NOT use_hide_var)
          message(FATAL_ERROR "The variable PACKAGE attribute is not supported w/o the FINAL or w/o the HIDE attributes: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        endif()

        # package + unhide
        if (use_package_scope_var AND use_unhide_var)
          message(FATAL_ERROR "The variable PACKAGE and UNHIDE attributes must not be used together: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        endif()

        if (NOT "${var_type}" STREQUAL "path" AND use_existed_value)
          message(FATAL_ERROR "Only the PATH variable supports the EXIST attribute: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        endif()

        if (NOT "${var_type}" STREQUAL "path" AND use_canonical_value)
          message(FATAL_ERROR "Only the PATH variable supports the CANONICAL attribute: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        endif()

        # builtins checks...

        if (use_unset_var OR use_hide_var OR use_unhide_var)
          if ("${var_name}" IN_LIST injected_vars_list)
            message(FATAL_ERROR "The UNSET/HIDE/UNHIDE can not be applied to the builtin variables: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          endif()
        endif()

        # not silent variable name ignore checks...

        # check variable token consistency
        if ("${var_name}" STREQUAL "")
          message(WARNING "Invalid variable token: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          continue()
        endif()

        string(SUBSTRING "${var_name}" 0 1 char)
        if (NOT char MATCHES "[_A-Za-z]")
          message(WARNING "Invalid variable token: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          continue()
        endif()

        if (var_name MATCHES "[^_A-Za-z0-9]")
          message(WARNING "Invalid variable token: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
          continue()
        endif()

        # variable unset/hide/unhide
        if (use_unset_var OR use_hide_var OR use_unhide_var)
          if (use_hide_var)
            # move a value to the hidden storage

            # first class storage
            if (NOT use_only_cache_var AND NOT use_only_env_var)
              if (DEFINED config_${var_name})
                set(config_${var_name}_hidden_var_value "${config_${var_name}}")
              else()
                unset(config_${var_name}_hidden_var_value)
              endif()

              if (NOT config_${var_name}_hidden_var)
                unset(config_${var_name})
              endif()

              set(config_${var_name}_hidden_var 1)
            endif()

            # cache variable
            if (use_only_cache_var OR use_cache_var)
              # the same condition as for a usual cache variable
              if (NOT config_${var_name}_hidden_var_cache OR use_force_cache_var)
                tkl_get_var(. config_${var_name}_hidden_var_cache_value ${var_name})
                # get the rest cache properties of a variable
                get_property(config_${var_name}_hidden_var_cache_type CACHE "${var_name}" PROPERTY TYPE)
                get_property(config_${var_name}_hidden_var_cache_docstring CACHE "${var_name}" PROPERTY HELPSTRING)
                set(config_${var_name}_hidden_var_cache_with_force ${use_force_cache_var})
                set(config_${var_name}_hidden_var_cache 1)
              endif()
            endif()

            # environment variable
            if (use_only_env_var OR use_env_var)
              if (DEFINED ENV{${var_name}})
                set(config_${var_name}_hidden_var_env_value "$ENV{${var_name}}")
              else()
                unset(config_${var_name}_hidden_var_env_value)
              endif()
              set(config_${var_name}_hidden_var_env 1)
            endif()
          endif()

          if (use_unset_var)
            if (NOT use_only_cache_var AND use_only_env_var)
              if (config_${var_name}_hidden_var)
                unset(config_${var_name}_hidden_var_value)
              else()
                unset(config_${var_name})
              endif()
            endif()

            if (use_only_cache_var OR use_cache_var)
              # unset hidden variable storage too
              if (config_${var_name}_hidden_var_cache)
                unset(config_${var_name}_hidden_var_cache_value)
                unset(config_${var_name}_hidden_var_cache_type)
                unset(config_${var_name}_hidden_var_cache_docstring)
                unset(config_${var_name}_hidden_var_cache_with_force)
              endif()

              unset(${var_name} CACHE)
            endif()

            if (use_only_env_var OR use_env_var)
              if (config_${var_name}_hidden_var_env)
                unset(config_${var_name}_hidden_var_env_value)
              endif()

              unset(ENV{${var_name}})
            endif()
          endif()

          if(use_unhide_var)
            # move a value from the hidden storage

            # first class storage
            if (NOT use_only_cache_var AND NOT use_only_env_var)
              if (config_${var_name}_hidden_var)
                if (DEFINED config_${var_name}_hidden_var_value)
                  set(config_${var_name} "${config_${var_name}_hidden_var_value}")
                  unset(config_${var_name}_hidden_var_value)
                else()
                  unset(config_${var_name})
                endif()
                set(config_${var_name}_hidden_var 0)
              endif()
            endif()

            # cache variable
            if (use_only_cache_var OR use_cache_var)
              if (config_${var_name}_hidden_var_cache)
                if (DEFINED config_${var_name}_hidden_var_cache_value)
                  # CAUTION:
                  #   Resets the original variable!
                  #
                  if (config_${var_name}_hidden_var_cache_with_force)
                    set(${var_name} "${config_${var_name}_hidden_var_cache_value}" CACHE ${config_${var_name}_hidden_var_cache_type} "${config_${var_name}_hidden_var_cache_docstring}" FORCE)
                  else()
                    set(${var_name} "${config_${var_name}_hidden_var_cache_value}" CACHE ${config_${var_name}_hidden_var_cache_type} "${config_${var_name}_hidden_var_cache_docstring}")
                  endif()
                else()
                  unset(${var_name} CACHE)
                endif()
                unset(config_${var_name}_hidden_var_cache_value)
                unset(config_${var_name}_hidden_var_cache_type)
                unset(config_${var_name}_hidden_var_cache_docstring)
                unset(config_${var_name}_hidden_var_cache_with_force)
                set(config_${var_name}_hidden_cache_var 0)
              endif()
            endif()

            # environment variable
            if (use_only_env_var OR use_env_var)
              if (config_${var_name}_hidden_var_env)
                if (DEFINED config_${var_name}_hidden_var_env_value)
                  set(config_${var_name} "${config_${var_name}_hidden_var_env_value}")
                  unset(config_${var_name}_hidden_var_env_value)
                else()
                  # protect variable change if not only environment variable unset
                  if (use_only_env_var)
                    unset(config_${var_name})
                  endif()
                endif()
                set(config_${var_name}_hidden_env_var 0)
              endif()
            endif()
          endif()

          if (config_${var_name}_defined)
            # global
            if (config_${var_name}_global_var)
              if (use_top_package_var)
                message(FATAL_ERROR "The GLOBAL variable reassignment as TOP: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
              endif()
              if (NOT use_global_var AND NOT use_local_var)
                message(FATAL_ERROR "The GLOBAL variable reassignment as not GLOBAL/LOCAL: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
              endif()
            endif()

            # top
            if (config_${var_name}_top_package_var)
              if (use_global_var)
                message(FATAL_ERROR "The TOP variable reassignment as GLOBAL: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
              endif()
              if (use_local_var)
                message(FATAL_ERROR "The TOP variable reassignment as LOCAL: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
              endif()
              if (NOT use_top_package_var)
                message(FATAL_ERROR "The TOP variable reassignment as not TOP: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
              endif()
            endif()

            # local
            if (config_${var_name}_local_var)
              if (use_global_var)
                message(FATAL_ERROR "The LOCAL variable reassignment as GLOBAL: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
              endif()
              if (use_top_package_var)
                message(FATAL_ERROR "The LOCAL variable reassignment as TOP: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
              endif()
              if (NOT use_local_var)
                message(FATAL_ERROR "The LOCAL variable reassignment as not LOCAL: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
              endif()
            endif()
          else()
            # save variable token suffix and other parameter to compare it later
            set(config_${var_name}_load_index "${config_load_index}")
            set(config_${var_name}_package_nest_lvl "${config_package_nest_lvl}")

            set(config_${var_name}_file_path_c "${file_path_c}")
            set(config_${var_name}_file_index "${file_path_index}")
            set(config_${var_name}_line "${var_file_content_line}")

            set(config_${var_name}_os_name "")
            set(config_${var_name}_compiler_name "")
            set(config_${var_name}_config_name "")
            set(config_${var_name}_arch_name "")

            set(config_${var_name}_global_var ${use_global_var})
            set(config_${var_name}_top_package_var ${use_top_package_var})
            set(config_${var_name}_local_var ${use_local_var})
            set(config_${var_name}_final_var ${use_final_var})
            set(config_${var_name}_package_scope_var ${use_package_scope_var})

            if (grant_assign_on_vars_change_list AND NOT var_name IN_LIST grant_assign_on_vars_change_list)
              # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
              set(config_${var_name}_var_values_onchange_list ";")
              set(config_${var_name}_has_values_onchange_list 1)

              foreach (onchange_var_name IN LISTS grant_assign_on_vars_change_list)
                if (DEFINED config_${onchange_var_name})
                  list(APPEND config_${var_name}_var_values_onchange_list "${config_${onchange_var_name}}")
                else()
                  # use special unexisted directory value to differentiate it from the defined empty value

                  # CAUTION:
                  #   `:` after `*` to workaround issue with the `os.path.abspath`: `os.path.abspath('$/{aa}/../bb')` would expand into invalid absolute path
                  #
                  list(APPEND config_${var_name}_var_values_onchange_list "*:\$/{${onchange_var_name}}")
                endif()
              endforeach()

              # remove 2 first dummy empty strings
              tkl_list_remove_sublist(config_${var_name}_var_values_onchange_list 0 2 config_${var_name}_var_values_onchange_list)
            else()
              set(config_${var_name}_has_values_onchange_list 0)
              set(config_${var_name}_var_values_onchange_list "")
            endif()

            # append variable to the state list
            if (NOT var_name IN_LIST config_var_names)
              list(APPEND config_var_names "${var_name}")
            endif()
          endif()

          # increment global definition counter
          math(EXPR config_${var_name}_defined ${config_${var_name}_defined}+1)

          # update the actual variable

          # first class storage as is
          if (NOT use_only_cache_var AND NOT use_only_env_var)
            if (set_vars)
              if (NOT config_${var_name}_hidden_var)
                if (DEFINED config_${var_name})
                  set(${var_name} "${config_${var_name}}" PARENT_SCOPE)
                else()
                  unset(${var_name} PARENT_SCOPE)
                endif()

                if (use_uncache_var)
                  unset(${var_name} CACHE PARENT_SCOPE)
                endif()
              else()
                if (DEFINED config_${var_name})
                  # set instead the hidden variable storage
                  set(config_${var_name}_hidden_var_value "${config_${var_name}}")
                else()
                  unset(config_${var_name}_hidden_var_value PARENT_SCOPE)
                endif()

                if (use_uncache_var)
                  set(config_${var_name}_hidden_var_cache 0)
                  unset(config_${var_name}_hidden_var_cache_value)
                endif()
              endif()
            endif()
          endif()

          # environment variable from first class storage variable
          if (set_env_vars)
            if (DEFINED config_${var_name})
              set(ENV{var_name} "${config_${var_name}}")
            else()
              unset(ENV{var_name})
            endif()
          endif()

          if (print_vars_set)
            message("[${config_load_index}:${file_path_index}:${var_file_content_line}] - ${var_set_msg_name_attr_prefix_str}${var_name}${var_set_msg_suffix_str}")
          endif()

          continue()
        endif()

        # silent variable name filter checks...

        # variable names include filter
        if (include_vars_filter_list)
          if (NOT var_name IN_LIST include_vars_filter_list)
            # silent ignore not included variables
            set(var_assign_ignore 1)
          endif()
        endif()

        # variable names exclude filter
        if (NOT var_assign_ignore AND exclude_vars_filter_list)
          if (var_name IN_LIST exclude_vars_filter_list)
            # silent ignore excluded variables
            set(var_assign_ignore 1)
          endif()
        endif()

        string(TOUPPER "${var_os_name}" var_os_name_upper)
        string(TOUPPER "${var_compiler_name}" var_compiler_name_upper)
        string(TOUPPER "${var_config_name}" var_config_name_upper)
        string(TOUPPER "${var_arch_name}" var_arch_name_upper)

        # check variable on a collision with builtin variable
        foreach (injected_var_name IN LISTS injected_vars_list)
          if ("${var_name}" STREQUAL "${injected_var_name}")
            message(FATAL_ERROR "The variable is a builtin variable which can not be changed: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${var_os_name_upper}:${var_compiler_name_upper}:${var_config_name_upper}:${var_arch_name_upper}]")
          endif()
        endforeach()

        # other not silent ignore checks...

        if ("${var_os_name}" STREQUAL "")
          set(var_os_name_to_process "${os_name_to_filter}")
        elseif (("${var_os_name_upper}" STREQUAL "WIN") OR
                ("${var_os_name_upper}" STREQUAL "UNIX") OR
                ("${var_os_name_upper}" STREQUAL "APPLE"))
          set(var_os_name_to_process "${var_os_name_upper}")
        else()
          set(var_unsupported_token_ignore 1)
          set(var_assign_ignore 1)
        endif()

        if ("${var_compiler_name_upper}" STREQUAL "")
          set(var_compiler_name_to_process "${compiler_name_to_filter}")
        elseif (var_compiler_name_upper MATCHES "([_A-Z]+)([0-9]+)?\\.?([0-9]+)?")
          if (("${CMAKE_MATCH_1}" STREQUAL "MSVC") OR
              ("${CMAKE_MATCH_1}" STREQUAL "GCC") OR
              ("${CMAKE_MATCH_1}" STREQUAL "CLANG"))
            set(var_compiler_name_to_process "${var_compiler_name_upper}")
          else()
            set(var_unsupported_token_ignore 1)
            set(var_assign_ignore 1)
          endif()
        else()
          set(var_unsupported_token_ignore 1)
          set(var_assign_ignore 1)
        endif()

        if ("${var_config_name}" STREQUAL "")
          set(var_config_name_to_process "${config_name_to_filter}")
        else()
          string(SUBSTRING "${var_config_name_upper}" 0 1 char)
          if (NOT char MATCHES "[_A-Z]")
            set(var_invalid_token_ignore 1)
            set(var_assign_ignore 1)
          elseif (var_name MATCHES "[^_A-Z0-9]")
            set(var_invalid_token_ignore 1)
            set(var_assign_ignore 1)
          endif()

          set(var_config_name_to_process "${var_config_name_upper}")
        endif()

        if ("${var_arch_name}" STREQUAL "")
          set(var_arch_name_to_process "${arch_name_to_filter}")
        elseif (("${var_arch_name_upper}" STREQUAL "X86") OR
                ("${var_arch_name_upper}" STREQUAL "X64"))
          set(var_arch_name_to_process "${var_arch_name_upper}")
        else()
          set(var_unsupported_token_ignore 1)
          set(var_assign_ignore 1)
        endif()

        # other silent ignore checks...

        # os name filter is always defined even if was empty
        if (NOT var_assign_ignore AND NOT "${var_os_name_to_process}" STREQUAL "")
          if (NOT "${os_name_to_filter}" STREQUAL "")
            if(NOT "${var_os_name_to_process}" STREQUAL "${os_name_to_filter}")
              # silently ignore valid tokens that didn't pass the filter
              set(var_assign_ignore 1)
            endif()
          elseif (ignore_statement_if_no_filter)
            # silently ignore specialized tokens that does not have a filter specification
            set(var_assign_ignore 1)
          endif()
        endif()

        if (NOT var_assign_ignore AND NOT "${var_compiler_name_to_process}" STREQUAL "")
          if (NOT "${compiler_name_to_filter}" STREQUAL "")
            tkl_compare_compiler_tokens("${compiler_name_to_filter}" = "${var_compiler_name_to_process}" is_equal_config_compilers)
            if (NOT is_equal_config_compilers)
              # silently ignore valid tokens that didn't pass the filter
              set(var_assign_ignore 1)
            endif()
          elseif (ignore_statement_if_no_filter)
            # silently ignore specialized tokens that does not have a filter specification
            set(var_assign_ignore 1)
          endif()
        endif()

        if (NOT var_assign_ignore AND NOT is_config_name_value_can_late_expand)
          if (NOT "${var_config_name_to_process}" STREQUAL "")
            if (NOT "${config_name_to_filter}" STREQUAL "")
              if (NOT "${var_config_name_to_process}" STREQUAL "${config_name_to_filter}")
                # silently ignore valid tokens that didn't pass the filter
                set(var_assign_ignore 1)
              endif()
            elseif (ignore_statement_if_no_filter OR ignore_statement_if_no_filter_config_name)
              # silently ignore specialized tokens that does not have a filter specification
              set(var_assign_ignore 1)
            endif()
          endif()
        elseif (NOT "${var_config_name_to_process}" STREQUAL "" AND ignore_late_expansion_statements)
          # ignore tokens with late expansion
          set(var_assign_ignore 1)
        endif()

        if (NOT var_assign_ignore AND NOT "${var_arch_name_to_process}" STREQUAL "")
          if (NOT "${arch_name_to_filter}" STREQUAL "")
            if (NOT "${var_arch_name_to_process}" STREQUAL "${arch_name_to_filter}")
              # silently ignore valid tokens that didn't pass the filter
              set(var_assign_ignore 1)
            endif()
          elseif (ignore_statement_if_no_filter)
            # silently ignore specialized tokens that does not have a filter specification
            set(var_assign_ignore 1)
          endif()
        endif()

        if (var_invalid_token_ignore)
          message(WARNING "invalid variable token: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        elseif (var_unsupported_token_ignore)
          message(WARNING "unsupported variable token: `${file_path_abs}`(${var_file_content_line}): `${var_token}`")
        endif()

        # save current processing variable token
        set(var_token_suffix_to_process "${var_os_name_to_process}:${var_compiler_name_to_process}:${var_config_name_to_process}:${var_arch_name_to_process}")
        set(var_token_suffix "${var_os_name}:${var_compiler_name}:${var_config_name}:${var_arch_name}")

        set(is_var_in_ODR_check_list 0)

        # check variable on a collision to prevent the assignment
        set(do_spec_collision_check 1)

        if (grant_assign_for_vars_list)
          foreach(grant_var_name IN LISTS grant_assign_for_vars_list)
            if ("${grant_var_name}" STREQUAL "${var_name}")
              set(do_spec_collision_check 0)
              break()
            endif()
          endforeach()
        endif()

        if (do_spec_collision_check AND config_${var_name}_has_values_onchange_list AND
            grant_assign_on_vars_change_list AND NOT var_name IN_LIST grant_assign_on_vars_change_list)
          set(onchange_var_name_index -1)
          list(LENGTH config_${var_name}_var_values_onchange_list onchange_var_values_len)

          foreach(onchange_var_name IN LISTS grant_assign_on_vars_change_list)
            math(EXPR onchange_var_name_index ${onchange_var_name_index}+1)

            if (onchange_var_name_index LESS onchange_var_values_len)
              tkl_list_get(onchange_var_prev_value config_${var_name}_var_values_onchange_list ${onchange_var_name_index})
            else()
              set(onchange_var_prev_value "")
            endif()

            if (DEFINED config_${onchange_var_name})
              set(onchange_var_value "${config_${onchange_var_name}}")
            else()
              # CAUTION:
              #   `:` after `*` to workaround issue with the `os.path.abspath`: `os.path.abspath('$/{aa}/../bb')` would expand into invalid absolute path
              #
              set(onchange_var_value "*:\$/{${onchange_var_name}}")
            endif()

            #message("${onchange_var_name} => `${onchange_var_prev_value}` -> `${onchange_var_value}`")

            if (NOT "${onchange_var_value}" STREQUAL "${onchange_var_prev_value}")
              set(do_spec_collision_check 0) # has changed
              break()
            endif()
          endforeach()
        endif()

        if (do_spec_collision_check)
          if (config_${var_name}_defined)
            #message("[${var_name}:${var_os_name}:${var_compiler_name}:${var_config_name}:${arch_name}] config_${var_name}_config_name=`${config_${var_name}_config_name}`")

            # A variable is already assigned, but we have to check whether we can allow to specialize a variable.
            if (NOT use_force_var)
              # ignore a variable in case of not equal and not empty specializations
              if ((NOT "${config_${var_name}_os_name}" STREQUAL "" AND NOT "${var_os_name}" STREQUAL "" AND NOT "${config_${var_name}_os_name}" STREQUAL "${var_os_name}") OR
                  (NOT "${config_${var_name}_compiler_name}" STREQUAL "" AND NOT "${var_compiler_name}" STREQUAL "" AND NOT "${config_${var_name}_compiler_name}" STREQUAL "${var_compiler_name}") OR
                  (NOT "${config_${var_name}_config_name}" STREQUAL "" AND NOT "${var_config_name}" STREQUAL "" AND NOT "${config_${var_name}_config_name}" STREQUAL "${var_config_name}") OR
                  (NOT "${config_${var_name}_arch_name}" STREQUAL "" AND NOT "${var_arch_name}" STREQUAL "" AND NOT "${config_${var_name}_arch_name}" STREQUAL "${var_arch_name}"))
                set(var_specialization_ignore 1)
                set(var_assign_ignore 1)
              else()
                if ((("${config_${var_name}_os_name}" STREQUAL "") OR (NOT "${var_os_name}" STREQUAL "" AND "${config_${var_name}_os_name}" STREQUAL "${var_os_name}")) AND
                    (("${config_${var_name}_compiler_name}" STREQUAL "") OR (NOT "${var_compiler_name}" STREQUAL "" AND "${config_${var_name}_compiler_name}" STREQUAL "${var_compiler_name}")) AND
                    (("${config_${var_name}_config_name}" STREQUAL "") OR (NOT "${var_config_name}" STREQUAL "" AND "${config_${var_name}_config_name}" STREQUAL "${var_config_name}")) AND
                    (("${config_${var_name}_arch_name}" STREQUAL "") OR (NOT "${var_arch_name}" STREQUAL "" AND "${config_${var_name}_arch_name}" STREQUAL "${var_arch_name}")) AND
                    # but in case of specialization something must be set to not empty and not equal with the previous
                    ((NOT "${var_os_name}" STREQUAL "" AND NOT "${config_${var_name}_os_name}" STREQUAL "${var_os_name}") OR
                     (NOT "${var_compiler_name}" STREQUAL "" AND NOT "${config_${var_name}_compiler_name}" STREQUAL "${var_compiler_name}") OR
                     (NOT "${var_config_name}" STREQUAL "" AND NOT "${config_${var_name}_config_name}" STREQUAL "${var_config_name}") OR
                     (NOT "${var_arch_name}" STREQUAL "" AND NOT "${config_${var_name}_arch_name}" STREQUAL "${var_arch_name}")))
                  # is specialization, allow to change
                else()
                  # is not specialization, deny change in case...
                  # is a variable from the same level package?
                  if (config_package_nest_lvl EQUAL config_${var_name}_package_nest_lvl)
                    if (use_global_var)
                      message(FATAL_ERROR "The GLOBAL variable reassignment w/o FORCE attribute: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
                    endif()
                    if (NOT config_${var_name}_global_var AND use_local_var)
                      message(WARNING "The variable is already assigned in the same package and can be subsequently changed only through the specialization or by force: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
                      set(var_assign_ignore 1)
                    endif()
                  endif()
                endif()
              endif()
            endif()
          elseif (var_name IN_LIST _5A06EEFA_previous_vars_list)
            if (grant_external_vars_assign_in_files_list_c AND file_path_c IN_LIST grant_external_vars_assign_in_files_list_c)
              set (do_spec_collision_check 0)
            elseif (grant_external_vars_for_assign_list AND var_name IN_LIST grant_external_vars_for_assign_list)
              set (do_spec_collision_check 0)
            endif()

            if (do_spec_collision_check)
              # we must check the variable's value on equality with outside value in case if no `force` attribute declared
              if (NOT use_force_var)
                set(is_var_in_ODR_check_list 1)
              endif()
            endif()
          endif()
        endif()

        if (config_${var_name}_defined)
          # global
          if (config_${var_name}_global_var)
            if (use_top_package_var)
              message(FATAL_ERROR "The GLOBAL variable reassignment as TOP: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
            endif()
            if (NOT use_global_var AND NOT use_local_var)
              message(FATAL_ERROR "The GLOBAL variable reassignment as not GLOBAL/LOCAL: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
            endif()
          endif()

          # top
          if (config_${var_name}_top_package_var)
            if (use_global_var)
              message(FATAL_ERROR "The TOP variable reassignment as GLOBAL: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
            endif()
            if (use_local_var)
              message(FATAL_ERROR "The TOP variable reassignment as LOCAL: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
            endif()
            if (NOT use_top_package_var)
              message(FATAL_ERROR "The TOP variable reassignment as not TOP: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
            endif()
          endif()

          # local
          if (config_${var_name}_local_var)
            if (use_global_var)
              message(FATAL_ERROR "The LOCAL variable reassignment as GLOBAL: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
            endif()
            if (use_top_package_var)
              message(FATAL_ERROR "The LOCAL variable reassignment as TOP: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
            endif()
            if (NOT use_local_var)
              message(FATAL_ERROR "The LOCAL variable reassignment as not LOCAL: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${config_${var_name}_load_index}:${config_${var_name}_file_index}:${config_${var_name}_line}] `${config_${var_name}_os_name}:${config_${var_name}_compiler_name}:${config_${var_name}_config_name}:${config_${var_name}_arch_name}` -> [${config_load_index}:${file_path_index}:${var_file_content_line}] `${var_token_suffix}`")
            endif()
          endif()
        endif()

        # final (re)assignment with or without specialization or enable/disable
        if (NOT var_specialization_ignore AND config_${var_name}_defined AND config_${var_name}_final_var)
          if ((config_package_nest_lvl EQUAL config_${var_name}_package_nest_lvl) OR (NOT use_package_scope_var))
            message(FATAL_ERROR "The variable is a final specialization variable which can not be (re)assigned or enabled/disabled (except reenable or redisabled) anymore: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${var_os_name_upper}:${var_compiler_name_upper}:${var_config_name_upper}:${var_arch_name_upper}]")
          endif()
        endif()

        if (NOT var_assign_ignore)
          # all fatal checks has passed, continue with the non fatal
          set(ignore_top_package_var 0)
          if (config_${var_name}_defined)
            # is a variable from a different level package?
            if (NOT config_package_nest_lvl EQUAL config_${var_name}_package_nest_lvl)
              if (config_${var_name}_top_package_var AND use_top_package_var AND config_package_nest_lvl)
                # a top level package variable in a not top level package, ignore it
                set(ignore_top_package_var 1)
              endif()
            endif()
          endif()

          # ignore only after all checks
          if (ignore_top_package_var)
            # increment package definition counter
            if (config_${var_name}_package_nest_lvl EQUAL config_package_nest_lvl)
              math(EXPR config_${var_name}_package_defined ${config_${var_name}_package_defined}+1)
            else()
              math(EXPR config_${var_name}_package_defined 1)
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

            # increment global definition counter
            math(EXPR config_${var_name}_defined ${config_${var_name}_defined}+1)

            set(var_assign_ignore 1)
          endif()
        endif()

        # state machine parser flags and intermediate values
        set(is_str_quote_open 0)      # "..."
        set(is_list_bracket_open 0)   # bash shell style list: (...)
        set(is_list_bracket_closed 0)
        set(is_list_value 0)
        set(is_next_list_value 0)     # to append `;` before a not empty value
        set(is_subst_open 0)          # after `$/{`
        set(prev_char "")
        set(is_prev_char_escaped 0)

        # CAUTION:
        #   We DO NOT use `list(APPEND ...)` for this variable, so we don't need to make a not empty initial value for it,
        #   because `list(APPEND ...)` can not append an empty value to an empty list (needs not empty list at first place).
        #   Instead we use `set` to make an append, so may leave it empty here.
        #
        set(var_values_list "")       # collect all values as a list by default

        set(this_file_line "")
      else()
        if (is_subst_open)
          message(FATAL_ERROR "Internal parser error")
        endif()

        # append line return in a particular case
        if (NOT is_next_char_to_escape AND is_str_quote_open)
          set(var_values_list "${var_values_list}\n")
        endif()

        if (NOT is_next_char_to_escape)
          set(prev_char "\n")
          set(is_prev_char_escaped 1)

          if (NOT is_str_quote_open)
            if (NOT "${var_values_list}" STREQUAL "")
              set(is_next_list_value 1)
            endif()
          endif()
        endif()

        set(var_has_value 1)
        set(var_value "${var_line}")
        string(LENGTH "${var_value}" var_value_len)
      endif()

      if (is_next_char_to_escape)
        # pop open sequence context
        tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line)
        tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process )
        tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_line)
        tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_this_file_line)
      endif()

      # state machine parser flags and intermediate values, always resets irrespectively to multiline parser
      set(is_invalid_var_line 0)
      set(is_invalid_open_sequence 0)
      set(is_next_char_to_escape 0) # `$/<char>`, escape sequence does exist on a single line only
      set(value_from_index 0)

      # a variable's values parse stage
      if (var_value_len)
        math(EXPR var_value_len_range_max ${var_value_len}-1)

        foreach (index RANGE ${var_value_len_range_max})
          string(SUBSTRING "${var_value}" ${index} 1 char)

          #message(" - [${index}] `${prev_char}`->`${char}`: fi=`${value_from_index}` `\"`->${is_str_quote_open} `(`->${is_list_bracket_open} `\$/`->${is_next_char_to_escape} `\$/{`->${is_subst_open}")

          if (NOT is_next_char_to_escape)
            # special cases, must be processed separately
            if (NOT is_str_quote_open)
              # register not white space character sequence begin
              if ((NOT "${char}" STREQUAL " " AND NOT "${char}" STREQUAL "\t") AND
                  ("${prev_char}" STREQUAL "" OR "${prev_char}" STREQUAL " " OR "${prev_char}" STREQUAL "\t" OR "${prev_char}" STREQUAL "\n"))
                if (NOT "${var_values_list}" STREQUAL "")
                  set(is_next_list_value 1)
                endif()
                set(value_from_index ${index})
              endif()
            endif()

            if (("${char}" STREQUAL " ") OR ("${char}" STREQUAL "\t")) # not quoted separator characters
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                set(is_invalid_open_sequence 1)
                break()
              endif()

              if (NOT is_str_quote_open)
                # make a record after first a white space character after a not white character
                if (("${char}" STREQUAL " " OR "${char}" STREQUAL "\t") AND
                    (NOT "${prev_char}" STREQUAL "" AND NOT "${prev_char}" STREQUAL " " AND NOT "${prev_char}" STREQUAL "\t" AND NOT "${prev_char}" STREQUAL "\n"))
                  if (is_next_list_value)
                    set(var_values_list "${var_values_list};")
                    set(is_next_list_value 0)
                  endif()

                  # a list item end, record a value
                  math(EXPR value_len ${index}-${value_from_index})
                  string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)

                  # WORKAROUND: we have to replace because `list(APPEND` will join lists together
                  tkl_escape_string_before_list_append(value "${value}")

                  set(var_values_list "${var_values_list}${value}")
                  math(EXPR value_from_index ${index}+1) # next value begin index
                endif()
              endif()
            elseif ("${char}" STREQUAL "\$")
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                set(is_invalid_open_sequence 1)
                break()
              endif()
            elseif ("${char}" STREQUAL "/")
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                set(is_invalid_open_sequence 1)
                break()
              endif()

              if (NOT is_prev_char_escaped AND "${prev_char}" STREQUAL "\$")
                set(is_next_char_to_escape 1)

                # push open sequence context
                tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line ${var_file_content_line})
                tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process "${var_token_suffix_to_process}")
                tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_var_line "${var_line}")
                tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_this_file_line "${CMAKE_CURRENT_LIST_LINE}")
              endif()
            elseif ("${char}" STREQUAL "}")
              if (is_subst_open)
                # pop open sequence context
                tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line)
                tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process )
                tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_line)
                tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_this_file_line)

                set(is_subst_open 0)

                if (is_next_list_value)
                  set(var_values_list "${var_values_list};")
                  set(is_next_list_value 0)
                endif()

                # make a substitution
                math(EXPR value_len ${index}-${value_from_index})
                string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)
                if (DEFINED "config_${value}")
                  # WORKAROUND: we have to replace because `list(APPEND` will join lists together
                  tkl_escape_string_before_list_append(value "${config_${value}}")

                  set(var_values_list "${var_values_list}${value}")
                else()
                  # not found, replace by a placeholder

                  # WORKAROUND: we have to replace because `list(APPEND` will join lists together
                  tkl_escape_string_before_list_append(value "${value}")

                  # CAUTION:
                  #   `:` after `*` to workaround issue with the `os.path.abspath`: `os.path.abspath('$/{aa}/../bb')` would expand into invalid absolute path
                  #
                  set(var_values_list "${var_values_list}*:\$/{${value}}")
                endif()

                math(EXPR value_from_index ${index}+1)
              endif()
            elseif ("${char}" STREQUAL "\"")
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                set(is_invalid_open_sequence 1)
                break()
              endif()

              if (NOT is_str_quote_open)
                set(is_str_quote_open 1)

                # push open sequence context
                tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line ${var_file_content_line})
                tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process "${var_token_suffix_to_process}")
                tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_var_line "${var_line}")
                tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_this_file_line "${CMAKE_CURRENT_LIST_LINE}")
              else()
                # pop open sequence context
                tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line)
                tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process )
                tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_line)
                tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_this_file_line)

                if (NOT is_list_bracket_open)
                  # reset multiline parser
                  set(is_continue_parse_var_value 0)
                endif()

                set(is_str_quote_open 0)

                if (is_next_list_value)
                  set(var_values_list "${var_values_list};")
                  set(is_next_list_value 0)
                endif()

                # make a record
                math(EXPR value_len ${index}-${value_from_index})
                string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)

                # WORKAROUND: we have to replace because `list(APPEND` will join lists together
                tkl_escape_string_before_list_append(value "${value}")

                set(var_values_list "${var_values_list}${value}")
              endif()

              math(EXPR value_from_index ${index}+1) # next value begin index
            elseif ("${char}" STREQUAL "#")  # comment
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                set(is_invalid_open_sequence 1)
                break()
              endif()

              if (NOT is_str_quote_open)
                # end of processing, truncate a variable's value length
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(var_value_len ${index})
                break()
              endif()
            elseif ("${char}" STREQUAL "(")
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                set(is_invalid_open_sequence 1)
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
                  math(EXPR value_from_index ${index}+1) # next value begin index

                  # push open sequence context
                  tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line ${var_file_content_line})
                  tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process "${var_token_suffix_to_process}")
                  tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_var_line "${var_line}")
                  tkl_pushset_var_to_stack("tkl::set_vars_from_files" open_sequence_this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                else()
                  set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                  set(is_invalid_var_line 1)
                  set(is_invalid_open_sequence 1)
                  break()
                endif()
              endif()
            elseif ("${char}" STREQUAL ")")
              if (is_subst_open)
                set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                set(is_invalid_var_line 1)
                set(is_invalid_open_sequence 1)
                break()
              endif()

              if (NOT is_str_quote_open)
                if (is_list_bracket_open)
                  # pop open sequence context
                  tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line)
                  tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process )
                  tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_line)
                  tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_this_file_line)

                  # reset multiline parser
                  set(is_continue_parse_var_value 0)

                  set(is_list_bracket_open 0)
                  set(is_list_bracket_closed 1)

                  # make a record after a close bracket after a not white character
                  if (NOT "${prev_char}" STREQUAL "" AND NOT "${prev_char}" STREQUAL " " AND NOT "${prev_char}" STREQUAL "\t" AND NOT "${prev_char}" STREQUAL "\n")
                    if (is_next_list_value)
                      set(var_values_list "${var_values_list};")
                      set(is_next_list_value 0)
                    endif()

                    # a list item end, record a value
                    math(EXPR value_len ${index}-${value_from_index})
                    string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)

                    # WORKAROUND: we have to replace because `list(APPEND` will join lists together
                    tkl_escape_string_before_list_append(value "${value}")

                    set(var_values_list "${var_values_list}${value}")
                  endif()

                  break()
                else()
                  set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
                  set(is_invalid_var_line 1)
                  break()
                endif()
              endif()
            endif()

            set(is_prev_char_escaped 0)
          else()
            set(is_next_char_to_escape 0)

            # make a record before an escape sequence or a substitution begin sequence
            math(EXPR value_len ${index}-${value_from_index}-2)
            if (value_len GREATER 0)
              if (is_next_list_value)
                set(var_values_list "${var_values_list};")
                set(is_next_list_value 0)
              endif()

              string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)

              # WORKAROUND: we have to replace because `list(APPEND` will join lists together
              tkl_escape_string_before_list_append(value "${value}")

              set(var_values_list "${var_values_list}${value}")
            endif()

            if (NOT "${char}" STREQUAL "{")
              # pop open sequence context
              tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line)
              tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process )
              tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_line)
              tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_this_file_line)

              # insert escaped character
              if (NOT "${char}" STREQUAL ";")
                if ("${char}" STREQUAL "n")
                  set(var_values_list "${var_values_list}\n")
                elseif ("${char}" STREQUAL "r")
                  set(var_values_list "${var_values_list}\r")
                elseif ("${char}" STREQUAL "t")
                  set(var_values_list "${var_values_list}\t")
                elseif ("${char}" STREQUAL "b")
                  set(var_values_list "${var_values_list}\b")
                else()
                  set(var_values_list "${var_values_list}${char}")
                endif()
              else()
                set(var_values_list "${var_values_list}\;")
              endif()
            else()
              # register a substitution begin sequence
              set(is_subst_open 1)
            endif()

            math(EXPR value_from_index ${index}+1)

            set(is_prev_char_escaped 1)
          endif()

          set(prev_char "${char}")
        endforeach()

        if (NOT is_list_bracket_closed)
          if (NOT is_next_char_to_escape)
            if (NOT is_subst_open)
              # make a record from last line
              math(EXPR value_len ${var_value_len}-${value_from_index})
              if (value_len GREATER 0)
                if (is_next_list_value)
                  set(var_values_list "${var_values_list};")
                  set(is_next_list_value 0)
                endif()

                string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)

                # WORKAROUND: we have to replace because `list(APPEND` will join lists together
                tkl_escape_string_before_list_append(value "${value}")

                set(var_values_list "${var_values_list}${value}")
              endif()
            else()
              # make a record from last line incomplete substitution

              # CAUTION:
              #   `:` after `*` to workaround issue with the `os.path.abspath`: `os.path.abspath('$/{aa}/../bb')` would expand into invalid absolute path
              #
              set(var_values_list "${var_values_list}*:\$/{")

              math(EXPR value_len ${var_value_len}-${value_from_index})
              if (value_len GREATER 0)
                if (is_next_list_value)
                  set(var_values_list "${var_values_list};")
                  set(is_next_list_value 0)
                endif()

                string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)

                # WORKAROUND: we have to replace because `list(APPEND` will join lists together
                tkl_escape_string_before_list_append(value "${value}")

                set(var_values_list "${var_values_list}${value}")
              endif()
            endif()
          else()
            # make a record before an escape sequence
            math(EXPR value_len ${var_value_len}-${value_from_index}-2)
            if (value_len GREATER 0)
              if (is_next_list_value)
                set(var_values_list "${var_values_list};")
                set(is_next_list_value 0)
              endif()

              string(SUBSTRING "${var_value}" ${value_from_index} ${value_len} value)

              # WORKAROUND: we have to replace because `list(APPEND` will join lists together
              tkl_escape_string_before_list_append(value "${value}")

              set(var_values_list "${var_values_list}${value}")
            else()
              set(is_next_list_value 0) # reset
            endif()
          endif()
        endif()

        if (is_subst_open)
          set(is_continue_parse_var_value 0) # disable multiline parser
          set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
          set(is_invalid_var_line 1)
          set(is_invalid_open_sequence 1)
        elseif (is_next_char_to_escape OR is_str_quote_open OR is_list_bracket_open)
          set(is_continue_parse_var_value 1) # enable multiline parser
        else()
          set(is_continue_parse_var_value 0) # disable multiline parser
        endif()
      elseif (is_next_char_to_escape OR is_str_quote_open OR is_list_bracket_open)
        if (NOT is_continue_parse_var_value)
          message(FATAL_ERROR "Internal parser error")
        endif()
      else()
        set(is_continue_parse_var_value 0) # disable multiline parser
        set(this_file_line "${CMAKE_CURRENT_LIST_LINE}")
        set(is_invalid_var_line 1)
      endif()

      # finalization, all explicit state flags and values must be already unflagged, closed or processed
      if (NOT is_invalid_var_line)
        if (NOT var_assign_ignore AND NOT is_continue_parse_var_value)
          tkl_list_join(var_values_joined_list var_values_list "${list_separator_char}")

          set(set_vars_to_files -1) # unknown or not need to know
          if ((NOT is_config_name_value_can_late_expand) OR ("${var_config_name}" STREQUAL ""))
            if (NOT DEFINED var_names_file_path AND NOT DEFINED var_values_file_path)
              set(set_vars_to_files 0)
            else()
              set(set_vars_to_files 1)
            endif()
          endif()

          set(is_bool_var_value 0)
          set(is_path_var_value -1) # unknown or not need to know

          if (is_var_in_ODR_check_list OR ((set_vars_to_files LESS 1) AND set_vars))
            if ("${var_type}" STREQUAL "bool")
              set(is_bool_var_value 1)
            elseif ("${var_type}" STREQUAL "path")
              set(is_path_var_value 1)
            elseif (NOT compare_var_paths_as_case_sensitive)
              # detect variable type by variable name variants
              tkl_is_path_var_by_name(is_path_var_value "${var_name}")
            endif()
          endif()

          # validate if variable has already existed and is an ODR variable

          set(var_parsed_value "${var_values_joined_list}")
          # escape all `\;` sequences to iterate it as a path list through the `foreach`
          if ("${var_type}" STREQUAL "path")
            string(REGEX REPLACE "([^\\\\])\\\\;" "\\1/;" var_parsed_value "${var_parsed_value}")
          endif()

          # validate if variable has already existed and is an ODR variable
          if (is_var_in_ODR_check_list)
            list(FIND _5A06EEFA_previous_vars_list "${var_name}" previous_var_index)
            if (previous_var_index GREATER_EQUAL 0) # still can be less
              list(GET _5A06EEFA_previous_var_values_list ${previous_var_index} previous_var_value) # discardes ;-escaping
            else()
              set(previous_var_value "")
            endif()

            if (is_bool_var_value)
              # make values boolean
              if (previous_var_value)
                set(previous_var_value_boolean 1)
              else()
                set(previous_var_value_boolean 0)
              endif()
              if (var_parsed_value)
                set(var_parsed_value_boolean 1)
              else()
                set(var_parsed_value_boolean 0)
              endif()
            endif()

            set(is_vars_equal 0)
            if (NOT is_path_var_value GREATER 0)
              if ((is_bool_var_value AND (previous_var_value_boolean EQUAL var_parsed_value_boolean)) OR
                  (NOT is_bool_var_value AND ("${previous_var_value}" STREQUAL "${var_parsed_value}")))
                set(is_vars_equal 1)
              endif()
            else()
              set(previous_var_value_list "")
              set(var_parsed_value_list "")

              foreach(previous_var_value_item IN LISTS previous_var_value)
                # WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
                tkl_escape_string_after_list_get(previous_var_value_item "${previous_var_value_item}")

                tkl_make_comparable_path(previous_var_value_item "${previous_var_value_item}" . compare_var_paths_as_case_sensitive 1)

                if (NOT "${previous_var_value_list}" STREQUAL "")
                  set(previous_var_value_list "${previous_var_value_list};${previous_var_value_item}")
                else()
                  set(previous_var_value_list "${previous_var_value_item}")
                endif()
              endforeach()

              foreach(var_parsed_value_item IN LISTS var_parsed_value)
                # WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
                tkl_escape_string_after_list_get(var_parsed_value_item "${var_parsed_value_item}")

                tkl_make_comparable_path(var_parsed_value_item "${var_parsed_value_item}" . compare_var_paths_as_case_sensitive 1)

                if (NOT "${var_parsed_value_list}" STREQUAL "")
                  set(var_parsed_value_list "${var_parsed_value_list};${var_parsed_value_item}")
                else()
                  set(var_parsed_value_list "${var_parsed_value_item}")
                endif()
              endforeach()

              tkl_is_equal_paths(is_vars_equal . "${previous_var_value_list}" "${var_parsed_value_list}" ${compare_var_paths_as_case_sensitive} 1)
            endif()

            if (NOT is_vars_equal)
              message(FATAL_ERROR "ODR violation, variables must declare the same value: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${var_os_name_upper}:${var_compiler_name_upper}:${var_config_name_upper}:${var_arch_name_upper}] -> [${var_token_suffix_to_process}]: `${previous_var_value}` -> `${var_parsed_value}` (is_path=`${is_path_var_value}`)")
            endif()

            # use previous value to avoid a value change, but apply all related attributes
            set(var_parsed_value "${${var_name}}")
          endif()

          # convert to the canonical
          if (use_canonical_value)
            if ("${var_type}" STREQUAL "path")
              string(REPLACE "\\" "/" var_parsed_value "${var_parsed_value}")
            endif()
          endif()

          # check variable's value on existence
          if ("${var_type}" STREQUAL "path" AND use_existed_value)
            foreach(path_var_value IN LISTS var_parsed_value)
              # WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
              tkl_escape_string_after_list_get(path_var_value "${path_var_value}")

              if (NOT EXISTS "${path_var_value}")
                if ("${var_parsed_value}" STREQUAL "${path_var_value}")
                  message(FATAL_ERROR "Path value from the variable does not exist: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${var_token_suffix_to_process}]: `${path_var_value}`")
                else()
                  message(FATAL_ERROR "Path value from the variable does not exist: `${file_path_abs}`(${var_file_content_line}): `${var_set_msg_name_attr_prefix_str}${var_name}` => [${var_token_suffix_to_process}]: `${var_parsed_value}` => `${path_var_value}`")
                endif()
              endif()
            endforeach()
          endif()

          # A variable with not late expansion expression or a variable with configuration specialized late expansion (generator) expression (`var_config_name` is empty)
          if ((NOT is_config_name_value_can_late_expand) OR ("${var_config_name}" STREQUAL ""))
            if (set_vars_to_files LESS 1)
              if (set_vars)
                # cache always must be set at first
                if (use_only_cache_var OR use_cache_var)
                  if (NOT config_${var_name}_hidden_var_cache)
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
                  elseif (use_force_cache_var) # the same condition as for a usual cache variable
                    # in quotes to enable a save variable's type as a list
                    set(config_${var_name}_hidden_var_cache_value "${var_parsed_value}")
                    set(config_${var_name}_hidden_var_cache_type ${cache_var_type})
                    set(config_${var_name}_hidden_var_cache_with_force 1)
                  endif()
                endif()

                if (NOT use_only_cache_var AND NOT use_only_env_var)
                  if (NOT config_${var_name}_hidden_var)
                    # in quotes to enable a save variable's type as a list
                    set(${var_name} "${var_parsed_value}" PARENT_SCOPE)

                    if (use_uncache_var)
                      unset(${var_name} CACHE)
                    endif()
                  else()
                    # set instead the hidden variable storage
                    set(config_${var_name}_hidden_var_value "${var_parsed_value}")

                    if (use_uncache_var)
                      set(config_${var_name}_hidden_var_cache 0)
                      unset(config_${var_name}_hidden_var_cache_value)
                    endif()
                  endif()
                endif()

                if (use_only_env_var OR use_env_var)
                  if (NOT config_${var_name}_hidden_env_var)
                    # in quotes to enable a save variable's type as a list
                    set(ENV{${var_name}} "${var_parsed_value}")
                  else()
                    # in quotes to enable a save variable's type as a list
                    set(config_${var_name}_hidden_var_env_value "${var_parsed_value}")
                  endif()
                endif()
              elseif (set_env_vars)
                if (NOT config_${var_name}_hidden_env_var)
                  # in quotes to enable a save variable's type as a list
                  set(ENV{${var_name}} "${var_parsed_value}")
                else()
                  # in quotes to enable a save variable's type as a list
                  set(config_${var_name}_hidden_var_env_value "${var_parsed_value}")
                endif()
              endif()
            else()
              if (DEFINED var_lines_file_path)
                tkl_file_append("${var_lines_file_path}" "${var_file_content_line}\n")
              endif()
              if (DEFINED var_names_file_path)
                tkl_file_append("${var_names_file_path}" "${var_name}\n")
              endif()
              if (DEFINED var_values_file_path)
                # truncate by line return
                if (var_parsed_value MATCHES "([^\r\n]*)")
                  tkl_file_append("${var_values_file_path}" "${CMAKE_MATCH_1}\n")
                else()
                  tkl_file_append("${var_values_file_path}" "${var_parsed_value}\n")
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

              if ("${config_${var_name}}" STREQUAL "${var_parsed_value}")
                set(var_set_msg_suffix_str "")
              else()
                set(var_set_msg_suffix_str " (`${var_parsed_value}`)")
              endif()

              if (use_override_var)
                if (var_set_msg_suffix_str)
                  set(var_set_msg_suffix_str " (overriden)${var_set_msg_suffix_str}")
                else()
                  set(var_set_msg_suffix_str " (overriden)")
                endif()
              endif()

              message("[${config_load_index}:${file_path_index}:${var_file_content_line}] [${var_token_suffix_note}] ${var_set_msg_name_attr_prefix_str}${var_name}=`${config_${var_name}}`${var_set_msg_suffix_str}")
            endif()

            # increment package definition counter
            if (config_${var_name}_package_nest_lvl EQUAL config_package_nest_lvl)
              math(EXPR config_${var_name}_package_defined ${config_${var_name}_package_defined}+1)
            else()
              math(EXPR config_${var_name}_package_defined 1)
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

            if ((NOT config_${var_name}_defined) OR
                (NOT config_package_nest_lvl EQUAL config_${var_name}_package_nest_lvl))
              set(config_${var_name}_global_var ${use_global_var})
              set(config_${var_name}_top_package_var ${use_top_package_var})
              set(config_${var_name}_local_var ${use_local_var})
              set(config_${var_name}_final_var ${use_final_var})
              set(config_${var_name}_package_scope_var ${use_package_scope_var})
            endif()

            if (grant_assign_on_vars_change_list AND NOT var_name IN_LIST grant_assign_on_vars_change_list)
              # WORKAROUND: empty list with one empty string treats as an empty list, but not with 2 empty strings!
              set(config_${var_name}_var_values_onchange_list ";")
              set(config_${var_name}_has_values_onchange_list 1)

              foreach (onchange_var_name IN LISTS grant_assign_on_vars_change_list)
                if (DEFINED config_${onchange_var_name})
                  list(APPEND config_${var_name}_var_values_onchange_list "${config_${onchange_var_name}}")
                else()
                  # use special unexisted directory value to differentiate it from the defined empty value

                  # CAUTION:
                  #   `:` after `*` to workaround issue with the `os.path.abspath`: `os.path.abspath('$/{aa}/../bb')` would expand into invalid absolute path
                  #
                  list(APPEND config_${var_name}_var_values_onchange_list "*:\$/{${onchange_var_name}}")
                endif()
              endforeach()

              # remove 2 first dummy empty strings
              tkl_list_remove_sublist(config_${var_name}_var_values_onchange_list 0 2 config_${var_name}_var_values_onchange_list)
            endif()

            # increment global definition counter
            math(EXPR config_${var_name}_defined ${config_${var_name}_defined}+1)

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

            if(NOT DEFINED config_gen_defined_forall_${var_name})
              set(config_gen_defined_forall_${var_name} 0)
            endif()
            if(NOT DEFINED config_gen_names_for_${var_name})
              set(config_gen_names_for_${var_name} "")
            endif()

            # save variable's value as a generator expression
            if ("${var_config_name}" STREQUAL "")
              # special syntax to hold an unescaped value for "all others" configurations
              set(config_gen_forall_${var_name} "${var_parsed_value}")
              set(config_gen_defined_forall_${var_name} 1)
            else()
              set(config_gen_for_${var_config_name}_${var_name} "${var_parsed_value}")
              list(FIND config_gen_names_for_${var_name} "${var_config_name}" config_gen_name_index) # just in case
              if (config_gen_name_index LESS 0)
                list(APPEND config_gen_names_for_${var_name} "${var_config_name}")
              endif()
            endif()
          endif()
        endif()
      else()
        if (is_invalid_open_sequence)
          message(WARNING "Invalid open sequence: `${file_path_abs}`(${open_sequence_var_file_content_line})(${open_sequence_this_file_line}): `${open_sequence_var_token_suffix_to_process}`: `${open_sequence_var_line}`")

          if (is_subst_open)
            # pop open sequence context
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line)
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process )
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_line)
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_this_file_line)

            set(is_subst_open 0)
          endif()

          if (is_str_quote_open)
            # pop open sequence context
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line)
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process )
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_line)
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_this_file_line)
          endif()

          if (is_str_quote_open)
            # pop open sequence context
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line)
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process )
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_line)
            tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_this_file_line)
          endif()
        else()
          message(WARNING "Invalid variable line: `${file_path_abs}`(${var_file_content_line})(${this_file_line}): `${var_token_suffix_to_process}`: `${var_line}`")
        endif()

        continue()
      endif()
    endforeach()

    if (is_next_char_to_escape OR is_str_quote_open OR is_list_bracket_open)
      message(WARNING "Invalid variable line: (${is_next_char_to_escape},${is_str_quote_open},${is_list_bracket_open}) `${file_path_abs}`(${var_file_content_line})(${this_file_line}): `${var_token_suffix_to_process}`: `${var_line}`")

      # pop open sequence context
      tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_file_content_line)
      tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_token_suffix_to_process )
      tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_var_line)
      tkl_pop_var_from_stack("tkl::set_vars_from_files" open_sequence_this_file_line)
    endif()
  endforeach()

  if (is_next_char_to_escape OR is_str_quote_open OR is_list_bracket_open)
    message(WARNING "not closed character sequence: `${file_path_abs}`(${open_sequence_var_file_content_line})(${open_sequence_this_file_line}): `${open_sequence_var_token_suffix_to_process}`: `${open_sequence_var_line}`")
  endif()

  if (DEFINED flock_file_path)
    file(LOCK "${flock_file_path}" RELEASE)
    tkl_file_remove_recurse("${flock_file_path}")
  endif()

  # save state
  if (save_state_into_cmake_global_properties_prefix)
    set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_load_index
      "${config_load_index}")

    #message("saving: vars: `${config_var_names}`")
    set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_var_names "${config_var_names}")

    foreach(config_var_name IN LISTS config_var_names)
      #message("config_var_name=`${config_var_name}` -> `${config_${config_var_name}_file_path_c}`")

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}
        "${config_${config_var_name}}")

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_defined
        "${config_${config_var_name}_defined}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_package_defined
        "${config_${config_var_name}_package_defined}")

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

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_hidden_var
        "${config_${config_var_name}_hidden_var}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_value
        "${config_${config_var_name}_hidden_var_value}")

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_cache
        "${config_${config_var_name}_hidden_var_cache}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_cache_value
        "${config_${config_var_name}_hidden_var_cache_value}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_cache_type
        "${config_${config_var_name}_hidden_var_cache_type}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_cache_docstring
        "${config_${config_var_name}_hidden_var_cache_decstring}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_cache_with_force
        "${config_${config_var_name}_hidden_var_cache_with_force}")

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_env
        "${config_${config_var_name}_hidden_var_env}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_hidden_var_env_value
        "${config_${config_var_name}_hidden_var_env_value}")

      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_global_var
        "${config_${config_var_name}_global_var}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_top_package_var
        "${config_${config_var_name}_top_package_var}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_local_var
        "${config_${config_var_name}_local_var}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_final_var
        "${config_${config_var_name}_final_var}")
      set_property(GLOBAL PROPERTY ${save_state_into_cmake_global_properties_prefix}config_${config_var_name}_package_scope_var
        "${config_${config_var_name}_package_scope_var}")

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
        string(REPLACE "\;" "\\\;" gen_var_escaped_value "${config_gen_for_${gen_config_name}_${gen_var_name}}")
        list(APPEND gen_var_escaped_values "${gen_var_escaped_value}")
      endforeach()
      set(gen_var_names "${config_gen_names_for_${gen_var_name}}")

      if (config_gen_defined_forall_${gen_var_name})
        list(APPEND gen_var_names "*")
        string(REPLACE "\;" "\\\;" gen_var_escaped_value "${config_gen_forall_${gen_var_name}}")
        list(APPEND gen_var_escaped_values "${gen_var_escaped_value}")
      endif()

      string(REPLACE "\;" "\\\;" gen_var_escaped_names "${gen_var_names}")
      string(REPLACE "\;" "\\\;" gen_var_dbl_escaped_values "${gen_var_escaped_values}")

      list(APPEND config_gen_names_list "${gen_var_escaped_names}")
      list(APPEND config_gen_values_list "${gen_var_dbl_escaped_values}")
    endforeach()

    # remove 2 first dummy empty strings
    tkl_list_remove_sublist(config_gen_values_list 0 2 config_gen_values_list1)
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
#     out_var_config_gen_var_lines_list - list of text line numbers from the source, where a variable has been declared
#     out_var_config_gen_vars_list      - list of variable names
#     out_var_config_gen_names_list     - list of variable configuration names (RELEASE/DEBUG/...)
#     out_var_config_gen_values_list    - list of variable values
#
# flags:
#   The same as in `tkl_set_vars_from_files` function plus these:
#   -F - additionally set full complement variables (if instead of multi variant configuration set has used only the all placeholder - `*`,
#        this means `all configurations` (these kind of variables does not need to be set in this stage because already has been set in previous))
#
function(tkl_set_multigen_vars_from_lists) # WITH OUT ARGUMENTS!
  if (NOT ${ARGC} GREATER_EQUAL 4)
    message(FATAL_ERROR "function must be called at least with 4 not optional arguments: `${ARGC}`")
  endif()

  # Parent variable are saved, now can create local variables!
  tkl_get_cmake_role(is_in_script_mode SCRIPT)

  if (NOT is_in_script_mode)
    # CMAKE_CONFIGURATION_TYPES consistency check, in case if not script mode
    tkl_check_CMAKE_CONFIGURATION_TYPES_vs_multiconfig()
  endif()

  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" . argn)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_vars_from_ARGV_ARGN_end(. argn)

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
  tkl_parse_function_optional_flags_into_vars(
    argn_index
    argn
    "p;e;E;F;a;S;s"
    "E\;set_vars"
    "p\;print_vars_set;e\;set_env_vars;E\;set_env_vars;F\;set_on_full_complement_config;a\;append_to_files;S\;script_mode;s\;silent_mode"
    "varlines\;.\;var_lines_file_path;vars\;.\;var_names_file_path;values\;.\;var_values_file_path;flock\;.\;flock_file_path;\
ignore_statement_if_no_filter;ignore_statement_if_no_filter_config_name;ignore_late_expansion_statements;\
grant_external_vars_for_assign\;.\;.;\
grant_external_vars_assign_in_files\;.\;.;\
grant_assign_for_vars\;.\;.;\
grant_assign_on_vars_change\;.\;.;\
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

  tkl_list_get(config_gen_var_lines_list_var argn ${argn_index})
  math(EXPR argn_index ${argn_index}+1)

  tkl_list_get(config_gen_vars_list_var argn ${argn_index})
  math(EXPR argn_index ${argn_index}+1)

  tkl_list_get(config_gen_names_list_var argn ${argn_index})
  math(EXPR argn_index ${argn_index}+1)

  tkl_list_get(config_gen_values_list_var argn ${argn_index})
  math(EXPR argn_index ${argn_index}+1)

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
    tkl_file_lock("${flock_file_path}" FILE)
  endif()
  if (NOT append_to_files)
    if (DEFINED var_lines_file_path)
      tkl_file_write("${var_lines_file_path}" "")
    endif()
    if (DEFINED var_names_file_path)
      tkl_file_write("${var_names_file_path}" "")
    endif()
    if (DEFINED var_values_file_path)
      tkl_file_write("${var_values_file_path}" "")
    endif()
  endif()

  set(var_index -1)

  foreach(var_name IN LISTS config_gen_vars_list)
    math(EXPR var_index ${var_index}+1)

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
      math(EXPR var_config_name_index ${var_config_name_index}+1)

      list(GET var_values ${var_config_name_index} var_value) # discardes ;-escaping

      if (NOT "${var_config_name}" STREQUAL "*")
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
        math(EXPR var_config_name_index ${var_config_name_index}+1)

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
        tkl_file_append("${var_lines_file_path}" "${var_line}\n")
      endif()
      if (DEFINED var_names_file_path)
        tkl_file_append("${var_names_file_path}" "${var_name}\n")
      endif()
      if (DEFINED var_values_file_path)
        # truncate by line return
        if (var_multigen_value MATCHES "([^\r\n]*)")
          tkl_file_append("${var_values_file_path}" "${CMAKE_MATCH_1}\n")
        else()
          tkl_file_append("${var_values_file_path}" "${var_multigen_value}\n")
        endif()
      endif()
    endif()
  endforeach()

  if (DEFINED flock_file_path)
    file(LOCK "${flock_file_path}" RELEASE)
    tkl_file_remove_recurse("${flock_file_path}")
  endif()
endfunction()

endif()
