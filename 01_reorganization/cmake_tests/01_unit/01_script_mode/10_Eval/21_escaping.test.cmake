include(tacklelib/Eval)

function(TestCase_var_expansion_01)
  set(a 111)

  tkl_eval("\
if (\"\${a}\" STREQUAL \"111\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a}")
  endif()
endfunction()

function(TestCase_var_expansion_02)
  set(a 222)

  tkl_eval("\
if (a STREQUAL \"222\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a}")
  endif()
endfunction()


function(TestCase_var_expansion_11)
  set(a 111)

  tkl_macro_eval("\
if (a STREQUAL \"111\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a}")
  endif()
endfunction()

function(TestCase_var_expansion_12)
  set(a 222)

  tkl_macro_eval("\
if (a STREQUAL \"222\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a}")
  endif()
endfunction()


function(TestCase_var_expansion_21)
  set(a 111)

  tkl_macro_fast_eval("\
if (a STREQUAL \"111\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a}")
  endif()
endfunction()

function(TestCase_var_expansion_22)
  set(a 222)

  tkl_macro_fast_eval("\
if (a STREQUAL \"222\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a}")
  endif()
endfunction()

###

function(TestCase_var_expansion_escaping_wo_eval_01)
  set(a 111)
  set(b "$\\{a}")

  tkl_test_assert_true("b STREQUAL \"$\\\\{a}\"" "1 a=${a} b=${b}")
  if (b STREQUAL "$\\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_wo_eval_02)
  set(a 222)
  set(b "\${a}")

  tkl_test_assert_true("b STREQUAL \"\\\${a}\"" "a=${a} b=${b}")
  if (b STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 a=${a} b=${b}")
  endif()
endfunction()


function(TestCase_var_expansion_escaping_01)
  set(a 333)

  tkl_eval("set(b \"\${a}\")")

  if (b STREQUAL "333")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_02)
  set(a 444)

  tkl_eval("set(b \"$\{a}\")")

  if (b STREQUAL "444")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_03)
  set(a 555)

  tkl_eval("set(b \"$\\{a}\")")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "1 a=${a} b=${b}")
  if (b STREQUAL "$\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_04)
  set(a 666)

  tkl_eval("set(b \"\\\${a}\")")

  tkl_test_assert_true("b STREQUAL \"\\\${a}\"" "1 a=${a} b=${b}")
  if (b STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 a=${a} b=${b}")
  endif()
endfunction()


function(TestCase_var_expansion_escaping_11)
  set(a 333)

  tkl_macro_eval("set(b \"\${a}\")")

  if (b STREQUAL "333")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_12)
  set(a 444)

  tkl_macro_eval("set(b \"$\{a}\")")

  if (b STREQUAL "444")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_13)
  set(a 555)

  tkl_macro_eval("set(b \"$\\\\{a}\")")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "1 a=${a} b=${b}")
  if (b STREQUAL "$\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_14)
  set(a 666)

  tkl_macro_eval("set(b \"\\\\\\\${a}\")")

  tkl_test_assert_true("b STREQUAL \"\\\${a}\"" "1 a=${a} b=${b}")
  if (b STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 a=${a} b=${b}")
  endif()
endfunction()


function(TestCase_var_expansion_escaping_21)
  set(a 333)

  tkl_macro_fast_eval("set(b \"\${a}\")")

  if (b STREQUAL "333")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_22)
  set(a 444)

  tkl_macro_fast_eval("set(b \"$\{a}\")")

  if (b STREQUAL "444")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_23)
  set(a 555)

  tkl_macro_fast_eval("set(b \"$\\\\{a}\")")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "1 a=${a} b=${b}")
  if (b STREQUAL "$\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_24)
  set(a 666)

  tkl_macro_fast_eval("set(b \"\\\\\\\${a}\")")

  tkl_test_assert_true("b STREQUAL \"\\\${a}\"" "1 a=${a} b=${b}")
  if (b STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "2 a=${a} b=${b}")
  endif()
endfunction()

###

function(test_func_arg_expansion_01 a)
  tkl_eval("\
if (\"${a}\" STREQUAL \"111\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "01 a=${a}")
  endif()
endfunction()

function(test_func_arg_expansion_02 a)
  tkl_macro_eval("\
if (\"${a}\" STREQUAL \"111\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "02 a=${a}")
  endif()
endfunction()

function(test_func_arg_expansion_03 a)
  tkl_macro_fast_eval("\
if (\"${a}\" STREQUAL \"111\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "03 a=${a}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_01)
  test_func_arg_expansion_01(111)
  test_func_arg_expansion_02(111)
  test_func_arg_expansion_03(111)
endfunction()

function(test_func_arg_expansion_11 a)
  tkl_eval("\
if (a STREQUAL \"222\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "11 a=${a}")
  endif()
endfunction()

function(test_func_arg_expansion_12 a)
  tkl_macro_eval("\
if (a STREQUAL \"222\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "12 a=${a}")
  endif()
endfunction()

function(test_func_arg_expansion_13 a)
  tkl_macro_fast_eval("\
if (a STREQUAL \"222\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "13 a=${a}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_02)
  test_func_arg_expansion_11(222)
  test_func_arg_expansion_12(222)
  test_func_arg_expansion_13(222)
endfunction()

###

function(test_func_arg_expansion_escaping_01 a)
  tkl_eval("set(b \"\${a}\")")

  if (b STREQUAL "333")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "01 a=${a} b=${b}")
  endif()
endfunction()

function(test_func_arg_expansion_escaping_02 a)
  tkl_macro_eval("set(b \"\${a}\")")

  if (b STREQUAL "333")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "02 a=${a} b=${b}")
  endif()
endfunction()

function(test_func_arg_expansion_escaping_03 a)
  tkl_macro_fast_eval("set(b \"\${a}\")")

  if (b STREQUAL "333")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "03 a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_escaping_01)
  test_func_arg_expansion_escaping_01(333)
  test_func_arg_expansion_escaping_02(333)
  test_func_arg_expansion_escaping_03(333)
endfunction()


function(test_func_arg_expansion_escaping_11 a)
  tkl_eval("set(b \"$\{a}\")")

  if (b STREQUAL "444")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "11 a=${a} b=${b}")
  endif()
endfunction()

function(test_func_arg_expansion_escaping_12 a)
  tkl_macro_eval("set(b \"$\{a}\")")

  if (b STREQUAL "444")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "12 a=${a} b=${b}")
  endif()
endfunction()

function(test_func_arg_expansion_escaping_13 a)
  tkl_macro_fast_eval("set(b \"$\{a}\")")

  if (b STREQUAL "444")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "13 a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_escaping_02)
  test_func_arg_expansion_escaping_11(444)
  test_func_arg_expansion_escaping_12(444)
  test_func_arg_expansion_escaping_13(444)
endfunction()


function(test_func_arg_expansion_escaping_21 a)
  tkl_eval("set(b \"$\\{a}\")")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "21 1 a=${a} b=${b}")
  if (b STREQUAL "$\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "21 2 a=${a} b=${b}")
  endif()
endfunction()

function(test_func_arg_expansion_escaping_22 a)
  tkl_macro_eval("set(b \"$\\\\{a}\")")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "22 1 a=${a} b=${b}")
  if (b STREQUAL "$\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "22 2 a=${a} b=${b}")
  endif()
endfunction()

function(test_func_arg_expansion_escaping_23 a)
  tkl_macro_fast_eval("set(b \"$\\\\{a}\")")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "23 1 a=${a} b=${b}")
  if (b STREQUAL "$\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "23 2 a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_escaping_03)
  test_func_arg_expansion_escaping_21(555)
  test_func_arg_expansion_escaping_22(555)
  test_func_arg_expansion_escaping_23(555)
