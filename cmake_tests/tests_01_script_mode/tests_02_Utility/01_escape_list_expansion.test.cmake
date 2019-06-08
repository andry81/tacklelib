set(a 123)

set(in_str "1;2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\;\\\\\;\\\\;\\\;\\")
tkl_escape_list_expansion(cmdline "${in_str}")

# TODO:
#   Fix visibility of ARGV, ARGC, ARGV0..N in the first argument from the inside of the `tkl_test_assert_true` function.
#  Temporary workarounded it by usage of explicit arguments: argv0, argv1
#
function(test_func argv0 argv1)
  tkl_test_assert_true("argv0 STREQUAL \"1\"" "1 argv0=${argv0}")
  if (argv0 STREQUAL "1")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv0=${argv0}")
  endif()

  # CAUTION: first argument must be escaped by the same rules as implemented in the `tkl_escape_test_assert_string`
  tkl_test_assert_true("argv1 STREQUAL \"2\;3\\\;4\\\\\;5\\\\\\\;6\\\\\\\\\;7\\\\\\\\\\\;\\\${a}\\\;\\\\\\\\\;\\\\\\\;\\\\\;\\\\\"" "1 argv1=${argv1}")

  # CAUTION: second argument must be the same as declared in the `in_str`!
  if (argv1 STREQUAL "2\;3\\;4\\\;5\\\\;6\\\\\;7\\\\\\;\${a}\\;\\\\\;\\\\;\\\;\\")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 argv1=${argv1}")
  endif()
endfunction()

test_func(${cmdline})
