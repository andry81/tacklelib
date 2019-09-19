# pure python module for commands w/o extension modules usage

import os, sys, inspect

if 'TackleImportModuleState' not in globals():
  class TackleImportModuleState:
    parent_modules = []

def tkl_membercopy(x, globals_):
  if inspect.isfunction(x):
    return type(x)(x.__code__, globals_, x.__name__, x.__defaults__, x.__closure__)
  elif inspect.isclass(x):
    cls_copy = type(x.__name__, x.__bases__, dict(x.__dict__))
    for key, value in dict(inspect.getmembers(cls_copy)).items():
      if not key.startswith('__') and inspect.isfunction(value):
        setattr(cls_copy, key, type(value)(value.__code__, globals_, value.__name__, value.__defaults__, value.__closure__))
    return cls_copy

  return x # return by reference

def tkl_merge_module(from_, to):
  to_dict = vars(to)
  for from_key, from_value in vars(from_).items():
    if not from_key.startswith('__'):
      if from_key in to_dict:
        to_value = to_dict[from_key]
        if id(from_value) != id(to_value):
          if not inspect.ismodule(from_value) and not inspect.ismodule(to_value):
            setattr(to, from_key, tkl_membercopy(from_value, vars(to)))
          else:
            tkl_merge_module(from_value, to_value)
      else:
        setattr(to, from_key, tkl_membercopy(from_value, vars(to)))

def tkl_get_parent_imported_module_state(ignore_not_scoped_modules):
  current_globals = globals()
  parent_module = None
  parent_scope_info = {}

  if len(current_globals['TackleImportModuleState'].parent_modules) > 0:
    parent_module = None
    # get module members, based on: https://stackoverflow.com/questions/1796180/how-can-i-get-a-list-of-all-classes-within-current-module-in-python
    for parent_module_tuple in reversed(current_globals['TackleImportModuleState'].parent_modules):
      if not ignore_not_scoped_modules or parent_module_tuple[0] != '.':
        parent_module = parent_module_tuple[1]
        parent_scope_info = parent_module_tuple[2]
        # `dict(...)` to convert from iteratable, based on: https://stackoverflow.com/questions/6586310/how-to-convert-list-of-key-value-tuples-into-dictionary/6586521#6586521
        parent_members = vars(parent_module)
        break

  if parent_module is None:
    parent_members = current_globals

  return (parent_module, parent_members, parent_scope_info)

