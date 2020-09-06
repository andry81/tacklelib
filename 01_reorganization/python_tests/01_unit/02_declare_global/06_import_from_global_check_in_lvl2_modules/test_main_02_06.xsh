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


tkl_import_module(SOURCE_DIR, 'inc1.xsh', 'inc1')

inc1.test_inc1_global_data1()

assert(globals()['test_inc1_data1'] == [1, 2])

# these no need to declare through the builtin `global`
assert(test_inc1_data1 == [1, 2])

def test_import_from_global_check_in_lvl2_modules_1():
  assert(globals()['test_inc1_data1'] == [1, 2])

  # these no need to declare through the builtin `global`
  assert(test_inc1_data1 == [1, 2])

  tkl_import_module(SOURCE_DIR, 'inc2.xsh', 'inc2')

  inc2.test_inc2_global_data1()

  assert(globals()['test_inc1_data1'] == [1, 2, 3, 4])

  # these no need to declare through the builtin `global`
  assert(test_inc1_data1 == [1, 2, 3, 4])
