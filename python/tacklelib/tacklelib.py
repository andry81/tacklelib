# pure python module for commands w/o extension modules usage

import os, sys, inspect, copy, builtins, enum, glob, pkgutil
from setuptools import distutils
if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 2: # >= 3.2
  import distutils.sysconfig
if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 4: # >= 3.4
  import importlib.util, importlib.machinery
else:
  import imp

# all members must be as a container to copy by reference
class TackleGlobalState:
  tkl_module = [None]
  import_nest_index = [0]
  # key:    <module>
  # value:  (<module_import_name>, <module_file_path>, {<module_attribute_name> : <module_attribute_value>})
  imported_modules = {}
  # key:    <module_file_path>
  # value:  <module>
  imported_modules_by_file_path = {}
  # key:    <variable_token>
  # value:  <value>
  global_vars = {}

  @classmethod
  def clear(cls):
    tkl_module = cls.tkl_module[0]
    del tkl_module
    cls.tkl_module[0] = None
    cls.imported_modules.clear()
    cls.imported_modules_by_file_path.clear()
    cls.global_vars.clear()

# all members must be as a container to copy by reference
class TackleGlobalCache:
  # cached packaged modules
  packaged_modules = {}

  @classmethod
  def clear(cls):
    cls.packaged_modules.clear()  # references in all modules must stay the same

def tkl_init(tkl_module, import_file_exts = ['.xsh'], reset_global_state = True):
  #print('tkl_init')

  # enable the `inspect.getmodulename` to return module name with non standard file extensions
  if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 4: # >= 3.4
    for import_file_ext in import_file_exts:
      if import_file_ext not in importlib.machinery.SOURCE_SUFFIXES:
        importlib.machinery.SOURCE_SUFFIXES.append(import_file_ext)

  # initialize both modules because, for example, in the pytest they are different in the collect phase!
  target_module0 = tkl_module.tkl_get_stack_frame_module_by_offset(1)
  target_module1 = tkl_module.tkl_get_stack_frame_module_by_name()
  if id(target_module0) == id(target_module1):
    target_module1 = None

  tkl_module_globals = vars(tkl_module)

  target_module0_globals = vars(target_module0)
  if target_module1:
    target_module1_globals = vars(target_module1)

  # update global cache
  packaged_modules = tkl_module.TackleGlobalCache.packaged_modules = tkl_module.tkl_get_packaged_modules()

  target_module0.TackleGlobalCache = tkl_module.tkl_membercopy(TackleGlobalCache, tkl_module_globals, target_module0_globals)
  target_module0.TackleGlobalCache.packaged_modules = packaged_modules
  if target_module1:
    target_module1.TackleGlobalCache = tkl_module.tkl_membercopy(TackleGlobalCache, tkl_module_globals, target_module1_globals)
    target_module1.TackleGlobalCache.packaged_modules = packaged_modules

  # update global state
  prev_target_module0_global_state = target_module0_global_state = getattr(target_module0, 'TackleGlobalState', None)
  if reset_global_state or target_module0_global_state is None:
    target_module0_global_state = TackleGlobalState
    if reset_global_state and not prev_target_module0_global_state is None:
        target_module0_global_state.clear()

  if target_module1:
    prev_target_module1_global_state = target_module1_global_state = getattr(target_module1, 'TackleGlobalState', None)
    if reset_global_state or target_module1_global_state is None:
      target_module1_global_state = TackleGlobalState
      if reset_global_state and not prev_target_module1_global_state is None:
          target_module1_global_state.clear()

  target_module0_global_state.tkl_module[0] = tkl_module
  if target_module1:
    target_module1_global_state.tkl_module[0] = tkl_module

  # all functions in the module have has a 'tkl_' prefix, all classes begins by `Tackle`, so we don't need a scope here
  tkl_merge_module(tkl_module, target_module0, tkl_module)
  if target_module1:
      tkl_merge_module(tkl_module, target_module1, tkl_module)

  # declare the current module as an already imported module to be able to propagate a global variable to it
  #print(target_module0.__name__, target_module0.__file__.replace('\\', '/'))
  target_module0_file_path = target_module0.__file__.replace('\\', '/')
  target_module0_global_state.imported_modules[target_module0] = (target_module0.__name__, target_module0_file_path, {})
  target_module0_global_state.imported_modules_by_file_path[os.path.normcase(target_module0_file_path).replace('\\', '/')] = target_module0
  if target_module1:
    target_module1_file_path = target_module1.__file__.replace('\\', '/')
    target_module1_global_state.imported_modules[target_module1] = (target_module1.__name__, target_module1_file_path, {})
    target_module1_global_state.imported_modules_by_file_path[os.path.normcase(target_module1_file_path).replace('\\', '/')] = target_module1

