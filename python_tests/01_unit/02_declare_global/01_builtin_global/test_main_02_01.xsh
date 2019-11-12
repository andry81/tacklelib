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


global test_data2
test_data2 = [1, 2]

global test_data4
test_data4 = [1, 2]

tkl_import_module(SOURCE_DIR, 'inc1.xsh', 'inc1')

def test_builtin_global():
  assert('test_data1' not in globals())
  assert(globals()['test_data2'] == [1, 2])
  assert('test_data3' not in globals())
  assert(globals()['test_data4'] == [1, 2])

  assert(test_data2 == [1, 2])
  assert(test_data4 == [1, 2])

  inc1.test_global_data1()
  inc1.test_global_data2()
  inc1.test_global_data3()
  inc1.test_global_data4()

  assert('test_data1' not in globals())
  assert(globals()['test_data2'] == [1, 2])
  assert('test_data3' not in globals())
  assert(globals()['test_data4'] == [1, 2])

  assert(test_data2 == [1, 2])
  assert(test_data4 == [1, 2])
