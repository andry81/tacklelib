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

def test_base_class_in_imported_module():
  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  tkl_declare_global('TACKLELIB_ROOT', TACKLELIB_ROOT)

  tkl_source_module('.', 'inc1.xsh')

  THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
  THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

  assert(SOURCE_DIR == THIS_TEST_ROOT)
  assert(SOURCE_FILE == THIS_TEST_FILE)

  # `b` is a method of the `B` which is the base class to the `A` AND in a different imported module versus `A`
  A().b()
