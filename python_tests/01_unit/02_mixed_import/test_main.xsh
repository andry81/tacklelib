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

def test_named_named():
  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  tkl_import_module(SOURCE_DIR, 'testlib_01_named.xsh', 'aaa')

  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  print(globals().keys())
  aaa.bbb.testlib_test()

def test_local_named():
  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  tkl_source_module(SOURCE_DIR, 'testlib_02_local.xsh')

  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  print(globals().keys())
  bbb.testlib_test()

def test_named_local():
  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  tkl_import_module(SOURCE_DIR, 'testlib_01_named.xsh', 'aaa')

  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  print(globals().keys())
  aaa.testlib_test()

def test_local_local():
  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  tkl_source_module(SOURCE_DIR, 'testlib_02_local.xsh')

  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  print(globals().keys())
  testlib_test()
