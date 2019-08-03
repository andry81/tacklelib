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
#     `$\{...}` or `\${...}` - to insert a variable expression without expansion.
#     But the first method is better, as it can additionally bypass a macro
#     arguments expansion stage, when the second is can not.
#     Works for:
#       `tkl_eval*`
#       `tkl_test_assert_true`
#
#   NOTE:
#     In case of nested expressions you have to double escape it:
#     `$\\{...}` or `\\\${...}`
#
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

  tkl_make_basic_timestamp_temp_dir(eval_temp_dir_path "CMake.Eval" 8)

  tkl_pushset_prop_to_stack(. GLOBAL "tkl::eval::last_include_dir_path" "tkl::eval" "${eval_temp_dir_path}")
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::eval::last_include_file_name" "tkl::eval" "${include_file_name}")
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::eval::last_include_file_path" "tkl::eval" "${eval_temp_dir_path}/${include_file_name}")

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

  # unset the function parameters too
  unset(begin_include_file_name)

  tkl_get_last_eval_include_file_path(_67AB359F_eval_include_file_path)

  if ("${end_include_file_path}" STREQUAL "" OR "${end_include_file_path}" STREQUAL ".")
    tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_dir_path" "tkl::eval")
    tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_name" "tkl::eval")
    tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_path" "tkl::eval")

    # unset the function parameters too
    unset(end_include_file_path)

    # builtin arguments can interfere with the eval expression...

    # switch to special ARGVn stack
    tkl_use_ARGVn_stack_begin("tkl::eval")

    # save ARGV, ARGC, ARGV0..N variables from this scope
    tkl_push_ARGVn_to_stack_from_vars()

    # cleanup all, in case if the ARGVn stack is empty
    tkl_pushunset_ARGVn_to_stack(32)

    # switch to default ARGVn stack
    tkl_use_ARGVn_stack_begin(.)

    # restore ARGVn builtin variables state from the current ARGVn stack top record
    tkl_restore_ARGVn_from_stack(0)

    #tkl_print_ARGVn()

    tkl_track_vars_begin()

    # evaluating...
    include("${_67AB359F_eval_include_file_path}")

    tkl_forward_changed_vars_to_parent_scope(_67AB359F_eval_include_file_path)
    tkl_track_vars_end()

    # switch to previous ARGVn stack
    tkl_use_ARGVn_stack_end()

    # restore ARGV, ARGC, ARGV0..N variables from this scope
    tkl_pop_ARGVn_from_stack()
    tkl_pop_ARGVn_from_stack()

    # switch to previous ARGVn stack
    tkl_use_ARGVn_stack_end()
  else()
    tkl_is_equal_paths(_67AB359F_eval_is_equal_include_file_paths REALPATH "${_67AB359F_eval_include_file_path}" "${end_include_file_path}" . .)
    if (NOT _67AB359F_eval_is_equal_include_file_paths)
      unset(_67AB359F_eval_include_file_path)
      unset(_67AB359F_eval_is_equal_include_file_paths)

      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_dir_path" "tkl::eval")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_name" "tkl::eval")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_path" "tkl::eval")

      # CAUTION:
      #   We have to call to a nested evaluation to make an inclusion from a file.
      #
      tkl_eval_begin("include_recursive.cmake" "")

      tkl_eval_append_from_file("include_recursive.cmake" "${end_include_file_path}")

      # unset the function parameters too
      unset(end_include_file_path)

      tkl_track_vars_begin()

      # evaluating...
      tkl_eval_end("include_recursive.cmake" .)

      tkl_forward_changed_vars_to_parent_scope()
      tkl_track_vars_end()
    else()
      unset(_67AB359F_eval_is_equal_include_file_paths)

      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_dir_path" "tkl::eval")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_name" "tkl::eval")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_path" "tkl::eval")

      # unset the function parameters too
      unset(end_include_file_path)

      tkl_track_vars_begin()

      # evaluating...
      include("${_67AB359F_eval_include_file_path}")

      tkl_forward_changed_vars_to_parent_scope(_67AB359F_eval_include_file_path)
      tkl_track_vars_end()
    endif()
  endif()
endfunction()

tkl_register_implementation(function tkl_eval_end)

