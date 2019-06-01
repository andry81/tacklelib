# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_EVAL_INCLUDE_DEFINED)
set(TACKLELIB_EVAL_INCLUDE_DEFINED 1)

include(tacklelib/Std)
include(tacklelib/MakeTemp)
include(tacklelib/Props)
include(tacklelib/Reimpl)
include(tacklelib/ForwardVariables)

# Usage:
#   Special characters:
#     `\`   - escape sequence character
#     `\n`  - multiline separator
#   Escape examples:
#     `$\\{...}` or `\${...}` - to insert a variable expression without expansion
#
# CAUTION:
#   You have to be careful with expressions passed into a macro, because a macro
#   in the cmake having a specific arguments expansion passes when the entire expansion
#   feature in the cmake having issues.
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
function(tkl_eval_begin include_file_name str)
  if (NOT ${ARGC} EQUAL 2)
    message(FATAL_ERROR "function must have 2 arguments")
  endif()

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTPROC_INDEX "tkl::testlib::testproc::index" 1)

  if (NOT TACKLELIB_TESTLIB_TESTPROC_INDEX STREQUAL "")
    # running under TestLib, the macro can call under different cmake process when the inner timestamp is not yet changed (timestamp has seconds resolution)
    tkl_make_temp_dir("CMake.Eval." "%Y'%m'%d''%H'%M'%SZ" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}" 8 eval_temp_dir_path)
  else()
    tkl_make_temp_dir("CMake.Eval." "%Y'%m'%d''%H'%M'%SZ" "" 8 eval_temp_dir_path)
  endif()

  unset(TACKLELIB_TESTLIB_TESTPROC_INDEX)

  tkl_pushset_prop_to_stack(. GLOBAL "tkl::eval::last_include_dir_path" "${eval_temp_dir_path}")
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::eval::last_include_file_name" "${include_file_name}")
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::eval::last_include_file_path" "${eval_temp_dir_path}/${include_file_name}")

  set(eval_include_str "\
unset(_67AB359F_eval_include_file_path)

# cleanup before evaluate
tkl_file_remove_recurse(\"${eval_temp_dir_path}\")

# evaluating...
")

  if (NOT str STREQUAL "")
    set(eval_include_str "${eval_include_str}${str}")
  endif()

  tkl_file_write("${eval_temp_dir_path}/${include_file_name}" "${eval_include_str}")
endfunction()

tkl_register_implementation(function tkl_eval_begin)

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_eval_append begin_include_file_name str)
  if (NOT ${ARGC} EQUAL 2)
    message(FATAL_ERROR "function must have 2 arguments")
  endif()

  if (str STREQUAL "")
    message(FATAL_ERROR "string must be not empty")
  endif()

  tkl_get_last_eval_include_file_name(eval_include_file_name)

  if (NOT eval_include_file_name STREQUAL "${begin_include_file_name}")
    message(FATAL_ERROR "begin_include_file_name for the `tkl_eval_append` must be the same as for the `tkl_eval_begin*`: tkl_eval_begin*->`${eval_include_file_name}` tkl_eval_end->`${begin_include_file_name}`")
  endif()

  tkl_get_last_eval_include_file_path(eval_include_file_path)

  tkl_file_append("${eval_include_file_path}" "${str}\n")
endfunction()

tkl_register_implementation(function tkl_eval_append)

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_eval_append_from_file begin_include_file_name file_path)
  if (NOT ${ARGC} EQUAL 2)
    message(FATAL_ERROR "function must have 2 arguments")
  endif()

  if ("${file_path}" STREQUAL "" OR NOT EXISTS "${file_path}" OR IS_DIRECTORY "${file_path}")
    message(FATAL_ERROR "file_path must be an existing file path to evaluate from: file_path=`${file_path}`")
  endif()

  tkl_get_last_eval_include_file_name(eval_include_file_name)

  if (NOT eval_include_file_name STREQUAL "${begin_include_file_name}")
    message(FATAL_ERROR "begin_include_file_name for the `tkl_eval_append_from_file` must be the same as for the `tkl_eval_begin*`: tkl_eval_begin*->`${eval_include_file_name}` tkl_eval_end->`${begin_include_file_name}`")
  endif()

  tkl_get_last_eval_include_file_path(eval_include_file_path)

  tkl_file_append_from_file("${eval_include_file_path}" "${file_path}" "" "\n")
