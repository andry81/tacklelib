#!/bin/bash

# Script library to support testing.

# LEGEND:
#   tkl_testmodule_*  - Functions for a single module, where the `tkl_testmodule_init` function calls manually by user.
#                       Basically that is a runnable single script containing multiple test cases.
#   tkl_test_*        - Functions for a single test case, where a test case is consisted from a single
#                       bash function and the `tkl_test_init` function calls automatically by the
#                       `tkl_testmodule_run_test` function.
#

# Note:
#   Return codes 127 and higher is reserved for the test system itself.
#

# Script can be ONLY included by "source" command.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$SOURCE_TACKLELIB_TESTLIB_SH" || SOURCE_TACKLELIB_TESTLIB_SH -eq 0) ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

SOURCE_TACKLELIB_TESTLIB_SH=1 # including guard

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  echo."$0: error: \`bash_tacklelib\` must be included explicitly."
  exit 255
fi >&2

tkl_include_or_abort 'baselib.sh'
tkl_include_or_abort 'traplib.sh'
tkl_include_or_abort 'funclib.sh'
tkl_include_or_abort 'stringlib.sh'

# special variable to direct inclusion in the `tkl_testmodule_run_test` function
SOURCE_TACKLELIB_TESTLIB_FILE="$BASH_SOURCE_FILE"

function tkl_test_echo()
{
  local code=$?
  echo "$@" 1>&3
  return $code
}

function tkl_testmodule_init()
{
  # avoid double initialization
  [[ -z "$TestModuleSessionId" ]] || return 0

  tkl_push_trap '' INT # ignore interruption while at init
  tkl_push_trap 'tkl_pop_trap INT' RETURN

  tkl_convert_backend_path_to_native "$BASH" -s
  echo "Environment:"
  echo "  BASH_VERSION=\"$BASH_VERSION\""
  echo "  BASH=\"$BASH\" -> \"$RETURN_VALUE\""
  echo "  PATH=\"$PATH\""
  echo

  local IFS=$' \t\r\n' # by default

  # Cleanup and reset locale to avoid potential problems with sort, grep and string comparison.
  unset LANG
  export LC_COLLATE=C
  export LC_ALL=C

  LAST_WAIT_PID=0

  NUM_TESTS_OVERALL=0
  NUM_TESTS_PASSED=0
  NUM_TESTS_FAILED=0

  TEST_SOURCES=()
  TEST_FUNCTIONS=()
  TEST_VARIABLES=()
  TEST_EXIT_CODES=()

  CONTINUE_ON_TEST_FAIL=1
  CONTINUE_ON_SIGINT=0

  local TestModuleProcId
  tkl_get_shell_pid
  printf -v TestModuleProcId %x ${RETURN_VALUE:-65535} # default value if fail
  tkl_zero_padding 4 "$TestModuleProcId"
  TestModuleProcId="$RETURN_VALUE"

  # date time request base on: https://stackoverflow.com/questions/1401482/yyyy-mm-dd-format-date-in-shell-script/1401495#1401495
  #

  local TestModuleLogFileNameDateTimeSuffix
  # RANDOM instead of milliseconds
  case $BASH_VERSION in
    # < 4.2
    [123].* | 4.[01] | 4.0* | 4.1[^0-9]*)
      TestModuleLogFileNameDateTimeSuffix="$(date "+%Y'%m'%d_%H'%M'%S''")$(( RANDOM % 1000 ))"
      ;;
    # >= 4.2
    *)
      printf -v TestModuleLogFileNameDateTimeSuffix "%(%Y'%m'%d_%H'%M'%S'')T$(( RANDOM % 1000 ))" -1
      ;;
  esac

  # NOTE:
  #   Using dot separator to be able to sort the directories by the name (test file name + test function + TestModuleProcId) and
  #   by the extension (date + time) separately.
  #
  TestModuleSessionId="${TestModuleLogFileNameDateTimeSuffix}-${TestModuleProcId}"
  TestModuleScriptBaseFileName="${BASH_SOURCE_FILE_NAME%.*}"
  TestModuleScriptLogDir="${TestModuleScriptBaseFileName}-${TestModuleSessionId}"

  TestModuleRetcodeFilePath="/tmp/$TestModuleScriptLogDir/retcode.txt"
  TestModuleScriptFilePath="/tmp/$TestModuleScriptLogDir/test_script.sh"
  TestModuleScriptLogDirVarPath="/tmp/$TestModuleScriptLogDir/test_script_log_dir.var"

  # with fall back to a lesser variable
  if [[ -n "${TESTS_PROJECT_LOG_ROOT+x}" ]]; then
    TestModuleScriptOutputDirPath="$TESTS_PROJECT_LOG_ROOT"
  elif [[ -n "${PROJECT_LOG_ROOT+x}" ]]; then
    TestModuleScriptOutputDirPath="$PROJECT_LOG_ROOT"
  else
    TestModuleScriptOutputDirPath="$BASH_SOURCE_DIR/.log"
  fi

  # enable extra variables check and test asserts
  export TEST_ENABLE_EXTRA_VARIABLES_CHECK=0
  export TEST_ENABLE_ALL_TEMP_OUTPUT_COPY=1

  tkl_push_trap "tkl_testmodule_exit_handler" EXIT
  tkl_pop_trap RETURN
  tkl_pop_trap INT
  tkl_push_trap "tkl_testmodule_int_handler" INT

  mkdir "/tmp/$TestModuleScriptLogDir"

  # create empty module files
  echo -n > "$TestModuleRetcodeFilePath"
  echo -n > "$TestModuleScriptFilePath"
  echo -n > "$TestModuleScriptLogDirVarPath"

  tkl_testmodule_set_last_error 127

  tkl_safe_func_call TestUserModuleInit

  return 0
}

