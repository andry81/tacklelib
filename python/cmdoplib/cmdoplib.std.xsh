# python module for commands with extension modules usage: tacklelib

tkl_declare_global('VERBOSITY_LEVEL', 0)

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.utils.py', 'tkl')

tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.yaml.xsh')

import os, sys, shutil, plumbum
from conditional import conditional

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

def delval(x):
  del x

# workaround for the issue:
# `lambda with an environment variable `${...}` gives NameError`:
# https://github.com/xonsh/xonsh/issues/3296
def delglobalvar(x):
  #del ${x}
  del globals()[x]

def setglobalvar(x, value):
  #${x} = value
  #globals()[x] = value
  tkl_declare_global(x, value) # reinject a variable to all imported modules has imported by the `tkl_import_module` function

def getglobalvar(x):
  #return ${x}
  return globals().get(x)

def hasglobalvar(x):
  #return True if x in ${...} else False
  return True if x in globals() else False

def delenvvar(x):
  #del os.environ[x]
  del plumbum.local.env[x]

def setenvvar(x, value):
  #os.environ[x] = value
  plumbum.local.env[x] = value

def getenvvar(x):
  return plumbum.local.env.get(x)

def hasenvvar(x):
  return True if x in plumbum.local.env else False

def discover_executable(env_var_name, exec_file_name_wo_ext, global_var_name):
  if env_var_name in os.environ:
    exec_path = os.environ[env_var_name]
    print('- discover environment variable: ' + env_var_name + '=`' + exec_path + '`')

    if exec_path.find('\\') >= 0 or exec_path.find('/') >= 0:
      exec_path = os.path.abspath(os.environ[env_var_name]).replace('\\', '/')
    #tkl_declare_global(global_var_name, exec_path)
    #print('- declare global variable: ' + global_var_name + '=`' + exec_path + '`')
    yaml_update_global_vars({global_var_name : exec_path}, search_by_pred_at_third = lambda var_name: getglobalvar(var_name))
    print('- declare global variable: ' + global_var_name + '=`' + exec_path + '`')
    return

  var = shutil.which(exec_file_name_wo_ext)
  if not var is None:
    exec_path = os.path.abspath(var).replace('\\', '/')
    #tkl_declare_global(global_var_name, exec_path)
    #print('- declare global variable: ' + global_var_name + '=`' + exec_path + '`')
    yaml_update_global_vars({global_var_name : exec_path}, search_by_pred_at_third = lambda var_name: getglobalvar(var_name))
    print('- declare global variable: ' + global_var_name + '=`' + exec_path + '`')
    return

  raise Exception('Executable is not found in the `' + env_var_name + '` environment variable nor in the PATH variable.')

def get_default_call_cmd_expr_expander():
  return lambda cmd_expr: yaml_expand_global_string(cmd_expr)

def set_verbosity_level(verbosity):
  global VERBOSITY_LEVEL

  if verbosity < 0:
    verbosity = 1 # max level

  VERBOSITY_LEVEL = verbosity