endfunction()

tkl_register_implementation(function tkl_eval_append_from_file)

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_eval_end begin_include_file_name end_include_file_path)
  if (NOT ${ARGC} EQUAL 2)
    message(FATAL_ERROR "function must have 2 arguments")
  endif()

  if ((NOT "${end_include_file_path}" STREQUAL "" AND NOT "${end_include_file_path}" STREQUAL ".") AND
      (NOT EXISTS "${end_include_file_path}" OR IS_DIRECTORY "${end_include_file_path}"))
    message(FATAL_ERROR "end_include_file_path if is not empty then must be an existing file path to include: end_include_file_path=`${end_include_file_path}`")
  endif()

  tkl_get_last_eval_include_file_name(eval_include_file_name)

  if (NOT eval_include_file_name STREQUAL "${begin_include_file_name}")
    message(FATAL_ERROR "begin_include_file_name for the `tkl_eval_end` must be the same as for the `tkl_eval_begin*`: tkl_eval_begin*->`${eval_include_file_name}` tkl_eval_end->`${begin_include_file_name}`")
  endif()

  unset(eval_include_file_name)

  tkl_get_last_eval_include_file_path(_67AB359F_eval_include_file_path)

  if ("${end_include_file_path}" STREQUAL "" OR "${end_include_file_path}" STREQUAL ".")
    tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_dir_path")
    tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_name")
    tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_path")

    tkl_begin_track_vars()

    # evaluating...
    include("${_67AB359F_eval_include_file_path}")

    tkl_forward_changed_vars_to_parent_scope()
    tkl_end_track_vars()
  else()
    tkl_is_equal_paths(REALPATH "${_67AB359F_eval_include_file_path}" "${end_include_file_path}" eval_is_equal_include_file_paths)
    if (NOT eval_is_equal_include_file_paths)
      unset(eval_is_equal_include_file_paths)

      tkl_get_last_eval_include_dir_path(eval_include_dir_path)

      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_dir_path")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_name")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_path")

      tkl_begin_track_vars()

      # CAUTION:
      #   We have to call to a nested evaluation to make an inclusion from a file.
      #
      tkl_eval_begin("include_recursive.cmake" "")
 
      unset(eval_include_dir_path)

      tkl_eval_append_from_file("include_recursive.cmake" "${end_include_file_path}")

      # evaluating...
      tkl_eval_end("include_recursive.cmake" .)

      tkl_forward_changed_vars_to_parent_scope()
      tkl_end_track_vars()
    else()
      unset(eval_is_equal_include_file_paths)

      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_dir_path")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_name")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_path")

      tkl_begin_track_vars()

      # evaluating...
      include("${_67AB359F_eval_include_file_path}")

      tkl_forward_changed_vars_to_parent_scope()
      tkl_end_track_vars()
    endif()
  endif()
endfunction()

tkl_register_implementation(function tkl_eval_end)

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_eval str)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  tkl_begin_track_vars()

  tkl_eval_begin("include.cmake" "${str}")
  tkl_eval_end("include.cmake" .)

  tkl_forward_changed_vars_to_parent_scope()
  tkl_end_track_vars()
endfunction()

tkl_register_implementation(function tkl_eval)

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_eval_from_file file_path)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  tkl_begin_track_vars()

  tkl_eval_begin("include.cmake" "")
  tkl_eval_append_from_file("${file_path}")
  tkl_eval_end("include.cmake" .)

  tkl_forward_changed_vars_to_parent_scope()
  tkl_end_track_vars()
endfunction()

tkl_register_implementation(function tkl_eval_from_file)

macro(tkl_get_last_eval_include_dir_path out_var)
  tkl_get_global_prop(${out_var} "tkl::eval::last_include_dir_path" 1)
endmacro()

macro(tkl_get_last_eval_include_file_path out_var)
  tkl_get_global_prop(${out_var} "tkl::eval::last_include_file_path" 1)
endmacro()

macro(tkl_get_last_eval_include_file_name out_var)
  tkl_get_global_prop(${out_var} "tkl::eval::last_include_file_name" 1)
endmacro()

endif()
