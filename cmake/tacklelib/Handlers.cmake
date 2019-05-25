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
# CAUTION:
#   Must be a function to:
#   1. Enable access the function arguments inside an include with the function
#      body (important for the `tkl_generate_call_handler` macro).
#   2. Simplify and reduce the entire code (for example, in a function the
#      `${ARGN}` no needs to be escaped in case of call a macro from a function,
#      when the escaping is a mandatory in case of a macro call from a macro:
#      https://gitlab.kitware.com/cmake/cmake/issues/19281 )
#
function(tkl_enable_handlers scope_type keyword_declarator func_name)
  if ("${func_name}" STREQUAL "")
    message(FATAL_ERROR "func_name must be not empty: func_name=`${func_name}`")
  endif()

  if ("${scope_type}" STREQUAL "PRE_ONLY")
  elseif ("${scope_type}" STREQUAL "PRE_POST")
  else()
    message(FATAL_ERROR "scope_type is not supported: scope_type=`${scope_type}` func_name=`${func_name}`")
  endif()

  if ("${keyword_declarator}" STREQUAL "macro")
  elseif ("${keyword_declarator}" STREQUAL "function")
  else()
    message(FATAL_ERROR "keyword_declarator is not supported: scope_type=`${scope_type}` keyword_declarator=`${keyword_declarator}` func_name=`${func_name}`")
  endif()

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  tkl_get_global_prop(TACKLELIB_HANDLERS_ENABLED_FOR_${func_name} "tkl::handlers::enabled[${func_name}]" 0)

  if (NOT TACKLELIB_HANDLERS_ENABLED_FOR_${func_name})
    set(TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${func_name} ${scope_type})
    set(TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${func_name} "")
    set(TACKLELIB_HANDLERS_POST_FUNCS_FOR_${func_name} "")

    set_property(GLOBAL PROPERTY "tkl::handlers::scope_type[${func_name}]" "${TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_${func_name}}")
    set_property(GLOBAL PROPERTY "tkl::handlers::pre_funcs[${func_name}]" "${TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${func_name}}")
    set_property(GLOBAL PROPERTY "tkl::handlers::post_funcs[${func_name}]" "${TACKLELIB_HANDLERS_POST_FUNCS_FOR_${func_name}}")

    tkl_set_global_prop_and_var(TACKLELIB_HANDLERS_CALL_GUARD_COUNTER_FOR_${func_name} "tkl::handlers::call_guard[${func_name}]::counter" 0)

    # as a separate macro to be able to make a test case for this through the return out
    macro(tkl_handle_call_infinite_recursion func_name)
      # indicate an infinite recursion from here
      message(FATAL_ERROR "The `${func_name}` function was redefined after this module inclusion. You must use only one and single user implementation of any function, another user implementation (reimplementation) will provoke an infinite recursion!")
    endmacro()

    macro(tkl_generate_call_handler gen_func_name ${ARGN})
      tkl_get_global_prop(TACKLELIB_TESTLIB_TESTPROC_INDEX "tkl::testlib::testproc::index" 1)

      if (NOT TACKLELIB_TESTLIB_TESTPROC_INDEX STREQUAL "")
        # running under TestLib, the macro can call under different cmake processe when the inner timestamp is not yet changed (timestamp has seconds resolution)
        tkl_make_temp_dir("CMake.EnableHandlers.${gen_func_name}." "%Y'%m'%d''%H'%M'%SZ" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}" 8 _3528D0E3_temp_dir_path)
      else()
        tkl_make_temp_dir("CMake.EnableHandlers.${gen_func_name}." "%Y'%m'%d''%H'%M'%SZ" "" 8 _3528D0E3_temp_dir_path)
      endif()

      unset(TACKLELIB_TESTLIB_TESTPROC_INDEX)

      # builtin variables for the `${gen_func_name}` function handlers self testing from the `TestLib`
      set_property(GLOBAL PROPERTY "tkl::handlers::last_temp_dir_path" "${_3528D0E3_temp_dir_path}")

      tkl_make_vars_escaped_expansion_cmdline_from_vars_list(_3528D0E3_escaped_expansion_cmdline_args ${ARGN})
      tkl_make_vars_unescaped_expansion_cmdline_from_vars_list(_3528D0E3_unescaped_expansion_cmdline_args ${ARGN})

      set(_3528D0E3_include_str "\
unset(_3528D0E3_temp_dir_path)

# early cleanup
tkl_file_remove_recurse(\"${_3528D0E3_temp_dir_path}\")

macro(tkl_add_handler handler_type func_name handler_func_name)
  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  tkl_get_global_prop(TACKLELIB_HANDLERS_ENABLED_FOR_\${func_name} \"tkl::handlers::enabled[\${func_name}]\" 0)

  if (NOT TACKLELIB_HANDLERS_ENABLED_FOR_\${func_name})
    message(FATAL_ERROR \"`\${func_name}` function handling must be enabled explicitly by call to the `tkl_enable_handlers` function\")
  endif()

  unset(TACKLELIB_HANDLERS_ENABLED_FOR_\${func_name})

  tkl_get_global_prop(TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_\${func_name} \"tkl::handlers::scope_type[\${func_name}]\" 1)

  if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_\${func_name} STREQUAL \"PRE_ONLY\")
    if (NOT \"\${handler_type}\" STREQUAL \"PRE\")
      message(FATAL_ERROR \"`\${handler_func_name}` function can be used only together with the `PRE` handler type: handler_type=`\${handler_type}`\")
    endif()
  else()
    if (NOT \"\${handler_type}\" STREQUAL \"PRE\" AND NOT \"\${handler_type}\" STREQUAL \"POST\")
      message(FATAL_ERROR \"`\${handler_func_name}` function can be used only together with the `PRE` or `POST` handler type: handler_type=`\${handler_type}`\")
    endif()
  endif()

  unset(TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_\${func_name})

  if (\"\${handler_type}\" STREQUAL \"PRE\")
    tkl_get_global_prop(TACKLELIB_HANDLERS_PRE_FUNCS_FOR_\${func_name} \"tkl::handlers::pre_funcs[\${func_name}]\" 0)
    list(APPEND TACKLELIB_HANDLERS_PRE_FUNCS_FOR_\${func_name} \"\${handler_func_name}\")
    set_property(GLOBAL PROPERTY \"tkl::handlers::pre_funcs[\${func_name}]\" \"\${TACKLELIB_HANDLERS_PRE_FUNCS_FOR_\${func_name}}\")
    unset(TACKLELIB_HANDLERS_PRE_FUNCS_FOR_\${func_name})
  elseif (\"\${handler_type}\" STREQUAL \"POST\")
    tkl_get_global_prop(TACKLELIB_HANDLERS_POST_FUNCS_FOR_\${func_name} \"tkl::handlers::post_funcs[\${func_name}]\" 0)
    list(APPEND TACKLELIB_HANDLERS_POST_FUNCS_FOR_\${func_name} \"\${handler_func_name}\")
    set_property(GLOBAL PROPERTY \"tkl::handlers::post_funcs[\${func_name}]\" \"\${TACKLELIB_HANDLERS_POST_FUNCS_FOR_\${func_name}}\")
    unset(TACKLELIB_HANDLERS_POST_FUNCS_FOR_\${func_name})
  endif()

  tkl_generate_call_handler(\"\${func_name}\" ${_3528D0E3_escaped_expansion_cmdline_args})
endmacro()

macro(tkl_remove_handler handler_type func_name handler_func_name)
  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  tkl_get_global_prop(TACKLELIB_HANDLERS_ENABLED_FOR_\${func_name} \"tkl::handlers::enabled[\${func_name}]\" 0)

  if (NOT TACKLELIB_HANDLERS_ENABLED_FOR_\${func_name})
    message(FATAL_ERROR \"`\${func_name}` function handling must be enabled explicitly by call to the `tkl_enable_handlers` function\")
  endif()

  unset(TACKLELIB_HANDLERS_ENABLED_FOR_\${func_name})

  tkl_get_global_prop(TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_\${func_name} \"tkl::handlers::scope_type[\${func_name}]\" 1)

  if (TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_\${func_name} STREQUAL \"PRE_ONLY\")
    if (NOT \"\${handler_type}\" STREQUAL \"PRE\")
      message(FATAL_ERROR \"`\${handler_func_name}` function can be used only together with the `PRE` handler type: handler_type=`\${handler_type}`\")
    endif()
  else()
    if (NOT \"\${handler_type}\" STREQUAL \"PRE\" AND NOT \"\${handler_type}\" STREQUAL \"POST\")
      message(FATAL_ERROR \"`\${handler_func_name}` function can be used only together with the `PRE` or `POST` handler type: handler_type=`\${handler_type}`\")
    endif()
  endif()

  unset(TACKLELIB_HANDLERS_SCOPE_TYPE_FOR_\${func_name})

  if (\"\${handler_type}\" STREQUAL \"PRE\")
    tkl_get_global_prop(TACKLELIB_HANDLERS_PRE_FUNCS_FOR_\${func_name} \"tkl::handlers::pre_funcs[\${func_name}]\" 0)
    list(REMOVE_AT TACKLELIB_HANDLERS_PRE_FUNCS_FOR_\${func_name} \"\${handler_func_name}\" -1)
    set_property(GLOBAL PROPERTY \"tkl::handlers::pre_funcs[\${func_name}]\" \"\${TACKLELIB_HANDLERS_PRE_FUNCS_FOR_\${func_name}}\")
    unset(TACKLELIB_HANDLERS_PRE_FUNCS_FOR_\${func_name})
  elseif (\"\${handler_type}\" STREQUAL \"POST\")
    tkl_get_global_prop(TACKLELIB_HANDLERS_POST_FUNCS_FOR_\${func_name} \"tkl::handlers::post_funcs[\${func_name}]\" 0)
    list(REMOVE_AT TACKLELIB_HANDLERS_POST_FUNCS_FOR_\${func_name} \"\${handler_func_name}\" -1)
    set_property(GLOBAL PROPERTY \"tkl::handlers::post_funcs[\${func_name}]\" \"\${TACKLELIB_HANDLERS_POST_FUNCS_FOR_\${func_name}}\")
    unset(TACKLELIB_HANDLERS_POST_FUNCS_FOR_\${func_name})
  endif()

  tkl_generate_call_handler(\"\${func_name}\" ${_3528D0E3_escaped_expansion_cmdline_args})
endmacro()

macro(tkl_handle_call_for_${gen_func_name} ${ARGN})
  # We must check a function call on infinite recursion and if it is, then call to a handler macro.
  tkl_get_global_prop(TACKLELIB_HANDLERS_CALL_GUARD_COUNTER_FOR_${gen_func_name} \"tkl::handlers::call_guard[${gen_func_name}]::counter\" 1)

  if (TACKLELIB_HANDLERS_CALL_GUARD_COUNTER_FOR_${gen_func_name} EQUAL 0)
    math(EXPR TACKLELIB_HANDLERS_CALL_GUARD_COUNTER_FOR_${gen_func_name} \${TACKLELIB_HANDLERS_CALL_GUARD_COUNTER_FOR_${gen_func_name}}+1)
    set_property(GLOBAL PROPERTY \"tkl::handlers::call_guard[${gen_func_name}]::counter\" \"\${TACKLELIB_HANDLERS_CALL_GUARD_COUNTER_FOR_${gen_func_name}}\")
    unset(TACKLELIB_HANDLERS_CALL_GUARD_COUNTER_FOR_${gen_func_name})\n
")

      tkl_get_global_prop(TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${gen_func_name} "tkl::handlers::pre_funcs[${gen_func_name}]" 0)

      # invoke pre handlers
      foreach(_3528D0E3_handler_func IN LISTS TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${gen_func_name})
        set(_3528D0E3_include_str
          "${_3528D0E3_include_str}\
    ${_3528D0E3_handler_func}()
")
      endforeach()

      unset(_3528D0E3_handler_func)
      unset(TACKLELIB_HANDLERS_PRE_FUNCS_FOR_${gen_func_name})

      # must call to a not redefined version of the implementation!
      set(_3528D0E3_include_str
        "${_3528D0E3_include_str}\
    # call to the previous implementation of being handled function
    _${gen_func_name}(${_3528D0E3_unescaped_expansion_cmdline_args})\n
")

      tkl_get_global_prop(TACKLELIB_HANDLERS_POST_FUNCS_FOR_${gen_func_name} GLOBAL PROPERTY "tkl::handlers::post_funcs[${gen_func_name}]" 0)

      # invoke post handlers
      foreach(_3528D0E3_handler_func IN LISTS TACKLELIB_HANDLERS_POST_FUNCS_FOR_${gen_func_name})
        set(_3528D0E3_include_str
          "${_3528D0E3_include_str}\
    ${_3528D0E3_handler_func}()
")
      endforeach()

      unset(_3528D0E3_handler_func)
      unset(TACKLELIB_HANDLERS_POST_FUNCS_FOR_${gen_func_name})

      set(_3528D0E3_include_str
        "${_3528D0E3_include_str}\
  else()
    tkl_handle_call_infinite_recursion(\"${gen_func_name}\")
  endif()
endmacro()

")

      # CAUTION:
      #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
      #
      tkl_get_global_prop(TACKLELIB_REIMPL_FOR_${gen_func_name} "tkl::reimpl[${gen_func_name}]" 1)

      if (NOT TACKLELIB_REIMPL_FOR_${gen_func_name})
        unset(TACKLELIB_REIMPL_FOR_${gen_func_name})

        set(_3528D0E3_include_str
          "${_3528D0E3_include_str}\
# function redefinition
#
# CAUTION:
#   Must not be redefined before or after, otherwise the infinite recursion can take a place!
#
${keyword_declarator}(${gen_func_name} ${ARGN})
")
        # CAUTION:
        #   This conversion is required ONLY if `${keyword_declarator}(...)` is reimplemented as a macro!
        #   For details: https://gitlab.kitware.com/cmake/cmake/issues/19281
        #
        if ("${keyword_declarator}" STREQUAL "macro")
          set(_3528D0E3_include_str
            "${_3528D0E3_include_str}\
  tkl_handle_call_for_${gen_func_name}(${_3528D0E3_escaped_expansion_cmdline_args})
")
        else()
          set(_3528D0E3_include_str
            "${_3528D0E3_include_str}\
  tkl_handle_call_for_${gen_func_name}(${_3528D0E3_unescaped_expansion_cmdline_args})
")
        endif()

        set(_3528D0E3_include_str
          "${_3528D0E3_include_str}\
end${keyword_declarator}()

tkl_register_implementation(\"${keyword_declarator}\" \"${gen_func_name}\")
")
      else()
        unset(TACKLELIB_REIMPL_FOR_${gen_func_name})
      endif()

      # CAUTION:
      #   This conversion required ONLY if `file(...)` is reimplemented as a macro, which is by default in the `File.cmake`!
      #   For details: https://gitlab.kitware.com/cmake/cmake/issues/19281
      #
      tkl_get_reimpl_prop(file . TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file)

      if (TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file STREQUAL "macro")
        tkl_escape_string_for_macro_args("${_3528D0E3_include_str}" _3528D0E3_include_str)
      endif()

      unset(TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file)

      file(WRITE "${_3528D0E3_temp_dir_path}/include.cmake" "${_3528D0E3_include_str}")

      # enable before evaluation in case of recursion
      tkl_append_enable_handler_prop("${gen_func_name}")

      unset(_3528D0E3_include_str)
      unset(_3528D0E3_escaped_expansion_cmdline_args)
      unset(_3528D0E3_unescaped_expansion_cmdline_args)


      # evaluating...
      #
      # INFO:
      #   This include can be invoked inside a macro.
      #
      include("${_3528D0E3_temp_dir_path}/include.cmake")
    endmacro()

    # first time the call handler generation from a function
    tkl_get_global_prop(TACKLELIB_TESTLIB_TESTPROC_INDEX "tkl::testlib::testproc::index" 1)

    if (NOT TACKLELIB_TESTLIB_TESTPROC_INDEX STREQUAL "")
      # running under TestLib, the macro can call under different cmake processe when the inner timestamp is not yet changed (timestamp has seconds resolution)
      tkl_make_temp_dir("CMake.EnableHandlers.${func_name}." "%Y'%m'%d''%H'%M'%SZ" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}" 8 _EBC697D4_temp_dir_path)
    else()
      tkl_make_temp_dir("CMake.EnableHandlers.${func_name}." "%Y'%m'%d''%H'%M'%SZ" "" 8 _EBC697D4_temp_dir_path)
    endif()

    unset(TACKLELIB_TESTLIB_TESTPROC_INDEX)

    # builtin variables for the `${func_name}` function handlers self testing from the `TestLib`
    set(TACKLELIB_HANDLERS_LAST_TEMP_DIR_PATH "${_EBC697D4_temp_dir_path}")

    tkl_make_vars_unescaped_expansion_cmdline_from_vars_list(_EBC697D4_unescaped_expansion_cmdline_args ${ARGN})

    set(_EBC697D4_include_str "\
unset(_EBC697D4_temp_dir_path)

tkl_file_remove_recurse(\"${_EBC697D4_temp_dir_path}\")

tkl_generate_call_handler(\"${func_name}\" ${_EBC697D4_unescaped_expansion_cmdline_args})
")

    # CAUTION:
    #   This conversion required ONLY if `file(...)` is reimplemented as a macro, which is by default in the `File.cmake`!
    #   For details: https://gitlab.kitware.com/cmake/cmake/issues/19281
    #
    tkl_get_reimpl_prop(file . TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file)

    if (TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file STREQUAL "macro")
      tkl_escape_string_for_macro_args("${_3528D0E3_include_str}" _3528D0E3_include_str)
    endif()

    unset(TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_file)

    file(WRITE "${_EBC697D4_temp_dir_path}/include.cmake" "${_EBC697D4_include_str}")

    unset(_EBC697D4_include_str)
    unset(_EBC697D4_unescaped_expansion_cmdline_args)

    # evaluating...
    #
    # CAUTION: 
    #   This include MUST BE invoked inside a function, NOT A MACRO!
    #
    include("${_EBC697D4_temp_dir_path}/include.cmake")
  endif()
endfunction()

macro(tkl_append_enable_handler_prop func_name)
  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  set_property(GLOBAL PROPERTY "tkl::handlers::enabled[${func_name}]" 1)
  tkl_append_global_prop("tkl::handlers::enabled_list" "${func_name}")
endmacro()

endif()
