# python module for commands with extension modules usage: tacklelib, yaml

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.cache.py', 'tkl')
tkl_import_module(TACKLELIB_ROOT, 'tacklelib.sig.py', 'tkl')
tkl_import_module(TACKLELIB_ROOT, 'tacklelib.io.py', 'tkl')
tkl_import_module(TACKLELIB_ROOT, 'tacklelib.utils.py', 'tkl')

tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.std.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.yaml.xsh')

import os, psutil, time, re

class RootDirCache(tkl.FileCache):
  def __init__(self, cache_file):
    if cache_file.find('.') >= 0:
      raise Exception('cache_file must not contain dot (`.`) characters')
    tkl.FileCache.__init__(self, 'cmdoplib.' + cache_file, app_cache_dir = LOCAL_CACHE_ROOT, no_logger_warnings = True)

class ServiceProcCache(RootDirCache):
  def __init__(self):
    RootDirCache.__init__(self, 'service_proc')

def cache_print_proc_list_header(column_names, column_widths, fmt_str = '{:<{}} {:<{}}'):
  print('  ' + fmt_str.format(
    *(i for j in [(column_name, column_width) for column_name, column_width in zip(column_names, column_widths)] for i in j)
  ))

  text = ''
  for column_width in column_widths:
    if len(text) > 0:
      text += ' '
    text += (column_width * '=')

  print('  ' + text)

def cache_print_proc_list_row(row_values, column_widths, fmt_str = '{:<{}} {:<{}}'):
  print('  ' + fmt_str.format(
    *(i for j in [(row_value, column_width) for row_value, column_width in zip(row_values, column_widths)] for i in j)
  ))

def cache_print_proc_list_footer(column_widths):
  text = ''
  for column_width in column_widths:
    if len(text) > 0:
      text += ' '
    text += (column_width * '-')

  print('  ' + text)

def cache_close_running_procs(procs, service_proc_cache, proc_sigterm_wait_timeout_sec = 5, proc_sigkill_wait_timeout_sec = 1):
  if len(procs) > 0:
    print('- Closing running processes with timeout={{SIGTERM={}, SIGKILL={}}} secs:'.format(proc_sigterm_wait_timeout_sec, proc_sigkill_wait_timeout_sec))

    proc_column_fmt = '{:<{}} {:<{}} {:<{}} {:<{}}'
    proc_column_names = ['<pid>', '<proc_name>', '<exit_code>', '<status>']
    proc_column_widths = [8, 24, 12, 32]

    cache_print_proc_list_header(proc_column_names, proc_column_widths, proc_column_fmt)

    def on_proc_sigterm(proc):
      proc_row_values = [proc.pid, proc.name(), proc.returncode, 'terminated by <SIGTERM>']
      cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)
      del service_proc_cache[str(proc.pid)]
      service_proc_cache.sync() # sync immediately

    def on_proc_sigkill(proc):
      proc_row_values = [proc.pid, proc.name(), proc.returncode, 'terminated by <SIGTKILL>']
      cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)
      del service_proc_cache[str(proc.pid)]
      service_proc_cache.sync() # sync immediately

    def on_proc_sigkill_ignore(proc):
      proc_row_values = [proc.pid, proc.name(), '-', 'running, <SIGTKILL> ignored']
      cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)

    # send SIGTERM
    for proc_id, proc in procs.items():
      try:
        proc.terminate()
      except psutil.NoSuchProcess:
        pass

    gone_procs, alive_procs = psutil.wait_procs(procs.values(), timeout = proc_sigterm_wait_timeout_sec, callback = on_proc_sigterm)
    if len(alive_procs) > 0:
      # send SIGKILL
      for proc in alive_procs:
        try:
          p.kill()
        except psutil.NoSuchProcess:
          pass

      gone_procs, alive_procs = psutil.wait_procs(alive_procs, timeout = proc_sigkill_wait_timeout_sec, callback = on_proc_sigkill)
      if len(alive_procs) > 0:
        # report ignored
        for proc in alive_procs:
          on_proc_sigkill_ignore(proc)

    cache_print_proc_list_footer(proc_column_widths)