# CAUTION:
#   Beware of arguments double expansion here.
#
macro(tkl_macro_eval_end begin_include_file_name end_include_file_path)
  if (NOT ${ARGC} EQUAL 2)
    message(FATAL_ERROR "function must have 2 arguments")
  endif()

  if ((NOT "${end_include_file_path}" STREQUAL "" AND NOT "${end_include_file_path}" STREQUAL ".") AND
      (NOT EXISTS "${end_include_file_path}" OR IS_DIRECTORY "${end_include_file_path}"))
    message(FATAL_ERROR "end_include_file_path if is not empty then must be an existing file path to include: end_include_file_path=`${end_include_file_path}`")
  endif()

  tkl_get_last_eval_include_file_name(_34E75220_eval_include_file_name)

  if (NOT _34E75220_eval_include_file_name STREQUAL "${begin_include_file_name}")
    message(FATAL_ERROR "begin_include_file_name for the `tkl_macro_eval_end` must be the same as for the `tkl_eval_begin*`: tkl_eval_begin*->`${_34E75220_eval_include_file_name}` tkl_macro_eval_end->`${begin_include_file_name}`")
  endif()

  unset(_34E75220_eval_include_file_name)

  tkl_get_last_eval_include_file_path(_67AB359F_eval_include_file_path)

  if ("${end_include_file_path}" STREQUAL "" OR "${end_include_file_path}" STREQUAL ".")
    tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_dir_path" "tkl::eval")
    tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_name" "tkl::eval")
    tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_path" "tkl::eval")

    # builtin arguments can interfere with the eval expression...

    # switch to special ARGVn stack
    tkl_use_ARGVn_stack_begin("tkl::eval")

    # cleanup all, in case if the ARGVn stack is empty
    tkl_pushunset_ARGVn_to_stack(32)

    # switch to default ARGVn stack
    tkl_use_ARGVn_stack_begin(.)

    # restore ARGVn builtin variables state from the current ARGVn stack top record
    tkl_restore_ARGVn_from_stack(0)

    #tkl_print_ARGVn()

    # evaluating...
    include("${_67AB359F_eval_include_file_path}")

    # switch to previous ARGVn stack
    tkl_use_ARGVn_stack_end()

    tkl_pop_ARGVn_from_stack()

    # switch to previous ARGVn stack
    tkl_use_ARGVn_stack_end()
  else()
    tkl_is_equal_paths(_34E75220_eval_is_equal_include_file_paths REALPATH "${_67AB359F_eval_include_file_path}" "${end_include_file_path}" . .)
    if (NOT _34E75220_eval_is_equal_include_file_paths)
      unset(_67AB359F_eval_include_file_path)
      unset(_34E75220_eval_is_equal_include_file_paths)

      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_dir_path" "tkl::eval")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_name" "tkl::eval")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_path" "tkl::eval")

      # CAUTION:
      #   We have to call to a nested evaluation to make an inclusion from a file.
      #
      tkl_eval_begin("include_recursive.cmake" "")
 
      tkl_eval_append_from_file("include_recursive.cmake" "${end_include_file_path}")

      # evaluating...
      tkl_macro_eval_end("include_recursive.cmake" .)
    else()
      unset(_34E75220_eval_is_equal_include_file_paths)

      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_dir_path" "tkl::eval")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_name" "tkl::eval")
      tkl_pop_prop_from_stack(. GLOBAL "tkl::eval::last_include_file_path" "tkl::eval")

      # evaluating...
      include("${_67AB359F_eval_include_file_path}")
    endif()
  endif()
endmacro()

tkl_register_implementation(macro tkl_macro_eval_end)

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_eval str)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  tkl_eval_begin("include.cmake" "${str}")

  # unset the function parameters too
  unset(str)

  tkl_track_vars_begin()

  tkl_eval_end("include.cmake" .)

  tkl_forward_changed_vars_to_parent_scope()
  tkl_track_vars_end()
endfunction()

tkl_register_implementation(function tkl_eval)

# CAUTION:
#   Beware of arguments double expansion here.
#
macro(tkl_macro_eval str)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  tkl_eval_begin("include.cmake" "${str}")

  # unset the function parameters too
  unset(str)

  tkl_macro_eval_end("include.cmake" .)
endmacro()

tkl_register_implementation(macro tkl_macro_eval)

# CAUTION:
#   Must be a function to:
#   1. Avoid double expansion of the arguments.
#
function(tkl_eval_from_file file_path)
  if (NOT ${ARGC} EQUAL 1)
    message(FATAL_ERROR "function must have 1 argument")
  endif()

  tkl_eval_begin("include.cmake" "")
  tkl_eval_append_from_file("${file_path}")

  tkl_track_vars_begin()

  tkl_eval_end("include.cmake" .)

  tkl_forward_changed_vars_to_parent_scope()
  tkl_track_vars_end()
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
