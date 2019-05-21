# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_REIMPL_INCLUDE_DEFINED)
set(TACKLELIB_REIMPL_INCLUDE_DEFINED 1)

include(tacklelib/Props)

macro(tkl_get_reimpl_prop func_name)
  get_property(TACKLELIB_REIMPL_FOR_${func_name} GLOBAL PROPERTY "tkl::reimpl[${func_name}]")
  get_property(TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_${func_name} GLOBAL PROPERTY "tkl::reimpl[${func_name}]::keyword_declarator")
endmacro()

macro(tkl_register_implementation keyword_declarator func_name)
  if ("${keyword_declarator}" STREQUAL "macro")
  elseif ("${keyword_declarator}" STREQUAL "function")
  else()
    message(FATAL_ERROR "implementation registration is not supported for this keyword declarator: keyword_declarator=`${keyword_declarator}`")
  endif()

  tkl_get_reimpl_prop("${func_name}")

  if (TACKLELIB_REIMPL_FOR_${func_name})
    message(FATAL_ERROR "reimplementation has been done already, secondary reimplementation is not supported and currently can not be")
  endif()

  set(TACKLELIB_REIMPL_FOR_${func_name} 1)
  set(TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_${func_name} "${keyword_declarator}")

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  set_property(GLOBAL PROPERTY "tkl::reimpl[${func_name}]" "${TACKLELIB_REIMPL_FOR_${func_name}}")
  set_property(GLOBAL PROPERTY "tkl::reimpl[${func_name}]::keyword_declarator" "${TACKLELIB_REIMPL_KEYWORD_DECLARATOR_FOR_${func_name}}")

  tkl_append_global_prop("tkl::reimpl_list" "${func_name}")
endmacro()

endif()
