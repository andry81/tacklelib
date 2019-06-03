# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_RETURN_CODE_FILE_INCLUDE_DEFINED)
set(TACKLELIB_RETURN_CODE_FILE_INCLUDE_DEFINED 1)

include(tacklelib/File)
include(tacklelib/MakeTemp)

function(tkl_make_ret_code_file_dir dir_path_abs_var)
  tkl_make_basic_timestamp_temp_dir(dir_path_abs "CMake.RetCode." 8)
  set(file_path_abs "${dir_path_abs}/ret_code.var")
  tkl_file_write("${file_path_abs}" "") # not set yet
  #file(LOCK "${dir_path_abs}" DIRECTORY RELEASE)
  set(${dir_path_abs_var} "${dir_path_abs}" PARENT_SCOPE)
endfunction()

function(tkl_remove_ret_code_file_dir dir_path_abs)
  tkl_file_remove_recurse("${dir_path_abs}")
endfunction()

function(tkl_set_ret_code_to_file_dir dir_path_abs value)
  set(file_path_abs "${dir_path_abs}/ret_code.var")
  tkl_file_write("${file_path_abs}" "${value}") # not set yet
  #file(LOCK "${dir_path_abs}" DIRECTORY RELEASE)
endfunction()

function(tkl_get_ret_code_from_file_dir dir_path_abs value_var)
  set(file_path_abs "${dir_path_abs}/ret_code.var")
  tkl_file_read(value "${file_path_abs}" OFFSET 0)
  #file(LOCK "${dir_path_abs}" DIRECTORY RELEASE)
  set(${value_var} "${value}" PARENT_SCOPE)
endfunction()

endif()
