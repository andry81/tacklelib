set(a 123)

#tkl_enable_test_dbg_msg()

###

function(test_inner_func_ARGV_01)
  tkl_test_dbg_msg("test_inner_func_ARGV_01: ARGV=${ARGV}")
  set(out_str "${ARGV}")
  tkl_test_assert_true("\"\${out_str}\" STREQUAL \"\${ref_str}\"" "1 out_str=${out_str} ref_str=${ref_str}")
  if ("${out_str}" STREQUAL "${ref_str}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 out_str=${out_str} ref_str=${ref_str}")
  endif()
endfunction()

macro(test_outter_macro_ARGV_01)
  tkl_test_dbg_msg("test_outter_macro_ARGV_01: ARGV=${ARGV}")
  test_inner_func_ARGV_01("${ARGV}")          # AS A SINGLE ARGUMENT
endmacro()

function(test_outter_func_ARGV_01)
  tkl_test_dbg_msg("test_outter_func_ARGV_01: ARGV=${ARGV}")
  test_inner_func_ARGV_01("${ARGV}")
endfunction()

set(ref_str \${a}\\\\;\\\;\;)

test_outter_macro_ARGV_01(\\\${a}\\\\;\\\;\;)
test_outter_func_ARGV_01(\${a}\\\\;\\\;\;)
test_inner_func_ARGV_01(\${a}\\\\;\\\;\;)
tkl_test_dbg_msg("")

set(ref_str \\111\${a})

test_outter_macro_ARGV_01(\\\\111\\\${a})
test_outter_func_ARGV_01(\\111\${a})
test_inner_func_ARGV_01(\\111\${a})
tkl_test_dbg_msg("")

set(ref_str "\${a}\\;\;;")

test_outter_macro_ARGV_01("\\\${a}\\;\;;")
test_outter_func_ARGV_01("\${a}\\;\;;")
test_inner_func_ARGV_01("\${a}\\;\;;")
tkl_test_dbg_msg("")

set(ref_str "\\111\${a}")

test_outter_macro_ARGV_01("\\\\111\\\${a}")
test_outter_func_ARGV_01("\\111\${a}")
test_inner_func_ARGV_01("\\111\${a}")
tkl_test_dbg_msg("")

###