function tkl_testmodule_exit_handler()
{
  tkl_push_trap '' INT # ignore interruption while at init
  tkl_push_trap 'tkl_pop_trap INT INT' RETURN # duplicated because including the trap from the `tkl_testmodule_init`

  tkl_safe_func_call TestUserModuleExit

  echo "-------------------------------------------------------------------------------"
  echo "  Tests passed:  $NUM_TESTS_PASSED"
  echo "  Tests failed:  $NUM_TESTS_FAILED"
  echo "  Tests overall: $NUM_TESTS_OVERALL"
  echo "-------------------------------------------------------------------------------"

  rm -f "$TestModuleRetcodeFilePath"
  rm -f "$TestModuleScriptFilePath"
  rm -f "$TestModuleScriptLogDirVarPath"
  rmdir "/tmp/$TestModuleScriptLogDir"

  printf '\7' # beep
}

function tkl_testmodule_int_handler()
{
  (( ! CONTINUE_ON_SIGINT )) && tkl_set_trap_postponed_exit 254
}

function tkl_test_init()
{
  TestScriptEntry="$1"
  TestStdoutDeclare="$2"

  tkl_push_trap '' INT # ignore interruption while at init
  tkl_push_trap 'tkl_pop_trap INT' RETURN

  CONTINUE_ON_SIGINT=0

  local TestProcId
  tkl_get_shell_pid
  printf -v TestProcId %x ${RETURN_VALUE:-65535} # default value if fail
  tkl_zero_padding 4 "$TestProcId"
  TestProcId="$RETURN_VALUE"

  # date time request base on: https://stackoverflow.com/questions/1401482/yyyy-mm-dd-format-date-in-shell-script/1401495#1401495
  #

  local TestLogFileNameDateTimeSuffix
  # RANDOM instead of milliseconds
  case $BASH_VERSION in
    # < 4.2
    [123].* | 4.[01] | 4.0* | 4.1[^0-9]*)
      TestLogFileNameDateTimeSuffix="$(date "+%Y'%m'%d_%H'%M'%S''")$(( RANDOM % 1000 ))"
      ;;
    # >= 4.2
    *)
      printf -v TestLogFileNameDateTimeSuffix "%(%Y'%m'%d_%H'%M'%S'')T$(( RANDOM % 1000 ))" -1
      ;;
  esac

  # NOTE:
  #   Using dot separator to be able to sort the directories by the name (test file name + test function + TestProcId) and
  #   by the extension (date + time) separately.
  #
  TestSessionId="${TestLogFileNameDateTimeSuffix}-${TestProcId}"
  #TestScriptBaseFileName="${BASH_SOURCE_FILE_NAME%.*}"
  TestScriptLogDir="${TestScriptEntry}-${TestSessionId}"

  TestStdoutFilePath="/tmp/$TestModuleScriptLogDir/$TestScriptLogDir/stdout.txt"
  TestStdoutDefFilePath="/tmp/$TestModuleScriptLogDir/$TestScriptLogDir/stdout-def.txt"
  TestStdoutsDiffFilePath="/tmp/$TestModuleScriptLogDir/$TestScriptLogDir/stdouts-diff.txt"
  TestInitEnvFilePath="/tmp/$TestModuleScriptLogDir/$TestScriptLogDir/env-0.txt"
  TestExitEnvFilePath="/tmp/$TestModuleScriptLogDir/$TestScriptLogDir/env-1.txt"
  if (( TEST_ENABLE_EXTRA_VARIABLES_CHECK )); then
    TestHasVarsEnvFilePath="/tmp/$TestModuleScriptLogDir/$TestScriptLogDir/1-has_vars.txt"
    TestHasNoVarsEnvFilePath="/tmp/$TestModuleScriptLogDir/$TestScriptLogDir/2-has_no_vars.txt"
    TestHasVarEnvDiffFilePath="/tmp/$TestModuleScriptLogDir/$TestScriptLogDir/1-has_vars_diff.txt"
    TestHasNoVarEnvDiffFilePath="/tmp/$TestModuleScriptLogDir/$TestScriptLogDir/2-has_no_vars_diff.txt"
  fi

  tkl_push_trap "tkl_test_exit_handler" EXIT
  tkl_pop_trap RETURN
  tkl_pop_trap INT
  tkl_push_trap "tkl_test_int_handler" INT

  mkdir "/tmp/$TestModuleScriptLogDir/$TestScriptLogDir" || exit 240
  mkdir -p "$TestModuleScriptOutputDirPath/$TestModuleScriptLogDir/$TestScriptLogDir" || exit 241

  tkl_test_set_last_error 128

  exec 3> "$TestStdoutFilePath"
  if (( TEST_ENABLE_EXTRA_VARIABLES_CHECK )); then
    exec 5> "$TestHasVarsEnvFilePath"
    exec 6> "$TestHasNoVarsEnvFilePath"
  fi

  # save generated log directory name
  echo "$TestScriptLogDir" > "$TestModuleScriptLogDirVarPath"

  return 0
}

