# pure python module for commands w/o extension modules usage

import os, re, types

class YamlConfig(dict):
  def __init__(self, user_config = None):
    # default config
    self.update({
      'expand_undefined_var': True,
      'expand_undefined_var_to_prefix': r'*$/{',  # CAUTION: `$` and `{` must be separated from each other, otherwise the infinite recursion would take a place
      'expand_undefined_var_to_value': None,      # None - use variable name instead, '' - empty
      'expand_undefined_var_to_suffix': r'}'
    })
    if not user_config is None:
      self.update(user_config)

  def update(self, user_config):
    return super().update(user_config)

class YamlEnv(object):
  def __init__(self, user_vars = None, user_config = None):
    self.unexpanded_vars = user_vars if not user_vars is None else {}
    self.expanded_vars = {}
    self.config = YamlConfig(user_config)
    # local stacks to push/pop variables
    self.unexpanded_stack = []
    self.expanded_stack = []

  def push_unexpanded_vars(self):
    # `(<previous dictionary>, [<newly added keys>])`
    self.unexpanded_stack.append((self.unexpanded_vars, []))

  def pop_unexpanded_vars(self, reexpand_vars, remove_pred = None):
    if len(self.unexpanded_stack) == 0:
      raise Exception('unexpanded_stack is empty to pop')
    last_stack_record = self.unexpanded_stack[-1]
    self.unexpanded_vars = last_stack_record[0]
    if not remove_pred is None:
      if not isinstance(remove_pred, types.LambdaType):
        raise Exception('remove_pred is not a lambda type' + str(type(remove_pred)))
      for key in last_stack_record[1]:
        remove_pred(key)
    del self.unexpanded_stack[-1]
    if reexpand_vars:
      self.expand()

  def push_expanded_vars(self):
    # `(<previous dictionary>, [<newly added keys>])`
    self.expanded_stack.append((self.expanded_vars, []))

  def pop_expanded_vars(self, remove_pred = None):
    if len(self.expanded_stack) == 0:
      raise Exception('expanded_stack is empty to pop')
    last_stack_record = self.expanded_stack[-1]
    self.expanded_vars = last_stack_record[0]
    if not remove_pred is None:
      if not isinstance(remove_pred, types.LambdaType):
        raise Exception('remove_pred is not a lambda type' + str(type(remove_pred)))
      for key in last_stack_record[1]:
        remove_pred(key)
    del self.expanded_stack[-1]

  def load(self, yaml_dict):
    if not isinstance(yaml_dict, dict):
      raise Exception('yaml_dict is not a dictionary object')

    if len(self.unexpanded_stack) == 0:
      self.unexpanded_vars.update(yaml_dict)
    else:
      # record variables changes
      last_stack_record = self.unexpanded_stack[-1]
      last_unexpanded_vars = last_stack_record[0]
      last_added_unexpanded_var_names = last_stack_record[1]
      for key, val in yaml_dict.items():
        if key not in last_unexpanded_vars.keys() and key not in last_added_unexpanded_var_names:
          last_added_unexpanded_var_names.append(key)
        self.unexpanded_vars[key] = val
      last_stack_record = (last_stack_record[0], last_added_unexpanded_var_names)

  def has_unexpanded_var(self, var_name):
    return True if var_name in self.unexpanded_vars.keys() else False

  def get_unexpanded_value(self, var_name):
    return self.unexpanded_vars.get(var_name)

  def has_expanded_var(self, var_name):
    return True if var_name in self.expanded_vars.keys() else False

  def get_expanded_value(self, var_name):
    return self.expanded_vars.get(var_name)

  def set_config(self, key, value):
    self.config[key] = value

  def get_config(self, key):
    return self.config[key]

  def has_config(self, key):
    return True if key in self.config else False

  def unexpanded_items(self):
    return self.unexpanded_vars.items()

  def expanded_items(self):
    return self.expanded_vars.items()

  # expands `${...}` expressions recursively from not nested YAML dictionary for a single external value
  def expand_value(self, value, user_config = None):
    config = self.config
    if not user_config is None:
      config.update(user_config)

    expand_undefined_var = config['expand_undefined_var']
    expand_undefined_var_to_prefix = config['expand_undefined_var_to_prefix'] if expand_undefined_var else ''
    expand_undefined_var_to_value = config['expand_undefined_var_to_value'] if expand_undefined_var else ''
    expand_undefined_var_to_suffix = config['expand_undefined_var_to_suffix'] if expand_undefined_var else ''

    out_value = str(value)
    has_unexpanded_sequences = False

    while True:
      expanded_value = ''
      prev_match_index = 0

      has_unexpanded_sequences = False

      for m in re.finditer(r'\${([^\$]+)}', out_value):
        has_unexpanded_sequences = True
        var_name = m.group(1)
        if not var_name[:4] == 'env:':
          if not var_name[-5:] == ':path':
            var_value = self.get_unexpanded_value(var_name)
          else:
            var_value = self.get_unexpanded_value(var_name[:-6]).replace('\\', '/')
        else:
          if not var_name[-5:] == ':path':
            var_value = os.environ[var_name[4:]]
          else:
            var_value = os.environ[var_name[4:-5]].replace('\\', '/')
        if not var_value is None:
          expanded_value += out_value[prev_match_index:m.start()] + str(var_value)
        else:
          if expand_undefined_var:
            # replace by special construction to indicate an expansion of not defined variable
            if expand_undefined_var_to_value is None:
              expanded_value += out_value[prev_match_index:m.start()] + expand_undefined_var_to_prefix + m.group(1) + expand_undefined_var_to_suffix
            else:
              expanded_value += out_value[prev_match_index:m.start()] + expand_undefined_var_to_prefix + expand_undefined_var_to_value + expand_undefined_var_to_suffix
          else:
            expanded_value += out_value[prev_match_index:m.end()]
        prev_match_index = m.end()

      if prev_match_index > 0:
        out_value = expanded_value + out_value[prev_match_index:]

      if not has_unexpanded_sequences:
        break

    return out_value

  # expands `${...}` expressions and lists recursively from not nested YAML dictionary for all variables in the storage
  def expand(self):
    for key, val in self.unexpanded_vars.items():
      if len(self.expanded_stack) != 0:
        # record variables changes
        last_stack_record = self.expanded_stack[-1]
        last_expanded_vars = last_stack_record[0]
        last_added_expanded_var_names = last_stack_record[1]
        if key not in last_expanded_vars.keys() and key not in last_added_expanded_var_names:
          last_added_expanded_var_names.append(key)

      if isinstance(val, str) or isinstance(val, int) or isinstance(val, float):
        self.expanded_vars[key] = self.expand_value(val)
      elif isinstance(val, list):
        """if not key.endswith('_CMDLINE'):"""
        expanded_val = self.expanded_vars[key] = []

        for i in val:
          if not isinstance(i, str):
            # TODO
            raise Exception('YamlEnv does not support yaml list item type: ' + str(type(i)))

          expanded_val.append(self.expand_value(i))
        """
        else:
          cmdline = ''

          for i in val:
            if not isinstance(i, str):
              # TODO
              raise Exception('YamlEnv does not support yaml list item type: ' + str(type(i)))

            j = self.expand_value(i)

            has_spaces = False

            for c in j:
              if c.isspace():
                has_spaces = True
                break

            if not has_spaces:
              cmdline = (cmdline + ' ' if len(cmdline) > 0 else '') + j
            else:
              cmdline = (cmdline + ' ' if len(cmdline) > 0 else '') + '"' + j + '"'

          self.expanded_vars[key] = cmdline
        """
      else:
        # TODO
        raise Exception('YamlEnv does not support yaml object type: ' + str(type(val)))

      if len(self.expanded_stack) != 0:
        last_stack_record[1] = last_added_expanded_var_names
