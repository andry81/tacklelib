# python module for commands with extension modules usage: tacklelib, plumbum

import os, sys
from plumbum import local

tkl_source_module(SOURCE_DIR, 'cmdoplib.std.xsh')

def svn_update(configure_dir, scm_name):
  print(">svn update: {0}".format(configure_dir))

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 2

  wcroot_dir = getvar(scm_name + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  print(' -> {0}...'.format(wcroot_path))

  with local.cwd(wcroot_path):
    call('svn', ['up'])

def svn_checkout(configure_dir, scm_name):
  print(">svn checkout: {0}".format(configure_dir))

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 2

  wcroot_dir = getvar(scm_name + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  svn_checkout_url = getvar(scm_name + '.CHECKOUT_URL')

  print(' -> {0}...'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  if os.path.isdir(wcroot_path + '/.svn'):
    return 0

  call('svn', ['co', svn_checkout_url, wcroot_path])
