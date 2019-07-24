set(a 123)

# TODO:
#  Fix visibility of ARGV, ARGC, ARGV0..N in the first argument from the inside of the `tkl_test_assert_true` function.
#  Temporary workarounded is by usage of explicit arguments: argv0, argv1
#
function(test_func_with_list_sep_escape argv0 argv1)
  tkl_test_assert_true("argv0 STREQUAL \"1\"" "1 argv0=${argv0}")
  if (argv0 STREQUAL "1")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv0=${argv0}")
  endif()

  # CAUTION: first argument must be escaped by the same rules as implemented in the `tkl_escape_test_assert_string`
  # r"2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\;\\\\\;\\\\;\\\;\\"
  tkl_test_assert_true("argv1 STREQUAL \"2\;3\\\;4\\\\\;5\\\\\\\;6\\\\\\\\\;7\\\\\\\\\\\;\\\${a}\\\;\\\\\\\\\;\\\\\\\;\\\\\;\\\\\"" "1 argv1=${argv1}")

  # CAUTION: second argument must be the same as declared in the `in_str`!
  # r"2\;3\;4\\;5\\;6\\\;7\\\;${a}\;\\\;\\;\\;\"
  if (argv1 STREQUAL "2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\;\\\\\;\\\\;\\\;\\")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv1=${argv1}")
  endif()
endfunction()

function(test_func_wo_list_sep_escape argv0 argv1)
  tkl_test_assert_true("argv0 STREQUAL \"1\"" "3 argv0=${argv0}")
  if (argv0 STREQUAL "1")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "4 argv0=${argv0}")
  endif()

  # CAUTION: first argument must be escaped by the same rules as implemented in the `tkl_escape_test_assert_string`
  # r"2;3;4\;5\;6\\\;7\\\;\${a};\\\;\;\;\\"
  tkl_test_assert_true("argv1 STREQUAL \"2;3;4\\;5\\;6\\\\\\;7\\\\\\;\\\${a};\\\\\\;\\;\\;\\\\\"" "3 argv1=${argv1}")

  # CAUTION: second argument must be the same as declared in the `in_str`!
  # r"2;3;4\;5\;6\\;7\\;${a};\\;\;\;\"
  if (argv1 STREQUAL "2;3;4\;5\;6\\\;7\\\;\${a};\\\;\;\;\\")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "4 argv1=${argv1}")
  endif()
endfunction()

set(in_str "1;2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\;\\\\\;\\\\;\\\;\\")

tkl_escape_list_expansion(cmdline "${in_str}" 0 1)
test_func_with_list_sep_escape(${cmdline})

tkl_escape_list_expansion(cmdline "${in_str}")
test_func_wo_list_sep_escape(${cmdline})
