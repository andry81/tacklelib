#!/bin/bash

# Script library to support trap shell operations.

# DESCRIPTION:
#
# Pros:
#   1. Automatically restores the previous trap handler in nested functions.
#      Originally the `RETURN` trap restores ONLY if ALL functions in the stack did set it.
#   2. The `RETURN` signal trap can support other signal traps to achieve the RAII pattern as in other languages.
#      For example, to temporary disable interruption handling and auto restore it at the end of a function
#      while an initialization code is executing.
#   3. Protection from call not from a function context in case of the `RETURN` signal trap.
#   4. The not `RETURN` signal handlers in the whole stack invokes together in a bash process from the
#      bottom to the top and executes them in order reversed to the `tkl_push_trap` function calls
#   5. The `RETURN` signal trap handlers invokes only for a single function from the bottom to the top in
#      reverse order to the `tkl_push_trap` function calls.
#   6. Because the `EXIT` signal does not trigger the `RETURN` signal trap handler, then the `EXIT` signal trap
#      handler does setup automatically at least once per bash process when the `RETURN` signal trap handler
#      makes setup at first time in a bash process.
#      That includes all bash processes, for example, represented as `(...)` or `$(...)` operators.
#      So the `EXIT` signal trap handlers automatically handles all the `RETURN` trap handlers before to run itself.
#   7. The `RETURN` signal trap handler still can call to `tkl_push_trap` and `tkl_pop_trap` functions to process
#      the not `RETURN` signal traps
#   8. The `RETURN` signal trap handler can call to `tkl_set_trap_postponed_exit` function from both the `EXIT` and
#      `RETURN` signal trap handlers.
#      If is called from the `RETURN` signal trap handler, then the `EXIT` trap handler will be called after all the
#      `RETURN` signal trap handlers in the bash process.
#      If is called from the `EXIT` signal trap handler, then the `EXIT` trap handler will change the exit code after
#      the last `EXIT` signal trap handler is invoked.
#   9. Faster access to trap stack as a global variable instead of usage the `(...)` or `$(...)` operators
#      which invokes an external bash process.
#   10. The `source` command ignores by the `RETURN` signal trap handler, so all calls to the `source` command will not
#      invoke the `RETURN` signal trap user code (marked in the Pros, because `RETURN` signal trap handler has to be
#      called only after return from a function in the first place and not from a script inclusion).
#
# Cons:
#   1. You must not use builtin `trap` command in the handler passed to the `tkl_push_trap` function as `tkl_*_trap` functions
#      does use it internally.
#   2. You must not use builtin `exit` command in the `EXIT` signal handlers while the `EXIT` signal trap
#      handler is running. Otherwise that will leave the rest of the `RETURN` and `EXIT` signal trap handlers not executed.
#      To change the exit code from the `EXIT` handler you can use `tkl_set_trap_postponed_exit` function for that.
#   3. You must not use builtin `return` command in the `RETURN` signal trap handler while the `RETURN` signal trap handler
#      is running. Otherwise that will leave the rest of the `RETURN` and `EXIT` signal trap handlers not executed.
#   4. All calls to the `tkl_push_trap` and `tkl_pop_trap` functions has no effect if has been called from a trap
#      handler for a signal the trap handler is handling (recursive call through the signal).
#   5. You have to replace all builtin `trap` commands in nested or 3dparty scripts by `tkl_*_trap` functions if
#      already using the library.
#   6. The `source` command ignores by the `RETURN` signal trap handler, so all calls to the `source` command will not
#      invoke the `RETURN` signal trap user code (marked in the Cons, because of losing the back compatability here).
#
#   1. Examples with RETURN signal handlers auto pop:
#   1.1. with the library:
#        > foo() { echo foo; boo() { builtin trap 'echo 2' RETURN; echo boo; }; boo; builtin trap -p RETURN; }
#        > foo
#          foo
#          boo
#          2
#          trap -- 'echo 2' RETURN
#          2
#        > builtin trap -p RETURN
#          trap -- 'echo 2' RETURN
#   1.2. with the library:
#        > . traplib.sh
#        > foo() { echo foo; boo() { tkl_push_trap 'echo 2' RETURN; echo boo; }; boo }
#        > foo
#          foo
#          boo
#          2
#        > builtin trap -p RETURN
#          
#
#   2. Examples with RETURN signal handlers nesting:
#   2.1. without the library:
#        > foo() { builtin trap 'echo 1' RETURN; echo foo; boo() { builtin trap 'echo 2' RETURN; echo boo; }; boo; builtin trap -p RETURN; }
#        > foo
#          foo
#          boo
#          2
#          trap -- 'echo 2' RETURN
#          1
#        > builtin trap -p RETURN
#          trap -- 'echo 1' RETURN
#   2.2. with the library:
#        > . traplib.sh
#        > foo() { tkl_push_trap 'echo 1' RETURN; echo foo; boo() { tkl_push_trap 'echo 2' RETURN; echo boo; }; boo; }
#        > foo
#          foo
#          boo
#          2
#          1
#        > builtin trap -p RETURN
#          
#
#   3. Examples with RETURN signal handlers usage from not a function context:
#   3.1. without the library:
#        > builtin trap 'echo 1' RETURN
#        > . x
#          bash: x: No such file or directory
#          1
#        > . x
#          bash: x: No such file or directory
#          1
#   3.2. with the library:
#        > . traplib.sh
#        > tkl_push_trap 'echo 1' RETURN
#        > echo $?
#          255
#        > . x
#          bash: x: No such file or directory
#
#   4. Examples with different signals composing to achieve the RAII pattern:
#   4.1. without the library:
#        > pause() { local key; read -n1 -r -p "Press any key to continue..."$'\n' key; }
#        > foo() { builtin trap 'echo 1' INT; builtin trap 'trap - INT' RETURN; echo foo; boo() { builtin trap 'echo 2' INT; builtin trap 'trap - INT' RETURN; echo boo; builtin trap -p INT; }; boo; builtin trap -p INT; pause; }
#        > ( foo )
#          foo
#          boo
#          trap -- 'echo 2' SIGINT
#          Press any key to continue...
#          *CTRL-C*
#        > echo $?
#          130
#   4.2. with the library:
#        > . traplib.sh
#        > pause() { local key; read -n1 -r -p "Press any key to continue..."$'\n' key; }
#        > foo() { tkl_push_trap 'echo 1' INT; tkl_push_trap 'tkl_pop_trap INT' RETURN; echo foo; boo() { tkl_push_trap 'echo 2' INT; tkl_push_trap 'tkl_pop_trap INT' RETURN; echo boo; }; boo; pause; }
#        > ( foo )
#          foo
#          boo
#          Press any key to continue...
#          *CTRL-C*
#          1
#          *CTRL-C*
#        > echo $?
#          130
#
#   5. Examples with non RETURN handlers chaining:
#   5.1. without the library:
#        > pause() { local key; read -n1 -r -p "Press any key to continue..."$'\n' key; }
#        > foo() { builtin trap 'echo 1' INT; echo foo; boo() { builtin trap 'echo 2' INT; echo boo; }; boo; builtin trap -p INT; pause; }
#        > ( foo )
#          foo
#          boo
#          trap -- 'echo 2' SIGINT
#          Press any key to continue...
#          *CTRL-C*
#          2
#          *press any key to exit*
#          
#        > echo $?
#          0
#   5.2. with the library:
#        > . traplib.sh
#        > pause() { local key; read -n1 -r -p "Press any key to continue..."$'\n' key; }
#        > foo() { tkl_push_trap 'echo 1' INT; echo foo; boo() { tkl_push_trap 'echo 2' INT; echo boo; pause; }; boo; }
#        > ( foo )
#          foo
#          boo
#          Press any key to continue...
#          *CTRL-C*
#          2
#          1
#          *press any key to exit*
#          
#        > echo $?
#          0
#
#   6. Examples with non RETURN handlers chaining with the postponed exit from a trap handler:
#   6.1. without the library:
#        > pause() { local key; read -n1 -r -p "Press any key to continue..."$'\n' key; }
#        > foo() { builtin trap 'echo 1; exit 1' INT; echo foo; boo() { builtin trap 'echo 2; exit 2' INT; echo boo; }; boo; builtin trap -p INT; pause; }
#        > ( foo )
#          foo
#          boo
#          trap -- 'echo 2; exit 2' SIGINT
#          Press any key to continue...
#          *CTRL-C*
#          2
#        > echo $?
#          2
#   6.2. with the library:
#        > . traplib.sh
#        > pause() { local key; read -n1 -r -p "Press any key to continue..."$'\n' key; }
#        > foo() { tkl_push_trap 'echo 1; tkl_set_trap_postponed_exit 1' INT; echo foo; boo() { tkl_push_trap 'echo 2; tkl_set_trap_postponed_exit 2' INT; echo boo; pause; }; boo; pause; }
#        > ( foo )
#          foo
#          boo
#          Press any key to continue...
#          *CTRL-C*
#          2
#          1
#        > echo $?
#          2
#
#   7. Examples with mix of RETURN and EXIT handlers:
#   7.1. without the library:
#        > ( builtin trap 'echo e1' EXIT; echo 1; foo() { ( builtin trap 'echo r2' RETURN; builtin trap 'echo e2' EXIT; echo 2; ); }; foo; echo 3; )
#          1
#          2
#          e2
#          3
#          e1
#   7.2. with the library:
#        > . traplib.sh
#        > ( tkl_push_trap 'echo e1' EXIT; echo 1; foo() { ( tkl_push_trap 'echo r2' RETURN; tkl_push_trap 'echo e2' EXIT; echo 2; ); }; foo; echo 3; )
#          1
#          2
#          r2
#          e2
#          3
#          e1
#

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$SOURCE_TACKLELIB_TRAPLIB_SH" || SOURCE_TACKLELIB_TRAPLIB_SH -eq 0) ]]; then

