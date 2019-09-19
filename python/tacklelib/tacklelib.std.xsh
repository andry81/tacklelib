# pure python module for commands with extension modules usage: tacklelib

import os, plumbum

### local import ###

tkl_import_module(SOURCE_DIR, 'tacklelib.std.py', 'tkl')

### functions ###

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

# workaround for the issue:
# `lambda with an environment variable `${...}` gives NameError`:
# https://github.com/xonsh/xonsh/issues/3296
def delvar(x):
  #del ${x}
  del globals()[x]

def setvar(x, value):
  #${x} = value
  globals()[x] = value

def getvar(x):
  #return ${x}
  return globals()[x]

def call(cmd, *args):
  if cmd == '':
    raise Exception('cmd must be a not empty command string')

  #cmdline = [cmd]
  #cmdline_args = ''
  #
  #for arg in args:
  #  cmdline.append(arg)
  #
  #  if arg != '':
  #    give_quotes = False
  #
  #    for c in arg:
  #      if c.isspace():
  #        give_quotes = True
  #        break
  #  else:
  #    give_quotes = True
  #
  #  if not give_quotes:
  #    cmdline_args += ' ' + arg
  #  else:
  #    cmdline_args += ' "' + arg + '"'
  #
  #print('>{0} {1}'.format(cmd, cmdline_args))
  #
  #@(cmdline) # xonsh expression

  localcmd = plumbum.local[cmd]
  localcmd.append(*args)

  localcmd() # plumbum expression
