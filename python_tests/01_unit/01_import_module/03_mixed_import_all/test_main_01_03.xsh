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


def test_mixed_import_all():
  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  tkl_source_module(SOURCE_DIR, 'inc1.xsh')

  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  inc1()
  aaa.inc2()
  aaa.inc3()
  aaa.bbb.inc4()
  print("=")
