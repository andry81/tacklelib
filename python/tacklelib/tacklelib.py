# pure python module for commands w/o extension modules usage

class TackleGlobalImportModuleState:
  parent_modules = []
  imported_modules = set()
  exec_guards = []

class TackleLocalImportModuleState:
  # key:    variable token
  # value:  (<value>, <value globals>)
  export_globals = {}

# based on:
# https://stackoverflow.com/questions/3589311/get-defining-class-of-unbound-method-object-in-python-3/25959545#25959545
# https://stackoverflow.com/questions/3589311/get-defining-class-of-unbound-method-object-in-python-3/54597033#54597033
#
def tkl_get_method_class(x, from_module = None):
  import inspect

  if inspect.ismethod(x):
    for cls in inspect.getmro(x.__self__.__class__):
      if cls.__dict__.get(x.__name__) is x:
        return cls
    x = x.__func__ # fallback to __qualname__ parsing
  if inspect.isfunction(x):
    cls_name = x.__qualname__.split('.<locals>', 1)[0].rsplit('.', 1)[0]
    #print('tkl_get_method_class:', x, '->', cls_name, '->', inspect.getmodule(x))
    try:
      cls = getattr(inspect.getmodule(x), cls_name)
    except AttributeError:
      cls = x.__globals__.get(cls_name)
    if isinstance(cls, type):
      return cls

  return getattr(x, '__objclass__', None)  # handle special descriptor objects

# DESCRIPTION:
#
#   The function must be expressed separately to correctly resolve base classes
#   copy function to be able to fix `globals()` only in those methods which are
#   a part of a class been defined from a source module including a base class.
#   And if a base class is a part of a different module than the module which
#   objects being copied from, then what the base class methods would be
#   skipped to fixup the `globals()`.
#   In other words a derived and a base class could have be defined in
#   different modules and their methods has to be fixed for a correct globals
#   reference if and only if a being copied class has been defined in the
#   module which members are being copied from. If a class has been defined not
#   in the being copied module, then it's member functions must be left as is.
#
def tkl_classcopy(x, from_globals, to_globals):
  import inspect

  if not inspect.isclass(x):
    raise Exception('x must a class: ' + type(x))

  cls_copy = type(x.__name__, x.__bases__, dict(x.__dict__))

  if id(from_globals) != id(to_globals):
    # CAUTION:
    #   Have to use `inspect.getmembers(x)` instead of `inspect.getmembers(cls_copy)` to avoid the errors:
    #   * File "...\lib\inspect.py", line 341, in getmembers
    #     value = getattr(object, key)
    #     TypeError: descriptor 'combine' for type 'datetime.datetime' doesn't apply to type 'datetime'
    #
    # NOTE:
    #   `dict(...)` to convert from iterable, based on: https://stackoverflow.com/questions/6586310/how-to-convert-list-of-key-value-tuples-into-dictionary/6586521#6586521
    #
    for key, value in dict(inspect.getmembers(x)).items():
      if not key.startswith('__'):
        if inspect.isfunction(value):
          member_cls = tkl_get_method_class(value)
          if member_cls in from_globals:
            #print('  tkl_classcopy:', key)
            # globals retarget to the destination globals
            setattr(cls_copy, key, type(value)(value.__code__, to_globals, value.__name__, value.__defaults__, value.__closure__))

  return cls_copy

# to readdress `globals()` in all functions
def tkl_membercopy(x, from_globals, to_globals):
  if id(from_globals) != id(to_globals):
    import inspect

    if inspect.isfunction(x):
      return type(x)(x.__code__, to_globals, x.__name__, x.__defaults__, x.__closure__)
    elif inspect.isclass(x):
      return tkl_classcopy(x, from_globals, to_globals)

  return x # return by reference