SOURCE_TACKLELIB_TRAPLIB_SH=1 # including guard

source '/bin/bash_entry'

tkl_include 'baselib.sh'
tkl_include 'funclib.sh'

function tkl_has_trap_cmd_line()
{
  # drop return values
  RETURN_VALUES=()

  local trap_sig
  local stack_var
  local stack_arr_size

  tkl_get_shell_pid
  local shell_pid="${RETURN_VALUE:-65535}" # default value if fail

  local i=0
  for trap_sig in "$@"; do
    if [[ -n "$trap_sig" ]]; then
      stack_var="tkl__traplib_cmdline_stack__${trap_sig}_${shell_pid}"
      eval "stack_arr_size=\${#$stack_var[@]}"
      if (( stack_arr_size )); then
        RETURN_VALUES[i++]=1
      else
        RETURN_VALUES[i++]=0
      fi
    else
      # must be to avoid miscount in `for in ...`
      RETURN_VALUE[i++]=''
    fi
  done
}

function tkl_get_last_trap_cmd_line()
{
  # drop return values
  RETURN_VALUES=()

  local trap_sig
  local stack_var
  local stack_arr_size
  local trap_prev_cmdline

  tkl_get_shell_pid
  local shell_pid="${RETURN_VALUE:-65535}" # default value if fail

  local i=0
  for trap_sig in "$@"; do
    if [[ -n "$trap_sig" ]]; then
      stack_var="tkl__traplib_cmdline_stack__${trap_sig}_${shell_pid}"
      eval "stack_arr_size=\${#$stack_var[@]}"
      if (( stack_arr_size )); then
        eval "RETURN_VALUE[i++]=\"\${$stack_var[@]: -1}\""
      else
        # must be to avoid miscount in `for in ...`
        RETURN_VALUE[i++]=''
      fi
    else
      # must be to avoid miscount in `for in ...`
      RETURN_VALUE[i++]=''
    fi
  done
}

