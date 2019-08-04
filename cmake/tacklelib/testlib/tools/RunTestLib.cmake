include(tacklelib/testlib/TestLib)

tkl_testlib_init()

if (ENABLE_CMAKE_COMMAND_FROM_COMMAND_LIST)
  tkl_testlib_setup_msg("Enabled `CMAKE_COMMAND` variable's values read from the external list - `CMAKE_COMMAND_LIST`:")

  foreach(CMAKE_COMMAND IN LISTS CMAKE_COMMAND_LIST)
    tkl_testlib_info_msg("CMAKE_COMMAND=`${CMAKE_COMMAND}`")
  endforeach()
  message("===")

  tkl_testlib_setup_msg("CMAKE_COMMAND=`${CMAKE_COMMAND}`")
  tkl_testlib_setup_msg(">\${CMAKE_COMMAND} --version")
  execute_process(
    COMMAND
      "${CMAKE_COMMAND}"
      --version
  )
  message("---")

  tkl_make_var_from_CMAKE_ARGV_ARGC(cmake_argv)
  #message("cmake_argv=${cmake_argv}")

  tkl_list_sublist(cmake_argv_tail 1 -1 cmake_argv)
  #message("cmake_argv_tail=${cmake_argv_tail}")

  tkl_escape_list_expansion(cmake_args "${cmake_argv_tail}")
  #message("cmake_args=${cmake_args}")

  foreach(CMAKE_COMMAND IN LISTS CMAKE_COMMAND_LIST)
    if (EXISTS "${CMAKE_COMMAND}" AND NOT IS_DIRECTORY "${CMAKE_COMMAND}")
      # We must call the new cmake version from here directly instead of include and pass all respective variables.
      execute_process(
        COMMAND
          "${CMAKE_COMMAND}"
          "-DTACKLELIB_TESTLIB_SKIP_LOAD_VARS=1"        # skip load variables from `tkl_testlib_init` function
          "-DENABLE_CMAKE_COMMAND_FROM_COMMAND_LIST=0"  # disable recursion
          ${cmake_args}
      )
    else()
      message(WARNING "CMAKE_COMMAND is not found: CMAKE_COMMAND=`${CMAKE_COMMAND}`")
    endif()
  endforeach()
else()
  tkl_testlib_setup_msg("CMAKE_COMMAND=`${CMAKE_COMMAND}`")
  tkl_testlib_setup_msg(">\${CMAKE_COMMAND} --version")
  execute_process(
    COMMAND
      "${CMAKE_COMMAND}"
      --version
  )
  include("${TACKLELIB_TESTLIB_TESTSCRIPT_FILE}")
endif()

tkl_testlib_exit()
