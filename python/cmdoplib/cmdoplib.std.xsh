# python module for commands with extension modules usage: tacklelib

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.py', 'tkl')

import os, sys, shutil, plumbum

# call from pipe
def pcall(args):
  args.pop(0)(*args)

# call from pipe w/o capture: https://xon.sh/tutorial.html#uncapturable-aliases
#@xonsh.tools.uncapturable # xonsh attribute
def pcall_nocap(args):
  args.pop(0)(*args)

# /dev/null (Linux) or nul (Windows) replacement
def pnull(args, stdin=None):
  for line in stdin:
    pass

def devnull():
  return tkl.devnull()

# workaround for the issue:
# `lambda with an environment variable `${...}` gives NameError`:
# https://github.com/xonsh/xonsh/issues/3296
def delglobalvar(x):
  #del ${x}
  del globals()[x]

def setglobalvar(x, value):
  #${x} = value
  #globals()[x] = value
  tkl_declare_global(x, value) # additionally would (re)inject the variable to all children modules

def getglobalvar(x):
  #return ${x}
  return globals()[x]

def hasglobalvar(x):
  #return True if x in ${...} else False
  return True if x in globals() else False

def delenvvar(x):
  del plumbum.local.env[x]

def setenvvar(x, value):
  plumbum.local.env[x] = value

def getenvvar(x):
  return plumbum.local.env[x]

def hasenvvar(x):
  return True if x in plumbum.local.env else False

def discover_executable(env_var_name, exec_file_name_wo_ext, global_var_name):
  if env_var_name in os.environ:
    exec_path = os.environ[env_var_name]
    print('- discover environment variable: ' + env_var_name + '=`' + exec_path + '`')

    if exec_path.find('\\') >= 0 or exec_path.find('/') >= 0:
      exec_path = os.path.abspath(os.environ[env_var_name]).replace('\\', '/')
    tkl_declare_global(global_var_name, exec_path)
    print('- declare global variable: ' + global_var_name + '=`' + exec_path + '`')
    return

  var = shutil.which(exec_file_name_wo_ext)
  if not var is None:
    exec_path = os.path.abspath(var).replace('\\', '/')
    tkl_declare_global(global_var_name, exec_path)
    print('- declare global variable: ' + global_var_name + '=`' + exec_path + '`')
    return

  raise Exception('Executable is not found in the `' + env_var_name + '` environment variable nor in the PATH variable.')

def call(cmd_expr, args_list, stdout = sys.stdout, stderr = sys.stderr, no_except = False):
  if cmd_expr == '':
    raise Exception('cmd_expr must be a not empty command string or global variable name (command expression)')

  #cmdline = [cmd_expr]
  cmdline_args = ''

  for arg in args_list:
    #cmdline.append(arg)

    if arg != '':
      give_quotes = False

      for c in arg:
        if c.isspace():
          give_quotes = True
          break
    else:
      give_quotes = True

    if not give_quotes:
      cmdline_args += ' ' + arg
    else:
      cmdline_args += ' "' + arg + '"'

  if stdout is None or stdout.name != '<null>':
    print('>{0}{1}'.format(cmd_expr, cmdline_args))

  # xonsh expression
  #@(cmdline)

  # plumbum expression

  # check on a global variable at first
  if cmd_expr.startswith('${') and cmd_expr.endswith('}'):
    global_var_name = cmd_expr[2:-1]
    if hasglobalvar(global_var_name):
      cmd_exec = getglobalvar(global_var_name)
    else:
      raise Exception('no such global variable: `' + global_var_name + '`')
  else:
    cmd_exec = cmd_expr

  cmd = plumbum.local[cmd_exec]

  if args_list:
    cmd = cmd[args_list]

  # must be to avoid a mix
  sys.stdout.flush()
  sys.stderr.flush()

  # Passing the `None` does not help to intercept a command output to a variable, instead does need to not pass the parameter!
  if not stdout is None:
    if not stderr is None:
      if not no_except:
       return cmd.run(stdout = stdout, stderr = stderr)
      else:
       return cmd.run(stdout = stdout, stderr = stderr, retcode = None)
    else:
      if not no_except:
        return cmd.run(stdout = stdout)
      else:
        return cmd.run(stdout = stdout, retcode = None)
  else:
    if not stderr is None:
      if not no_except:
        return cmd.run(stderr = stderr)
      else:
        return cmd.run(stderr = stderr, retcode = None)
    else:
      if not no_except:
        return cmd.run()
      else:
        return cmd.run(retcode = None)

def call_no_except(cmd_expr, args_list, stdout = sys.stdout, stderr = sys.stderr):
  return call(cmd_expr, args_list, stdout, stderr, no_except = True)