function(test_inner_func_with_args_01 argv0)
  tkl_test_dbg_msg("test_inner_func_with_args_01: argv0=${argv0}")
  set(out_str "${argv0}")
  tkl_test_assert_true("\"\${out_str}\" STREQUAL \"\${ref_str}\"" "3 out_str=${out_str} ref_str=${ref_str}")
  if ("${out_str}" STREQUAL "${ref_str}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "4 out_str=${out_str} ref_str=${ref_str}")
  endif()
endfunction()

macro(test_outter_macro_with_args_01 argv0)
  tkl_test_dbg_msg("test_outter_macro_with_args_01: argv0=${argv0}")
  test_inner_func_with_args_01("${argv0}")    # AS A SINGLE ARGUMENT
endmacro()

function(test_outter_func_with_args_01 argv0)
  tkl_test_dbg_msg("test_outter_func_with_args_01: argv0=${argv0}")
  test_inner_func_with_args_01("${argv0}")
endfunction()

function(test_outter_func_ARGV_02)
  tkl_test_dbg_msg("test_outter_func_ARGV_02: ARGV=${ARGV}")
  test_inner_func_ARGV_02("${ARGV}")
endfunction()

set(ref_str \${a}\\\\;\\\;\;)

test_outter_macro_with_args_01(\\\${a}\\\\;\\\;\;)
test_outter_func_with_args_01(\${a}\\\\;\\\;\;)
test_inner_func_with_args_01(\${a}\\\\;\\\;\;)
tkl_test_dbg_msg("")

set(ref_str \\111\${a})

test_outter_macro_with_args_01(\\\\111\\\${a})
test_outter_func_with_args_01(\\111\${a})
test_inner_func_with_args_01(\\111\${a})
tkl_test_dbg_msg("")

set(ref_str "\${a}\\;\;;")

test_outter_macro_with_args_01("\\\${a}\\;\;;")
test_outter_func_with_args_01("\${a}\\;\;;")
test_inner_func_with_args_01("\${a}\\;\;;")
tkl_test_dbg_msg("")

set(ref_str "\\111\${a}")

test_outter_macro_with_args_01("\\\\111\\\${a}")
test_outter_func_with_args_01("\\111\${a}")
test_inner_func_with_args_01("\\111\${a}")
tkl_test_dbg_msg("")

###

function(test_inner_func_ARGV_02)
  tkl_test_dbg_msg("test_inner_func_ARGV_02: ARGV=${ARGV}")
  set(out_str "${ARGV}")
  tkl_test_assert_true("\"\${out_str}\" STREQUAL \"\${ref_str}\"" "1 out_str=${out_str} ref_str=${ref_str}")
  if ("${out_str}" STREQUAL "${ref_str}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 out_str=${out_str} ref_str=${ref_str}")
  endif()
endfunction()

macro(test_outter_macro_ARGV_02)
  tkl_test_dbg_msg("test_outter_macro_ARGV_02: ARGV=${ARGV}")
  test_inner_func_ARGV_02(${ARGV})            # WITH OUT QUOTES
endmacro()

function(test_outter_func_with_args_02 argv0)
  tkl_test_dbg_msg("test_outter_func_with_args_02: argv0=${argv0}")
  test_inner_func_with_args_02("${argv0}")
endfunction()

set(ref_str \${a}\\\\;\\\;\;)

test_outter_macro_ARGV_02(\\\${a}\\\\\\\\;\\\\\\\;\\\;)     # CAUTION: difference with previous!
test_outter_func_ARGV_02(\${a}\\\\;\\\;\;)
test_inner_func_ARGV_02(\${a}\\\\;\\\;\;)
tkl_test_dbg_msg("")

set(ref_str \\111\${a})

test_outter_macro_ARGV_02(\\\\111\\\${a})
test_outter_func_ARGV_02(\\111\${a})
test_inner_func_ARGV_02(\\111\${a})
tkl_test_dbg_msg("")

set(ref_str "\${a}\\;\;;")

test_outter_macro_ARGV_02("\\\${a}\\\\\\\\;\\\\\\\;\;")     # CAUTION: difference with previous!
test_outter_func_ARGV_02("\${a}\\;\;;")
test_inner_func_ARGV_02("\${a}\\;\;;")
tkl_test_dbg_msg("")

set(ref_str "\\111\${a}")

test_outter_macro_ARGV_02("\\\\111\\\${a}")
test_outter_func_ARGV_02("\\111\${a}")
test_inner_func_ARGV_02("\\111\${a}")
tkl_test_dbg_msg("")

###

function(test_inner_func_with_args_02 argv0)
  tkl_test_dbg_msg("test_inner_func_with_args_02: argv0=${argv0}")
  set(out_str "${argv0}")
  tkl_test_assert_true("\"\${out_str}\" STREQUAL \"\${ref_str}\"" "3 out_str=${out_str} ref_str=${ref_str}")
  if ("${out_str}" STREQUAL "${ref_str}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "4 out_str=${out_str} ref_str=${ref_str}")
  endif()
endfunction()

macro(test_outter_macro_with_args_02 argv0)
  tkl_test_dbg_msg("test_outter_macro_with_args_02: argv0=${argv0}")
  test_inner_func_with_args_02(${argv0})      # WITH OUT QUOTES
endmacro()

function(test_outter_func_with_args_02 argv0)
  tkl_test_dbg_msg("test_outter_func_with_args_02: argv0=${argv0}")
  test_inner_func_with_args_02("${argv0}")
endfunction()

set(ref_str \${a}\\\\;\\\;\;)

test_outter_macro_with_args_02(\\\${a}\\\\\\\\;\\\\\\\;\\\;)
test_outter_func_with_args_02(\${a}\\\\;\\\;\;)
test_inner_func_with_args_02(\${a}\\\\;\\\;\;)
tkl_test_dbg_msg("")

set(ref_str \\111\${a})

test_outter_macro_with_args_02(\\\\111\\\${a})
test_outter_func_with_args_02(\\111\${a})
test_inner_func_with_args_02(\\111\${a})
tkl_test_dbg_msg("")

set(ref_str "\${a}\\;\;;")

test_outter_macro_with_args_02("\\\${a}\\\\\\\\;\\\\\\\;\;")  # CAUTION: difference with previous!
test_outter_func_with_args_02("\${a}\\;\;;")
test_inner_func_with_args_02("\${a}\\;\;;")
tkl_test_dbg_msg("")

set(ref_str "\\111\${a}")

test_outter_macro_with_args_02("\\\\111\\\${a}")
test_outter_func_with_args_02("\\111\${a}")
test_inner_func_with_args_02("\\111\${a}")
tkl_test_dbg_msg("")