function tkl_test_exit_handler()
{
  local ExitCode=$?

  tkl_push_trap '' INT # ignore interruption while at exit
  tkl_push_trap 'tkl_pop_trap INT' RETURN

  local Output="${TestStdoutDeclare%$'\n'}" # remove last line return as optional
  echo -ne "$Output${Output:+$'\n'}" > "$TestStdoutDefFilePath"
  local StdoutsDiff="$( \
    diff -c "$TestStdoutFilePath" "$TestStdoutDefFilePath" | \
    sed -e 's|--- /tmp/traplib/|--- |' -e 's|\*\*\* /tmp/traplib/|\*\*\* |')"
  if [[ -n "$StdoutsDiff" ]]; then
    echo -n "$StdoutsDiff" > "$TestStdoutsDiffFilePath"
    tkl_test_add_last_error 245 0x01
  else
    # reset the into success if not done yet
    tkl_test_assert_true '(( 1 ))'
  fi

  # close all pipes
  exec 3>&-
  if (( TEST_ENABLE_EXTRA_VARIABLES_CHECK )); then
    exec 5>&-
    exec 6>&-

    # checking output from the test, slow but necessary
    local CleanEnvironment
    local TestEnvironment
    local TestInitEnv="$(cat "$TestInitEnvFilePath")"
    if [[ -n "$TestInitEnv" ]]; then
      HasVarsEnv="$(cat "$TestHasVarsEnvFilePath")"
      if [[ -n "$HasVarsEnv" ]]; then
        tkl_compare_envs "$HasVarsEnv" "$TestInitEnv" "%%=*" "%%=*" &&
        if [[ -n "$RETURN_VALUE" ]]; then
          echo "$RETURN_VALUE" > "$TestHasVarEnvDiffFilePath"
          tkl_test_add_last_error 246 0x02
        else
          # reset the into success if not done yet
          tkl_test_assert_true '(( 1 ))'
        fi
      fi
      HasNoVarsEnv="$(cat "$TestHasNoVarsEnvFilePath")"
      if [[ -n "$HasNoVarsEnv" ]]; then
        tkl_compare_envs "$HasNoVarsEnv" "$TestInitEnv" "%%=*" "%%=*" &&
        if [[ -n "$RETURN_VALUE" ]]; then
          echo "$RETURN_VALUE" > "$TestHasNoVarEnvDiffFilePath"
          tkl_test_add_last_error 247 0x04
        else
          # reset the into success if not done yet
          tkl_test_assert_true '(( 1 ))'
        fi
      fi
    else
      tkl_test_add_last_error 248
    fi
  fi

  local TestLastError
  tkl_testmodule_get_last_error TestLastError

  {
    # remove output files only if test is passed!
    if (( TestLastError && TestFlags & 0x01 )); then
      mv -v "$TestStdoutsDiffFilePath" "$TestModuleScriptOutputDirPath/$TestModuleScriptLogDir/$TestScriptLogDir"
    else
      rm -f "$TestStdoutsDiffFilePath"
    fi 

    if (( TEST_ENABLE_ALL_TEMP_OUTPUT_COPY )); then
      if (( TestLastError )); then
        cp -vr "/tmp/$TestModuleScriptLogDir/$TestScriptLogDir" "$TestModuleScriptOutputDirPath/$TestModuleScriptLogDir"
      fi
      if (( TEST_ENABLE_EXTRA_VARIABLES_CHECK )); then
        rm -f "$TestHasVarEnvDiffFilePath"
        rm -f "$TestHasNoVarEnvDiffFilePath"
        rm -f "$TestHasVarsEnvFilePath"
        rm -f "$TestHasNoVarsEnvFilePath"
      fi
    elif (( TEST_ENABLE_EXTRA_VARIABLES_CHECK )); then
      if (( TestLastError && TestFlags & 0x02 )); then
        mv -v "$TestHasVarEnvDiffFilePath" "$TestModuleScriptOutputDirPath/$TestModuleScriptLogDir/$TestScriptLogDir"
      else
        rm -f "$TestHasVarEnvDiffFilePath"
      fi
      if (( TestLastError && TestFlags & 0x04 )); then
        mv -v "$TestHasNoVarEnvDiffFilePath" "$TestModuleScriptOutputDirPath/$TestModuleScriptLogDir/$TestScriptLogDir"
      else
        rm -f "$TestHasNoVarEnvDiffFilePath"
      fi
      rm -f "$TestHasVarsEnvFilePath"
      rm -f "$TestHasNoVarsEnvFilePath"
    fi

    # move test output into respective
    rm -f "$TestStdoutFilePath"
    rm -f "$TestStdoutDefFilePath"
    rm -f "$TestInitEnvFilePath"
    rm -f "$TestExitEnvFilePath"
    rmdir "/tmp/$TestModuleScriptLogDir/$TestScriptLogDir"

    # copy return codes at last
    cp -v "$TestModuleRetcodeFilePath" "$TestModuleScriptOutputDirPath/$TestModuleScriptLogDir/$TestScriptLogDir"

    echo
  } > /dev/null

  if (( ! TestLastError )); then
    echo "[PASSED]: TestLastError=$TestLastError ExitCode=$ExitCode"
    echo
  else
    echo "[FAILED]: TestLastError=$TestLastError ExitCode=$ExitCode"
    echo
  fi

  return $ExitCode
}

