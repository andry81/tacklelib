include(tacklelib/Eval)

function(TestCase_var_expansion_01)
  set(a 111)

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

###

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

  if (b STREQUAL "$\\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_04)
  set(a 666)

  tkl_eval("set(b \"\\\${a}\")")

  if (b STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_var_expansion_escaping_05)
  set(a 777)
  set(b "$\\{a}")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "a=${a} b=${b}")
endfunction()

function(TestCase_var_expansion_escaping_06)
  set(a 888)
  set(b "\${a}")

  tkl_test_assert_true("b STREQUAL \"\\\${a}\"" "a=${a} b=${b}")
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
    tkl_test_assert_true(0 "a=${a}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_01)
  test_func_arg_expansion_01(111)
endfunction()

function(test_func_arg_expansion_02 a)
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

function(TestCase_func_arg_expansion_02)
  test_func_arg_expansion_02(222)
endfunction()

###

function(test_func_arg_expansion_escaping_01 a)
  tkl_eval("set(b \"\${a}\")")

  if (b STREQUAL "333")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_escaping_01)
  test_func_arg_expansion_escaping_01(333)
endfunction()

function(test_func_arg_expansion_escaping_02 a)
  tkl_eval("set(b \"$\{a}\")")

  if (b STREQUAL "444")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_escaping_02)
  test_func_arg_expansion_escaping_02(444)
endfunction()

function(test_func_arg_expansion_escaping_03 a)
  tkl_eval("set(b \"$\\{a}\")")

  if (b STREQUAL "$\\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_escaping_03)
  test_func_arg_expansion_escaping_03(555)
endfunction()

function(test_func_arg_expansion_escaping_04 a)
  tkl_eval("set(b \"\\\${a}\")")

  if (b STREQUAL "\${a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endfunction()

function(TestCase_func_arg_expansion_escaping_04)
  test_func_arg_expansion_escaping_04(666)
endfunction()

function(test_func_arg_expansion_escaping_05 a)
  set(b "$\\{a}")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "a=${a} b=${b}")
endfunction()

function(TestCase_func_arg_expansion_escaping_05)
  test_func_arg_expansion_escaping_05(777)
endfunction()

function(test_func_arg_expansion_escaping_06 a)
  set(b "\${a}")

  tkl_test_assert_true("b STREQUAL \"\\\${a}\"" "a=${a} b=${b}")
endfunction()

function(TestCase_func_arg_expansion_escaping_06)
  test_func_arg_expansion_escaping_06(888)
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
    tkl_test_assert_true(0 "a=${a}")
  endif()
endmacro()

function(TestCase_macro_arg_expansion_01)
  test_macro_arg_expansion_01(111)
endfunction()

macro(test_macro_arg_expansion_02 a)
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
    tkl_test_assert_true(0 "a=${a}")
  endif()
endmacro()

function(TestCase_macro_arg_expansion_02)
  test_macro_arg_expansion_02(222)
endfunction()

###

macro(test_macro_arg_expansion_escaping_02 a)
  tkl_eval("set(b \"$\{a}\")")

  if (b STREQUAL "b") # specific case
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endmacro()

function(TestCase_macro_arg_expansion_escaping_02)
  test_macro_arg_expansion_escaping_02(444)
endfunction()

macro(test_macro_arg_expansion_escaping_03 a)
  tkl_eval("set(b \"$\\{a}\")")

  if (b STREQUAL "$\\{a}")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a} b=${b}")
  endif()
endmacro()

function(TestCase_macro_arg_expansion_escaping_03)
  test_macro_arg_expansion_escaping_03(555)
endfunction()

macro(test_macro_arg_expansion_escaping_05 a)
  set(b "$\\{a}")

  tkl_test_assert_true("b STREQUAL \"$\\{a}\"" "a=${a} b=${b}")
endmacro()

function(TestCase_macro_arg_expansion_escaping_05)
  test_macro_arg_expansion_escaping_05(777)
endfunction()

macro(test_macro_arg_expansion_escaping_09 a)
  if (a STREQUAL "a")
    tkl_test_assert_true(1)
  else()
    tkl_test_assert_true(0 "a=${a}")
  endif()
endmacro()

function(TestCase_macro_arg_expansion_escaping_09)
  test_macro_arg_expansion_escaping_09(999)
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_var_expansion_01
  TestCase_var_expansion_02

  ###

  TestCase_var_expansion_escaping_01
  TestCase_var_expansion_escaping_02
  TestCase_var_expansion_escaping_03
  TestCase_var_expansion_escaping_04
  TestCase_var_expansion_escaping_05
  TestCase_var_expansion_escaping_06

  ###

  TestCase_func_arg_expansion_01
  TestCase_func_arg_expansion_02

  ###

  TestCase_func_arg_expansion_escaping_01
  TestCase_func_arg_expansion_escaping_02
  TestCase_func_arg_expansion_escaping_03
  TestCase_func_arg_expansion_escaping_04
  TestCase_func_arg_expansion_escaping_05
  TestCase_func_arg_expansion_escaping_06

  ###

  TestCase_macro_arg_expansion_01
  TestCase_macro_arg_expansion_02

  ###

  #TestCase_macro_arg_expansion_escaping_01 # N/A
  TestCase_macro_arg_expansion_escaping_02
  TestCase_macro_arg_expansion_escaping_03
  #TestCase_macro_arg_expansion_escaping_04 # N/A
  TestCase_macro_arg_expansion_escaping_05
  #TestCase_macro_arg_expansion_escaping_06 # N/A
  TestCase_macro_arg_expansion_escaping_09 # specific case
)