# basiclly required in a teardown code in tests
def tkl_uninit():
  target_module0 = tkl_module.tkl_get_stack_frame_module_by_offset(1)
  target_module1 = tkl_module.tkl_get_stack_frame_module_by_name()
  if id(target_module0) == id(target_module1):
    target_module1 = None

  target_module0_global_state = getattr(target_module0, 'TackleGlobalState', None)
  target_module0_global_cache = getattr(target_module0, 'TackleGlobalCache', None)
  if target_module1:
    target_module1_global_state = getattr(target_module1, 'TackleGlobalState', None)
    target_module1_global_cache = getattr(target_module1, 'TackleGlobalCache', None)

  target_module0_global_state.clear()
  target_module0_global_cache.clear()
  if target_module1:
    target_module1_global_state.clear()
    target_module1_global_cache.clear()

def tkl_is_inited(target_module):
  global_state = getattr(target_module, 'TackleGlobalState', None)
  if global_state is None or len(global_state.tkl_module) == 0:
    return False

  global_cache = getattr(target_module, 'TackleGlobalCache', None)
  if global_cache is None or len(global_cache.packaged_modules) == 0:
    return False

  return True

def tkl_get_imported_module_by_file_path(imported_module_file_path, current_globals = None):
  # CAUTION:
  #   We can not use the stack access here until we get a module where to search for the global state class.
  #   Instead the current globals already has to contain the globals state class.
  #
  if not current_globals:
    current_globals = globals()

  imported_module_file_path = os.path.normcase(os.path.abspath(imported_module_file_path)).replace('\\', '/')
  global_state = current_globals.get('TackleGlobalState')
  if global_state is not None:
    return global_state.imported_modules_by_file_path.get(imported_module_file_path)

  return None

def tkl_get_stack_frame_module_by_offset(skip_stack_frames = 0):
  skip_frame_index = skip_stack_frames + 1;

  # search for the first module in the stack
  stack_frame = inspect.currentframe()
  while stack_frame and skip_frame_index > 0:
    #print('***', skip_frame_index, stack_frame.f_code.co_name, stack_frame.f_code.co_filename, stack_frame.f_lineno)
    stack_frame = stack_frame.f_back
    skip_frame_index -= 1

  if stack_frame is None:
    raise Exception('target module is not found on the stack')

  #print('>>>', stack_frame.f_code.co_name, stack_frame.f_code.co_filename, stack_frame.f_lineno)

  target_module = tkl_get_imported_module_by_file_path(stack_frame.f_code.co_filename, stack_frame.f_globals)
  if target_module is None: # fallback to the inspect
    target_module = inspect.getmodule(stack_frame)
  if target_module is None:
    raise Exception('target module is not found on the stack')

  return target_module

def tkl_get_stack_frame_module_by_name(name = '<module>'):
  target_module = None

  # search for the first module in the stack
  stack_frame = inspect.currentframe()
  while stack_frame:
    if stack_frame.f_code.co_name == name:
      #print('>>>', stack_frame.f_code.co_name, stack_frame.f_code.co_filename, stack_frame.f_lineno)
      target_module = tkl_get_imported_module_by_file_path(stack_frame.f_code.co_filename, stack_frame.f_globals)
      if target_module is None: # fallback to the inspect
        target_module = inspect.getmodule(stack_frame)
      if target_module is None:
        raise Exception('invalid stack top module')
      break
    #else:
    #  print('***', stack_frame.f_code.co_name, stack_frame.f_code.co_filename, stack_frame.f_lineno)
    stack_frame = stack_frame.f_back

  if stack_frame is None:
    raise Exception('top module is not found on the stack')

  return target_module

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
    cls_module = inspect.getmodule(x)
    #print('tkl_get_method_class:', x, '->', cls_name, '->', cls_module)
    try:
      cls = getattr(cls_module, cls_name)
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

  #print('classcopy:', x)
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
      #if not key.startswith('__'):
      if inspect.isfunction(value):
        member_cls = tkl_get_method_class(value)
        if member_cls in from_globals:
          #print('  tkl_classcopy:', key)
          # globals retarget to the destination globals
          setattr(cls_copy, key, type(value)(value.__code__, to_globals, value.__name__, value.__defaults__, value.__closure__))

  return cls_copy

