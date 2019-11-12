# pure python module for commands w/o extension modules usage

import os, sys, inspect, copy
if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 4:
  import importlib.util, importlib.machinery
else:
  import imp

class TackleGlobalState:
  import_nest_index = [0] # in list to store as reference
  this_module = None
  # key:    <module>
  # value:  (<module_import_name>, <module_file_path>, {<module_attribute_name> : <module_attribute_value>})
  imported_modules = {}
  # key:    <variable_token>
  # value:  <value>
  global_vars = {}

  @classmethod
  def reset(cls):
    cls.this_module = None
    cls.imported_modules = None
    cls.global_vars = {}

def tkl_init(tkl_module, import_file_exts = ['.xsh'], reset_global_state = True, init_stack_module = 'caller'):
  #print('tkl_init')

  # enable the `inspect.getmodulename` to return module name with non standard file extensions
  if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 4:
    for import_file_ext in import_file_exts:
      if import_file_ext not in importlib.machinery.SOURCE_SUFFIXES:
        importlib.machinery.SOURCE_SUFFIXES.append(import_file_ext)

  if init_stack_module == 'caller':
    current_module = tkl_get_stack_frame_module(1)
  elif init_stack_module == 'current':
    current_module = tkl_get_current_module()
  else:
    raise Exception('unknown module to init: `' + init_stack_module + '`')

  prev_global_state = global_state = getattr(current_module, 'TackleGlobalState', None)
  if reset_global_state or global_state is None:
    global_state = TackleGlobalState
    if reset_global_state and not prev_global_state is None:
      global_state.reset()

  global_state.this_module = tkl_module

  # all functions in the module have has a 'tkl_' prefix, all classes begins by `Tackle`, so we don't need a scope here
  tkl_merge_module(tkl_module, current_module)

  # declare the current module as an already imported module to be able to propagate a global variable to it
  #print(current_module.__name__, current_module.__file__.replace('\\', '/'))
  global_state.imported_modules[current_module] = (current_module.__name__, current_module.__file__.replace('\\', '/'), {})

# basiclly required in a teardown code in tests
def tkl_uninit():
  for global_var, value in TackleGlobalState.global_vars.items():
    del global_var
  TackleGlobalState.global_vars = {}
  for imported_module, imported_module_value in TackleGlobalState.imported_modules.items():
    del imported_module
  TackleGlobalState.imported_modules = {}
  del TackleGlobalState.this_module
  TackleGlobalState.this_module = None

def tkl_get_stack_frame_module(skip_frames = 0):
  skip_frame_index = skip_frames + 1;

  # search for the first module in the stack
  stack_frame = inspect.currentframe()
  while stack_frame and skip_frame_index > 0:
    #print('***', stack_frame.f_code.co_name, stack_frame.f_code.co_filename, stack_frame.f_lineno)
    stack_frame = stack_frame.f_back
    skip_frame_index -= 1

  if stack_frame is None:
    raise Exception('target module is not found on the stack')

  #print('>>>', stack_frame.f_code.co_name, stack_frame.f_code.co_filename, stack_frame.f_lineno)

  target_module = inspect.getmodule(stack_frame)
  if target_module is None:
    raise Exception('target module is not found on the stack')

  return target_module

def tkl_get_current_module():
  current_module = None

  # search for the first module in the stack
  stack_frame = inspect.currentframe()
  while stack_frame:
    #print('***', stack_frame.f_code.co_name, stack_frame.f_code.co_filename, stack_frame.f_lineno)
    if stack_frame.f_code.co_name == '<module>':
      current_module = inspect.getmodule(stack_frame)
      #print('MODULEFILE:', stack_frame.f_code.co_filename)
      #print('MODULE:', inspect.getmodulename(stack_frame.f_code.co_filename), current_module)
      if current_module is None:
        raise Exception('invalid stack top module')
      break
    stack_frame = stack_frame.f_back

  if stack_frame is None:
    raise Exception('top module is not found on the stack')

  return current_module

