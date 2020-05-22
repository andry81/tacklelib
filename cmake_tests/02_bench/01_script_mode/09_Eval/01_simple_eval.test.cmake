include(tacklelib/Eval)

# implementation from here: https://stackoverflow.com/a/43073402/2672125
function(cmakepp_eval_01 __eval_code)
  # one file per execution of cmake (if this file were in memory it would probably be faster...)
  # this is where the temporary eval file will be stored.  it will only be used once per eval
  # and since cmake is not multihreaded no race conditions should occure.  however if you start 
  # two cmake processes in the same project this could lead to collisions
  set(__eval_temp_file "${CMAKE_CURRENT_BINARY_DIR}/__eval_temp.cmake")

  # write the content of temp file and include it directly, this overwrite the 
  # eval function you are currently defining (initializer function pattern)
  file(WRITE "${__eval_temp_file}" "
function(cmakepp_eval_01 __eval_code)
  file(WRITE ${__eval_temp_file} \"\${__eval_code}\")
  include(${__eval_temp_file})
  tkl_file_remove(\"${__eval_temp_file}\")
endfunction()
  ")

  include("${__eval_temp_file}")
  ## now eval is defined as what was just written into __eval_temp_file

  ## since we are still in first definition we just need to execute eval now
  ## (which calls the second definition of eval).
  cmakepp_eval_01("${__eval_code}")
endfunction()

# modificated previous implementation
function(cmakepp_eval_02 __eval_code)
  tkl_make_basic_timestamp_temp_dir(__eval_temp_dir "CMake.cmakepp.eval" 8)
  set(__eval_temp_file "${__eval_temp_dir}/__eval_temp.cmake")

  tkl_file_write("${__eval_temp_file}" "
function(cmakepp_eval_02 __eval_code)
  tkl_file_write(\"${__eval_temp_file}\" \"\${__eval_code}\")
  include(${__eval_temp_file})
  tkl_file_remove_recurse(\"${__eval_temp_dir}\")
endfunction()
  ")

  include("${__eval_temp_file}")

  cmakepp_eval_02("${__eval_code}")
endfunction()

function(TestCase_direct_message)
  tkl_test_info_msg("TestCase_direct_message_run_count=${TestCase_direct_message_run_count}")

  math(EXPR TestCase_direct_message_run_upper_count ${TestCase_direct_message_run_count}-1)
  foreach(i RANGE ${TestCase_direct_message_run_upper_count})
    message(1)
  endforeach()

  tkl_testmodule_time_check_point_sec(time_spent_int_sec)
  tkl_uint_div(time_spent_per_call_int_sec time_spent_per_call_frac_sec 3 ${time_spent_int_sec} ${TestCase_direct_message_run_count})

  tkl_test_info_msg("Time spent per call: ${time_spent_per_call_int_sec}.${time_spent_per_call_frac_sec} sec")

  tkl_test_assert_true(1)
endfunction()

function(TestCase_tkl_eval_message)
  tkl_test_info_msg("TestCase_tkl_eval_message_run_count=${TestCase_tkl_eval_message_run_count}")

  math(EXPR TestCase_tkl_eval_message_run_upper_count ${TestCase_tkl_eval_message_run_count}-1)
  foreach(i RANGE ${TestCase_tkl_eval_message_run_upper_count})
    tkl_eval("message(1)")
  endforeach()

  tkl_testmodule_time_check_point_sec(time_spent_int_sec)
  tkl_uint_div(time_spent_per_call_int_sec time_spent_per_call_frac_sec 3 ${time_spent_int_sec} ${TestCase_tkl_eval_message_run_count})

  tkl_test_info_msg("Time spent per call: ${time_spent_per_call_int_sec}.${time_spent_per_call_frac_sec} sec")

  tkl_test_assert_true(1)
endfunction()

function(TestCase_tkl_macro_eval_message)
  tkl_test_info_msg("TestCase_tkl_macro_eval_message_run_count=${TestCase_tkl_macro_eval_message_run_count}")

  math(EXPR TestCase_tkl_macro_eval_message_run_upper_count ${TestCase_tkl_macro_eval_message_run_count}-1)
  foreach(i RANGE ${TestCase_tkl_macro_eval_message_run_upper_count})
    tkl_macro_eval("message(1)")
  endforeach()

  tkl_testmodule_time_check_point_sec(time_spent_int_sec)
  tkl_uint_div(time_spent_per_call_int_sec time_spent_per_call_frac_sec 3 ${time_spent_int_sec} ${TestCase_tkl_macro_eval_message_run_count})

  tkl_test_info_msg("Time spent per call: ${time_spent_per_call_int_sec}.${time_spent_per_call_frac_sec} sec")

  tkl_test_assert_true(1)
endfunction()

function(TestCase_tkl_macro_fast_eval_message)
  tkl_test_info_msg("TestCase_tkl_macro_fast_eval_message_run_count=${TestCase_tkl_macro_fast_eval_message_run_count}")

  math(EXPR TestCase_tkl_macro_fast_eval_message_run_upper_count ${TestCase_tkl_macro_fast_eval_message_run_count}-1)
  foreach(i RANGE ${TestCase_tkl_macro_fast_eval_message_run_upper_count})
    tkl_macro_fast_eval("message(1)")
  endforeach()

  tkl_testmodule_time_check_point_sec(time_spent_int_sec)
  tkl_uint_div(time_spent_per_call_int_sec time_spent_per_call_frac_sec 3 ${time_spent_int_sec} ${TestCase_tkl_macro_fast_eval_message_run_count})

  tkl_test_info_msg("Time spent per call: ${time_spent_per_call_int_sec}.${time_spent_per_call_frac_sec} sec")

  tkl_test_assert_true(1)
endfunction()

function(TestCase_cmakepp_eval_01_message)
  tkl_test_info_msg("TestCase_cmakepp_eval_01_message_run_count=${TestCase_cmakepp_eval_01_message_run_count}")

  math(EXPR TestCase_cmakepp_eval_01_message_run_upper_count ${TestCase_cmakepp_eval_01_message_run_count}-1)
  foreach(i RANGE ${TestCase_cmakepp_eval_01_message_run_upper_count})
    cmakepp_eval_01("message(1)")
  endforeach()

  tkl_testmodule_time_check_point_sec(time_spent_int_sec)
  tkl_uint_div(time_spent_per_call_int_sec time_spent_per_call_frac_sec 3 ${time_spent_int_sec} ${TestCase_cmakepp_eval_01_message_run_count})

  tkl_test_info_msg("Time spent per call: ${time_spent_per_call_int_sec}.${time_spent_per_call_frac_sec} sec")

  tkl_test_assert_true(1)
endfunction()

function(TestCase_cmakepp_eval_02_message)
  tkl_test_info_msg("TestCase_cmakepp_eval_02_message_run_count=${TestCase_cmakepp_eval_02_message_run_count}")

  math(EXPR TestCase_cmakepp_eval_02_message_run_upper_count ${TestCase_cmakepp_eval_02_message_run_count}-1)
  foreach(i RANGE ${TestCase_cmakepp_eval_02_message_run_upper_count})
    cmakepp_eval_02("message(1)")
  endforeach()

  tkl_testmodule_time_check_point_sec(time_spent_int_sec)
  tkl_uint_div(time_spent_per_call_int_sec time_spent_per_call_frac_sec 3 ${time_spent_int_sec} ${TestCase_cmakepp_eval_02_message_run_count})

  tkl_test_info_msg("Time spent per call: ${time_spent_per_call_int_sec}.${time_spent_per_call_frac_sec} sec")

  tkl_test_assert_true(1)
endfunction()

tkl_testmodule_run_test_cases(
  TestCase_direct_message
  TestCase_tkl_eval_message
  TestCase_tkl_macro_eval_message
  TestCase_tkl_macro_fast_eval_message
  TestCase_cmakepp_eval_01_message
  TestCase_cmakepp_eval_02_message
)
