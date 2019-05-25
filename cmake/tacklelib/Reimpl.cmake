# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_REIMPL_INCLUDE_DEFINED)
set(TACKLELIB_REIMPL_INCLUDE_DEFINED 1)

include(tacklelib/Props)

function(tkl_get_reimpl_prop func_name out_is_reimpl_var out_keyword_decl_var)
  if (NOT out_is_reimpl_var STREQUAL "" AND NOT out_is_reimpl_var STREQUAL ".")
    tkl_get_global_prop(is_reimpl "tkl::reimpl[${func_name}]" 1)
    if (is_reimpl STREQUAL "")
      set(is_reimpl 0)
    endif()

    set(${out_is_reimpl_var} ${is_reimpl} PARENT_SCOPE)
  endif()

  if (NOT out_keyword_decl_var STREQUAL "" AND NOT out_keyword_decl_var STREQUAL ".")
    tkl_get_global_prop(keyword_decl "tkl::reimpl[${func_name}]::keyword_declarator" 0)
    set(${out_keyword_decl_var} ${keyword_decl} PARENT_SCOPE)
  endif()
endfunction()

function(tkl_register_implementation keyword_declarator func_name)
  if ("${keyword_declarator}" STREQUAL "macro")
  elseif ("${keyword_declarator}" STREQUAL "function")
  else()
    message(FATAL_ERROR "implementation registration is not supported for this keyword declarator: keyword_declarator=`${keyword_declarator}`")
  endif()

  tkl_get_reimpl_prop("${func_name}" is_reimpl .)

  if (is_reimpl)
    message(FATAL_ERROR "reimplementation has been done already, secondary reimplementation is not supported and currently can not be")
  endif()

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  set_property(GLOBAL PROPERTY "tkl::reimpl[${func_name}]" 1)
  set_property(GLOBAL PROPERTY "tkl::reimpl[${func_name}]::keyword_declarator" "${keyword_declarator}")

  tkl_append_global_prop("tkl::reimpl_list" "${func_name}")
endfunction()

endif()