def tkl_get_caller_module():
  caller_module = None

  # search for the first module in the stack
  stack_frame = inspect.currentframe()
  while stack_frame:
    #print('***', stack_frame.f_code.co_name, stack_frame.f_code.co_filename, stack_frame.f_lineno)
    if stack_frame.f_code.co_name == '<module>':
      caller_module = inspect.getmodule(stack_frame)
      #print('MODULEFILE:', stack_frame.f_code.co_filename)
      #print('MODULE:', inspect.getmodulename(stack_frame.f_code.co_filename), caller_module)
      if caller_module is None:
        raise Exception('invalid stack top module')
      break
    stack_frame = stack_frame.f_back

  if stack_frame is None:
    raise Exception('top module is not found on the stack')

  return caller_module

# based on:
# https://stackoverflow.com/questions/3589311/get-defining-class-of-unbound-method-object-in-python-3/25959545#25959545
# https://stackoverflow.com/questions/3589311/get-defining-class-of-unbound-method-object-in-python-3/54597033#54597033
#
def tkl_get_method_class(x, from_module = None):
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
#   A derived and a base class can be defined in different modules and their
#   methods has to be fixed for a correct globals reference if and only if a
#   source and a destination global context is not the same. If a base or a
#   derived class is not belong to the context of the source module, then the
#   class member functions must be left as is. Otherwise they must be fixed to
#   reference a destination globals.
#
def tkl_classcopy(x, from_globals, to_globals):
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
    if inspect.isfunction(x):
      return type(x)(x.__code__, to_globals, x.__name__, x.__defaults__, x.__closure__)
    elif inspect.isclass(x):
      return tkl_classcopy(x, from_globals, to_globals)

  return x # return by reference

def tkl_merge_module(from_, to):
  from_globals = vars(from_)
  if inspect.ismodule(to):
    to_dict = vars(to)
    is_to_module = True
  else:
    to_dict = to
    is_to_module = False

  if id(to) != id(from_):
    for from_key, from_value in vars(from_).items():
      if not from_key.startswith('__') and from_key not in ['SOURCE_FILE', 'SOURCE_DIR', 'SOURCE_FILE_NAME', 'SOURCE_FILE_NAME_WO_EXT']:
        if is_to_module:
          to_value = getattr(to, from_key, None)
        else:
          to_value = to_dict.get(from_key)
        if not from_value is None:
          if to_value is None or id(from_value) != id(to_value):
            if not inspect.ismodule(from_value):
              to_value = tkl_membercopy(from_value, from_globals, to_dict)
              if is_to_module:
                #print(" tkl_merge_module: ", to.__name__, '<-' , from_key)
                setattr(to, from_key, to_value)
              else:
                #print(" tkl_merge_module: globals() <- ", from_key)
                to[from_key] = to_value
            elif not inspect.ismodule(to_value):
              # replace by a module instance, based on: https://stackoverflow.com/questions/11170949/how-to-make-a-copy-of-a-python-module-at-runtime/11173076#11173076
              to_value = type(from_value)(from_value.__name__, from_value.__doc__)
              to_value.__dict__.update(from_value.__dict__)

              if is_to_module:
                setattr(to, from_key, to_value)
              else:
                to_dict[from_key] = to_value

              # CAUTION:
              #   Must do explicit merge, otherwise some classes would not be merged!
              #
              tkl_merge_module(from_value, to_value)

              # we must register being merged (new) module in the imported modules if the source module is registered too to expose it for the globals export function
              global_state = getattr(from_, 'TackleGlobalState', None)
              if not global_state is None:
                imported_modules = global_state.imported_modules
                from_module_value_in_imported_modules = imported_modules.get(from_)
                if not from_module_value_in_imported_modules is None:
                  imported_modules[to_value] = (from_module_value_in_imported_modules[0], from_module_value_in_imported_modules[1], {})
            else:
              tkl_merge_module(from_value, to_value)
          """
          elif not inspect.ismodule(from_value):
            to_value = tkl_membercopy(from_value, from_globals, to_dict)
            if is_to_module:
              #print(" tkl_merge_module: ", to.__name__, '<-' , from_key)
              setattr(to, from_key, to_value)
            else:
              #print(" tkl_merge_module: globals() <- ", from_key)
              to[from_key] = to_value
          else:
            # as reference
            if is_to_module:
              #print(" tkl_merge_module: ", to.__name__, '<-' , from_key)
              setattr(to, from_key, from_value)
            else:
              #print(" tkl_merge_module: globals() <- ", from_key)
              to[from_key] = from_value
          """

  return to

