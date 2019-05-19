# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_HANDLERS_INCLUDE_DEFINED)
set(TACKLELIB_HANDLERS_INCLUDE_DEFINED 1)

# enable_scope_type:
#   PRE_ONLY  - only for handler_type=PRE
#   PRE_POST  - for both handler_type=PRE and handler_type=POST
#
macro(tkl_enable_handlers_for enable_func_name enable_scope_type)
  if ("${enable_scope_type}" STREQUAL "PRE_ONLY")
  elseif ("${enable_scope_type}" STREQUAL "PRE_POST")
  else()
    message(FATAL_ERROR "handlers scope_type for the `${func_name}()` function is not supported: scope_type=`${TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${enable_func_name}}`"
  endif()

  if (NOT DEFINED TACKLELIB_HANDLERS_ENABLED_FOR_${enable_func_name})
    set(TACKLELIB_HANDLERS_ENABLED_FOR_${enable_func_name} 1)
    set(TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${enable_func_name} ${enable_scope_type})
    set(TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${enable_func_name} "")
    set(TACKLELIB_HANDLERS_POST_FUNCS_FOR_${enable_func_name} "")

    set(TACKLELIB_TEST_CALL_COUNTER_FOR_${enable_func_name} 0)

    string(RANDOM LENGTH 8 TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name})
    set(TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name} "_${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}_")

    macro(tkl_add_handler_for_${enable_func_name} handler_type func_name)
      if (NOT DEFINED TACKLELIB_HANDLERS_ENABLED_FOR_${func_name} OR NOT TACKLELIB_HANDLERS_ENABLED_FOR_${func_name})
        message(FATAL_ERROR "`${func_name}()` handling must be enabled explicitly by call to the `tkl_enable_handlers_for` function")
      endif()

      if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${enable_func_name} STREQUAL "PRE_ONLY")
        if (NOT "${handler_type}" STREQUAL "PRE")
          message(FATAL_ERROR "`${func_name}()` can be used only together with the `PRE` handler type: handler_type=`${handler_type}`")
        endif()
      else()
        if (NOT "${handler_type}" STREQUAL "PRE" AND NOT "${handler_type}" STREQUAL "POST")
          message(FATAL_ERROR "`${func_name}()` can be used only together with the `PRE` or `POST` handler type: handler_type=`${handler_type}`")
        endif()
      endif()

      list(APPEND TACKLELIB_HANDLERS_${handler_type}_FUNCS_FOR_${enable_func_name} "${func_name}")
    endmacro()

    macro(tkl_remove_handler_for_${enable_func_name} handler_type func_name)
      if (NOT DEFINED TACKLELIB_HANDLERS_ENABLED_FOR_${func_name} OR NOT TACKLELIB_HANDLERS_ENABLED_FOR_${func_name})
        message(FATAL_ERROR "`${func_name}()` handling must be enabled explicitly by call to the `tkl_enable_handlers_for` function")
      endif()

      if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${enable_func_name} STREQUAL "PRE_ONLY")
        if (NOT "${handler_type}" STREQUAL "PRE")
          message(FATAL_ERROR "`${func_name}()` can be used only together with the `PRE` handler type: handler_type=`${handler_type}`")
        endif()
      else()
        if (NOT "${handler_type}" STREQUAL "PRE" AND NOT "${handler_type}" STREQUAL "POST")
          message(FATAL_ERROR "`${func_name}()` can be used only together with the `PRE` or `POST` handler type: handler_type=`${handler_type}`")
        endif()
      endif()

      list(REMOVE_AT TACKLELIB_HANDLERS_${handler_type}_FUNCS_FOR_${enable_func_name} "${func_name}" -1)
    endmacro()

    macro(tkl_handle_call_for_${enable_func_name} scope_type)
      # We must test a function call again to replace infinite recursion by an explicit error.
      if (TACKLELIB_TEST_CALL_COUNTER_FOR_${enable_func_name} EQUAL 0)
        if (TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${enable_func_name} STREQUAL "" AND TACKLELIB_HANDLERS_POST_FUNCS_FOR_${enable_func_name} STREQUAL "")
          # must call to a not redefined version of the implementation!
          _${enable_func_name}()
        else()
          if (NOT TACKLELIB_TESTLIB_TESTPROC_INDEX STREQUAL "")
            # running under TestLib, the macro can call under different cmake processes when the inner timestamp is not yet changed (timestamp has seconds resolution)
            tkl_make_temp_dir("CMake.PreOnlyHandlers.${enable_func_name}." "%Y'%m'%d''%H'%M'%SZ" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}" 8 ${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}temp_dir_path)
          else()
            tkl_make_temp_dir("CMake.PreOnlyHandlers.${enable_func_name}." "%Y'%m'%d''%H'%M'%SZ" "" 8 ${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}temp_dir_path)
          endif()

          # builtin variables for the `${enable_func_name}` function handlers self testing from the `TestLib`
          set(TACKLELIB_HANDLERS_LAST_TEMP_DIR_PATH "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}temp_dir_path}" PARENT_SCOPE)

          # 1. drop local variables at begin
          # 2. the expression at the middle
          # 3. self cleanup at the end
          set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str "\
unset(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}temp_dir_path)
unset(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str)\n
")

          # invoke pre handlers
          foreach(handler_func IN LISTS TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${enable_func_name})
            set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str}${handler_func}()\n")
          endforeach()

          # cleanup after pre only handlers
          if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${enable_func_name} STREQUAL "PRE_ONLY")
            set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str}
