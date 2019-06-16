include(tacklelib/testlib/TestLib)

tkl_testlib_init()

if (ENABLE_CMAKE_COMMAND_FROM_COMMAND_LIST)
  tkl_testlib_setup_msg("Enabled `CMAKE_COMMAND` variable's values read from the external list - `CMAKE_COMMAND_LIST`:")

  foreach(CMAKE_COMMAND IN LISTS CMAKE_COMMAND_LIST)
    tkl_testlib_info_msg("CMAKE_COMMAND=`${CMAKE_COMMAND}`")
  endforeach()

  foreach(CMAKE_COMMAND IN LISTS CMAKE_COMMAND_LIST)
    if (EXISTS "${CMAKE_COMMAND}" AND NOT IS_DIRECTORY "${CMAKE_COMMAND}")
      tkl_testlib_setup_msg("CMAKE_COMMAND=`${CMAKE_COMMAND}`")
      tkl_testlib_setup_msg(">\${CMAKE_COMMAND} --version")
      execute_process(
        COMMAND
          "${CMAKE_COMMAND}"
          --version
      )
      include("${TACKLELIB_TESTLIB_TESTSCRIPT_FILE}")
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