# to declare globals in a current module from the stack
def tkl_declare_global(var, value, from_globals = None):
  current_module = tkl_get_stack_frame_module(1)

  global_state = getattr(current_module, 'TackleGlobalState', None)
  if global_state is None:
    global_state = TackleGlobalState

  if global_state.this_module is None:
    raise Exception('tacklelib is not properly initialized, call to tkl_init_current_module in the top module')

  imported_modules = global_state.imported_modules
  global_vars = global_state.global_vars

  if from_globals is None:
    from_globals = globals()

  current_module_globals = vars(current_module)
  value_copy = tkl_membercopy(value, from_globals, current_module_globals)

  # at first, assign as a global
  #exec('global ' + var + '\n' + var + ' = value_copy')

  setattr(current_module, var, value_copy)

  global_vars[var] = value_copy
  #globals()[var] = value_copy

  # export a global to rest of imported modules
  for imported_module in imported_modules:
    if id(imported_module) != id(current_module):
      imported_module_globals = vars(imported_module)
      value_copy = tkl_membercopy(value, from_globals, imported_module_globals)
      setattr(imported_module, var, value_copy)
      #imported_module_globals[var] = value_copy

# ref_module_name:
#   `module`    - either import the module file as `module` if the module was not imported before or import locally and membercopy the module content into existed one.
#   `.`         - import the module file locally and do membercopy the content of the module either into the parent module if it exists or into globals.
#   `.module`   - the same as `module` but the module must not be imported before.
#   `module/`   - the same as `module` but the module must be imported before.
#   `module.`   - the same as `module` and the module can not be merged in the next `module` import (some kind of the `.module` behaviour but for the next import).
#   `.module.`  - has meaning of the both above.
#
def tkl_import_module(dir_path, module_file_name, ref_module_name = None, inject_attrs = {}, prefix_exec_module_pred = None, skip_stack_frames = 0):
  if not ref_module_name is None and ref_module_name == '':
    raise Exception('ref_module_name should either be None or not empty string')

  module_file_path = os.path.normcase(os.path.abspath(os.path.join(dir_path, module_file_name))).replace('\\', '/')
  module_name_wo_ext = os.path.splitext(module_file_name)[0]

  current_module = tkl_get_stack_frame_module(skip_stack_frames + 1)

  global_state = getattr(current_module, 'TackleGlobalState', None)
  if global_state is None:
    global_state = TackleGlobalState

  import_nest_index = global_state.import_nest_index[0]

  print(('| ' * import_nest_index) + 'import :', import_nest_index, module_file_path, 'as', module_name_wo_ext if ref_module_name is None else ref_module_name, end='')

  if global_state.this_module is None:
    print()
    raise Exception('tacklelib is not properly initialized, call to tkl_init_current_module in the top module')

  current_module_globals = vars(current_module)

  imported_modules = global_state.imported_modules
  global_vars = global_state.global_vars

  # execution guard, always enabled
  for imported_module, imported_module_value in imported_modules.items():
    imported_module_file_path = imported_module_value[1]
    if imported_module_file_path == module_file_path:
      print(' (cached)')
      imported_module_name = imported_module_value[0]
      imported_module_attrs = imported_module_value[2]

      imported_module_globals = vars(imported_module)

      # copy merge module into current module
      if ref_module_name != '.':
        to_value = getattr(current_module, ref_module_name, None)
        from_value = imported_module

        to_value_is_module = inspect.ismodule(to_value) if not to_value is None else False
        if to_value_is_module and to_value in imported_modules:
          current_module_in_imported = imported_modules[to_value]
          current_module_attrs = current_module_in_imported[2]
          if 'nomergemodule' in current_module_attrs and current_module_attrs['nomergemodule']:
            raise Exception('attempt to merge the module content to the existed module has been declared as not mergable: ' + to_value.__name__)

        if to_value is None or id(from_value) != id(to_value):
          if to_value is None or not to_value_is_module:
            # replace by a module instance, based on: https://stackoverflow.com/questions/11170949/how-to-make-a-copy-of-a-python-module-at-runtime/11173076#11173076
            to_value = type(from_value)(from_value.__name__, from_value.__doc__)
            to_value.__dict__.update(from_value.__dict__)

            setattr(current_module, ref_module_name, to_value)

            # CAUTION:
            #   Must do explicit merge, otherwise some classes would not be merged!
            #
            tkl_merge_module(from_value, to_value)

            # we must register being merged (new) module in the imported modules if the source module is registered too to expose it for the globals export function
            imported_modules[to_value] = (imported_module_name, imported_module_file_path, imported_module_attrs)
          else:
            tkl_merge_module(from_value, to_value)

      else:
        if id(current_module) == id(imported_module):
          raise Exception('attempt to merge the module content to itself: ' + current_module.__name__)

        if current_module in imported_modules:
          current_module_in_imported = imported_modules[current_module]
          current_module_attrs = current_module_in_imported[2]
          if 'nomergemodule' in current_module_attrs and current_module_attrs['nomergemodule']:
            raise Exception('attempt to merge the module content to the existed module has been declared as not mergable: ' + current_module.__name__)

        # export globals to a being imported module
        for var, value in global_vars.items(): 
          setattr(current_module, var, tkl_membercopy(value, imported_module_globals, current_module_globals))

        tkl_merge_module(imported_module, current_module)

      return imported_module

  print()

  import_nest_index = global_state.import_nest_index

  # get parent module state
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
      import_spec = importlib.util.spec_from_loader(import_module_name, importlib.machinery.SourceFileLoader(import_module_name, module_file_path))
      imported_module = importlib.util.module_from_spec(import_spec)
      imported_module_globals = vars(imported_module)

      # inject the members of the tacklelib module
      tkl_merge_module(global_state.this_module, imported_module)

      # export globals to a being imported module
      for var, value in global_vars.items(): 
        setattr(imported_module, var, tkl_membercopy(value, current_module_globals, imported_module_globals))

      # inject attributes in being imported module
      imported_module.SOURCE_FILE = module_file_path
      imported_module.SOURCE_DIR = os.path.dirname(module_file_path)
      module_file_wo_ext = imported_module.SOURCE_FILE_NAME = os.path.basename(module_file_path)
      imported_module.SOURCE_FILE_NAME_WO_EXT = os.path.splitext(module_file_wo_ext)[0]

      for attr, val in inject_attrs.items():
        setattr(imported_module, attr, val)

      is_module_ref_already_exist = False

      # reference a being imported module from a parent module
      to_value = getattr(current_module, import_module_name, None)
      if not to_value is None and inspect.ismodule(to_value):
        is_module_ref_already_exist = True

      if module_must_not_exist:
        if is_module_ref_already_exist:
          raise Exception('The module reference must not exist as a module before the import: ' + import_module_name)
      elif module_must_exist:
        if not is_module_ref_already_exist:
          raise Exception('The module reference must already exist as a module before the import: ' + import_module_name)

      # remember last parent before the module execution because of recursion
      prev_imported_module_value_imported_modules = imported_modules.get(imported_module)
      imported_modules[imported_module] = (import_module_name, module_file_path, {'nomergemodule' : nomerge_module})

      # we must register being merged module in the imported modules if the source module is registered too to expose it for the globals export function
      prev_current_module_value_in_imported_modules = imported_modules.get(current_module)
      if prev_current_module_value_in_imported_modules is None:
        imported_modules[current_module] = (import_module_name, module_file_path, {})

      prev_sys_module = sys.modules.get(import_module_name)

      try:
        if not prefix_exec_module_pred is None:
          prefix_exec_module_pred(import_module_name, module_file_path, imported_module)

        # based on: https://docs.python.org/3/library/importlib.html#importing-a-source-file-directly :
        # `To import a Python source file directly, use the following recipe (Python 3.5 and newer only)`
        #
        sys.modules[import_module_name] = imported_module

        import_nest_index[0] += 1

        import_spec.loader.exec_module(imported_module)

      except:
        # restore
        if prev_sys_module is None:
          del sys.modules[import_module_name]
        else: 
          sys.modules[import_module_name] = prev_sys_module

        if prev_current_module_value_in_imported_modules is None:
          del imported_modules[current_module]
        else:
          imported_modules[current_module] = prev_current_module_value_in_imported_modules

        if prev_imported_module_value_imported_modules is None:
          del imported_modules[imported_module]

        if to_value is None:
          to_value = getattr(current_module, import_module_name, None)
          if not to_value is None:
            del to_value

        raise

      finally:
        import_nest_index[0] -= 1

    else:
      # back compatability
      import_nest_index[0] += 1

      try:
        imported_module = imp.load_source(import_module_name, module_file_path)
        imported_module_globals = vars(imported_module)

        imported_modules[imported_module] = (import_module_name, module_file_path, {'nomergemodule' : nomerge_module})

        # we must register being merged module in the imported modules if the source module is registered too to expose it for the globals export function
        prev_current_module_value_in_imported_modules = imported_modules.get(current_module)
        if prev_current_module_value_in_imported_modules is None:
          imported_modules[current_module] = (import_module_name, module_file_path, {})

        # based on: https://docs.python.org/3/library/importlib.html#importing-a-source-file-directly :
        # `To import a Python source file directly, use the following recipe (Python 3.5 and newer only)`
        #
        sys.modules[import_module_name] = imported_module

        to_value = getattr(current_module, import_module_name, None)
        if not to_value is None and inspect.ismodule(to_value):
          is_module_ref_already_exist = True
        else:
          is_module_ref_already_exist = False

      finally:
        import_nest_index[0] -= 1

    # copy the module content into already existed module (behaviour by default, do import as `.module` or `module.` or `.module.` to prevent a merge)
    if is_module_ref_already_exist:
      tkl_merge_module(imported_module, to_value)
    else:
      # replace by a module instance, based on: https://stackoverflow.com/questions/11170949/how-to-make-a-copy-of-a-python-module-at-runtime/11173076#11173076
      to_value = type(imported_module)(imported_module.__name__, imported_module.__doc__)
      to_value.__dict__.update(imported_module.__dict__)

      ## export globals to new module
      #for var, value in global_vars.items(): 
      #  setattr(to_value, var, tkl_membercopy(value, imported_module_globals, vars(to_value)))

      setattr(current_module, import_module_name, to_value)

      # CAUTION:
      #   Must do explicit merge, otherwise some classes would not be merged!
      #
      tkl_merge_module(imported_module, to_value)

      # we must register being merged (new) module in the imported modules if the source module is registered too to expose it for the globals export function
      imported_modules[to_value] = (import_module_name, module_file_path, {})

  else: # import to the global namespace
    if current_module in imported_modules:
      current_module_in_imported = imported_modules[current_module]
      current_module_attrs = current_module_in_imported[2]
      if 'nomergemodule' in current_module_attrs and current_module_attrs['nomergemodule']:
        raise Exception('attempt to merge the module content to the existed module has been declared as not mergable: ' + current_module.__name__)

    if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 4:
      import_spec = importlib.util.spec_from_loader(import_module_name, importlib.machinery.SourceFileLoader(import_module_name, module_file_path))
      imported_module = importlib.util.module_from_spec(import_spec)
      imported_module_globals = vars(imported_module)

      # inject the members of the tacklelib module
      tkl_merge_module(global_state.this_module, imported_module)

      # export globals to a being imported module
      for var, value in global_vars.items(): 
        setattr(imported_module, var, tkl_membercopy(value, current_module_globals, imported_module_globals))

      # inject attributes in being imported module
      imported_module.SOURCE_FILE = module_file_path
      imported_module.SOURCE_DIR = os.path.dirname(module_file_path)
      module_file_wo_ext = imported_module.SOURCE_FILE_NAME = os.path.basename(module_file_path)
      imported_module.SOURCE_FILE_NAME_WO_EXT = os.path.splitext(module_file_wo_ext)[0]

      for attr, val in inject_attrs.items():
        setattr(imported_module, attr, val)

      is_module_ref_already_exist = False

      # remember last parent before the module execution because of recursion
      prev_imported_module_value_imported_modules = imported_modules.get(imported_module)
      imported_modules[imported_module] = (import_module_name, module_file_path, {})

      # we must register being merged module in the imported modules if the source module is registered too to expose it for the globals export function
      prev_current_module_value_in_imported_modules = imported_modules.get(current_module)
      if prev_current_module_value_in_imported_modules is None:
        imported_modules[current_module] = (import_module_name, module_file_path, {})

      prev_sys_module = sys.modules.get(import_module_name)

      try:
        if not prefix_exec_module_pred is None:
          prefix_exec_module_pred(import_module_name, module_file_path, imported_module)

        # based on: https://docs.python.org/3/library/importlib.html#importing-a-source-file-directly :
        # `To import a Python source file directly, use the following recipe (Python 3.5 and newer only)`
        #
        sys.modules[import_module_name] = imported_module

        import_nest_index[0] += 1

        import_spec.loader.exec_module(imported_module)

      except:
        # restore
        if prev_sys_module is None:
          del sys.modules[import_module_name]
        else:
          sys.modules[import_module_name] = prev_sys_module

        if prev_current_module_value_in_imported_modules is None:
          del imported_modules[current_module]

        if prev_imported_module_value_imported_modules is None:
          del imported_modules[imported_module]
        else:
          imported_modules[imported_module] = prev_imported_module_value_imported_modules

        raise

      finally:
        import_nest_index[0] -= 1

    else:
      # back compatability
      import_nest_index[0] += 1

      try:
        imported_module = imp.load_source(import_module_name, module_file_path).__dict__
        imported_module_globals = vars(imported_module)

        imported_module_value_in_imported_modules = imported_modules[imported_module] = (import_module_name, module_file_path, {})

        # we must register being merged module in the imported modules if the source module is registered too to expose it for the globals export function
        prev_current_module_value_in_imported_modules = imported_modules.get(current_module)
        if prev_current_module_value_in_imported_modules is None:
          imported_modules[current_module] = imported_module_value_in_imported_modules

        # based on: https://docs.python.org/3/library/importlib.html#importing-a-source-file-directly :
        # `To import a Python source file directly, use the following recipe (Python 3.5 and newer only)`
        #
        sys.modules[import_module_name] = imported_module

      finally:
        import_nest_index[0] -= 1

    # copy the module content into already existed module
    tkl_merge_module(imported_module, current_module)

  # must be to avoid a mix
  sys.stdout.flush()
  sys.stderr.flush()

  return imported_module

# shortcut function
def tkl_source_module(dir_path, module_file_name):
  return tkl_import_module(dir_path, module_file_name, '.', skip_stack_frames = 1)
