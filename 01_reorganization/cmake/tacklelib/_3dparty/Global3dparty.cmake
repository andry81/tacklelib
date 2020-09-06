function(find_global_3dparty_environments out_global_vars_file_path_list_var)
  if (NOT _3DPARTY_GLOBAL_ROOTS_LIST)
    set(${out_global_vars_file_path_list_var} "" PARENT_SCOPE)
    return()
  endif()

  if(NOT _3DPARTY_GLOBAL_ROOTS_FILE_LIST)
    set(_3DPARTY_GLOBAL_ROOTS_FILE_LIST "environment.vars")
  endif()

  set(global_vars_file_path_list "")

  list(REMOVE_DUPLICATES _3DPARTY_GLOBAL_ROOTS_LIST)
  list(REMOVE_DUPLICATES _3DPARTY_GLOBAL_ROOTS_FILE_LIST)

  foreach(root_path IN LISTS _3DPARTY_GLOBAL_ROOTS_LIST)
    foreach(file_path IN LISTS _3DPARTY_GLOBAL_ROOTS_FILE_LIST)
      set(env_file_path "${root_path}/${file_path}")
      if (EXISTS "${env_file_path}")
        message(STATUS "(*) Environment file found: `${env_file_path}`")
        list(APPEND global_vars_file_path_list "${env_file_path}")
      endif()
    endforeach()
  endforeach()

  set(${out_global_vars_file_path_list_var} "${global_vars_file_path_list}" PARENT_SCOPE)
endfunction()
