# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_STRING_INCLUDE_DEFINED)
set(TACKLELIB_STRING_INCLUDE_DEFINED 1)

function(tkl_string_begins_with str str_prefix out_var)
  string(LENGTH str_prefix str_prefix_len)
  string(SUBSTRING str 0 ${str_prefix_len} substr_prefix)
  if (substr_prefix STREQUAL str_prefix)
    set(${out_var} 1 PARENT_SCOPE)
  else()
    set(${out_var} 0 PARENT_SCOPE)
  endif()
endfunction()

#function(tkl_escape_string out_var in_str)
#  string(REGEX REPLACE "\\\\([^;])" "\\\\\\\\\\1" out_str "${in_str}")
#  string(REGEX REPLACE "\\\\\$" "\\\\\\\\" out_str "${out_str}")
#  #string(REPLACE ";" "\;" out_str "${out_str}")
#  string(REPLACE "\$" "\\\$" out_str "${out_str}")
#  string(REPLACE "\"" "\\\"" out_str "${out_str}")
#  set(${out_var} "${out_str}" PARENT_SCOPE)
#endfunction()

# Used to be called after:
#   `list(GET ...)`
#   `foreach(... IN LISTS ...)`
function(tkl_escape_string_after_list_get out_var in_str)
  string(REPLACE ";" "\;" out_str "${in_str}")
  set(${out_var} "${out_str}" PARENT_SCOPE)
endfunction()

# Used to be called before:
#   `list(APPEND ...)`
function(tkl_escape_string_before_list_append out_var in_str)
  string(REPLACE ";" "\;" out_str "${in_str}")
  set(${out_var} "${out_str}" PARENT_SCOPE)
endfunction()

endif()
