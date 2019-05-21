# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_HANDLERS_INCLUDE_DEFINED)
set(TACKLELIB_HANDLERS_INCLUDE_DEFINED 1)

include(tacklelib/File)
include(tacklelib/MakeTemp)
include(tacklelib/Reimpl)
include(tacklelib/Utility)

# scope_type:
#   PRE_ONLY  - only for handler_type=PRE
#   PRE_POST  - for both handler_type=PRE and handler_type=POST
#
# ARGN:
#   Function argument names.
#
macro(tkl_enable_handlers_for scope_type keyword_declarator func_name)
  if ("${scope_type}" STREQUAL "PRE_ONLY")
  elseif ("${scope_type}" STREQUAL "PRE_POST")
  else()
    message(FATAL_ERROR "handlers scope_type for the `${func_name}` function is not supported: scope_type=`${scope_type}`")
  endif()

  if ("${keyword_declarator}" STREQUAL "macro")
  elseif ("${keyword_declarator}" STREQUAL "function")
  else()
    message(FATAL_ERROR "handlers keyword_declarator for the `${func_name}` function is not supported: keyword_declarator=`${keyword_declarator}`")
  endif()

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  get_property(TACKLELIB_HANDLERS_ENABLED_FOR_${func_name} GLOBAL PROPERTY "tkl::handlers::enabled[${func_name}]")

  if (NOT TACKLELIB_HANDLERS_ENABLED_FOR_${func_name})
    set(TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${func_name} ${scope_type})
    set(TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${func_name} "")
    set(TACKLELIB_HANDLERS_POST_FUNCS_FOR_${func_name} "")

    set_property(GLOBAL PROPERTY "tkl::handlers::scope_type[${func_name}]" "${TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${func_name}}")
    set_property(GLOBAL PROPERTY "tkl::handlers::pre_funcs[${func_name}]" "${TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${func_name}}")
    set_property(GLOBAL PROPERTY "tkl::handlers::post_funcs[${func_name}]" "${TACKLELIB_HANDLERS_POST_FUNCS_FOR_${func_name}}")

    set(TACKLELIB_TEST_CALL_COUNTER_FOR_${func_name} 0)

    string(RANDOM LENGTH 8 TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name})
    set(TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name} "_${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}_")

    macro(tkl_add_handler_for_${func_name} handler_type handler_func_name)
      # CAUTION:
      #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
      #
      get_property(TACKLELIB_HANDLERS_ENABLED_FOR_${func_name} GLOBAL PROPERTY "tkl::handlers::enabled[${func_name}]")

      if (NOT TACKLELIB_HANDLERS_ENABLED_FOR_${func_name})
        message(FATAL_ERROR "`${func_name}` function handling must be enabled explicitly by call to the `tkl_enable_handlers_for` function")
      endif()

      get_property(TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${func_name} GLOBAL PROPERTY "tkl::handlers::scope_type[${func_name}]")

      if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${func_name} STREQUAL "PRE_ONLY")
        if (NOT "${handler_type}" STREQUAL "PRE")
          message(FATAL_ERROR "`${handler_func_name}` function can be used only together with the `PRE` handler type: handler_type=`${handler_type}`")
        endif()
      else()
        if (NOT "${handler_type}" STREQUAL "PRE" AND NOT "${handler_type}" STREQUAL "POST")
          message(FATAL_ERROR "`${handler_func_name}` function can be used only together with the `PRE` or `POST` handler type: handler_type=`${handler_type}`")
        endif()
      endif()

      list(APPEND TACKLELIB_HANDLERS_${handler_type}_FUNCS_FOR_${func_name} "${handler_func_name}")
    endmacro()

    macro(tkl_remove_handler_for_${func_name} handler_type handler_func_name)
      # CAUTION:
      #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
      #
      get_property(TACKLELIB_HANDLERS_ENABLED_FOR_${func_name} GLOBAL PROPERTY "tkl::handlers::enabled[${func_name}]")

      if (NOT TACKLELIB_HANDLERS_ENABLED_FOR_${func_name})
        message(FATAL_ERROR "`${func_name}` function handling must be enabled explicitly by call to the `tkl_enable_handlers_for` function")
      endif()

      get_property(TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${func_name} GLOBAL PROPERTY "tkl::handlers::scope_type[${func_name}]")

      if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${func_name} STREQUAL "PRE_ONLY")
        if (NOT "${handler_type}" STREQUAL "PRE")
          message(FATAL_ERROR "`${handler_func_name}` function can be used only together with the `PRE` handler type: handler_type=`${handler_type}`")
        endif()
      else()
        if (NOT "${handler_type}" STREQUAL "PRE" AND NOT "${handler_type}" STREQUAL "POST")
          message(FATAL_ERROR "`${handler_func_name}` function can be used only together with the `PRE` or `POST` handler type: handler_type=`${handler_type}`")
        endif()
      endif()

      list(REMOVE_AT TACKLELIB_HANDLERS_${handler_type}_FUNCS_FOR_${func_name} "${handler_func_name}" -1)
    endmacro()

    # in a macro to make a test case for this
    macro(tkl_handle_call_infinite_recursion_for_${func_name})
      # replace infinite recursion by the error
      message(FATAL_ERROR "The `${func_name}` function was redefined after this module inclusion. You must use only one and single user implementation of any function, another user implementation (reimplementation) will provoke an infinite recursion!")
    endmacro()

    get_property(TACKLELIB_TESTLIB_TESTPROC_INDEX GLOBAL PROPERTY "tkl::testlib::testproc::index")

    if (NOT TACKLELIB_TESTLIB_TESTPROC_INDEX STREQUAL "")
      # running under TestLib, the macro can call under different cmake processes when the inner timestamp is not yet changed (timestamp has seconds resolution)
      tkl_make_temp_dir("CMake.EnableHandlers.${func_name}." "%Y'%m'%d''%H'%M'%SZ" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}" 8 ${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}temp_dir_path)
    else()
      tkl_make_temp_dir("CMake.EnableHandlers.${func_name}." "%Y'%m'%d''%H'%M'%SZ" "" 8 ${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}temp_dir_path)
    endif()

    # builtin variables for the `${func_name}` function handlers self testing from the `TestLib`
    set(TACKLELIB_HANDLERS_LAST_TEMP_DIR_PATH "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}temp_dir_path}")

    # generate from ARGN="a;b;c" -> "a" "b" "c"
    tkl_make_eval_cmdline_from_vars_list(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_args ${ARGN})

    set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str "\
# 1. drop local variables at begin
# 2. the expression at the middle
# 3. self cleanup at the end

