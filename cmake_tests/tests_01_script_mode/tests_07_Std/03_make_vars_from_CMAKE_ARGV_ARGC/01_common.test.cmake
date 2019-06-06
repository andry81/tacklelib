include(tacklelib/Eval)

function(dbg_message msg)
  #message("${msg}")
endfunction()

function(make_CMAKE_ARGV_from_ARGV)
  tkl_make_var_from_ARGV_begin("${ARGV}" argv)
  tkl_make_var_from_ARGV_end(argv)

  set(arg_index 0)
  foreach(arg IN LISTS argv)
    # WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
    string(REPLACE ";" "\;" arg "${arg}")

    set(CMAKE_ARGV${arg_index} "${arg}" PARENT_SCOPE)

    math(EXPR arg_index ${arg_index}+1)
  endforeach()

  set(CMAKE_ARGC ${arg_index} PARENT_SCOPE)
endfunction()

set(a 123)

macro(TestCase_test_01)
  make_CMAKE_ARGV_from_ARGV(app.ext -P module.cmake "a\\b" "c;d" "e\;f" "\${a}")
  dbg_message("CMAKE_ARGC=${CMAKE_ARGC} CMAKE_ARGV0=${CMAKE_ARGV0} CMAKE_ARGV1=${CMAKE_ARGV1} CMAKE_ARGV2=${CMAKE_ARGV2} CMAKE_ARGV3=${CMAKE_ARGV3} CMAKE_ARGV4=${CMAKE_ARGV4}")

  tkl_make_var_from_CMAKE_ARGV_ARGC(argv)

  tkl_test_assert_true("argv STREQUAL \"app.ext;-P;module.cmake;a\\\\b;c\\\\\\\;d;e\\\\\\\\\\\;f;\\\${a}\"" "1 argv=${argv}")
  if (argv STREQUAL "app.ext;-P;module.cmake;a\\b;c\\\;d;e\\\\\;f;\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv=${argv}")
  endif()

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)
  list(GET argv 3 argv3)
  list(GET argv 4 argv4)
  list(GET argv 5 argv5)
  list(GET argv 6 argv6)

  tkl_test_assert_true("argv0 STREQUAL \"app.ext\"" "1 argv0=${argv0}")
  if (argv0 STREQUAL "app.ext")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv0=${argv0}")
  endif()

  tkl_test_assert_true("argv1 STREQUAL \"-P\"" "1 argv1=${argv1}")
  if (argv1 STREQUAL "-P")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv1=${argv1}")
  endif()

  tkl_test_assert_true("argv2 STREQUAL \"module.cmake\"" "1 argv2=${argv2}")
  if (argv2 STREQUAL "module.cmake")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv2=${argv2}")
  endif()

  tkl_test_assert_true("argv3 STREQUAL \"a\\\\b\"" "1 argv3=${argv3}")
  if (argv3 STREQUAL "a\\b")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv3=${argv3}")
  endif()

  tkl_test_assert_true("argv4 STREQUAL \"c\\\;d\"" "1 argv4=${argv4}")
  if (argv4 STREQUAL "c\;d")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv4=${argv4}")
  endif()

  tkl_test_assert_true("argv5 STREQUAL \"e\\\\\;f\"" "1 argv5=${argv5}")
  if (argv5 STREQUAL "e\\\;f")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv5=${argv5}")
  endif()

  tkl_test_assert_true("argv6 STREQUAL \"\\\${a}\"" "1 argv6=${argv6}")
  if (argv6 STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv6=${argv6}")
  endif()
endmacro()

macro(TestCase_test_02)
  make_CMAKE_ARGV_from_ARGV(app.ext -P module.cmake "a\\b" "c;d" "e\;f" "\${a}")
  dbg_message("CMAKE_ARGC=${CMAKE_ARGC} CMAKE_ARGV0=${CMAKE_ARGV0} CMAKE_ARGV1=${CMAKE_ARGV1} CMAKE_ARGV2=${CMAKE_ARGV2} CMAKE_ARGV3=${CMAKE_ARGV3} CMAKE_ARGV4=${CMAKE_ARGV4}")

  tkl_make_var_from_CMAKE_ARGV_ARGC(-P argv)

  tkl_test_assert_true("argv STREQUAL \"module.cmake;a\\\\b;c\\\\\\\;d;e\\\\\\\\\\\;f;\\\${a}\"" "1 argv=${argv}")
  if (argv STREQUAL "module.cmake;a\\b;c\\\;d;e\\\\\;f;\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv=${argv}")
  endif()

  list(GET argv 0 argv0)
  list(GET argv 1 argv1)
  list(GET argv 2 argv2)
  list(GET argv 3 argv3)
  list(GET argv 4 argv4)

  tkl_test_assert_true("argv0 STREQUAL \"module.cmake\"" "1 argv0=${argv0}")
  if (argv0 STREQUAL "module.cmake")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv0=${argv0}")
  endif()

  tkl_test_assert_true("argv1 STREQUAL \"a\\\\b\"" "1 argv1=${argv1}")
  if (argv1 STREQUAL "a\\b")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv1=${argv1}")
  endif()

  tkl_test_assert_true("argv2 STREQUAL \"c\\\;d\"" "1 argv2=${argv2}")
  if (argv2 STREQUAL "c\;d")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv2=${argv2}")
  endif()

  tkl_test_assert_true("argv3 STREQUAL \"e\\\\\;f\"" "1 argv3=${argv3}")
  if (argv3 STREQUAL "e\\\;f")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv3=${argv3}")
  endif()

  tkl_test_assert_true("argv4 STREQUAL \"\\\${a}\"" "1 argv4=${argv4}")
  if (argv4 STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv4=${argv4}")
  endif()
endmacro()

tkl_testmodule_run_test_cases(
  TestCase_test_01
  TestCase_test_02
)
