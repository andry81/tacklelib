# python module for commands with extension modules usage: tacklelib, plumbum

tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.std.xsh')

import sys, plumbum

def call_svn(args_list,
             stdout = None, stderr = None, no_except = False, in_bg = False,
             cmd_expr_expander = get_default_call_cmd_expr_expander(), max_stdout_lines = 7):
  try:
    ret = call('${SVN}', args_list,
      stdout = stdout, stderr = stderr, no_except = no_except, in_bg = in_bg, cmd_expr_expander = cmd_expr_expander)

  except plumbum.ProcessExecutionError as proc_err:
    if len(proc_err.stdout) > 0:
      print(proc_err.stdout.rstrip())
    if len(proc_err.stderr) > 0:
      print(proc_err.stderr.rstrip())
    raise

  else:
    # cut out the middle of the stdout
    stdout_lines = ret[1].rstrip()
    stderr_lines = ret[2].rstrip()

    tkl.print_max(stdout_lines, max_lines = max_stdout_lines)
    if len(stderr_lines) > 0:
      print(stderr_lines)
      stderr_warning_match = re.match('warning: [^+]', stderr_lines)
      if stderr_warning_match:
        raise Exception('specific warnings from the `svn ...` command is treated as errors')

  return ret

def call_svn_no_except(args_list, stdout = None, stderr = None,
                       cmd_expr_expander = get_default_call_cmd_expr_expander(), max_stdout_lines = 7):
  return call_svn(args_list, stdout = stdout, stderr = stderr, no_except = True,
    cmd_expr_expander = cmd_expr_expander, max_stdout_lines = max_stdout_lines)