def cache_init_service_proc(service_proc_cache):
  print('- Initializing service processes cache...')

  all_procs = {}

  for proc in psutil.process_iter(attrs=['pid', 'name']):
    try:
      pinfo = proc.as_dict(attrs=['pid', 'name'])
    except psutil.NoSuchProcess:
      pass
    else:
      all_procs[int(pinfo['pid'])] = pinfo['name']

  # Iterate over process records to:
  #   1. Close processes which are created by already unexisted python.exe process id.
  #   2. Remove process records which python.exe process has been closed.
  #

  print('- Reading service processes cache:')

  running_orphan_procs = {}

  # Format:
  #   Key:    service or background process pid
  #   Value:  (<python_pid>, <proc_name>, <proc_exe>)
  #

  proc_column_fmt = '{:<{}} {:<{}} {:<{}} {:<{}}'
  proc_column_names = ['<pid>', '<proc_name>', '<proc_exe>', '<status>']
  proc_column_widths = [8, 24, 64, 32]

  cache_print_proc_list_header(proc_column_names, proc_column_widths, proc_column_fmt)

  for svc_proc_key, svc_proc_value in dict(service_proc_cache).items():
    all_proc_ids = all_procs.keys()
    svc_proc_id = int(svc_proc_key)
    svc_proc_name = svc_proc_value[1]
    svc_proc_exe = svc_proc_value[2]
    if svc_proc_id in all_proc_ids:
      try:
        running_svc_proc = psutil.Process(svc_proc_id)
        running_svc_proc_exe = running_svc_proc.exe()
        if tkl.compare_file_paths(running_svc_proc_exe, svc_proc_exe):
          python_proc_id = int(svc_proc_value[0])
          if python_proc_id not in all_proc_ids:
            proc_row_values = [svc_proc_id, running_svc_proc.name(), running_svc_proc_exe, 'running, orphan']
            cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)
            running_orphan_procs[svc_proc_id] = running_svc_proc
          else:
            proc_row_values = [svc_proc_id, running_svc_proc.name(), running_svc_proc_exe, 'running, controlled']
            cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)
      except psutil.NoSuchProcess:
        proc_row_values = [svc_proc_id, svc_proc_name, svc_proc_exe, 'not found, removed']
        cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)
        del service_proc_cache[svc_proc_key]
        service_proc_cache.sync() # sync immediately
        pass
      except psutil.AccessDenied:
        proc_row_values = [svc_proc_id, running_svc_proc.name(), '?' + svc_proc_exe, 'access denied, ignored']
        cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)
    else:
      proc_row_values = [svc_proc_id, svc_proc_name, svc_proc_exe, 'not found, removed']
      cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)
      del service_proc_cache[svc_proc_key]
      service_proc_cache.sync() # sync immediately

  cache_print_proc_list_footer(proc_column_widths)

  cache_close_running_procs(running_orphan_procs, service_proc_cache)

  executed_procs = {}

  if SVN_SSH_ENABLED or GIT_SSH_ENABLED:
    current_proc_id = os.getpid()

    print('- Starting service processes:')

    proc_column_fmt = '{:<{}} {:<{}} {:<{}} {:<{}}'
    proc_column_names = ['<pid>', '<proc_name>', '<proc_exe>', '<status>']
    proc_column_widths = [8, 24, 64, 32]

    cache_print_proc_list_header(proc_column_names, proc_column_widths, proc_column_fmt)
    stdout_iostr = tkl.TmpFileIO('w+t')
    stderr_iostr = tkl.TmpFileIO('w+t')

    # use signals delayer to delay a user interruption in a critical code
    call_proc_id = None
    call_proc = None

    with tkl.DelayedSigInterrupt((tkl.signal.SIGINT, tkl.signal.SIGTERM)):
      ret = call('${GIT_SVN_SSH_AGENT}', [], stdout = stdout_iostr, stderr = stderr_iostr, in_bg = True)

      # WORKAROUND:
      #   In case of redirection the process id can be not a target process id but intermediate process, where the child is our target process.
      #   We must reread a process list and search the id as a parent process id to extract a child process as a target process.
      #

      # open immediately in case of interemediate process
      call_proc_id = ret.proc.pid # this is not a target process, but intermediate process
      try:
        call_proc = psutil.Process(call_proc_id)
      except psutil.NoSuchProcess:
        # too late, process is already closed
        pass

      cmd_expr_expanded = get_default_call_cmd_expr_expander()('${GIT_SVN_SSH_AGENT}')

      # scan for a child process while a timeout
      child_proc_search_timeout_sec = 3
      prev_time = time.time()
      is_child_proc_found = False

      while True:
        all_child_procs = {}

        for proc in psutil.process_iter(attrs=['pid', 'ppid', 'name']):
          try:
            pinfo = proc.as_dict(attrs=['pid', 'ppid', 'name'])
          except psutil.NoSuchProcess:
            pass
          else:
            proc_id = int(pinfo['pid'])
            proc_parent_id = int(pinfo['ppid'])
            proc_name = pinfo['name']
            all_child_procs[proc_id] = (proc_parent_id, proc_name)

        for child_proc_id, child_proc_value in all_child_procs.items():
          child_proc_parent_id = child_proc_value[0]
          child_proc_name = child_proc_value[1]

          if child_proc_parent_id == call_proc_id:
            # retest process on existence
            child_proc = None
            try:
              child_proc = psutil.Process(child_proc_id)
            except psutil.NoSuchProcess:
              pass

            if child_proc:
              try:
                child_proc_exe = child_proc.exe()
                if tkl.compare_file_paths(child_proc_exe, cmd_expr_expanded):
                  call_proc_id = child_proc_id
                  call_proc = child_proc

                  proc_row_values = [child_proc_id, child_proc.name(), child_proc_exe, 'child process, running']
                  cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)

                  # register a process in the cache
                  service_proc_cache[str(child_proc_id)] = (current_proc_id, child_proc_name, child_proc_exe)
                  service_proc_cache.sync() # sync immediately

                  executed_procs[child_proc_id] = child_proc

                  is_child_proc_found = True
                  break
              except psutil.NoSuchProcess:
                proc_row_values = [child_proc_id, child_proc.name(), '-', 'child process, closed']
                cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)
              except psutil.AccessDenied:
                proc_row_values = [child_proc_id, child_proc.name(), '-', 'child process, access denied']
                cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)
            else:
              proc_row_values = [child_proc_id, child_proc.name(), '-', 'child process, closed']
              cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)

        if is_child_proc_found:
          break

        next_time = time.time()
        if next_time - prev_time >= child_proc_search_timeout_sec:
          break

        # give to scheduler a break
        time.sleep(.05)

      if not is_child_proc_found and call_proc:
        # retest process on existence
        call_proc = None
        try:
          call_proc = psutil.Process(call_proc_id)
        except psutil.NoSuchProcess:
          pass

        if call_proc:
          proc_row_values = [call_proc_id, call_proc_exe, 'immediate process, running']
          cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)

          # register a process in the cache
          service_proc_cache[str(call_proc_id)] = (current_proc_id, call_proc.name(), call_proc_exe)
          service_proc_cache.sync() # sync immediately

          executed_procs[call_proc_id] = call_proc
        else:
          proc_row_values = [call_proc_id, call_proc_exe, 'immediate process, closed']
          cache_print_proc_list_row(proc_row_values, proc_column_widths, proc_column_fmt)

    cache_print_proc_list_footer(proc_column_widths)

    # reading stdout until no length change in timeout
    stdout_prev_len = stdout_iostr.tell()
    stderr_prev_len = stderr_iostr.tell()
    prev_time = time.time()
    while True:
      time.sleep(.05)

      stdout_next_len = stdout_iostr.tell()
      stderr_next_len = stderr_iostr.tell()

      next_time = time.time()

      if stdout_next_len != stdout_prev_len or stderr_next_len != stderr_prev_len:
        stdout_prev_len = stdout_next_len
        stderr_prev_len = stderr_next_len
        prev_time = next_time
      else:
        if next_time - prev_time >= 0.1:
          break

    stdout_size = stdout_iostr.tell()
    stderr_size = stderr_iostr.tell()

    # rereading stdout to extract `SSH_AUTH_SOCK` environment variable
    ssh_auth_sock_value = None
    stdout_iostr.seek(0)
    for line in stdout_iostr.readlines():
      ssh_auth_sock_match = re.match('SSH_AUTH_SOCK[ \t]*=[ \t]*\'?([^\';]+)\'?', line)
      if ssh_auth_sock_match:
        ssh_auth_sock_value = ssh_auth_sock_match.group(1)
        break

    if stdout_size > 0:
      stdout_iostr.seek(0)
      print(str(stdout_iostr.read()).rstrip())
    if stderr_size > 0:
      stderr_iostr.seek(0)
      print(str(stderr_iostr.read()).rstrip())
    if stdout_size > 0 or stderr_size > 0:
      print('---')

    if ssh_auth_sock_value is None:
      raise Exception('SSH_AUTH_SOCK is not found in the stdout of the `GIT_SVN_SSH_AGENT` process')

    # register SSH_AUTH_SOCK environment variable
    yaml_update_environ_vars(
      { 'SSH_AUTH_SOCK' : {
          'if'    : '${SVN_SSH_ENABLED} or ${GIT_SSH_ENABLED}',
          'apps'  : ['${GIT}'],
          'value' : ssh_auth_sock_value
        }
      },
      search_by_pred_at_third = lambda var_name: getglobalvar(var_name))

  return executed_procs