file(REMOVE_RECURSE \"${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}temp_dir_path}\")
")
          endif()

          # must call to a not redefined version of the implementation!
          set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str}
_${enable_func_name}()\n
")

          if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${enable_func_name} STREQUAL "PRE_POST")
            # invoke post handlers
            foreach(handler_func IN LISTS TACKLELIB_HANDLERS_POST_FUNCS_FOR_${enable_func_name})
              set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str}${handler_func}()\n")
            endforeach()
          endif()

          # cleanup after post handlers
          if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${enable_func_name} STREQUAL "PRE_POST")
            set(${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str}
file(REMOVE_RECURSE \"${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}temp_dir_path}\")
")
          endif()

          tkl_decode_control_chars("${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str}" ${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str)

          file(WRITE "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}temp_dir_path}/eval.cmake" "${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}call_eval_str}")

          # evaluating...
          include("${${TACKLELIB_HANDLERS_TEMP_VAR_PREFIX_TOKEN_FOR_${enable_func_name}}temp_dir_path}/eval.cmake")
        endif()
      else()
        # We are in the `return` testing, ignore the call.
      endif()
    endmacro()

    # function redefinition
    #
    # CAUTION:
    #   Must not be redefined before, otherwise the infinite recursion can take a place!
    #
    macro(${enable_func_name})
      tkl_test_call_for_${enable_func_name}() # test at call, no need to reset the counter because the increment has made inside a function
      tkl_handle_call_for_${enable_func_name}(${TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${enable_func_name}})
    endmacro()

    # in a macro to make a test case for this
    macro(tkl_handle_call_infinite_recursion_for_${enable_func_name})
      # replace infinite recursion by the error
      message(FATAL_ERROR "The `${enable_func_name}` function was redefined after this module inclusion. You must use only one and single user implementation of any function, another user implementation (reimplementation) will provoke an infinite recursion!")
    endmacro()

    # If the function would be redefined later, then the call tester would invoke infinitely.
    function(tkl_test_call_for_${enable_func_name})
      if (NOT TACKLELIB_TEST_CALL_COUNTER_FOR_${enable_func_name} EQUAL 0)
        tkl_handle_call_infinite_recursion_for_${enable_func_name}()
      endif()
      math(EXPR TACKLELIB_TEST_CALL_COUNTER_FOR_${enable_func_name} "${TACKLELIB_TEST_CALL_COUNTER_FOR_${enable_func_name}}+1")
      _${enable_func_name}() # must call to a not redefined version of the implementation!
    endfunction()

    tkl_test_call_for_${enable_func_name}() # test at inclusion, no need to reset the counter because the increment has made inside a function
  endif()
endmacro()

endif()
