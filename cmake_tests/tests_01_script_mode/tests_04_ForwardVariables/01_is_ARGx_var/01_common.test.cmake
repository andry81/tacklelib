tkl_is_ARGx_var(is_argx "ARGV")
tkl_test_assert_true("is_argx" "ARGV=${is_argx}")

tkl_is_ARGx_var(is_argx "ARGC")
tkl_test_assert_true("is_argx" "ARGC=${is_argx}")

tkl_is_ARGx_var(is_argx "ARGN")
tkl_test_assert_true("is_argx" "ARGN=${is_argx}")

set(index 0)
while(index LESS 32)
  tkl_is_ARGx_var(is_argx "ARGV${index}")
  tkl_test_assert_true("is_argx" "ARGV{$index}=${is_argx}")

  math(EXPR index ${index}+1)
endwhile()
