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


def test_basic_declare_before_1():
  tkl_declare_global('test_inc1_data1', [1, 2])
  tkl_declare_global('test_inc1_data2', [1, 2])
  tkl_declare_global('test_inc1_data3', [1, 2])
  tkl_declare_global('test_inc1_data4', [1, 2])

  assert(globals()['test_inc1_data1'] == [1, 2])
  assert(globals()['test_inc1_data2'] == [1, 2])
  assert(globals()['test_inc1_data3'] == [1, 2])
  assert(globals()['test_inc1_data4'] == [1, 2])
  assert(test_inc1_data1 == [1, 2])
  assert(test_inc1_data2 == [1, 2])
  assert(test_inc1_data3 == [1, 2])
  assert(test_inc1_data4 == [1, 2])

  tkl_import_module(SOURCE_DIR, 'inc1.xsh', 'inc1')

  inc1.test_inc1_global_data1()
  inc1.test_inc1_global_data2()
  inc1.test_inc1_global_data3()
  inc1.test_inc1_global_data4()

  # these no need to declare through the builtin `global`
  assert(test_inc1_data1 == [1, 2, 3, 4])
  assert(test_inc1_data2 == [1, 2])
  assert(test_inc1_data3 == [1, 2, 3, 4])
  assert(test_inc1_data4 == [1, 2, 3, 4])

def test_basic_declare_before_2():
  tkl_declare_global('test_inc2_data1', [3, 4])
  tkl_declare_global('test_inc2_data2', [3, 4])
  tkl_declare_global('test_inc2_data3', [3, 4])
  tkl_declare_global('test_inc2_data4', [3, 4])

  assert(globals()['test_inc2_data1'] == [3, 4])
  assert(globals()['test_inc2_data2'] == [3, 4])
  assert(globals()['test_inc2_data3'] == [3, 4])
  assert(globals()['test_inc2_data4'] == [3, 4])
  assert(test_inc2_data1 == [3, 4])
  assert(test_inc2_data2 == [3, 4])
  assert(test_inc2_data3 == [3, 4])
  assert(test_inc2_data4 == [3, 4])

  tkl_source_module(SOURCE_DIR, 'inc2.xsh')

  test_inc2_global_data1()
  test_inc2_global_data2()
  test_inc2_global_data3()
  test_inc2_global_data4()

  # these no need to declare through the builtin `global`
  assert(test_inc2_data1 == [3, 4, 5, 6])
  assert(test_inc2_data2 == [3, 4])
  assert(test_inc2_data3 == [3, 4, 5, 6])
  assert(test_inc2_data4 == [3, 4, 5, 6])
