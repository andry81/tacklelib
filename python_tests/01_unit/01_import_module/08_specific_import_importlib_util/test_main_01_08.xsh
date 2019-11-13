import os, sys, inspect, pytest

SOURCE_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
SOURCE_DIR = os.path.dirname(SOURCE_FILE)

TACKLELIB_ROOT = os.path.normcase(os.path.abspath(os.environ['TACKLELIB_ROOT'])).replace('\\', '/')

# portable import to the global space
sys.path.append(TACKLELIB_ROOT)
import tacklelib as tkl

tkl.tkl_init(tkl)

# cleanup
del tkl # must be instead of `tkl = None`, otherwise the variable would be still persist
sys.path.pop()


def test_specific_import_importlib_util_1():
  tkl_source_module(SOURCE_DIR, 'inc1.xsh')

  target_module = tkl_get_stack_frame_module_by_offset()

  assert(hasattr(target_module, 'importlib'))
  assert('importlib' in vars(target_module))
  assert('importlib' in globals())

  assert(hasattr(target_module.importlib, 'util'))
  assert('util' in vars(vars(target_module)['importlib']))
  assert('util' in vars(globals()['importlib']))

  assert(inspect.ismodule(target_module.importlib))
  assert(inspect.ismodule(vars(target_module)['importlib']))
  assert(inspect.ismodule(globals()['importlib']))

  assert(inspect.ismodule(target_module.importlib.util))
  assert(inspect.ismodule(vars(vars(target_module)['importlib'])['util']))
  assert(inspect.ismodule(vars(globals()['importlib'])['util']))

  assert(hasattr(target_module.importlib.util, 'spec_from_loader'))
  assert(hasattr(vars(vars(target_module)['importlib'])['util'], 'spec_from_loader'))
  assert(hasattr(vars(globals()['importlib'])['util'], 'spec_from_loader'))

def test_specific_import_importlib_util_2():
  tkl_import_module(SOURCE_DIR, 'inc1.xsh', 'inc1')

  assert(hasattr(inc1, 'importlib'))
  assert('importlib' in vars(inc1))

  assert(hasattr(inc1.importlib, 'util'))
  assert('util' in vars(vars(inc1)['importlib']))

  assert(inspect.ismodule(inc1.importlib))
  assert(inspect.ismodule(vars(inc1)['importlib']))

  assert(inspect.ismodule(inc1.importlib.util))
  assert(inspect.ismodule(vars(vars(inc1)['importlib'])['util']))

  assert(hasattr(inc1.importlib.util, 'spec_from_loader'))
  assert(hasattr(vars(vars(inc1)['importlib'])['util'], 'spec_from_loader'))