def call(cmd_expr, args_list,
         stdin = sys.stdin, stdout = sys.stdout, stderr = sys.stderr,
         env = None, no_except = False, in_bg = False,
         cmd_expr_expander = get_default_call_cmd_expr_expander(), dry_run = False, verbosity = None):
  global VERBOSITY_LEVEL

  if cmd_expr == '':
    raise Exception('cmd_expr must be a not empty string and a command expression with or without variables')

  if verbosity is None:
    verbosity = VERBOSITY_LEVEL

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

  if stdout is None or not hasattr(stdout, 'name') or stdout.name != '<null>':
    print('>{0}{1}'.format(cmd_expr, cmdline_args))

  # xonsh expression
  #@(cmdline)

  # Read yaml environment variables and export only those of them which values are a dictionary.
  # A string values is not dependent on a call context and is exported already up on a declaration.
  #
  yaml_environ_vars_local_stack = {}
  yaml_environ_unexpanded_vars = yaml_get_environ_unexpanded_vars()

  environ_expanded_vars = []

  for yaml_environ_var_name, yaml_environ_var_value in yaml_environ_unexpanded_vars.items():
    if isinstance(yaml_environ_var_value, dict):
      yaml_environ_var_value_if = yaml_environ_var_value.get('if')
      if not yaml_environ_var_value_if is None:
        yaml_environ_var_value_if_result = eval(yaml_expand_global_string(yaml_environ_var_value_if))
        if not yaml_environ_var_value_if_result:
          continue

      # parse only if have has `value` key
      yaml_environ_var_value_value = yaml_environ_var_value.get('value')
      if not yaml_environ_var_value_value is None:
        yaml_environ_var_value_apps = yaml_environ_var_value.get('apps')
        if not yaml_environ_var_value_apps is None:
          yaml_environ_var_value_applicable = False
          for app_expr in yaml_environ_var_value_apps:
            if cmd_expr.find(app_expr) >= 0: # both must be unevaluated or unexpanded
              yaml_environ_var_value_applicable = True
              break

          if not yaml_environ_var_value_applicable:
            continue

        # save previous environment variable into local stack
        yaml_environ_vars_local_stack[yaml_environ_var_name] = getenvvar(yaml_environ_var_name)

        # set the variable
        setenvvar(yaml_environ_var_name, yaml_expand_environ_value(yaml_environ_var_value_value))
        environ_expanded_vars.append(yaml_environ_var_name)
      else:
        yaml_environ_var_value_values = yaml_environ_var_value.get('values')
        if not yaml_environ_var_value_values is None:
          yaml_environ_var_value_apps = yaml_environ_var_value.get('apps')
          if not yaml_environ_var_value_apps is None:
            yaml_environ_var_value_applicable = False
            for app_expr in yaml_environ_var_value_apps:
              if cmd_expr.find(app_expr) >= 0: # both must be unevaluated or unexpanded
                yaml_environ_var_value_applicable = True
                break

            if not yaml_environ_var_value_applicable:
              continue

          yaml_environ_var_value_applicable = False
          for yaml_environ_var_value_value_dict in yaml_environ_var_value_values:
            yaml_environ_var_value_if = yaml_environ_var_value_value_dict['if']
            if not yaml_environ_var_value_if is None:
              yaml_environ_var_value_if_result = eval(yaml_expand_global_string(yaml_environ_var_value_if))
              if yaml_environ_var_value_if_result:
                yaml_environ_var_value_value = yaml_environ_var_value_value_dict['value']
                yaml_environ_var_value_applicable = True
                break
            else:
              yaml_environ_var_value_value = yaml_environ_var_value_value_dict['value']
              yaml_environ_var_value_applicable = True
              break

          if not yaml_environ_var_value_applicable:
            continue

          # save previous environment variable into local stack
          yaml_environ_vars_local_stack[yaml_environ_var_name] = getenvvar(yaml_environ_var_name)

          # set the variable
          setenvvar(yaml_environ_var_name, yaml_expand_environ_value(yaml_environ_var_value_value))
          environ_expanded_vars.append(yaml_environ_var_name)
        else:
          raise Exception('unknown environment variable format: ' + yaml_environ_var_name + ': ' + str(type(yaml_environ_var_value)))

  # use the explicit enviroment dictionary
  if not env is None:
    for env_var, env_value in env.items():
      # save previous environment variable into local stack if has not been already saved
      if env_var not in yaml_environ_vars_local_stack:
        yaml_environ_vars_local_stack[env_var] = getenvvar(env_var)

      # set the variable
      setenvvar(env_var, yaml_expand_environ_value(env_value))
      environ_expanded_vars.append(env_var)

  if verbosity > 0 and len(environ_expanded_vars) > 0:
    # print command environment variable at first
    print('- environment variables:')
    for env_var in environ_expanded_vars:
      print('  ' + env_var + '=`' + getenvvar(env_var) + '`')

  if len(yaml_environ_vars_local_stack) > 0 and (stdout is None or not hasattr(stdout, 'name') or stdout.name != '<null>'):
    # build `on exit` handler function
    def on_exit_call():
      for yaml_environ_var_name, yaml_environ_var_value in yaml_environ_vars_local_stack.items():
        if not yaml_environ_var_value is None:
          setenvvar(yaml_environ_var_name, yaml_environ_var_value)
        else:
          delenvvar(yaml_environ_var_name)
  else:
    on_exit_call = None

  # active the `on exit` handler
  with conditional(not on_exit_call is None, tkl.OnExit(lambda: (on_exit_call(), delval(on_exit_call)) if not on_exit_call is None else None)):
    # expand the variable
    cmd_exec = cmd_expr_expander(cmd_expr)

    # plumbum expression
    cmd = plumbum.local[cmd_exec]

    if args_list:
      cmd = cmd[args_list]

    if not in_bg:
      # must be to avoid a mix
      sys.stdout.flush()
      sys.stderr.flush()

      if not dry_run:
        # Passing the `None` does not help to intercept a command output to a variable, instead does need to not pass the parameter!
        if stdin is None:
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
        else:
          if not stdout is None:
            if not stderr is None:
              if not no_except:
               return cmd.run(stdin = stdin, stdout = stdout, stderr = stderr)
              else:
               return cmd.run(stdin = stdin, stdout = stdout, stderr = stderr, retcode = None)
            else:
              if not no_except:
                return cmd.run(stdin = stdin, stdout = stdout)
              else:
                return cmd.run(stdin = stdin, stdout = stdout, retcode = None)
          else:
            if not stderr is None:
              if not no_except:
                return cmd.run(stdin = stdin, stderr = stderr)
              else:
                return cmd.run(stdin = stdin, stderr = stderr, retcode = None)
            else:
              if not no_except:
                return cmd.run(stdin = stdin)
              else:
                return cmd.run(stdin = stdin, retcode = None)

    if not dry_run:
      if stdin is None:
        if not stdout is None:
          if not stderr is None:
            return cmd.run_bg(stdout = stdout, stderr = stderr)
          else:
            return cmd.run_bg(stdout = stdout)
        else:
          if not stderr is None:
            return cmd.run_bg(stderr = stderr)
          else:
            return cmd.run_bg()
      else:
        if not stdout is None:
          if not stderr is None:
            return cmd.run_bg(stdin = stdin, stdout = stdout, stderr = stderr)
          else:
            return cmd.run_bg(stdin = stdin, stdout = stdout)
        else:
          if not stderr is None:
            return cmd.run_bg(stdin = stdin, stderr = stderr)
          else:
            return cmd.run_bg(stdin = stdin)

  return (0, '', '') # dry run always succeed

def call_no_except(cmd_expr, args_list, **kwargs):
  return call(
    cmd_expr, args_list,
    no_except = True,
    **kwargs
  )
