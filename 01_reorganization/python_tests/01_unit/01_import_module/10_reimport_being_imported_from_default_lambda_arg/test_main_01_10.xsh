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


def test_reimport_being_imported_from_lambda_1():
  tkl_import_module(SOURCE_DIR, 'inc1_lvl2.xsh', '.')

  inc1_lvl3_test()

def test_reimport_being_imported_from_lambda_2():
  tkl_import_module(SOURCE_DIR, 'inc2_lvl2.xsh', '.')

  inc2_lvl3_test()

def test_reimport_being_imported_from_lambda_3():
  tkl_import_module(SOURCE_DIR, 'inc3_lvl2.xsh', 'inc3')

  inc3.inc3_lvl3_test()

def test_reimport_being_imported_from_lambda_4():
  tkl_import_module(SOURCE_DIR, 'inc4_lvl2.xsh', 'inc4')

  inc4.inc4_lvl3_test()
