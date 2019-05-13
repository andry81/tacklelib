include(MakeTemp)

function(CreateReturnCodeFile dir_path_abs_var)
  if (NOT TESTLIB_TESTPROC_INDEX STREQUAL "")
    # running under TestLib, the function can call under different cmake processes when the inner timestamp is not yet changed (timestamp has seconds resolution)
    MakeTempDir("CMake.RetCode." "%Y'%m'%d''%H'%M'%SZ" "${TESTLIB_TESTPROC_INDEX}" 8 dir_path_abs)
  else()
    MakeTempDir("CMake.RetCode." "%Y'%m'%d''%H'%M'%SZ" "" 8 dir_path_abs)
  endif()
  set(file_path_abs "${dir_path_abs}/ret_code.var")
  file(WRITE "${file_path_abs}" "") # not set yet
  #file(LOCK "${dir_path_abs}" DIRECTORY RELEASE)
  set(${dir_path_abs_var} "${dir_path_abs}" PARENT_SCOPE)
endfunction()

function(RemoveReturnCodeFile dir_path_abs)
  file(REMOVE_RECURSE "${dir_path_abs}")
endfunction()

function(SetReturnCodeToFile dir_path_abs value)
  set(file_path_abs "${dir_path_abs}/ret_code.var")
  file(WRITE "${file_path_abs}" "${value}") # not set yet
  #file(LOCK "${dir_path_abs}" DIRECTORY RELEASE)
endfunction()

function(GetReturnCodeFromFile dir_path_abs value_var)
  set(file_path_abs "${dir_path_abs}/ret_code.var")
  file(READ "${file_path_abs}" value OFFSET 0)
  #file(LOCK "${dir_path_abs}" DIRECTORY RELEASE)
  set(${value_var} "${value}" PARENT_SCOPE)
endfunction()
