# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_EVAL_INCLUDE_DEFINED)
set(TACKLELIB_EVAL_INCLUDE_DEFINED 1)

include(tacklelib/Std)
include(tacklelib/MakeTemp)
include(tacklelib/Reimpl)
include(tacklelib/ForwardVariables)

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

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_eval) # WITH OUT ARGUMENTS!
  tkl_begin_track_vars()

  #message("=${ARGV}=")
  #message("=${ARGN}=")
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" "" _67AB359F_eval_str)
  # in case of in a function call we don't have to pass all ARGV arguments explicitly
  tkl_make_vars_from_ARGV_ARGN_end("" _67AB359F_eval_str)

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTPROC_INDEX "tkl::testlib::testproc::index" 1)

  if (NOT TACKLELIB_TESTLIB_TESTPROC_INDEX STREQUAL "")
    # running under TestLib, the macro can call under different cmake process when the inner timestamp is not yet changed (timestamp has seconds resolution)
    tkl_make_temp_dir("CMake.Eval." "%Y'%m'%d''%H'%M'%SZ" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}" 8 _67AB359F_temp_dir_path)
  else()
    tkl_make_temp_dir("CMake.Eval." "%Y'%m'%d''%H'%M'%SZ" "" 8 _67AB359F_temp_dir_path)
  endif()

  unset(TACKLELIB_TESTLIB_TESTPROC_INDEX)

  # builtin variables for the `eval` self testing from the `TestLib`
  set_property(GLOBAL PROPERTY "tkl::eval::last_temp_dir_path" "${_67AB359F_temp_dir_path}")

  tkl_encode_control_chars_for_eval("${_67AB359F_eval_str}" _67AB359F_eval_str)

  set_property(GLOBAL PROPERTY "tkl::eval::last_str" "${_67AB359F_eval_str}")

  get_property(_67AB359F_is_eval_enabled GLOBAL PROPERTY "tkl::eval::enabled")
  if (_67AB359F_is_eval_enabled)
    set(_67AB359F_include_str "\
unset(_67AB359F_temp_dir_path)

# cleanup before evaluate
tkl_file_remove_recurse(\"${_67AB359F_temp_dir_path}\")

# evaluating...
${_67AB359F_eval_str}
")

    # CAUTION:
    #   This conversion required ONLY if `file(...)` is reimplemented as a macro, which is by default in the `File.cmake`!
    #   For details: https://gitlab.kitware.com/cmake/cmake/issues/19281
    #
    tkl_get_reimpl_prop(file . TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file)

    if (TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file STREQUAL "macro")
      tkl_encode_control_chars_for_macro("${_67AB359F_include_str}" _67AB359F_include_str)
    endif()

    unset(TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file)

    file(WRITE "${_67AB359F_temp_dir_path}/include.cmake" "${_67AB359F_include_str}")

    unset(_67AB359F_is_eval_enabled)
    unset(_67AB359F_eval_str)

    # evaluating...
    include("${_67AB359F_temp_dir_path}/include.cmake")

    tkl_forward_changed_vars_to_parent_scope()
  else()
    unset(_67AB359F_temp_dir_path)
    unset(_67AB359F_eval_str)
  endif()

  tkl_end_track_vars()
endfunction()

tkl_register_implementation(function tkl_eval)

endif()
