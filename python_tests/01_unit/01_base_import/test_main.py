import os, sys, inspect, pytest

SOURCE_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
SOURCE_DIR = os.path.dirname(SOURCE_FILE)

TACKLELIB_ROOT = os.path.normcase(os.path.abspath(os.environ['TACKLELIB_ROOT'])).replace('\\', '/')

# portable import to the global space
sys.path.append(TACKLELIB_ROOT)
import tacklelib as tkl
# all functions in the module have has a 'tkl_' prefix, all classes begins by `Tackle`, so we don't need a scope here
tkl.tkl_merge_module(tkl, globals())
# cleanup
tkl = None
sys.path.pop()

def test_base_import():
  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  tkl_import_module(SOURCE_DIR, 'testlib.py')

  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  print(globals().keys())

  testlib.base_test()
  testlib.testlib_inc1.inc1_test()
  testlib.testlib_inc1.testlib_inc2.inc2_test()
  #testlib.testlib.inc3.inc3_test()                             # does not reachable directly ...
  getattr(globals()['testlib'], 'testlib.inc3').inc3_test()     # ... but reachable through the `globals` + `getattr`

  tkl_import_module(SOURCE_DIR, 'testlib.py', '.')

  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  print(globals().keys())

  base_test()
  testlib_inc1.inc1_test()
  testlib_inc1.testlib_inc2.inc2_test()
  #testlib.inc3.inc3_test()                                     # does not reachable directly ...
  globals()['testlib.inc3'].inc3_test()                         # ... but reachable through the `globals` + `getattr`
