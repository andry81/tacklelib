# python module for commands with extension modules usage: tacklelib

tkl_source_module(SOURCE_DIR, 'cmdoplib.std.xsh')
tkl_source_module(SOURCE_DIR, 'cmdoplib.yaml.xsh')

import os

def parse_cmd_script_name(cmd_script_file_name):
  cmd_script_file_components = os.path.splitext(os.path.split(cmd_script_file_name)[1])
  cmd_components = cmd_script_file_components.split('~', 2)
  if cmd_components[0] == '':
    raise Exception('hub_attr must not be empty')
  if cmd_components[1] == '':
    raise Exception('scm_name must not be empty')
  if cmd_components[2] == '':
    raise Exception('cmd_name must not be empty')
  return {
    'hub_abbr': cmd_components[0],
    'scm_name': cmd_components[1],
    'cmd_name': cmd_components[2],
  }