def tkl_merge_module(from_, to):
  import inspect

  from_globals = vars(from_)
  if inspect.ismodule(to):
    to_dict = vars(to)
    to_globals = False
  else:
    to_dict = to
    to_globals = True
  for from_key, from_value in vars(from_).items():
    if not from_key.startswith('__') and from_key not in ['SOURCE_FILE', 'SOURCE_DIR']:
      if from_key in to_dict:
        to_value = to_dict[from_key]
        if id(from_value) != id(to_value):
          # The `to_value` sometimes can be not a module when the `from_value` is a module, for example, if
          # from_ = <module 'datetime'>, but
          # to = <class 'datetime.datetime'>, where
          #   `type(to) == type` and `type` is not iterable
          # In that case we must replace the destination by a module instance.
          if not inspect.ismodule(from_value):
            if not to_globals:
              #print(" tkl_merge_module: ", to.__name__, '<-' , from_key)
              var_copy = tkl_membercopy(from_value, from_globals, to_dict)
              setattr(to, from_key, var_copy)
            else:
              #print(" tkl_merge_module: globals() <- ", from_key)
              to[from_key] = tkl_membercopy(from_value, from_globals, to_dict)
          else:
            if inspect.ismodule(to_value):
              tkl_merge_module(from_value, to_value)
            else:
              # replace by a module instance, based on: https://stackoverflow.com/questions/11170949/how-to-make-a-copy-of-a-python-module-at-runtime/11173076#11173076
              to_value = type(from_value)(from_value.__name__, from_value.__doc__)
              to_value.__dict__.update(from_value.__dict__)
              to_dict[from_key] = to_value
              tkl_merge_module(from_value, to_value)
      else:
        if not to_globals:
          #print(" tkl_merge_module: ", to.__name__,'<-' ,from_key)
          var_copy = tkl_membercopy(from_value, from_globals, to_dict)
          setattr(to, from_key, var_copy)
        else:
          #print(" tkl_merge_module: globals() <-", from_key)
          to[from_key] = tkl_membercopy(from_value, from_globals, to_dict)

  return to

def tkl_get_parent_imported_module_state(ignore_not_scoped_modules):
  current_globals = globals()
  parent_module = None
  parent_scope_info = {}

  parent_modules = current_globals['TackleGlobalImportModuleState'].parent_modules

  if len(parent_modules) > 0:
    parent_module = None
    for parent_module_tuple in reversed(parent_modules):
      if not ignore_not_scoped_modules or parent_module_tuple[0] != '.':
        parent_module = parent_module_tuple[1]
        parent_scope_info = parent_module_tuple[2]
        parent_members = vars(parent_module)
        break

  if parent_module is None:
    parent_members = current_globals

  return (parent_module, parent_members, parent_scope_info)

# to auto export globals from a parent module to a child module on it's import
def tkl_declare_global(var, value, value_from_globals = None, auto_export = True, copy_as_reference_in_parent = False):
  import inspect, copy

  current_globals = globals()
  if value_from_globals is None:
    value_from_globals = current_globals

  # get parent module state
  parent_module, parent_members, parent_scope_info = tkl_get_parent_imported_module_state(False)

  # make a global either in a current module or in the globals
  if not parent_module is None:
    setattr(parent_module, var, value)
  else:
    parent_members[var] = value

  export_globals = current_globals['TackleLocalImportModuleState'].export_globals
  export_globals[var] = (value, value_from_globals, copy_as_reference_in_parent)

  if auto_export:
    imported_modules = current_globals['TackleGlobalImportModuleState'].imported_modules
    for key, global_value in current_globals.items():
      if not key.startswith('__') and key not in ['SOURCE_FILE', 'SOURCE_DIR'] and \
        inspect.ismodule(global_value) and global_value in imported_modules: # ignore modules which are not imported by `tkl_import_module`
        # make a deepcopy with globals retarget to a child module
        var_copy = copy.deepcopy(tkl_membercopy(value, value_from_globals, vars(global_value)))
        setattr(global_value, var, var_copy)

  return value