function tkl_test_int_handler()
{
  tkl_test_add_last_error 254
  (( ! CONTINUE_ON_SIGINT )) && tkl_set_trap_postponed_exit $TestLastError
}

function tkl_testmodule_get_last_error()
{
  local IFS=$'\r\n'
  read -r $1 < "$TestModuleRetcodeFilePath"
}

function tkl_testmodule_set_last_error()
{
  local TestLastError=$1
  echo "$TestLastError" > "$TestModuleRetcodeFilePath"
}

function tkl_test_set_last_error()
{
  local TestLastError=$1
  echo "$TestLastError" > "$TestModuleRetcodeFilePath"
  let "TestFlags|=${2:-0}"
}

function tkl_test_add_last_error()
{
  local TestLastError=$1
  echo "$TestLastError" >> "$TestModuleRetcodeFilePath"
  let "TestFlags|=${2:-0}"
}

function tkl_test_exit_if_error()
{
  local LastError=$1

  if (( LastError )); then
    tkl_test_add_last_error $LastError
    exit $LastError
  fi

  return 0
}

function tkl_testmodule_run_test_and_wait()
{
  local FuncBeforeWait="$1"
  shift

  tkl_testmodule_run_test "$@" &
  LAST_WAIT_PID=$!
  tkl_safe_func_call "$FuncBeforeWait"
  wait $LAST_WAIT_PID
}