# to readdress `globals()` in all functions
def tkl_membercopy(x, from_globals, to_globals):
  #print('membercopy:', x)
  if id(from_globals) != id(to_globals):
    if inspect.isfunction(x):
      return type(x)(x.__code__, to_globals, x.__name__, x.__defaults__, x.__closure__)
    elif inspect.isclass(x):
      # 1. ignore enumerations
      if not isinstance(x, enum.Enum) and not issubclass(x, enum.Enum):
        # 2. ignore builtins because each what type has to be copied exclusively
        if getattr(builtins, x.__name__, None) is not x:
          # 3. ignore not trivially copiable classes
          cls_vars = vars(x)
          qualname = cls_vars.get('__qualname__')
          if qualname is None or isinstance(qualname, str):
            return tkl_classcopy(x, from_globals, to_globals)

  return x # return by reference

# based on:
#   https://stackoverflow.com/questions/4922520/determining-if-a-given-python-module-is-a-built-in-module/37243423#37243423
#   https://gist.github.com/mateor/89a9cef41532021549739a12eae7790a
#
def tkl_get_packaged_modules(include_builtins = True):
  modules = {module for _, module, package in list(pkgutil.iter_modules()) if package is False}
  top_level_txt = glob.iglob(os.path.join(os.path.dirname(os.__file__) + '/site-packages', '*-info', 'top_level.txt'))
  modules -= {open(txt).read().strip() for txt in list(top_level_txt)}
  if include_builtins:
    builtin_modules = set(sys.builtin_module_names)
  else:
    builtin_modules = set()
  _, top_level_libs, _ = list(os.walk(distutils.sysconfig.get_python_lib(standard_lib=True)))[0]
  return sorted(top_level_libs + list(modules | builtin_modules))

def tkl_merge_module(from_, to, target_module):
  if target_module.__name__ != 'tacklelib':
    is_target_module_inited = tkl_is_inited(target_module)
    if not is_target_module_inited:
      raise Exception('tacklelib is not properly initialized, call to tkl_init in the top module')

  from_globals = vars(from_)
  if inspect.ismodule(to):
    to_dict = vars(to)
    is_to_module = True
  else:
    to_dict = to
    is_to_module = False

  #print('mergemodule: ==', from_, to)
  if id(to) != id(from_):
    for from_key, from_value in vars(from_).items():
      if not from_key.startswith('__') and from_key not in ['SOURCE_FILE', 'SOURCE_DIR', 'SOURCE_FILE_NAME', 'SOURCE_FILE_NAME_WO_EXT']:
        if is_to_module:
          to_value = getattr(to, from_key, None)
        else:
          to_value = to_dict.get(from_key)

        if to_value is None or (isinstance(from_value, type) or id(from_value) != id(to_value)):
          if not inspect.ismodule(from_value):
            #print('mergemodule: ->', from_.__name__, '->', from_key, id(from_value), id(to_value), type(from_value), type(to_value))
            to_value = tkl_membercopy(from_value, from_globals, to_dict)
            if is_to_module:
              setattr(to, from_key, to_value)
            else:
              to[from_key] = to_value
          else:
            # avoid copying builtin modules including all packaged modules
            global_cache = getattr(target_module, 'TackleGlobalCache', None)
            packaged_modules = global_cache.packaged_modules
            if from_value.__name__ not in packaged_modules:
              #print('mergemodule: ->', from_.__name__, '->', from_key, id(from_value), id(to_value), type(from_value), type(to_value))
              if not inspect.ismodule(to_value):
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
                tkl_merge_module(from_value, to_value, target_module)

                # We must register being merged (new) module in the imported modules container if the source module is registered too to:
                # 1. To expose it for the globals export function - `tkl_export_global`.
                #
                global_state = getattr(target_module, 'TackleGlobalState', None)
                if not global_state is None:
                  imported_modules = global_state.imported_modules
                  from_module_value_in_imported_modules = imported_modules.get(from_)
                  if not from_module_value_in_imported_modules is None:
                    from_imported_module_file_path = from_module_value_in_imported_modules[1]
                    imported_modules[to_value] = (from_module_value_in_imported_modules[0], from_imported_module_file_path, {})
              else:
                tkl_merge_module(from_value, to_value, target_module)
            else:
              if is_to_module:
                setattr(to, from_key, from_value)
              else:
                to[from_key] = from_value
  else:
    raise Exception('module merge to the same object')

  return to