function tkl_set_trap_postponed_exit()
{
  tkl_get_shell_pid
  local shell_pid="${RETURN_VALUE:-65535}" # default value if fail

  tkl_declare_global tkl__traplib_cmdline_stack__EXIT_${shell_pid}_postponed 1
  eval "(( ! \${#tkl__traplib_cmdline_stack__EXIT_${shell_pid}_postponed_code} ))" && tkl_declare_global tkl__traplib_cmdline_stack__EXIT_${shell_pid}_postponed_code $1
}

function tkl_unset_trap_postponed_exit()
{
  tkl_get_shell_pid
  local shell_pid="${RETURN_VALUE:-65535}" # default value if fail

  unset tkl__traplib_cmdline_stack__EXIT_${shell_pid}_postponed
  unset tkl__traplib_cmdline_stack__EXIT_${shell_pid}_postponed_code
}

function tkl_set_trap_handler_pop_on_exec()
{
  local trap_sig="$1"

  tkl_get_shell_pid
  local shell_pid="${RETURN_VALUE:-65535}" # default value if fail

  tkl_join_array FUNCNAME '|' 2
  local func_names_stack="${RETURN_VALUES[1]}"

  tkl_declare_global tkl__traplib_cmdline_stack__${trap_sig}_${shell_pid}_pop_on_exec 1

  unset RETURN_VALUES
}