function tkl_testmodule_run_test()
{
  local TestScriptEntry="$1"
  local TestStdoutDeclare="$2"
  shift 2
  local TestFuncArgs=("$@")

  # replace special character to line returns
  tkl_escape_string "${TestStdoutDeclare//:/$'\n'}" '' 1
  TestStdoutDeclare="$RETURN_VALUE"

  tkl_get_func_body "$TestScriptEntry"

  local TestFuncBody="$RETURN_VALUE"

  tkl_get_func_decls TestUserInit TestUserExit "${TEST_FUNCTIONS[@]}"

  local IFS=$'\n'
  local TestFuncDecls
  local arg

  # add prefix and suffix
  for arg in "${RETURN_VALUES[@]}"; do
    TestFuncDecls="${TestFuncDecls}function $arg"$'\n\n'
  done

  # Test script to run single test w/o environment inheritance from parent shell process.
  # First line in environment output is internal parameters list from
  # `tkl_test_assert_has_extra_vars` and `tkl_test_assert_has_not_extra_vars` functions.
  local TestScript="#!/bin/bash

# builtin search
for BASH_SOURCE_DIR in '/usr/local/bin' '/usr/bin' '/bin'; do
  if [[ -f \"\$BASH_SOURCE_DIR/bash_tacklelib\" ]]; then
    source \"\$BASH_SOURCE_DIR/bash_tacklelib\" || exit \$?
    break
  fi
done

tkl_include_or_abort \"$SOURCE_TACKLELIB_TESTLIB_FILE\"

TestModuleSessionId=\"$TestModuleSessionId\"
TestModuleScriptOutputDirPath=\"$TestModuleScriptOutputDirPath\"
TestModuleScriptLogDir=\"$TestModuleScriptLogDir\"
TestModuleRetcodeFilePath=\"$TestModuleRetcodeFilePath\"
TestModuleScriptLogDirVarPath=\"$TestModuleScriptLogDirVarPath\"

tkl_test_init \"$TestScriptEntry\" \"$TestStdoutDeclare\" || tkl_test_exit_if_error \$?

echo \"$TestScriptEntry: TestSessionId=\$TestSessionId\"

"

  for arg in "${TEST_SOURCES[@]}"; do
    TestScript="${TestScript}tkl_include_or_abort \"$arg\""$'\n'
  done

  if (( ${#TEST_SOURCES[@]} )); then
    TestScript="${TestScript}"$'\n'
  fi

  local i=0
  TestScript="${TestScript}TEST_SCRIPT_ARGS=()"$'\n'
  for arg in "${TestFuncArgs[@]}"; do
    tkl_escape_string "$arg" '' 1
    TestScript="${TestScript}TEST_SCRIPT_ARGS[$i]='$RETURN_VALUE'"$'\n'
    (( i++ ))
  done

  if (( ${#TEST_SCRIPT_ARGS[@]} )); then
    TestScript="${TestScript}"$'\n'
  fi

  local var_name
  local i=0
  for arg in "${TEST_VARIABLES[@]}"; do
    if (( ! ( i % 2 ) )); then
      var_name="$arg"
    else
      if [[ "${arg:0:1}" != "(" ]]; then
        tkl_escape_string "$arg" '' 1
        TestScript="${TestScript}declare $var_name='$RETURN_VALUE'"$'\n'
      else
        TestScript="${TestScript}declare $var_name=$arg"$'\n'
      fi
    fi
    (( i++ ))
  done

  if (( ${#TEST_VARIABLES[@]} )); then
    TestScript="$TestScript"$'\n'
  fi

  TestScript="$TestScript$TestFuncDecls"

  TestScript="${TestScript}\
tkl_safe_func_call TestUserInit

function tkl_test_script_LocalExitHandler()
{
  tkl_push_trap \"tkl_delete_this_func\" RETURN

  set -o posix
  set > \"\$TestExitEnvFilePath\"

  tkl_safe_func_call TestUserExit
}

tkl_push_trap 'tkl_test_script_LocalExitHandler' EXIT

set -o posix
set > \"\$TestInitEnvFilePath\"

function TestCase()
{
$TestFuncBody
}

TestCase
"

  # save the script text into temporary file before run it
  echo "$TestScript" > "$TestModuleScriptFilePath"

  # NOTE:
  #   Run a test case in the standalone shell process with empty environment.
  #
  #echo "TestScript=$TestScript"
  env -i "$SHELL" -c "$TestScript"
  local TestProcessLastError=$?

  # copy temporary test script file into the log test case directory
  local TestScriptLogDir
  read -r TestScriptLogDir < "$TestModuleScriptLogDirVarPath"
  cp "$TestModuleScriptFilePath" "$TestModuleScriptOutputDirPath/$TestModuleScriptLogDir/$TestScriptLogDir"

  local TestLastError
  tkl_testmodule_get_last_error TestLastError

  [[ -z "$TestLastError" ]] && TestLastError=255 # just in case

  local i=0
  local test_func_name
  local registered_exit_code=0
  for arg in "${TEST_EXIT_CODES[@]}"; do
    if (( ! ( i % 2 ) )); then
      test_func_name="$arg"
    elif [[ "$test_func_name" == "$TestScriptEntry" ]]; then
      registered_exit_code=$arg
      break
    fi
    (( i++ ))
  done

  if (( TestProcessLastError == registered_exit_code && ! TestLastError )); then
    (( NUM_TESTS_PASSED++ ))
  else
    (( NUM_TESTS_FAILED++ ))
  fi
  (( NUM_TESTS_OVERALL++ ))
  (( TestLastError && ! CONTINUE_ON_TEST_FAIL )) && exit $TestLastError
  (( TestProcessLastError && ! CONTINUE_ON_TEST_FAIL )) && exit $TestProcessLastError

  return 0
}

function tkl_test_assert_true()
{
  local TestLastError
  tkl_testmodule_get_last_error TestLastError

  if eval "$1"; then
    if (( TestLastError == 128 )); then
      tkl_test_set_last_error 0
    fi
  else
    echo "${FUNCNAME[0]}: ${FUNCNAME[1]} ($(( BASH_LINENO[0] + 1 ))): \`$1\`"
    shift
    while (( $# )); do
      eval "echo \"\${FUNCNAME[0]}:  arg: $1=\\\`\$$1\\\`\""
      shift
    done
    if (( ! TestLastError || TestLastError == 128 )); then
      tkl_test_set_last_error 250
    fi
  fi
}

function tkl_test_assert_false()
{
  local TestLastError
  local IFS=$'\r\n'
  read -r TestLastError < "$TestModuleRetcodeFilePath"

  if ! eval "$1"; then
    if (( TestLastError == 128 )); then
      tkl_test_set_last_error 0
    fi
  else
    echo "${FUNCNAME[0]}: ${FUNCNAME[1]} ($(( BASH_LINENO[0] + 1 ))): \`$1\`"
    shift
    while (( $# )); do
      eval "echo \"\${FUNCNAME[0]}:  arg: $1=\\\`\$$1\\\`\""
      shift
    done
    if (( ! TestLastError || TestLastError == 128 )); then
      tkl_test_set_last_error 251
    fi
  fi
}

function tkl_test_assert_true_expr()
{
  local TestLastError
  tkl_testmodule_get_last_error TestLastError

  if "$@"; then
    if (( TestLastError == 128 )); then
      tkl_test_set_last_error 0
    fi
  else
    echo "${FUNCNAME[0]}: ${FUNCNAME[1]} ($(( BASH_LINENO[0] + 1 ))): \`$1\`"
    shift
    local i=0
    while (( $# )); do
      echo "${FUNCNAME[0]}:  arg: [$i]=\`$1\`"
      shift
      (( i++ ))
    done
    if (( ! TestLastError || TestLastError == 128 )); then
      tkl_test_set_last_error 250
    fi
  fi
}

function tkl_test_assert_false_expr()
{
  local TestLastError
  tkl_testmodule_get_last_error TestLastError

  if ! "$@"; then
    if (( TestLastError == 128 )); then
      tkl_test_set_last_error 0
    fi
  else
    echo "${FUNCNAME[0]}: ${FUNCNAME[1]} ($(( BASH_LINENO[0] + 1 ))): \`$1\`"
    shift
    local i=0
    while (( $# )); do
      echo "${FUNCNAME[0]}:  arg: [$i]=\`$1\`"
      shift
      (( i++ ))
    done
    if (( ! TestLastError || TestLastError == 128 )); then
      tkl_test_set_last_error 250
    fi
  fi
}

function tkl_test_assert_has_extra_vars()
{
  echo \"=AssertHasExtraVars \$@\" >&5
  set -o posix
  set >&5
  return 0
}

function tkl_test_assert_has_not_extra_vars()
{
  echo \"=AssertHasNoExtraVars \$@\" >&6
  set -o posix
  set >&6
  return 0
}

function tkl_compare_envs()
{
  local List1="$1"
  local List2="$2"
  local ListLineFilter1="$3"
  local ListLineFilter2="$4"
  local IgnoreReturnTrapVars="${5:-0}"
  local IgnoreExitTrapVars="${6:-1}"

  # drop return value
  RETURN_VALUES=''

  function tkl_compare_envs_LocalReturnHandler()
  {
    [[ -n "$oldShopt" ]] && eval $oldShopt
  }

  local oldShopt
  tkl_push_trap "tkl_compare_envs_LocalReturnHandler" RETURN

  # enable case match for a variable names
  oldShopt="$(shopt -p nocasematch)"
  if [[ "$oldShopt" == 'shopt -s nocasematch' ]]; then
    shopt -u nocasematch
  else
    oldShopt=''
  fi

  # reload strings into arrays
  local IFS=$'\n' # to join by line return
  local ListArr1=(${List1[*]})
  local ListArr2=(${List2[*]})
  local ListArrSize1=${#ListArr1[@]};
  local ListArrSize2=${#ListArr2[@]};

  local LinesDiff
  LinesDiff=()

  local AssertTypeStr
  local TrapType
  local TrapTypesArr
  TrapTypesArr=('*') # has (has no) any (all) of trap types declared by pattern
  local TrapTypesArrSize=${#TrapTypesArr[@]}
  local TrapStackHasVarsArrName
  local TrapStackHasVarsArrSize
  local TrapStackHasVarName
  local TrapStackHasNoVarsArrName
  local TrapStackHasNoVarsArrSize
  local TrapStackHasNoVarName
  local CompCmdLine
  local CompCmdArr
  local NumCompBlocks=0
  local NumDiffLine=0
  local HasCurBlockDiffs=0
  local HasLastBlockDiffs=0
  local IsDiffLineFound

  # uses by AssertHasExtraVars
  local FoundTrapTypeNums

  local i
  local j
  local k
  local NumDiffsFound=0
  local Line1
  local FilteredLine1
  local Line2
  local FilteredLine2
  local LastFoundIndex=-1
  local DoIgnoreLine
  for (( i=0; i < ListArrSize1; i++ )); do
    IsDiffLineFound=0
    DoIgnore=0
    tkl_read_multiline_env_string ListArr1 $i
    Line1="${RETURN_VALUES[0]}"
    i=${RETURN_VALUES[1]}
    if [[ -z "$Line1" ]]; then
      continue
    # ignore empty variables but read special technical lines to (re)initialize comparison
    elif [[ -z "${Line1%%=*}" ]]; then
      # previous technical line process
      if (( NumCompBlocks )); then
        if [[ "$AssertTypeStr" == "AssertHasExtraVars" ]]; then
          # report by special lines what trap type variables were not found at all
          for (( k=0; k < TrapTypesArrSize; k++ )); do
            if (( ! FoundTrapNums[k] )); then
              LinesDiff[NumDiffLine]="> Not found: ${TrapTypesArr[k]}"
              (( NumDiffLine++ ))
              (( NumDiffsFound++ ))
            fi
          done
        fi
      fi
      # technical line: reinitialize comparison
      eval "CompCmdLine=(${Line1#=})"
      if (( ${#CompCmdLine} > 1 )); then
        local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
        eval "TrapTypesArr=(${CompCmdLine[@]:1})"
        local IFS=$'\n' # to join by line return
      else
        TrapTypesArr=() # has (has no) any (all) of trap types declared by pattern
      fi
      TrapTypesArrSize=${#TrapTypesArr[@]}
      AssertTypeStr="${CompCmdLine[0]}"
      (( ! TrapTypesArrSize )) && TrapTypesArr[0]='*'
      TrapTypesArrSize=${#TrapTypesArr[@]}
      # do zeros found trap type numbers
      FoundTrapTypeNums=()
      for (( j=0; j < TrapTypesArrSize; j++ )); do
        FoundTrapTypeNums[j]=0
      done
      # find from begin
      LastFoundIndex=-1
      HasLastBlockDiffs=$HasCurBlockDiffs
      HasCurBlockDiffs=0
      if (( HasLastBlockDiffs )); then
        LinesDiff[NumDiffLine]=''
        (( NumDiffLine++ ))
      fi
      LinesDiff[NumDiffLine]=">> $AssertTypeStr: ${TrapTypesArr[@]}"
      (( NumDiffLine++ ))
      (( NumCompBlocks++ ))
      continue
    fi
    #echo "$i: $Line1"
    # Msys bash 3.1.x has weak ctrl-c handling, this improves it a bit
    if (( ! (i % 10) && (BASH_VERSINFO[0] < 3 || BASH_VERSINFO[0] == 3 && BASH_VERSINFO[1] <= 1) )); then
      Wait 1
    fi
    eval "FilteredLine1=\"\${Line1$ListLineFilter1}\""
    # always ignore base extra variables created by other libraries than traplib
    for (( j=0; j < IgnoreBaseExtraVariablesSize; j++ )); do
      if [[ "${IgnoreBaseExtraVariables[j]}" == "$FilteredLine1" ]]; then
        DoIgnore=1
        break
      fi
    done
    (( DoIgnore )) && continue
    # but always checks presence of special extra variables created by the traplib functions
    if [[ "$AssertTypeStr" == "AssertHasExtraVars" ]]; then
      # test on specific extra variable absence except declared
      for (( j=0; j < TrapTypesArrSize; j++ )); do
        TrapType="${TrapTypesArr[j]}"
        if [[ "$TrapType" == '*' ]]; then
          TrapStackHasVarsArrName=IgnoreTrapStackExtraVars_ALL
          TrapStackHasVarsArrSize=$IgnoreTrapStackExtraVarsSize_ALL
        elif [[ "$TrapType" == 'RETURN' ]]; then
          TrapStackHasVarsArrName=IgnoreTrapStackExtraVars_RETURN
          TrapStackHasVarsArrSize=$IgnoreTrapStackExtraVarsSize_RETURN
        else
          TrapStackHasVarsArrName=IgnoreTrapStackExtraVars_OTHERS
          TrapStackHasVarsArrSize=$IgnoreTrapStackExtraVarsSize_OTHERS
        fi
        for (( k=0; k < TrapStackHasVarsArrSize; k++ )); do
          eval "TrapStackHasVarName=\"\${$TrapStackHasVarsArrName[k]}\""
          TrapStackHasVarName="${TrapStackHasVarName//\%TRAPTYPE\%/$TrapType}"
          case "$FilteredLine1" in
            $TrapStackHasVarName)
              (( FoundTrapNums[j]++ ))
              DoIgnore=1
              break
            ;;
          esac
        done
        (( DoIgnore )) && break
      done
    elif [[ "$AssertTypeStr" == "AssertHasNoExtraVars" ]]; then
      # test on specific extra variable absence of declared
      for (( j=0; j < TrapTypesArrSize; j++ )); do
        TrapType="${TrapTypesArr[j]}"
        if [[ "$TrapType" == '*' ]]; then
          TrapStackHasNoVarsArrName=IgnoreTrapStackExtraVars_ALL
          TrapStackHasNoVarsArrSize=$IgnoreTrapStackExtraVarsSize_ALL
        elif [[ "$TrapType" == 'RETURN' ]]; then
          TrapStackHasNoVarsArrName=IgnoreTrapStackExtraVars_RETURN
          TrapStackHasNoVarsArrSize=$IgnoreTrapStackExtraVarsSize_RETURN
          TrapStackHasVarsArrName=IgnoreTrapStackExtraVars_OTHERS
          TrapStackHasVarsArrSize=$IgnoreTrapStackExtraVarsSize_OTHERS
        else
          TrapStackHasNoVarsArrName=IgnoreTrapStackExtraVars_OTHERS
          TrapStackHasNoVarsArrSize=$IgnoreTrapStackExtraVarsSize_OTHERS
          TrapStackHasVarsArrName=IgnoreTrapStackExtraVars_ALL
          TrapStackHasVarsArrSize=$IgnoreTrapStackExtraVarsSize_ALL
        fi
        for (( k=0; k < TrapStackHasNoVarsArrSize; k++ )); do
          eval "TrapStackHasNoVarName=\"\${$TrapStackHasNoVarsArrName[k]}\""
          TrapStackHasNoVarName="${TrapStackHasNoVarName//\%TRAPTYPE\%/$TrapType}"
          case "$FilteredLine1" in
            $TrapStackHasNoVarName)
              IsDiffLineFound=1
              break
            ;;
          esac
        done
        (( IsDiffLineFound )) && break
        if [[ "$TrapType" != '*' ]]; then
          for (( k=0; k < TrapStackHasVarsArrSize; k++ )); do
            eval "TrapStackHasVarName=\"\${$TrapStackHasVarsArrName[k]}\""
            TrapStackHasVarName="${TrapStackHasVarName//\%TRAPTYPE\%/*}"
            case "$FilteredLine1" in
              $TrapStackHasVarName)
                DoIgnore=1
                break
              ;;
            esac
          done
          (( DoIgnore )) && break
        fi
      done
    fi
    if (( IsDiffLineFound )); then
      LinesDiff[NumDiffLine]="$Line1"
      (( NumDiffLine++ ))
      (( NumDiffsFound++ ))
      HasCurBlockDiffs=1
    fi
    (( IsDiffLineFound || DoIgnore )) && continue
    # lists should be already sorted, start compare after last found
    for (( j=LastFoundIndex+1; j < ListArrSize2; j++ )); do
      tkl_read_multiline_env_string ListArr2 $j
      Line2="${RETURN_VALUES[0]}"
      j=${RETURN_VALUES[1]}
      # technical line: ignore it
      if [[ -z "$Line2" || -z "${Line2%%=*}" ]]; then
        LastFoundIndex=$j
        continue
      fi
      eval "FilteredLine2=\"\${Line2$ListLineFilter2}\""
      if [[ "$FilteredLine1" == "$FilteredLine2" ]]; then
        LastFoundIndex=$j;
        break
      fi
    done
    if (( j >= ListArrSize2 )); then
      LinesDiff[NumDiffLine]="$Line1"
      (( NumDiffLine++ ))
      (( NumDiffsFound++ ))
      HasCurBlockDiffs=1
      IsDiffLineFound=1
    fi
  done

  if (( NumCompBlocks )); then
    if [[ "$AssertTypeStr" == "AssertHasExtraVars" ]]; then
      # report by special lines what trap type variables were not found at all
      for (( k=0; k < TrapTypesArrSize; k++ )); do
        if (( ! FoundTrapNums[k] )); then
          LinesDiff[NumDiffLine]="> Not found: ${TrapTypesArr[k]}"
          (( NumDiffLine++ ))
          (( NumDiffsFound++ ))
        fi
      done
    fi
  fi

  if (( NumDiffsFound )); then
    RETURN_VALUE="${LinesDiff[*]}"
  else
    RETURN_VALUE=''
  fi

  return 0 # test has no internal errors
}

# searches for the ' character as multiline string quote
function tkl_read_multiline_env_string()
{
  local ArrName="$1"
  local Index="$2"

  # drop return values
  RETURN_VALUES=('' -1)

  local NewArr
  NewArr=()
  local NewLineIndex
  local EndMultilineIndex
  local IsMultilineEnd=0
  local IsMultilineQuote=0  # '-quoted string started
  local Line
  local Value
  local ValueSize
  local i
  local IsEscape
  local Char

  EndMultilineIndex=$Index
  NewLineIndex=0
  while (( ! IsMultilineEnd )); do
    eval "Line=\"\${$ArrName[EndMultilineIndex]}\""
    [[ -z "$Line" ]] && break
    Value="${Line#*=}"
    ValueSize=${#Value}
    IsEscape=0
    for (( i=0; i < ValueSize; i++ )); do
      Char="${Value:i:1}"
      # state machine on flags
      if [[ "$Char" == "'" ]]; then
        if (( ! IsMultilineQuote )); then
          if (( ! IsEscape )); then
            IsMultilineQuote=1
          else
            IsEscape=0
          fi
        else
          IsMultilineQuote=0
        fi
      elif [[ "$Char" == '\' ]]; then
        (( ! IsMultilineQuote )) && IsEscape=1
      fi
    done

    NewArr[NewLineIndex]="$Line"
    (( NewLineIndex++ ))

    # stop state machine if no begin of '-quoted string
    (( ! IsMultilineQuote )) && IsMultilineEnd=1

    (( ! IsMultilineEnd && EndMultilineIndex++ ))
  done

  local IFS=$'\n' # to join by line return
  RETURN_VALUES=("${NewArr[*]}" $EndMultilineIndex)
}
