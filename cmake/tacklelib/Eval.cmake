# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_EVAL_INCLUDE_DEFINED)
set(TACKLELIB_EVAL_INCLUDE_DEFINED 1)

include(tacklelib/Std)
include(tacklelib/MakeTemp)
include(tacklelib/Reimpl)

# Usage:
#   Special characters:
#     `\`   - escape sequence character
#     `\n`  - multiline separator
#   Escape examples:
#     `$\\{...}` or `\\\${...}` - to insert a variable expression without expansion
#
# CAUTION:
#   You have to be careful with expressions passed into the function, because
#   `tkl_eval` is a macro and a macro in the cmake having specific arguments
#   expansion when the entire expansion feature in the cmake having issues.
#
#   Here is several issues related to the macro/variable/string expansion:
#
#   * `string escape sequence depends on macro call nesting level : "\\\${a}" -> "\\\\\\\${a}" -> "\\\\\\\\\\\\\\\${a}"` :
#      https://gitlab.kitware.com/cmake/cmake/issues/19281
#   *  `;-escape list implicit unescaping` :
#      https://gitlab.kitware.com/cmake/cmake/issues/18946
#   *  `Not paired `]` or `[` characters breaks "file(STRINGS` :
#      https://gitlab.kitware.com/cmake/cmake/issues/19156
#
#   Other issues which might be important too:
#
#   * `file(REMOVE_RECURSE "")` removes everything from current working directory` :
#      https://gitlab.kitware.com/cmake/cmake/issues/19274
#   * `CMAKE_CONFIGURATION_TYPES is not empty when empty` :
#      https://gitlab.kitware.com/cmake/cmake/issues/19057
#   *  `file(LOCK ./lock GUARD FILE)` is broken in script mode` :
#      https://gitlab.kitware.com/cmake/cmake/issues/19007
#

set_property(GLOBAL PROPERTY "tkl::eval::enabled" 1)

macro(tkl_eval)
  #message("=${ARGV}=")
  #message("=${ARGN}=")
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" "" _67AB359F_eval_str)
  # in case of in a macro call we must pass all ARGV arguments explicitly
  tkl_set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_vars_from_ARGV_ARGN_end("" _67AB359F_eval_str)
  tkl_unset_ARGV()
  #message("tkl_eval: argn=${_67AB359F_eval_str}")

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTPROC_INDEX "tkl::testlib::testproc::index" 1)

  if (NOT TACKLELIB_TESTLIB_TESTPROC_INDEX STREQUAL "")
    # running under TestLib, the macro can call under different cmake process when the inner timestamp is not yet changed (timestamp has seconds resolution)
    tkl_make_temp_dir("CMake.Eval." "%Y'%m'%d''%H'%M'%SZ" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}" 8 _67AB359F_temp_dir_path)
  else()
    tkl_make_temp_dir("CMake.Eval." "%Y'%m'%d''%H'%M'%SZ" "" 8 _67AB359F_temp_dir_path)
  endif()

  # builtin variables for the `eval` self testing from the `TestLib`
  set(TACKLELIB_EVAL_LAST_TEMP_DIR_PATH "${_67AB359F_temp_dir_path}")

  tkl_decode_control_chars("${_67AB359F_eval_str}" _67AB359F_eval_str)

  # CAUTION:
  #   This conversion is required ONLY if `file(...)` is reimplemented as a macro, which is by default in the `File.cmake`!
  #   For details: https://gitlab.kitware.com/cmake/cmake/issues/19281
  #
  tkl_get_reimpl_prop(file)

  if (TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file STREQUAL "macro")
    tkl_escape_list_expansion(_67AB359F_eval_str "${_67AB359F_eval_str}")
  endif()

  set(TACKLELIB_EVAL_LAST_STR "${_67AB359F_eval_str}")

  get_property(_67AB359F_is_eval_enabled GLOBAL PROPERTY "tkl::eval::enabled")
  if (_67AB359F_is_eval_enabled)
    # 1. drop local variables at begin
    # 2. the expression at the middle
    # 3. self cleanup at the end
    file(WRITE "${_67AB359F_temp_dir_path}/include.cmake" "\
unset(_67AB359F_temp_dir_path)
unset(_67AB359F_eval_str)

# cleanup before evaluate
tkl_file_remove_recurse(\"${_67AB359F_temp_dir_path}\")

# evaluating...
${_67AB359F_eval_str}
")

    # evaluating...
    include("${_67AB359F_temp_dir_path}/include.cmake")
  else()
    unset(_67AB359F_temp_dir_path)
    unset(_67AB359F_eval_str)
  endif()
endmacro()

tkl_register_implementation(macro tkl_eval)

endif()