# ref_module_name:
#   `module`  - either import the module file as `module` if the module was not imported before or import locally and membercopy the module content into existed one.
#   `.`       - import the module file locally and do membercopy the content of the module either into the parent module if it exists or into globals.
#   `.module` - the same as `module` but the module must not be imported before.
#   `module/` - the same as `module` but the module must be imported before.
#   `module.` - the same as `module` and the module can not be merged in the next `module` import (some kind of the `.module` behaviour but for the next import).
#
def tkl_import_module(dir_path, module_file_name, ref_module_name = None, inject_attrs = {}, prefix_exec_module_pred = None):
  if not ref_module_name is None and ref_module_name == '':
    raise Exception('ref_module_name should either be None or not empty string')

  import os, sys
  current_globals = globals()

  module_file_path = os.path.join(dir_path, module_file_name).replace('\\', '/')
  module_name_wo_ext = os.path.splitext(module_file_name)[0]

  #print('import :', module_file_path, 'as', module_name_wo_ext if ref_module_name is None else ref_module_name, '->', list(((parent_imported_module_name + '//' + parent_imported_module.__name__) if parent_imported_module_name != parent_imported_module.__name__ else parent_imported_module.__name__) for parent_imported_module_name, parent_imported_module, parent_imported_module_info in TackleImportModuleState.parent_modules))

  # get parent module state
  parent_module, parent_members, parent_scope_info = tkl_get_parent_imported_module_state(False)

  module_must_not_exist   = False
  module_must_exist       = False
  nomerge_module          = False

  if not ref_module_name is None and ref_module_name != '.':
    if ref_module_name.startswith('.'): # module must not been imported before by the name
      ref_module_name = ref_module_name[1:]
      module_must_not_exist = True 
    if ref_module_name.endswith('/'):   # module must be already imported by the name
      ref_module_name = ref_module_name[:-1]
      module_must_exist = True
    if ref_module_name.endswith('.'):   # module must not be merged from others (standalone)
      ref_module_name = ref_module_name[:-1]
      nomerge_module = True

    import_module_name = ref_module_name

    if (module_must_not_exist and module_must_exist):
      raise Exception('The module can be imported either as `.module` or as `module/`, but not as both at a time: ' + ref_module_name)
  else:
    import_module_name = module_name_wo_ext

  if ref_module_name != '.': # import to a local namespace?
    if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 4:
      import importlib.util, importlib.machinery
      import_spec = importlib.util.spec_from_loader(import_module_name, importlib.machinery.SourceFileLoader(import_module_name, module_file_path))
      imported_module = importlib.util.module_from_spec(import_spec)

      # inject attributes in being imported module
      imported_module.SOURCE_FILE = module_file_path
      imported_module.SOURCE_DIR = os.path.dirname(module_file_path)
      imported_module.TackleImportModuleState = parent_members['TackleImportModuleState']
      imported_module.tkl_import_module = parent_members['tkl_import_module']
      if 'TackleSourceModuleState' in parent_members:
        imported_module.TackleSourceModuleState = parent_members['TackleSourceModuleState']
      if 'tkl_get_parent_imported_module_state' in parent_members:
        imported_module.tkl_get_parent_imported_module_state = parent_members['tkl_get_parent_imported_module_state']
      if 'tkl_source_module' in parent_members:
        imported_module.tkl_source_module = parent_members['tkl_source_module']
      for attr, val in inject_attrs.items():
        setattr(imported_module, attr, val)

      is_module_ref_already_exist = False

      # update parent state
      if parent_module:
        # reference a being imported module from a parent module
        if hasattr(parent_module, import_module_name) and inspect.ismodule(getattr(parent_module, import_module_name)):
          is_module_ref_already_exist = True
      else:
        # reference a being imported module from globals
        if import_module_name in parent_members and inspect.ismodule(parent_members[import_module_name]):
          is_module_ref_already_exist = True

      if module_must_not_exist:
        if is_module_ref_already_exist:
          raise Exception('The module reference must not exist as a module before the import: ' + import_module_name)
      elif module_must_exist:
        if not is_module_ref_already_exist:
          raise Exception('The module reference must already exist as a module before the import: ' + import_module_name)

      if parent_module:
        if not is_module_ref_already_exist:
          setattr(parent_module, import_module_name, imported_module)
      else:
        if not is_module_ref_already_exist:
          parent_members[import_module_name] = imported_module

      # remember last parent before the module execution because of recursion
      parent_members['TackleImportModuleState'].parent_modules.append((
        import_module_name, imported_module,
        {'nomergemodule' : nomerge_module}
      ))

      try:
        if prefix_exec_module_pred:
          prefix_exec_module_pred(import_module_name, module_file_path, imported_module)

        import_spec.loader.exec_module(imported_module)

      finally:
        parent_members['TackleImportModuleState'].parent_modules.pop()

      # copy the module content into already existed module (behaviour by default, do import as `.module` or `module.` or `.module.` to prevent a merge)
      if is_module_ref_already_exist:
        if parent_module:
          tkl_merge_module(imported_module, getattr(parent_module, import_module_name))
        else:
          tkl_merge_module(imported_module, parent_members[import_module_name])

    else:
      # back compatability
      import imp
      imported_module = imp.load_source(import_module_name, module_file_path)
      parent_members[import_module_name] = imported_module

  else: # import to the global namespace
    if parent_module and 'nomergemodule' in parent_scope_info and parent_scope_info['nomergemodule']:
      raise Exception('attempt to merge the module content to the existed module has been declared as not mergable: ' + parent_module.__name__)

    if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 4:
      import importlib.util, importlib.machinery
      import_spec = importlib.util.spec_from_loader(module_name_wo_ext, importlib.machinery.SourceFileLoader(module_name_wo_ext, module_file_path))
      imported_module = importlib.util.module_from_spec(import_spec)

      # inject attributes in being imported module
      imported_module.SOURCE_FILE = module_file_path
      imported_module.SOURCE_DIR = os.path.dirname(module_file_path)
      imported_module.TackleImportModuleState = parent_members['TackleImportModuleState']
      imported_module.tkl_import_module = parent_members['tkl_import_module']
      if 'TackleSourceModuleState' in parent_members:
        imported_module.TackleSourceModuleState = parent_members['TackleSourceModuleState']
      if 'tkl_get_parent_imported_module_state' in parent_members:
        imported_module.tkl_get_parent_imported_module_state = parent_members['tkl_get_parent_imported_module_state']
      if 'tkl_source_module' in parent_members:
        imported_module.tkl_source_module = parent_members['tkl_source_module']
      for attr, val in inject_attrs.items():
        setattr(imported_module, attr, val)

      # remember last parent before the module execution because of recursion
      parent_members['TackleImportModuleState'].parent_modules.append((import_module_name, imported_module, {}))

      try:
        if prefix_exec_module_pred:
          prefix_exec_module_pred(import_module_name, module_file_path, imported_module)

        import_spec.loader.exec_module(imported_module)

      finally:
        last_import_module_state = parent_members['TackleImportModuleState'].parent_modules.pop()

      # copy globals to the parent module
      parent_module, parent_members, parent_scope_info = tkl_get_parent_imported_module_state(False)

      if not parent_module is None:
        tkl_merge_module(imported_module, parent_module)
      else:
        for key, value in vars(imported_module).items():
          if not key.startswith('__'):
            if not inspect.ismodule(value) or key not in parent_members or not inspect.ismodule(parent_members[key]):
              parent_members[key] = tkl_membercopy(value, current_globals)
            else:
              tkl_merge_module(value, parent_members[key])

    else:
      # back compatability
      import imp
      imported_module = imp.load_source(module_name_wo_ext, module_file_path).__dict__

      for key, value in imported_module.items():
        if not key.startswith('__'):
          parent_members[key] = tkl_membercopy(value, current_globals)

  return imported_module

