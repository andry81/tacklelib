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


def test_base_import_class_1():
  tkl_import_module(SOURCE_DIR, 'inc1.xsh', 'inc1')

  assert(hasattr(inc1, 'Test'))
  assert('Test' in vars(inc1))

  assert(hasattr(inc1.Test, 'test'))

  assert(inspect.isclass(inc1.Test))
  assert(inspect.isclass(vars(inc1)['Test']))

  assert(inc1.Test.test == [1, 2])
  assert(vars(inc1)['Test'].test == [1, 2])

def test_base_import_class_2():
  tkl_source_module(SOURCE_DIR, 'inc2.xsh')

  target_module = tkl_get_stack_frame_module_by_offset()

  assert(hasattr(target_module, 'Test2'))
  assert('Test2' in vars(target_module))
  assert('Test2' in globals())

  assert(hasattr(target_module.Test2, 'test2'))

  assert(inspect.isclass(target_module.Test2))
  assert(inspect.isclass(vars(target_module)['Test2']))
  assert(inspect.isclass(globals()['Test2']))

  assert(target_module.Test2.test2 == [3, 4])
  assert(vars(target_module)['Test2'].test2 == [3, 4])
  assert(globals()['Test2'].test2 == [3, 4])