unset(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}temp_dir_path)
unset(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str)

macro(tkl_handle_call_for_${func_name} ${ARGN})
  # We must test a function call again to replace infinite recursion by an explicit error.
  if (TACKLELIB_TEST_CALL_COUNTER_FOR_${func_name} EQUAL 0)
")

    get_property(TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${func_name} GLOBAL PROPERTY "tkl::handlers::pre_funcs[${func_name}]")

    # invoke pre handlers
    foreach(handler_func IN LISTS TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${func_name})
      set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str
        "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}\
    ${handler_func}()
")
    endforeach()

    # cleanup after pre only handlers
    if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${func_name} STREQUAL "PRE_ONLY")
      set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str
        "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}
    tkl_file_remove_recurse(\"${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}temp_dir_path}\")\n
")
    endif()

    # must call to a not redefined version of the implementation!
    set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str
      "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}\
    _${func_name}(${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_args})\n
")

    get_property(TACKLELIB_HANDLERS_POST_FUNCS_FOR_${func_name} GLOBAL PROPERTY "tkl::handlers::post_funcs[${func_name}]")

    # invoke post handlers
    foreach(handler_func IN LISTS TACKLELIB_HANDLERS_POST_FUNCS_FOR_${func_name})
      set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str
        "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}\
    ${handler_func}()
")
    endforeach()

    # cleanup after post handlers
    if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${func_name} STREQUAL "PRE_POST")
      set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str
        "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}
    tkl_file_remove_recurse(\"${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}temp_dir_path}\")
")
    endif()

    set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str
      "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}\
  else()
    # We are in the `return` testing, ignore the call except cleanup.
    tkl_file_remove_recurse(\"${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}temp_dir_path}\")
  endif()
endmacro()

# If the function would be redefined later, then the call tester would invoke infinitely.
function(tkl_test_call_for_${func_name} ${ARGN})
  if (NOT TACKLELIB_TEST_CALL_COUNTER_FOR_${func_name} EQUAL 0)
    tkl_handle_call_infinite_recursion_for_${func_name}()
  endif()
  math(EXPR TACKLELIB_TEST_CALL_COUNTER_FOR_${func_name} \${TACKLELIB_TEST_CALL_COUNTER_FOR_${func_name}}+1)

  # must call to a not redefined version of the implementation!
  _${func_name}(${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_args})
endfunction()

")

    # CAUTION:
    #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
    #
    get_property(TACKLELIB_REIMPL_FOR_${func_name} GLOBAL PROPERTY "tkl::reimpl[${func_name}]")

    if (NOT TACKLELIB_REIMPL_FOR_${func_name})
      set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str
        "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}\
# function redefinition
#
# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can take a place!
#
${keyword_declarator}(${func_name} ${ARGN})
  tkl_test_call_for_${func_name}() # test at call, no need to reset the counter because the increment has made inside a function
  tkl_handle_call_for_${func_name}()
end${keyword_declarator}()
")

      tkl_register_implementation("${keyword_declarator}" "${func_name}")
    endif()

    set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str
      "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}
# test at inclusion, no need to reset the counter because the increment has made inside a function
tkl_test_call_for_${func_name}()

tkl_file_remove_recurse(\"${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}temp_dir_path}\")
")

    tkl_decode_control_chars("${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}"
      ${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str)

    # CAUTION:
    #   This conversion required ONLY if `file(...)` is reimplemented by a macro, which is by default in the `File.cmake`!
    #   For details: https://gitlab.kitware.com/cmake/cmake/issues/19281
    #
    tkl_get_reimpl_prop(file)

    if (TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file STREQUAL "macro")
      tkl_escape_list_expansion(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}")
    endif()

    file(WRITE "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}temp_dir_path}/eval.cmake" "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_str}")

    unset(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}call_eval_args)

    # evaluating...
    include("${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${func_name}}temp_dir_path}/eval.cmake")

    tkl_append_enable_handler_prop(${func_name})
  endif()
endmacro()

macro(tkl_append_enable_handler_prop func_name)
  set(TACKLELIB_HANDLERS_ENABLED_FOR_${func_name} 1)

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  set_property(GLOBAL PROPERTY "tkl::handlers::enabled[${func_name}]" "${TACKLELIB_HANDLERS_ENABLED_FOR_${func_name}}")

  tkl_append_global_prop("tkl::handlers::enabled_list" "${func_name}")
endmacro()

endif()