# to declare globals in a current module from the stack
def tkl_declare_global(var, value, from_globals = None):
  target_module = tkl_get_stack_frame_module_by_offset(1)

  is_target_module_inited = tkl_is_inited(target_module)
  if not is_target_module_inited:
    raise Exception('tacklelib is not properly initialized, call to tkl_init in the top module')

  global_state = getattr(target_module, 'TackleGlobalState', None)

  imported_modules = global_state.imported_modules
  global_vars = global_state.global_vars

  if from_globals is None:
    from_globals = globals()

  target_module_globals = vars(target_module)
  value_copy = tkl_membercopy(value, from_globals, target_module_globals)

  # at first, assign as a global
  #exec('global ' + var + '\n' + var + ' = value_copy')

  setattr(target_module, var, value_copy)

  global_vars[var] = value_copy
  #globals()[var] = value_copy

  # export a global to rest of imported modules
  for imported_module in imported_modules:
    if id(imported_module) != id(target_module):
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

  target_module = tkl_get_stack_frame_module_by_offset(skip_stack_frames + 1)

  is_target_module_inited = tkl_is_inited(target_module)
  if not is_target_module_inited:
    raise Exception('tacklelib is not properly initialized, call to tkl_init in the top module')

  global_state = getattr(target_module, 'TackleGlobalState', None)

  import_nest_index = global_state.import_nest_index[0]

  print(('| ' * import_nest_index) + 'import :', import_nest_index, module_file_path, 'as', module_name_wo_ext if ref_module_name is None else ref_module_name, end='')

  target_module_globals = vars(target_module)

  imported_modules = global_state.imported_modules
  imported_modules_by_file_path = global_state.imported_modules_by_file_path

  global_vars = global_state.global_vars

  # import to a local/global namespace?
  if ref_module_name != '.':
    named_scope = True
  else:
    named_scope = False

  # get parent module state
  module_must_not_exist   = False
  module_must_exist       = False
  nomerge_module          = False

  if not ref_module_name is None and named_scope:
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

  is_module_ref_already_exist = False

  # execution guard, always enabled
  for imported_module, imported_module_value in imported_modules.items():
    imported_module_file_path = imported_module_value[1]
    if imported_module_file_path == module_file_path:
      print(' (cached)')
      imported_module_name = imported_module_value[0]
      imported_module_attrs = imported_module_value[2]

      imported_module_globals = vars(imported_module)

      # copy merge module into current module
      if named_scope:
        # reference a being imported module from a parent module
        to_value = getattr(target_module, import_module_name, None)
        if not to_value is None and inspect.ismodule(to_value):
          is_module_ref_already_exist = True

        if module_must_not_exist:
          if is_module_ref_already_exist:
            raise Exception('The module reference must not exist as a module before the import: ' + import_module_name)
        elif module_must_exist:
          if not is_module_ref_already_exist:
            raise Exception('The module reference must already exist as a module before the import: ' + import_module_name)

        from_value = imported_module

        if is_module_ref_already_exist and to_value in imported_modules:
          target_module_in_imported = imported_modules[to_value]
          target_module_attrs = target_module_in_imported[2]
          if 'nomergemodule' in target_module_attrs and target_module_attrs['nomergemodule']:
            raise Exception('attempt to merge the module content to the existed module has been declared as not mergable: ' + to_value.__name__)

        if not is_module_ref_already_exist:
          # replace by a module instance, based on: https://stackoverflow.com/questions/11170949/how-to-make-a-copy-of-a-python-module-at-runtime/11173076#11173076
          to_value = type(from_value)(from_value.__name__, from_value.__doc__)
          to_value.__dict__.update(from_value.__dict__)

          setattr(target_module, import_module_name, to_value)

          # CAUTION:
          #   Must do explicit merge, otherwise some classes would not be merged!
          #
          tkl_merge_module(from_value, to_value, target_module)

          # We must register being merged (new) module in the imported modules container to:
          # 1. To expose it for the globals export function - `tkl_export_global`.
          #
          imported_modules[to_value] = (imported_module_name, imported_module_file_path, imported_module_attrs)
        else:
          tkl_merge_module(from_value, to_value, target_module)

      else:
        if id(target_module) == id(imported_module):
          raise Exception('attempt to merge the module content to itself: ' + target_module.__name__)

        if target_module in imported_modules:
          target_module_in_imported = imported_modules[target_module]
          target_module_attrs = target_module_in_imported[2]
          if 'nomergemodule' in target_module_attrs and target_module_attrs['nomergemodule']:
            raise Exception('attempt to merge the module content to the existed module has been declared as not mergable: ' + target_module.__name__)

        # export globals to a being imported module
        for var, value in global_vars.items(): 
          setattr(target_module, var, tkl_membercopy(value, imported_module_globals, target_module_globals))

        tkl_merge_module(imported_module, target_module, target_module)

      return imported_module

  print()

  import_nest_index = global_state.import_nest_index

  if sys.version_info[0] > 3 or sys.version_info[0] == 3 and sys.version_info[1] >= 4: # >= 3.4
    has_importlib = True
  else:
    has_importlib = False

  if not named_scope:
    if target_module in imported_modules:
      target_module_in_imported = imported_modules[target_module]
      target_module_attrs = target_module_in_imported[2]
      if 'nomergemodule' in target_module_attrs and target_module_attrs['nomergemodule']:
        raise Exception('attempt to merge the module content to the existed module has been declared as not mergable: ' + target_module.__name__)

  imported_module = None

  try:
    if has_importlib:
      import_spec = importlib.util.spec_from_loader(import_module_name, importlib.machinery.SourceFileLoader(import_module_name, module_file_path))
      imported_module = importlib.util.module_from_spec(import_spec)
    else:
      # back compatability
      import_nest_index[0] += 1

      if named_scope:
        imported_module = imp.load_source(import_module_name, module_file_path)
      else:
        imported_module = imp.load_source(import_module_name, module_file_path).__dict__

    imported_module_globals = vars(imported_module)

    # inject the members of the tacklelib module
    tkl_merge_module(global_state.tkl_module[0], imported_module, target_module)

    # export globals to a being imported module
    for var, value in global_vars.items(): 
      setattr(imported_module, var, tkl_membercopy(value, target_module_globals, imported_module_globals))

    # inject attributes in being imported module
    imported_module.SOURCE_FILE = module_file_path
    imported_module.SOURCE_DIR = os.path.dirname(module_file_path)
    module_file_wo_ext = imported_module.SOURCE_FILE_NAME = os.path.basename(module_file_path)
    imported_module.SOURCE_FILE_NAME_WO_EXT = os.path.splitext(module_file_wo_ext)[0]

    for attr, val in inject_attrs.items():
      setattr(imported_module, attr, val)

    if named_scope:
      # reference a being imported module from a parent module
      to_value = getattr(target_module, import_module_name, None)
      if not to_value is None and inspect.ismodule(to_value):
        is_module_ref_already_exist = True

      if module_must_not_exist:
        if is_module_ref_already_exist:
          raise Exception('The module reference must not exist as a module before the import: ' + import_module_name)
      elif module_must_exist:
        if not is_module_ref_already_exist:
          raise Exception('The module reference must already exist as a module before the import: ' + import_module_name)
    else:
      to_value = target_module
      is_module_ref_already_exist = True

    # We must register being imported module in the imported modules container to:
    # 1. To expose it for the globals export function - `tkl_export_global`.
    # 2. To be able to search a module by a module file path instead of by a module name like in the `inspect.getmodule(...)` function does.
    #
    prev_imported_module_value_in_imported_modules = imported_modules.get(imported_module)
    if named_scope:
      imported_modules[imported_module] = (import_module_name, module_file_path, {'nomergemodule' : nomerge_module})
    else:
      imported_modules[imported_module] = (import_module_name, module_file_path, {})
    prev_imported_module_value_in_imported_modules_by_file_path = imported_modules_by_file_path.get(module_file_path)
    if prev_imported_module_value_in_imported_modules_by_file_path is None:
      imported_modules_by_file_path[module_file_path] = imported_module

    # We must register being merged module in the imported modules container to:
    # 1. To expose it for the globals export function - `tkl_export_global`.
    #
    prev_target_module_value_in_imported_modules = imported_modules.get(target_module)
    if prev_target_module_value_in_imported_modules is None:
      imported_modules[target_module] = (import_module_name, module_file_path, {})

    prev_sys_module = sys.modules.get(import_module_name)

    try:
      import_nest_index[0] += 1

      # based on: https://docs.python.org/3/library/importlib.html#importing-a-source-file-directly :
      # `To import a Python source file directly, use the following recipe (Python 3.5 and newer only)`
      #
      if prev_sys_module is None:
        # CAUTION:
        #   We must check if a name was not already registered, because the `inspect.getmodule(...)` function on a stack frame
        #   uses SEARCH BY NAME instead of SEARCH BY FILE PATH!
        #   So we use the first time seen module name to store as a key in the system container.
        #
        sys.modules[import_module_name] = imported_module

      if has_importlib:
        if prefix_exec_module_pred is not None:
          prefix_exec_module_pred(import_module_name, module_file_path, imported_module)

        import_spec.loader.exec_module(imported_module)
      else:
        if prefix_exec_module_pred is not None:
          raise Exception('prefix_exec_module_pred is not implemented for the imp module')

    except:
      # restore
      if prev_sys_module is None:
        del sys.modules[import_module_name]

      if prev_target_module_value_in_imported_modules is None:
        del imported_modules[target_module]
      else:
        imported_modules[target_module] = prev_target_module_value_in_imported_modules

      if prev_imported_module_value_in_imported_modules_by_file_path is None:
        del prev_imported_module_value_in_imported_modules_by_file_path

      if prev_imported_module_value_in_imported_modules is None:
        del imported_modules[imported_module]
      else:
        imported_modules[imported_module] = prev_imported_module_value_in_imported_modules

      if named_scope:
        if to_value is None:
          to_value = getattr(target_module, import_module_name, None)
          if not to_value is None:
            del to_value

      raise

    finally:
      import_nest_index[0] -= 1

  except:
    if not has_importlib:
      import_nest_index[0] -= 1

    del imported_module

    raise

  if is_module_ref_already_exist:
    tkl_merge_module(imported_module, to_value, target_module)

    # We must register being merged (new) module in the imported modules container if the destination module is not registered yet to:
    # 1. To expose it for the globals export function - `tkl_export_global`.
    #
    if to_value not in imported_modules:
      imported_modules[to_value] = (import_module_name, module_file_path, {})
  else:
    # replace by a module instance, based on: https://stackoverflow.com/questions/11170949/how-to-make-a-copy-of-a-python-module-at-runtime/11173076#11173076
    to_value = type(imported_module)(imported_module.__name__, imported_module.__doc__)
    to_value.__dict__.update(imported_module.__dict__)

    setattr(target_module, import_module_name, to_value)

    # CAUTION:
    #   Must do explicit merge, otherwise some classes would not be merged!
    #
    tkl_merge_module(imported_module, to_value, target_module)

    # We must register being merged (new) module in the imported modules container to:
    # 1. To expose it for the globals export function - `tkl_export_global`.
    #
    imported_modules[to_value] = (import_module_name, module_file_path, {})

  # must be to avoid a mix
  sys.stdout.flush()
  sys.stderr.flush()

  return imported_module

# shortcut function
def tkl_source_module(dir_path, module_file_name):
  return tkl_import_module(dir_path, module_file_name, '.', skip_stack_frames = 1)