endfunction()


function(test_func_arg_expansion_escaping_31 a)
  tkl_eval("set(b \"\\\${a}\")")

  tkl_test_assert_true("b STREQUAL \"\\\${a}\"" "31 1 a=${a} b=${b}")
  if (b STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "31 2 a=${a} b=${b}")
  endif()
endfunction()

function(test_func_arg_expansion_escaping_32 a)
  tkl_macro_eval("set(b \"\\\\\\\${a}\")")

  tkl_test_assert_true("b STREQUAL \"\\\${a}\"" "32 1 a=${a} b=${b}")
  if (b STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "32 2 a=${a} b=${b}")
  endif()
endfunction()

function(test_func_arg_expansion_escaping_33 a)
  tkl_macro_fast_eval("set(b \"\\\\\\\${a}\")")

  tkl_test_assert_true("b STREQUAL \"\\\${a}\"" "33 1 a=${a} b=${b}")
  if (b STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "33 2 a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_escaping_04)
  test_func_arg_expansion_escaping_31(666)
  test_func_arg_expansion_escaping_32(666)
  test_func_arg_expansion_escaping_33(666)
endfunction()


function(test_func_arg_expansion_escaping_wo_eval_01 a)
  set(b "$\\{a}")

  tkl_test_assert_true("b STREQUAL \"$\\\\{a}\"" "01 1 a=${a} b=${b}")
  if (b STREQUAL "$\\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "01 2 a=${a} b=${b}")
  endif()
endfunction()

function(test_func_arg_expansion_escaping_wo_eval_02 a)
  set(b "\${a}")

  tkl_test_assert_true("b STREQUAL \"\\\${a}\"" "02 1 a=${a} b=${b}")
  if (b STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "02 2 a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_escaping_wo_eval_01)
  test_func_arg_expansion_escaping_wo_eval_01(777)
  test_func_arg_expansion_escaping_wo_eval_02(888)
endfunction()

###

macro(test_macro_arg_expansion_01 a)
  tkl_eval("\
if (\"${a}\" STREQUAL \"111\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "01 a=${a}")
  endif()
endmacro()

macro(test_macro_arg_expansion_02 a)
  tkl_macro_eval("\
if (\"${a}\" STREQUAL \"111\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "02 a=${a}")
  endif()
endmacro()

macro(test_macro_arg_expansion_03 a)
  tkl_macro_fast_eval("\
if (\"${a}\" STREQUAL \"111\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "03 a=${a}")
  endif()
endmacro()

function(TestCase_macro_arg_expansion_01)
  test_macro_arg_expansion_01(111)
  test_macro_arg_expansion_02(111)
  test_macro_arg_expansion_03(111)
endfunction()

macro(test_macro_arg_expansion_11 a)
  tkl_eval("\
if (a STREQUAL \"a\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "11 a=${a}")
  endif()
endmacro()

macro(test_macro_arg_expansion_12 a)
  tkl_macro_eval("\
if (a STREQUAL \"a\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "12 a=${a}")
  endif()
endmacro()

macro(test_macro_arg_expansion_13 a)
  tkl_macro_fast_eval("\
if (a STREQUAL \"a\")
  set(ret 1)
else()
  set(ret 0)
endif()
")

  if (ret EQUAL 1)
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "13 a=${a}")
  endif()
endmacro()

function(TestCase_macro_arg_expansion_02)
  test_macro_arg_expansion_11(222)
  test_macro_arg_expansion_12(222)
  test_macro_arg_expansion_13(222)
endfunction()

###

macro(test_macro_arg_expansion_escaping_11 a)
  tkl_eval("set(b \"$\{a}\")") # macro parameters should not be visible inside the command

  if (b STREQUAL "") # specific case
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "11 a=${a} b=${b}")
  endif()
endmacro()

macro(test_macro_arg_expansion_escaping_12 a)
  tkl_macro_eval("set(b \"$\{a}\")") # macro parameters should not be visible inside the command

  if (b STREQUAL "") # specific case
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "12 a=${a} b=${b}")
  endif()
endmacro()

macro(test_macro_arg_expansion_escaping_13 a)
  tkl_macro_fast_eval("set(b \"$\{a}\")") # macro parameters should not be visible inside the command

  if (b STREQUAL "") # specific case
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "13 a=${a} b=${b}")
  endif()
endmacro()

function(TestCase_macro_arg_expansion_escaping_02)
  test_macro_arg_expansion_escaping_11(444)
  test_macro_arg_expansion_escaping_12(444)
  test_macro_arg_expansion_escaping_13(444)
endfunction()

macro(test_macro_arg_expansion_escaping_21 a)
  tkl_eval("set(b \"$\\{a}\")")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "02 1 a=${a} b=${b}")
  if (b STREQUAL "$\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "02 2 a=${a} b=${b}")
  endif()
endmacro()

macro(test_macro_arg_expansion_escaping_22 a)
  tkl_macro_eval("set(b \"$\\\\{a}\")")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "22 1 a=${a} b=${b}")
  if (b STREQUAL "$\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "22 2 a=${a} b=${b}")
  endif()
endmacro()

macro(test_macro_arg_expansion_escaping_23 a)
  tkl_macro_fast_eval("set(b \"$\\\\{a}\")")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "23 1 a=${a} b=${b}")
  if (b STREQUAL "$\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "23 2 a=${a} b=${b}")
  endif()
endmacro()

function(TestCase_macro_arg_expansion_escaping_03)
  test_macro_arg_expansion_escaping_21(555)
  test_macro_arg_expansion_escaping_22(555)
  test_macro_arg_expansion_escaping_23(555)
endfunction()

macro(test_macro_arg_expansion_escaping_wo_eval_01 a)
  set(b "$\\{a}")

  tkl_test_assert_true("b STREQUAL \"$\\\\{a}\"" "01 1 a=${a} b=${b}")
  if (b STREQUAL "$\\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "01 2 a=${a} b=${b}")
  endif()
endmacro()

macro(test_macro_arg_expansion_escaping_wo_eval_03 a)
  if (a STREQUAL "a") # macro parameters does not exist as variables
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "03 a=${a}")
  endif()
endmacro()

function(TestCase_macro_arg_expansion_escaping_wo_eval_01)
  test_macro_arg_expansion_escaping_wo_eval_01(777)
  test_macro_arg_expansion_escaping_wo_eval_03(999)
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_var_expansion_01
  TestCase_var_expansion_02

  TestCase_var_expansion_11
  TestCase_var_expansion_12

  TestCase_var_expansion_21
  TestCase_var_expansion_22

  ###

  TestCase_var_expansion_escaping_wo_eval_01
  TestCase_var_expansion_escaping_wo_eval_02

  TestCase_var_expansion_escaping_01
  TestCase_var_expansion_escaping_02
  TestCase_var_expansion_escaping_03
  TestCase_var_expansion_escaping_04

  TestCase_var_expansion_escaping_11
  TestCase_var_expansion_escaping_12
  TestCase_var_expansion_escaping_13
  TestCase_var_expansion_escaping_14

  TestCase_var_expansion_escaping_21
  TestCase_var_expansion_escaping_22
  TestCase_var_expansion_escaping_23
  TestCase_var_expansion_escaping_24

  ###

  TestCase_func_arg_expansion_01
  TestCase_func_arg_expansion_02

  ###

  TestCase_func_arg_expansion_escaping_01
  TestCase_func_arg_expansion_escaping_02
  TestCase_func_arg_expansion_escaping_03
  TestCase_func_arg_expansion_escaping_04

  TestCase_func_arg_expansion_escaping_wo_eval_01

  ###

  TestCase_macro_arg_expansion_01
  TestCase_macro_arg_expansion_02

  ###

  #TestCase_macro_arg_expansion_escaping_01 # N/A
  TestCase_macro_arg_expansion_escaping_02
  TestCase_macro_arg_expansion_escaping_03
  #TestCase_macro_arg_expansion_escaping_04 # N/A

  TestCase_macro_arg_expansion_escaping_wo_eval_01
)
