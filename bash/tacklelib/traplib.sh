#!/bin/bash

# Script library to support trap shell operations.

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$SOURCE_TACKLELIB_TRAPLIB_SH" || SOURCE_TACKLELIB_TRAPLIB_SH -eq 0) ]]; then

SOURCE_TACKLELIB_TRAPLIB_SH=1 # including guard

source '/bin/bash_entry'

function tkl_get_trap_cmd_line()
{
  tkl_get_trap_cmd_line_impl RETURN_VALUES "$@"
}

function tkl_get_trap_cmd_line_impl()
{
  local out_var="$1"
  shift

  # drop return values
  eval "$out_var=()"

  local trap_sig
  local stack_var
  local stack_arr_size
  local trap_cmdline
  local trap_prev_cmdline

  local i=0
  for trap_sig in "$@"; do
    stack_var="tkl__traplib_cmdline_stack__$trap_sig"
    eval "stack_arr_size=\${#$stack_var[@]}"
    if (( stack_arr_size )); then
      eval "$out_var[i]=\"\${$stack_var[@]: -1}\""
    else
      # use the signal current trap command line
      declare -a "trap_cmdline=(`trap -p "$trap_sig"`)"
      eval "$out_var[i]=\"\${trap_cmdline[2]}\""
    fi
    (( i++ ))
  done
}

function tkl_push_trap()
{
  # drop return values
  EXIT_CODES=()
  RETURN_VALUES=()

  local cmdline="$1"
  [[ -z "$cmdline" ]] && return 0 # nothing to push
  shift

  local trap_sig
  local stack_var
  local trap_cmdline_size
  local prev_cmdline

  local i=0
  for trap_sig in "$@"; do
    stack_var="tkl__traplib_cmdline_stack__$trap_sig"
    eval "trap_cmdline_size=\${#$stack_var[@]}"
    if (( trap_cmdline_size )); then
      # append to the end is equal to push trap onto stack
      eval "$stack_var[trap_cmdline_size]=\"\$cmdline\""
    else
      # first stack element is always the trap current command line if not empty
      declare -a "prev_cmdline=(`trap -p $trap_sig`)"
      if (( ${#prev_cmdline[2]} )); then
        eval "$stack_var=(\"\${prev_cmdline[2]}\" \"\$cmdline\")"
      else
        eval "$stack_var=(\"\$cmdline\")"
      fi
    fi
    # update the signal trap command line
    tkl_get_trap_cmd_line "$trap_sig"
    if [[ "$trap_sig" == "RETURN" ]]; then
      # CAUTION:
      #   In case of RETURN signal convert the trap command line into nested trap command line to:
      #   1. Avoid handling return in this function.
      #   2. Pop and set the previous trap command line at the end of handler.
      #
      tkl_escape_string "${RETURN_VALUES[0]}; tkl_pop_trap RETURN; trap - RETURN" '' 0
      trap "trap \"$RETURN_VALUE\" RETURN" RETURN
    else
      trap "${RETURN_VALUES[0]}" "$trap_sig"
    fi
    EXIT_CODES[i++]=$?
  done
}

function tkl_pop_trap()
{
  # drop return values
  EXIT_CODES=()
  RETURN_VALUES=()

  local trap_sig
  local stack_var
  local trap_cmdline_size
  local trap_cmdline

  local i=0
  for trap_sig in "$@"; do
    stack_var="tkl__traplib_cmdline_stack__$trap_sig"
    eval "trap_cmdline_size=\${#$stack_var[@]}"
    if (( trap_cmdline_size-- )); then
      eval "RETURN_VALUES[i]=\"\${$stack_var[trap_cmdline_size]}\""
      # unset the end
      unset $stack_var[trap_cmdline_size]

      # update the signal trap command line

      # CAUTION:
      #   The `trap - RETURN` does change the trap state in this function and leaves the trap not changed for the caller function.
      #   But because the `trap "trap - RETURN" RETURN` has no effect from here, then we have to reset it in the immediate handler instead.
      #
      if (( trap_cmdline_size )); then
        if [[ "$trap_sig" != "RETURN" ]]; then
          tkl_get_trap_cmd_line_impl trap_cmdline "$trap_sig"
          trap "${trap_cmdline[0]}" "$trap_sig"
        fi
      else
        unset $stack_var
        [[ "$trap_sig" != "RETURN" ]] && trap - "$trap_sig"
      fi
      EXIT_CODES[i]=$?
    fi
    (( i++ ))
  done
}

function tkl_pop_exec_trap()
{
  # drop exit codes
  EXIT_CODES=()

  tkl_pop_trap "$@"

  local trap_sig
  local trap_cmdline

  local i=0
  for trap_cmdline in "${RETURN_VALUES[@]}"; do
    if [[ -n "$trap_cmdline" ]]; then
      # execute as function and store exit code
      eval "function tkl__traplib_immediate_handler() { $trap_cmdline; }"
      tkl__traplib_immediate_handler
      EXIT_CODES[i]=$?
      unset tkl__traplib_immediate_handler
    fi
    (( i++ ))
  done

  # CAUTION:
  #   In case of RETURN signal convert the trap command line into nested trap command line to:
  #   1. Avoid handling return in this function.
  #
  local i=0
  for trap_cmdline in "${RETURN_VALUES[@]}"; do
    if [[ -n "$trap_cmdline" ]]; then
      eval "trap_sig=\"\$$i\""
      if [[ "$trap_sig" == "RETURN" ]]; then
        tkl_escape_string "$trap_cmdline" '' 0
        trap "trap \"$RETURN_VALUE\" RETURN" RETURN
      fi
    fi
    (( i++ ))
  done
}

fi