function tkl_unset_trap_handler_pop_on_exec()
{
  local trap_sig="$1"

  tkl_get_shell_pid
  local shell_pid="${RETURN_VALUE:-65535}" # default value if fail

  tkl_join_array FUNCNAME '|' 2
  local func_names_stack="${RETURN_VALUES[1]}"

  unset tkl__traplib_cmdline_stack__${trap_sig}_${shell_pid}_pop_on_exec
  unset RETURN_VALUES
}

function tkl_declare_global_trap_handler()
{
  local trap_sig="$1"
  local shell_pid="$2"
  local func_names_stack="$3"
  local auto_pop_on_exec="${4:-0}" # has meaning only for not RETURN and not EXIT signals

  if [[ "$trap_sig" == "RETURN" ]]; then
    # CAUTION:
    #   To avoid call not in a function.
    if [[ -n "$func_names_stack" ]]; then
      tkl_declare_global tkl__traplib_cmdline_stack__RETURN_handler "declare tkl__last_error=\$?
if (( \${#FUNCNAME[@]} )); then
  if (( ! ${stack_var}_handling )); then
    ${stack_var}_handling=1
    builtin trap '' RETURN

    local ${stack_var}_cmdline

    declare tkl__stack_arr_size=\${#$stack_var[@]}
    while (( tkl__stack_arr_size )); do
      [[ \"\${$stack_var[tkl__stack_arr_size-2]}\" != \"$func_names_stack\" ]] && break
      ${stack_var}_cmdline=\${$stack_var[tkl__stack_arr_size-1]}
      unset $stack_var[tkl__stack_arr_size-1]
      unset $stack_var[tkl__stack_arr_size-2]
      {
        tkl_set_return \$tkl__last_error
        eval \"\$${stack_var}_cmdline\"
      }
      tkl__stack_arr_size=\${#$stack_var[@]}
    done

    if (( ! tkl__stack_arr_size )); then
      unset $stack_var
    fi
    unset ${stack_var}_cmdline

    if (( ! tkl__traplib_cmdline_stack__EXIT_${shell_pid}_handling && tkl__traplib_cmdline_stack__EXIT_${shell_pid}_postponed )); then
      local tkl__traplib_cmdline_stack__EXIT_${shell_pid}_cmdline

      declare tkl__stack_arr_size=\${#tkl__traplib_cmdline_stack__EXIT_${shell_pid}[@]}
      while (( tkl__stack_arr_size )); do
        tkl__traplib_cmdline_stack__EXIT_${shell_pid}_cmdline=\"\${tkl__traplib_cmdline_stack__EXIT_${shell_pid}[tkl__stack_arr_size-1]}\"
        unset tkl__traplib_cmdline_stack__EXIT_${shell_pid}[tkl__stack_arr_size-1]
        unset tkl__traplib_cmdline_stack__EXIT_${shell_pid}[tkl__stack_arr_size-2]
        {
          tkl_set_return \$tkl__last_error
          eval \"\$tkl__traplib_cmdline_stack__EXIT_${shell_pid}_cmdline\"
        }
        tkl__stack_arr_size=\${#tkl__traplib_cmdline_stack__EXIT_${shell_pid}[@]}
      done

      unset tkl__traplib_cmdline_stack__EXIT_${shell_pid}
      unset tkl__traplib_cmdline_stack__EXIT_${shell_pid}_cmdline

      exit \${tkl__traplib_cmdline_stack__EXIT_${shell_pid}_postponed_code:-\$tkl__last_error}
    fi

    unset ${stack_var}_handling

    if (( tkl__stack_arr_size )); then
      builtin trap \"\$tkl__traplib_cmdline_stack__RETURN_handler\" RETURN
    else
      builtin trap - RETURN
    fi

    unset tkl__stack_arr_size
  fi
fi"
    fi
  elif [[ "$trap_sig" == "EXIT" ]]; then
    tkl_declare_global tkl__traplib_cmdline_stack__EXIT_handler "declare tkl__last_error=\$?
if (( ! ${stack_var}_handling )); then
  ${stack_var}_handling=1
  builtin trap '' EXIT

  if (( ! tkl__traplib_cmdline_stack__RETURN_${shell_pid}_handling )); then
    declare tkl__stack_arr_size=\${#tkl__traplib_cmdline_stack__RETURN_${shell_pid}[@]}
    while (( tkl__stack_arr_size )); do
      declare tkl__traplib_cmdline_stack__RETURN_${shell_pid}_cmdline=\"\${tkl__traplib_cmdline_stack__RETURN_${shell_pid}[tkl__stack_arr_size-1]}\"
      unset tkl__traplib_cmdline_stack__RETURN_${shell_pid}[tkl__stack_arr_size-1]
      unset tkl__traplib_cmdline_stack__RETURN_${shell_pid}[tkl__stack_arr_size-2]
      {
        tkl_set_return \$tkl__last_error
        eval \"\$tkl__traplib_cmdline_stack__RETURN_${shell_pid}_cmdline\"
      }
      tkl__stack_arr_size=\${#tkl__traplib_cmdline_stack__RETURN_${shell_pid}[@]}
    done

    unset tkl__traplib_cmdline_stack__RETURN_${shell_pid}
    unset tkl__traplib_cmdline_stack__RETURN_${shell_pid}_cmdline
  fi

  declare tkl__stack_arr_size=\${#$stack_var[@]}
  while (( tkl__stack_arr_size )); do
    declare ${stack_var}_cmdline=\"\${$stack_var[tkl__stack_arr_size-1]}\"
    unset $stack_var[tkl__stack_arr_size-1]
    unset $stack_var[tkl__stack_arr_size-2]
    {
      tkl_set_return \$tkl__last_error
      eval \"\$${stack_var}_cmdline\"
    }
    tkl__stack_arr_size=\${#$stack_var[@]}
  done

  unset $stack_var
  unset ${stack_var}_cmdline
  unset tkl__stack_arr_size
  unset ${stack_var}_handling

  builtin trap - EXIT

  (( \${#${stack_var}_postponed_code} )) && exit \${${stack_var}_postponed_code}
fi"
  else
    tkl_declare_global tkl__traplib_cmdline_stack__${trap_sig}_handler "declare tkl__last_error=\$?
if (( ! ${stack_var}_handling )); then
  ${stack_var}_handling=1
  builtin trap '' $trap_sig

  declare tkl__stack_arr_size=\${#$stack_var[@]}
  if (( tkl__traplib_cmdline_stack__${trap_sig}_${shell_pid}_pop_on_exec )); then
    while (( tkl__stack_arr_size )); do
      declare ${stack_var}_cmdline=\"\${$stack_var[tkl__stack_arr_size-1]}\"
      unset $stack_var[tkl__stack_arr_size-1]
      unset $stack_var[tkl__stack_arr_size-2]
      {
        tkl_set_return \$tkl__last_error
        eval \"\$${stack_var}_cmdline\"
      }
      tkl__stack_arr_size=\${#$stack_var[@]}
    done
  else
    for (( ; tkl__stack_arr_size >= 2; tkl__stack_arr_size -= 2 )); do
      { eval \"\${$stack_var[tkl__stack_arr_size-1]}\"; }
    done
    tkl__stack_arr_size=\${#$stack_var[@]}
  fi

  unset $stack_var
  unset ${stack_var}_cmdline

  if (( ! tkl__traplib_cmdline_stack__EXIT_${shell_pid}_handling && tkl__traplib_cmdline_stack__EXIT_${shell_pid}_postponed )); then
    declare tkl__traplib_cmdline_stack__EXIT_${shell_pid}_cmdline

    tkl__stack_arr_size=\${#tkl__traplib_cmdline_stack__EXIT_${shell_pid}[@]}
    while (( tkl__stack_arr_size )); do
      tkl__traplib_cmdline_stack__EXIT_${shell_pid}_cmdline=\"\${tkl__traplib_cmdline_stack__EXIT_${shell_pid}[tkl__stack_arr_size-1]}\"
      unset tkl__traplib_cmdline_stack__EXIT_${shell_pid}[tkl__stack_arr_size-1]
      unset tkl__traplib_cmdline_stack__EXIT_${shell_pid}[tkl__stack_arr_size-2]
      {
        tkl_set_return \$tkl__last_error
        eval \"\$tkl__traplib_cmdline_stack__EXIT_${shell_pid}_cmdline\"
      }
      tkl__stack_arr_size=\${#tkl__traplib_cmdline_stack__EXIT_${shell_pid}[@]}
    done

    unset tkl__traplib_cmdline_stack__EXIT_${shell_pid}
    unset tkl__traplib_cmdline_stack__EXIT_${shell_pid}_cmdline

    exit \${tkl__traplib_cmdline_stack__EXIT_${shell_pid}_postponed_code:-\$tkl__last_error}
  fi

  unset ${stack_var}_handling

  if (( tkl__stack_arr_size )); then
    builtin trap \"\$tkl__traplib_cmdline_stack__${trap_sig}_handler\" $trap_sig
  else
    builtin trap - $trap_sig
  fi

  unset tkl__stack_arr_size
fi
tkl_set_return \$tkl__last_error"
  fi
}

function tkl_push_trap()
{
  # drop return values
  EXIT_CODES=()
  RETURN_VALUES=()

  local trap_cmdline="$1"
  [[ -z "$trap_cmdline" ]] && return 0 # nothing to push
  shift

  local last_error=255

  local trap_sig
  local stack_var
  local stack_arr_size
  local trap_prev_cmdline

  tkl_get_shell_pid
  local shell_pid="${RETURN_VALUE:-65535}" # default value if fail

  tkl_join_array FUNCNAME '|' 2
  local func_names_stack="${RETURN_VALUES[1]}"

  RETURN_VALUES=()

  local is_RETURN_trap_set=0
  local is_EXIT_trap_set=0

  local is_processed

  local i=0
  for trap_sig in "$@"; do
    is_processed=0

    if [[ -n "$trap_sig" ]]; then
      stack_var="tkl__traplib_cmdline_stack__${trap_sig}_${shell_pid}"

      # ignore if already at handling
      if (( ! ${stack_var}_handling )); then
        eval "stack_arr_size=\${#$stack_var[@]}"
        if (( stack_arr_size )); then
          # CAUTION:
          #   To avoid call not in a function.
          if [[ "$trap_sig" != "RETURN" || -n "$func_names_stack" ]]; then
            # append to the end is equal to push trap onto stack
            eval "$stack_var[stack_arr_size]=\"\$func_names_stack\""
            eval "$stack_var[stack_arr_size+1]=\"\$trap_cmdline\""
          fi
        else
          eval "$stack_var=(\"\$func_names_stack\" \"\$trap_cmdline\")"
        fi

        if [[ "$trap_sig" == "RETURN" ]]; then
          # CAUTION:
          #   To avoid call not in a function.
          if [[ -n "$func_names_stack" ]]; then
            # CAUTION:
            #   In case of RETURN signal convert the trap command line into nested trap command line to:
            #   1. Avoid handling return in this function.
            #
            is_RETURN_trap_set=1
            tkl_declare_global_trap_handler RETURN "$shell_pid" "$func_names_stack"
            tkl_escape_string "$tkl__traplib_cmdline_stack__RETURN_handler" '\$"' 0
            builtin trap "builtin trap \"$RETURN_VALUE\" RETURN" RETURN
            last_error=$?
            unset RETURN_VALUE
            EXIT_CODES[i++]=$last_error
            is_processed=1
          fi
        elif [[ "$trap_sig" == "EXIT" ]]; then
          is_EXIT_trap_set=1
          tkl_declare_global_trap_handler EXIT "$shell_pid" "$func_names_stack"
          eval "builtin trap \"\$tkl__traplib_cmdline_stack__EXIT_handler\" EXIT"
          last_error=$?
          EXIT_CODES[i++]=$last_error
          is_processed=1
        else
          tkl_declare_global_trap_handler "$trap_sig" "$shell_pid" "$func_names_stack"
          eval "builtin trap \"\${tkl__traplib_cmdline_stack__${trap_sig}_handler}\" \"\$trap_sig\""
          last_error=$?
          EXIT_CODES[i++]=$last_error
          is_processed=1
        fi
      fi
    fi

    if (( ! is_processed )); then
      # must be to avoid miscount in `for in ...`
      EXIT_CODES[i++]=''
    fi
  done

  # Push an empty EXIT signal trap handler in case if the RETURN signal trap handler is pushed
  # and the EXIT signal trap handler is not present.
  if (( is_RETURN_trap_set && ! is_EXIT_trap_set )); then
    eval "stack_arr_size=\${#tkl__traplib_cmdline_stack__EXIT_${shell_pid}[@]}"
    (( ! stack_arr_size )) && tkl_push_trap ':' EXIT # in case of exit call from the RETURN signal trap handler
  fi

  return $last_error
}

function tkl_pop_trap()
{
  # drop return values
  EXIT_CODES=()
  RETURN_VALUES=()

  local last_error=255

  local trap_sig
  local stack_var
  local stack_arr_size
  local trap_cmdline

  tkl_get_shell_pid
  local shell_pid="${RETURN_VALUE:-65535}" # default value if fail

  tkl_join_array FUNCNAME '|' 2
  local func_names_stack="${RETURN_VALUES[1]}"

  RETURN_VALUES=()

  local is_processed

  local i=0
  for trap_sig in "$@"; do
    is_processed=0
    stack_var="tkl__traplib_cmdline_stack__${trap_sig}_${shell_pid}"

    # ignore if already at handling
    if (( ! ${stack_var}_handling )); then
      eval "stack_arr_size=\${#$stack_var[@]}"
      if (( stack_arr_size )); then

        # CAUTION:
        #   The `builtin trap - RETURN` does change the trap state in this function and leaves the trap not changed for the caller function.
        #   But because the `builtin trap "builtin trap - RETURN" RETURN` has no effect from here, then we have to reset it in the immediate handler instead.
        #

        # update the signal trap command line
        if [[ "$trap_sig" == "RETURN" ]]; then
          # CAUTION:
          #   To avoid call not in a function.
          if [[ -n "$func_names_stack" ]]; then
            # can pop only from the same function
            if eval "[[ \"\${$stack_var[stack_arr_size-2]}\" == \"\$func_names_stack\" ]]"; then
              (( stack_arr_size -= 2 ))

              eval "RETURN_VALUES[i]=\"\${$stack_var[stack_arr_size+1]}\""

              unset $stack_var[stack_arr_size+1]
              unset $stack_var[stack_arr_size]

              if (( stack_arr_size )); then
                # CAUTION:
                #   In case of RETURN signal convert the trap command line into nested trap command line to:
                #   1. Avoid handling return in this function.
                #
                tkl_declare_global_trap_handler "$trap_sig" "$shell_pid" "$func_names_stack"
                tkl_escape_string "$tkl__traplib_cmdline_stack__RETURN_handler" '\$"' 0
                builtin trap "builtin trap \"$RETURN_VALUE\" RETURN" RETURN
                last_error=$?
                EXIT_CODES[i++]=$last_error
              else
                unset $stack_var
                unset tkl__traplib_cmdline_stack__RETURN_handler
                builtin trap "builtin trap - RETURN" RETURN # just in case if would work
                last_error=$?
                EXIT_CODES[i++]=$last_error
              fi
              is_processed=1
            fi
          fi
        else
          (( stack_arr_size -= 2 ))

          eval "RETURN_VALUES[i]=\"\${$stack_var[stack_arr_size+1]}\""

          unset $stack_var[stack_arr_size+1]
          unset $stack_var[stack_arr_size]

          if (( stack_arr_size )); then
            tkl_declare_global_trap_handler "$trap_sig" "$shell_pid" "$func_names_stack"
            eval "builtin trap \"\${tkl__traplib_cmdline_stack__${trap_sig}_handler}\" \"\$trap_sig\""
            last_error=$?
            EXIT_CODES[i++]=$last_error
          else
            unset $stack_var
            unset tkl__traplib_cmdline_stack__${trap_sig}_handler
            builtin trap - "$trap_sig"
            last_error=$?
            EXIT_CODES[i++]=$last_error
          fi
          is_processed=1
        fi
      fi
    fi

    if (( ! is_processed )); then
      # must be to avoid miscount in `for in ...`
      RETURN_VALUES[i]=''
      EXIT_CODES[i++]=''
    fi
  done

  return $last_error
}

fi
