# python module for commands with extension modules usage: tacklelib, plumbum

tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.std.xsh')

import sys, plumbum

def call_git(args_list,
             stdin = None, stdout = None, stderr = None,
             max_stdout_lines = 9, ignore_warnings = False,
             **kwargs):
  # retarget stdout/stderr to original handles to avoid it's interception and so the blocking
  if max_stdout_lines < 0:
    if not stdout:
      stdout = sys.stdout
    if not stderr:
      stderr = sys.stderr

  try:
    ret = call('${GIT}', args_list,
      stdin = stdin, stdout = stdout, stderr = stderr,
      **kwargs)

  except plumbum.ProcessExecutionError as proc_err:
    if len(proc_err.stdout) > 0:
      print(proc_err.stdout.rstrip())
    if len(proc_err.stderr) > 0:
      print(proc_err.stderr.rstrip())
    if stdout is None or not hasattr(stdout, 'name') or stdout.name != '<null>':
      print('<') # end of a command output
    raise

  else:
    # cut out the middle of the stdout
    stdout_lines = ret[1].rstrip()
    stderr_lines = ret[2].rstrip()

    tkl.print_max(stdout_lines, max_lines = max_stdout_lines)
    if len(stderr_lines) > 0:
      print(stderr_lines)
      if not ignore_warnings:
        stderr_warning_match_list = re.findall('W:\\s[^+-].*', stderr_lines, flags = re.MULTILINE)

        # ignore not alarmed warnings
        has_specific_warnings = False
        for stderr_warning_match in stderr_warning_match_list:
          #stderr_warning_second_match = re.match('W: ...', stderr_warning_match)
          stderr_warning_second_match = re.match('W:\\s[^:]+:\\s\\(160013\\): ', stderr_warning_match)
          if not stderr_warning_second_match:
            stderr_warning_second_match = re.match('W:\\sDo not be alarmed ', stderr_warning_match)
          if not stderr_warning_second_match:
            has_specific_warnings = True
            break

        if has_specific_warnings:
          raise Exception('specific warnings from the `git ...` command is treated as errors')

    if stdout is None or not hasattr(stdout, 'name') or stdout.name != '<null>':
      print('<') # end of a command output

  return ret

def call_git_no_except(args_list, **kwargs):
  return call_git(
    args_list,
    no_except = True,
    **kwargs)
