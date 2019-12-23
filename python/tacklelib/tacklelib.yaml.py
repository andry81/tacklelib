# pure python module for commands w/o extension modules usage

import os, re, types

class YamlConfig(dict):
  def __init__(self, user_config = None):
    # default config
    self.update({
      'expand_undefined_var': True,
      # CAUTION:
      #   `:` after `*` to workaround issue with the `os.path.abspath`: `os.path.abspath('*$/{aa}/../bb')` would expand into invalid absolute path
      #
      'expand_undefined_var_to_prefix': r'*:$/{',   # CAUTION: `$` and `{` must be separated from each other, otherwise the infinite recursion would take a place
      'expand_undefined_var_to_value': None,        # None - use variable name instead, '' - empty
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

  def pop_unexpanded_vars(self, reexpand_vars, remove_pred = None, list_as_cmdline = False):
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
      self.expand(list_as_cmdline = list_as_cmdline)

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

  # expands `${...}` string expressions recursively for a single external value
  def expand_string(self, str_value, search_in_expand_dict_at_second = None, search_by_pred_at_third = None, user_config = None):
    config = self.config
    if not user_config is None:
      config.update(user_config)

    expand_undefined_var = config['expand_undefined_var']
    expand_undefined_var_to_prefix = config['expand_undefined_var_to_prefix'] if expand_undefined_var else ''
    expand_undefined_var_to_value = config['expand_undefined_var_to_value'] if expand_undefined_var else ''
    expand_undefined_var_to_suffix = config['expand_undefined_var_to_suffix'] if expand_undefined_var else ''

    out_value = str(str_value)

    while True:
      expanded_value = ''
      prev_match_index = 0

      has_unexpanded_sequences = False

      for m in re.finditer(r'\${([^\$]+?)}', out_value):
        has_unexpanded_sequences = True
        var_name = m.group(1)
        if not var_name[:4] == 'env:':
          if not var_name[-5:] == ':path':
            var_value = self.get_unexpanded_value(var_name)
            if var_value is None: 
              if not search_in_expand_dict_at_second is None:
                var_value = search_in_expand_dict_at_second.get(var_name)
                if var_value is None:
                  if not search_by_pred_at_third is None:
                    var_value = search_by_pred_at_third(var_name)
              elif not search_by_pred_at_third is None:
                var_value = search_by_pred_at_third(var_name)
          else:
            var_name = var_name[:-6]
            var_value = self.get_unexpanded_value(var_name)
            if not var_value is None:
              var_value = var_value.replace('\\', '/')
              if var_value is None:
                if not search_in_expand_dict_at_second is None:
                  var_value = search_in_expand_dict_at_second.get(var_name)
                  if var_value is None:
                    if not search_by_pred_at_third is None:
                      var_value = search_by_pred_at_third(var_name)
                elif not search_by_pred_at_third is None:
                  var_value = search_by_pred_at_third(var_name)
        else:
          if not var_name[-5:] == ':path':
            var_name = var_name[4:]
            var_value = os.environ.get(var_name)
            if var_value is None:
              if not search_in_expand_dict_at_second is None:
                var_value = search_in_expand_dict_at_second.get(var_name)
                if var_value is None:
                  if not search_by_pred_at_third is None:
                    var_value = getglobalvar(var_name)
              elif not search_by_pred_at_third is None:
                var_value = getglobalvar(var_name)
          else:
            var_name = var_name[4:-5]
            var_value = os.environ.get(var_name)
            if not var_value is None:
              var_value = var_value.replace('\\', '/')
              if var_value is None:
                if not search_in_expand_dict_at_second is None:
                  var_value = search_in_expand_dict_at_second.get(var_name)
                  if var_value is None:
                    if not search_by_pred_at_third is None:
                      var_value = getglobalvar(var_name)
                elif not search_by_pred_at_third is None:
                  var_value = getglobalvar(var_name)
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

  # expands `${...}` string expressions in a list for all variables in the storage
  def expand_list(self, list_value, search_in_expand_dict_at_second = None, search_by_pred_at_third = None, list_as_cmdline = False):
    if not isinstance(list_value, list):
      raise Exception('list_value is not a list type' + str(type(list_value)))

    is_list_of_strings = True
    expanded_val = out_value = []

    for val in list_value:
      if isinstance(val, int) or isinstance(val, float):
        expanded_val.append(str(val))
      elif isinstance(val, str):
        expanded_val.append(
          self.expand_string(val,
            search_in_expand_dict_at_second = search_in_expand_dict_at_second,
            search_by_pred_at_third = search_by_pred_at_third
          )
        )
      elif isinstance(val, list):
        is_list_of_strings = False
        expanded_val.append(
          self.expand_list(val,
            search_in_expand_dict_at_second = search_in_expand_dict_at_second,
            search_by_pred_at_third = search_by_pred_at_third,
            list_as_cmdline = list_as_cmdline
          )
        )
      elif isinstance(val, dict):
        is_list_of_strings = False
        expanded_val.append(
          self.expand_dict(val,
            search_in_expand_dict_at_second = search_in_expand_dict_at_second,
            search_by_pred_at_third = search_by_pred_at_third,
            list_as_cmdline = list_as_cmdline
          )
        )
      else:
        raise Exception('unexpected yaml object type: ' + str(type(val)))

    if list_as_cmdline and is_list_of_strings:
      cmdline = ''

      for val in expanded_val:
        has_spaces = False

        for c in val:
          if c.isspace():
            has_spaces = True
            break

        if not has_spaces:
          cmdline = (cmdline + ' ' if len(cmdline) > 0 else '') + val
        else:
          cmdline = (cmdline + ' ' if len(cmdline) > 0 else '') + '"' + val + '"'

      out_value = cmdline

    return out_value

  # expands `${...}` string expressions, lists and dictionaries recursively for all variables in the storage
  def expand_dict(self, dict_value, search_in_expand_dict_at_second = None, search_by_pred_at_third = None, ignore_types = None, list_as_cmdline = False):
    if not isinstance(dict_value, dict):
      raise Exception('dict_value is not a dictionary type' + str(type(dict_value)))

    out_value = {}

    for key, val in dict_value.items():
      if not ignore_types is None:
        ignore_key = False
        for ignore_type in ignore_types:
          if isinstance(val, ignore_type):
            ignore_key = True
            break

        if ignore_key:
          continue

      if len(self.expanded_stack) != 0:
        # record variables changes
        last_stack_record = self.expanded_stack[-1]
        last_expanded_vars = last_stack_record[0]
        last_added_expanded_var_names = last_stack_record[1]
        if key not in last_expanded_vars.keys() and key not in last_added_expanded_var_names:
          last_added_expanded_var_names.append(key)

      if isinstance(val, str) or isinstance(val, int) or isinstance(val, float):
        out_value[key] = self.expand_string(val,
          search_in_expand_dict_at_second = search_in_expand_dict_at_second,
          search_by_pred_at_third = search_by_pred_at_third)
      elif isinstance(val, list):
        out_value[key] = self.expand_list(val,
          search_in_expand_dict_at_second = search_in_expand_dict_at_second,
          search_by_pred_at_third = search_by_pred_at_third,
          list_as_cmdline = list_as_cmdline)
      elif isinstance(val, dict):
        out_value[key] = self.expand_dict(val,
        search_in_expand_dict_at_second = search_in_expand_dict_at_second,
        search_by_pred_at_third = search_by_pred_at_third,
        list_as_cmdline = list_as_cmdline)
      else:
        # TODO
        raise Exception('unexpected yaml object type: ' + str(type(val)))

      if len(self.expanded_stack) != 0:
        last_stack_record[1] = last_added_expanded_var_names

    return out_value

  # expands `${...}` string expressions, lists and dictionaries recursively for all variables in the storage
  def expand(self, search_in_expand_dict_at_second = None, search_by_pred_at_third = None, ignore_types = None, list_as_cmdline = False):
    self.expanded_vars.update(
      self.expand_dict(
        self.unexpanded_vars,
        search_in_expand_dict_at_second = search_in_expand_dict_at_second,
        search_by_pred_at_third = search_by_pred_at_third,
        ignore_types = ignore_types,
        list_as_cmdline = list_as_cmdline
      )
    )
