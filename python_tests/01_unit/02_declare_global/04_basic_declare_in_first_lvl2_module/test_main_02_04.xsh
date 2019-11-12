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


def test_basic_declare_in_first_lvl2_module_1():
  tkl_import_module(SOURCE_DIR, 'inc1.xsh', 'inc1')

  assert('inc1' in globals())
  assert(globals()['test_inc1_data1'] == [1, 2, 3, 4])
  assert(globals()['test_inc1_data2'] == [1, 2, 3, 4])
  assert(globals()['test_inc1_data3'] == [1, 2])
  assert(test_inc1_data1 == [1, 2, 3, 4])
  assert(test_inc1_data2 == [1, 2, 3, 4])
  assert(test_inc1_data3 == [1, 2])

  inc1.test_inc1_global_data3()
  inc1.test_inc1_global_data4()
  inc1.test_inc1_global_data5()
  inc1.test_inc1_global_data6()

  assert(globals()['test_inc1_data1'] == [1, 2, 3, 4])
  assert(globals()['test_inc1_data2'] == [1, 2, 3, 4])
  assert(globals()['test_inc1_data3'] == [1, 2, 3, 4])
  assert(globals()['test_inc1_data4'] == [1, 2, 3, 4])
  assert(globals()['test_inc1_data5'] == [1, 2, 3, 4])
  assert(globals()['test_inc1_data6'] == [1, 2, 3, 4])

  # these no need to declare through the builtin `global`
  assert(test_inc1_data1 == [1, 2, 3, 4])
  assert(test_inc1_data2 == [1, 2, 3, 4])
  assert(test_inc1_data3 == [1, 2, 3, 4])
  assert(test_inc1_data4 == [1, 2, 3, 4])
  assert(test_inc1_data5 == [1, 2, 3, 4])
  assert(test_inc1_data6 == [1, 2, 3, 4])

def test_basic_declare_in_first_lvl2_module_2():
  tkl_source_module(SOURCE_DIR, 'inc2.xsh')

  assert(globals()['test_inc2_data1'] == [3, 4, 5, 6])
  assert(globals()['test_inc2_data2'] == [3, 4, 5, 6])
  assert(globals()['test_inc2_data3'] == [3, 4])
  assert(test_inc2_data1 == [3, 4, 5, 6])
  assert(test_inc2_data2 == [3, 4, 5, 6])
  assert(test_inc2_data3 == [3, 4])

  test_inc2_global_data3()
  test_inc2_global_data4()
  test_inc2_global_data5()
  test_inc2_global_data6()

  assert(globals()['test_inc2_data1'] == [3, 4, 5, 6])
  assert(globals()['test_inc2_data2'] == [3, 4, 5, 6])
  assert(globals()['test_inc2_data3'] == [3, 4, 5, 6])
  assert(globals()['test_inc2_data4'] == [3, 4, 5, 6])
  assert(globals()['test_inc2_data5'] == [3, 4, 5, 6])
  assert(globals()['test_inc2_data6'] == [3, 4, 5, 6])

  # these no need to declare through the builtin `global`
  assert(test_inc2_data1 == [3, 4, 5, 6])
  assert(test_inc2_data2 == [3, 4, 5, 6])
  assert(test_inc2_data3 == [3, 4, 5, 6])
  assert(test_inc2_data4 == [3, 4, 5, 6])
  assert(test_inc2_data5 == [3, 4, 5, 6])
  assert(test_inc2_data6 == [3, 4, 5, 6])