# ref_module_name:
#   `module`    - either import the module file as `module` if the module was not imported before or import locally and membercopy the module content into existed one.
#   `.`         - import the module file locally and do membercopy the content of the module either into the parent module if it exists or into globals.
#   `.module`   - the same as `module` but the module must not be imported before.
#   `module/`   - the same as `module` but the module must be imported before.
#   `module.`   - the same as `module` and the module can not be merged in the next `module` import (some kind of the `.module` behaviour but for the next import).
#   `.module.`  - has meaning of the both above.
#
def tkl_import_module(dir_path, module_file_name, ref_module_name = None, inject_attrs = {}, prefix_exec_module_pred = None, use_exec_guard = True):
  import os, sys, inspect, copy

  if not ref_module_name is None and ref_module_name == '':
    raise Exception('ref_module_name should either be None or not empty string')

  module_file_path = os.path.normcase(os.path.abspath(os.path.join(dir_path, module_file_name))).replace('\\', '/')
  module_name_wo_ext = os.path.splitext(module_file_name)[0]

  print('import :', module_file_path, 'as', module_name_wo_ext if ref_module_name is None else ref_module_name, '->', list(((parent_imported_module_name + '//' + parent_imported_module.__name__) if parent_imported_module_name != parent_imported_module.__name__ else parent_imported_module.__name__) for parent_imported_module_name, parent_imported_module, parent_imported_module_info in TackleGlobalImportModuleState.parent_modules))

  current_globals = globals()
  exec_guards = current_globals['TackleGlobalImportModuleState'].exec_guards

  if use_exec_guard:
    for guard_module_file_path, imported_module in exec_guards:
      if guard_module_file_path == module_file_path.replace('\\', '/'):
        # copy globals to the parent module
        parent_module, parent_members, parent_scope_info = tkl_get_parent_imported_module_state(False)

        if not parent_module is None and 'nomergemodule' in parent_scope_info and parent_scope_info['nomergemodule']:
          raise Exception('attempt to merge the module content to the existed module has been declared as not mergable: ' + parent_module.__name__)

        if not parent_module is None:
          tkl_merge_module(imported_module, parent_module)
        else:
          imported_module_globals = vars(imported_module)
          for key, value in imported_module_globals.items():
            if not key.startswith('__') and key not in ['SOURCE_FILE', 'SOURCE_DIR']:
              if not inspect.ismodule(value) or key not in parent_members or not inspect.ismodule(parent_members[key]):
                #print(' copy: globals()::', key, ' <- ', value)
                parent_members[key] = tkl_membercopy(value, imported_module_globals, current_globals)
              else:
                tkl_merge_module(value, parent_members[key])

        return imported_module

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
      imported_module_globals = vars(imported_module)

      parent_modules = parent_members['TackleGlobalImportModuleState'].parent_modules
      imported_modules = parent_members['TackleGlobalImportModuleState'].imported_modules
      export_globals = current_globals['TackleLocalImportModuleState'].export_globals

      # auto export globals at first
      for key, value_tuple in export_globals.items(): 
        copy_as_reference_in_parent = value_tuple[2]
        if not copy_as_reference_in_parent:
          # make a deep copy
          exported_global_copy = copy.deepcopy(tkl_membercopy(value_tuple[0], value_tuple[1], imported_module_globals))
          setattr(imported_module, key, exported_global_copy)
        else:
          # make a member/reference copy
          exported_global_copy = tkl_membercopy(value_tuple[0], value_tuple[1], imported_module_globals)
          # create reference in the parent
          if not parent_module is None:
            setattr(parent_module, key, exported_global_copy)
          else:
            parent_members[key] = exported_global_copy

      # inject attributes in being imported module
      imported_module.SOURCE_FILE = module_file_path
      imported_module.SOURCE_DIR = os.path.dirname(module_file_path)

      imported_module.TackleGlobalImportModuleState = parent_members['TackleGlobalImportModuleState']
      imported_module.TackleLocalImportModuleState = copy.deepcopy(current_globals['TackleLocalImportModuleState'])
      imported_module.tkl_get_method_class = parent_members['tkl_get_method_class']
      imported_module.tkl_classcopy = parent_members['tkl_classcopy']
      imported_module.tkl_membercopy = parent_members['tkl_membercopy']
      imported_module.tkl_merge_module = parent_members['tkl_merge_module']
      imported_module.tkl_get_parent_imported_module_state = parent_members['tkl_get_parent_imported_module_state']
      if 'tkl_declare_global' in parent_members:
        imported_module.tkl_declare_global = parent_members['tkl_declare_global']
      imported_module.tkl_import_module = parent_members['tkl_import_module']

      if 'tkl_source_module' in parent_members:
        imported_module.tkl_source_module = parent_members['tkl_source_module']
      for attr, val in inject_attrs.items():
        setattr(imported_module, attr, val)

      is_module_ref_already_exist = False

      # update parent state
      if not parent_module is None:
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

      if not parent_module is None:
        if not is_module_ref_already_exist:
          setattr(parent_module, import_module_name, imported_module)
      else:
        if not is_module_ref_already_exist:
          parent_members[import_module_name] = imported_module

      # remember last parent before the module execution because of recursion
      parent_modules.append((
        import_module_name, imported_module,
        {'nomergemodule' : nomerge_module}
      ))
      imported_modules.add(imported_module)

      try:
        if prefix_exec_module_pred:
          prefix_exec_module_pred(import_module_name, module_file_path, imported_module)

        # before the `exec_module`
        exec_guards.append((module_file_path, imported_module))

        import_spec.loader.exec_module(imported_module)

      finally:
        parent_modules.pop()

      # copy the module content into already existed module (behaviour by default, do import as `.module` or `module.` or `.module.` to prevent a merge)
      if is_module_ref_already_exist:
        if not parent_module is None:
          tkl_merge_module(imported_module, getattr(parent_module, import_module_name))
        else:
          tkl_merge_module(imported_module, parent_members[import_module_name])

    else:
      # back compatability
      import imp
      imported_module = imp.load_source(import_module_name, module_file_path)
      parent_members[import_module_name] = imported_module

      # back compatibility: can not be before the imp module exec
      exec_guards.append((module_file_path, imported_module))

  else: # import to the global namespace
    if not parent_module is None and 'nomergemodule' in parent_scope_info and parent_scope_info['nomergemodule']:
      raise Exception('attempt to merge the module content to the existed module has been declared as not mergable: ' + parent_module.__name__)

    if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 4:
      import importlib.util, importlib.machinery
      import_spec = importlib.util.spec_from_loader(module_name_wo_ext, importlib.machinery.SourceFileLoader(module_name_wo_ext, module_file_path))
      imported_module = importlib.util.module_from_spec(import_spec)
      imported_module_globals = vars(imported_module)

      parent_modules = parent_members['TackleGlobalImportModuleState'].parent_modules
      imported_modules = parent_members['TackleGlobalImportModuleState'].imported_modules
      export_globals = current_globals['TackleLocalImportModuleState'].export_globals
      parent_export_globals = parent_members['TackleLocalImportModuleState'].export_globals

      # auto export globals at first
      for key, value_tuple in export_globals.items():
        copy_as_reference_in_parent = value_tuple[2]
        if not copy_as_reference_in_parent:
          # make a deep copy
          exported_global_copy = copy.deepcopy(tkl_membercopy(value_tuple[0], value_tuple[1], imported_module_globals))
          setattr(imported_module, key, exported_global_copy)
        else:
          # make a member/reference copy
          exported_global_copy = tkl_membercopy(value_tuple[0], value_tuple[1], imported_module_globals)
          setattr(imported_module, key, exported_global_copy)
          # create reference in the parent
          if not parent_module is None:
            setattr(parent_module, key, exported_global_copy)
          else:
            parent_members[key] = exported_global_copy

      # inject attributes in being imported module
      imported_module.SOURCE_FILE = module_file_path
      imported_module.SOURCE_DIR = os.path.dirname(module_file_path)

      imported_module.TackleGlobalImportModuleState = parent_members['TackleGlobalImportModuleState']
      imported_module.TackleLocalImportModuleState = copy.deepcopy(current_globals['TackleLocalImportModuleState'])
      imported_module.tkl_get_method_class = parent_members['tkl_get_method_class']
      imported_module.tkl_classcopy = parent_members['tkl_classcopy']
      imported_module.tkl_membercopy = parent_members['tkl_membercopy']
      imported_module.tkl_merge_module = parent_members['tkl_merge_module']
      imported_module.tkl_get_parent_imported_module_state = parent_members['tkl_get_parent_imported_module_state']
      if 'tkl_declare_global' in parent_members:
        imported_module.tkl_declare_global = parent_members['tkl_declare_global']
      imported_module.tkl_import_module = parent_members['tkl_import_module']

      if 'tkl_source_module' in parent_members:
        imported_module.tkl_source_module = parent_members['tkl_source_module']
      for attr, val in inject_attrs.items():
        setattr(imported_module, attr, val)

      # remember last parent before the module execution because of recursion
      parent_modules.append((import_module_name, imported_module, {}))
      imported_modules.add(imported_module)

      try:
        if prefix_exec_module_pred:
          prefix_exec_module_pred(import_module_name, module_file_path, imported_module)

        # before the `exec_module`
        exec_guards.append((module_file_path, imported_module))

        import_spec.loader.exec_module(imported_module)

      finally:
        last_import_module_state = parent_modules.pop()

      # copy globals to the parent module
      parent_module, parent_members, parent_scope_info = tkl_get_parent_imported_module_state(False)

      if not parent_module is None:
        tkl_merge_module(imported_module, parent_module)
      else:
        imported_module_globals = vars(imported_module) # reget after execution
        for key, value in vars(imported_module).items():
          if not key.startswith('__') and key not in ['SOURCE_FILE', 'SOURCE_DIR']:
            if not inspect.ismodule(value) or key not in parent_members or not inspect.ismodule(parent_members[key]):
              #print(' copy: globals()::', key, ' <- ', value)
              parent_members[key] = tkl_membercopy(value, imported_module_globals, current_globals)
            else:
              tkl_merge_module(value, parent_members[key])

    else:
      # back compatability
      import imp
      imported_module = imp.load_source(module_name_wo_ext, module_file_path).__dict__

      for key, value in imported_module.items():
        if not key.startswith('__') and key not in ['SOURCE_FILE', 'SOURCE_DIR']:
          parent_members[key] = tkl_membercopy(value, current_globals)

      # back compatibility: can not be before the imp module exec
      exec_guards.append((module_file_path, imported_module))

  # must be to avoid a mix
  sys.stdout.flush()
  sys.stderr.flush()

  return imported_module

# shortcut function
def tkl_source_module(dir_path, module_file_name):
  return tkl_import_module(dir_path, module_file_name, '.')
