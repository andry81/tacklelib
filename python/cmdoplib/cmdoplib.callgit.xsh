# python module for commands with extension modules usage: tacklelib, plumbum

tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.std.xsh')

import sys, plumbum

def call_git(args_list,
             no_except = False, in_bg = False,
             cmd_expr_expander = get_default_call_cmd_expr_expander(),
             dry_run = False, max_stdout_lines = 9):
  try:
    ret = call('${GIT}', args_list,
      stdout = None, stderr = None, no_except = no_except, in_bg = in_bg,
      cmd_expr_expander = cmd_expr_expander, dry_run = dry_run)

  except plumbum.ProcessExecutionError as proc_err:
    if len(proc_err.stdout) > 0:
      print(proc_err.stdout.rstrip())
    if len(proc_err.stderr) > 0:
      print(proc_err.stderr.rstrip())
    if len(proc_err.stdout) > 0 or len(proc_err.stderr) > 0:
      print('<') # end of a command output
    raise

  else:
    # cut out the middle of the stdout
    stdout_lines = ret[1].rstrip()
    stderr_lines = ret[2].rstrip()

    tkl.print_max(stdout_lines, max_lines = max_stdout_lines)
    if len(stderr_lines) > 0:
      print(stderr_lines)
      stderr_warning_match = re.match('W: [^+]', stderr_lines)
      if stderr_warning_match:
        raise Exception('specific warnings from the `git ...` command is treated as errors')

    if len(stdout_lines) > 0 or len(stderr_lines) > 0:
      print('<') # end of a command output

  return ret

def call_git_no_except(args_list,
                       cmd_expr_expander = get_default_call_cmd_expr_expander(),
                       dry_run = False, max_stdout_lines = 9):
  return call_git(args_list, no_except = True,
    cmd_expr_expander = cmd_expr_expander, max_stdout_lines = max_stdout_lines)