if 'TackleSourceModuleState' not in globals():
  class TackleSourceModuleState:
    exec_guards = []

def tkl_source_module(dir_path, module_file_name, use_include_guard = True):
  source_module_path = os.path.abspath(os.path.join(dir_path, module_file_name)).replace('\\', '/')

  #print('source : ' + source_module_path)

  current_globals = globals()
  exec_guards = current_globals['TackleSourceModuleState'].exec_guards

  if use_include_guard:
    for module_file_path, imported_module in exec_guards:
      if source_module_path == module_file_path.replace('\\', '/'):
        # copy globals to the parent module
        parent_module, parent_members, parent_scope_info = tkl_get_parent_imported_module_state(False)

        if parent_module and 'nomergemodule' in parent_scope_info and parent_scope_info['nomergemodule']:
          raise Exception('attempt to merge the module content to the existed module has been declared as not mergable: ' + parent_module.__name__)

        if not parent_module is None:
          tkl_merge_module(imported_module, parent_module)
        else:
          for key, value in vars(imported_module).items():
            if not key.startswith('__'):
              if not inspect.ismodule(value) or key not in parent_members or not inspect.ismodule(parent_members[key]):
                parent_members[key] = tkl_membercopy(value, current_globals)
              else:
                tkl_merge_module(value, parent_members[key])

        return imported_module

  if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 4:
    imported_module = tkl_import_module(dir_path, module_file_name, '.',
      # must be before the importlib module exec
      prefix_exec_module_pred = lambda pred_import_module_name, pred_import_module_path, pred_import_module: \
        ( \
          [None for pred_import_module.TackleSourceModuleState in [current_globals['TackleSourceModuleState']]], \
          pred_import_module.TackleSourceModuleState.exec_guards.append((pred_import_module_path, pred_import_module)) \
        )
    )
  else:
    imported_module = tkl_import_module(dir_path, module_file_name, '.')
    # back compatibility: can not be before the imp module exec
    exec_guards.append((source_module_path, imported_module))

  return imported_module

# error print
def print_err(*args, **kwargs):
  print(*args, file=sys.stderr, **kwargs)
