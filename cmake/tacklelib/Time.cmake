# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_TIME_INCLUDE_DEFINED)
set(TACKLELIB_TIME_INCLUDE_DEFINED 1)

cmake_minimum_required(VERSION 3.6)

# at least cmake 3.6 is required for:
#   * specific `%s` format specifier in the `string(TIMESTAMP ...)`: https://cmake.org/cmake/help/v3.6/command/string.html#timestamp
#

include(tacklelib/ForwardVariables)

macro(tkl_time_sec out_var)
  string(TIMESTAMP ${out_var} "%s" UTC)
endmacro()

function(tkl_time_begin_push_sec out_var stack_entry)
  tkl_time_sec(time_begin_sec)
  tkl_pushset_prop_to_stack(${out_var} GLOBAL "tkl::time::begin_sec" "tkl::time" "${time_begin_sec}")
endfunction()

function(tkl_time_check_point_sec out_var stack_entry)
  tkl_time_sec(time_check_point_sec)
  get_property(time_begin_sec GLOBAL PROPERTY "tkl::time::begin_sec")
  math(EXPR time_spent_sec ${time_check_point_sec}-${time_begin_sec})
  set(${out_var} ${time_spent_sec} PARENT_SCOPE)
endfunction()

function(tkl_time_end_pop_sec out_var stack_entry)
  tkl_time_sec(time_end_sec)
  tkl_pop_prop_from_stack(time_begin_sec GLOBAL "tkl::time::begin_sec" "tkl::time")
  math(EXPR time_spent_sec ${time_end_sec}-${time_begin_sec})
  set(${out_var} ${time_spent_sec} PARENT_SCOPE)
endfunction()

endif()
