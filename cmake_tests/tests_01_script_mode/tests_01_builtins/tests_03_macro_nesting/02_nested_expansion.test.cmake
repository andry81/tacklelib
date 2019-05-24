include(tacklelib/testlib/TestModule)

tkl_testmodule_init()

set(a 222)
set(prefix "\\")
set(suffix "\${a}")

macro(inner_macro v)
  message("inner_macro v=${v}")
  tkl_test_assert_true("\"${v}\" STREQUAL \"\${prefix}111\${suffix}\"" "1 v=${v}")
  if ("${v}" STREQUAL "${prefix}111${suffix}")
    tkl_test_assert_true(1 "2 v=${v}")
  else()
    tkl_test_assert_true(0 "3 v=${v}")
  endif()
endmacro()

macro(outter_macro v)
  message("outter_macro v=${v}")
  inner_macro("${v}")
endmacro()

macro(outter_function v)
  message("outter_function v=${v}")
  inner_macro("${v}")
endmacro()

outter_macro("\\\\\\\\\\\\\\\\111\\\\\\\${a}")
outter_function("\\\\\\\\\\\\\\\\111\\\\\\\${a}")

tkl_testmodule_update_status()
