import os, sys, inspect, pytest

SOURCE_FILE = os.path.abspath(inspect.getsourcefile(lambda:0)).replace('\\','/')
SOURCE_DIR = os.path.dirname(SOURCE_FILE)

""" DOES NOT WORK AS EXPECTED
@pytest.fixture(scope='function', autouse=True)
def global_setup(request):
  print('=== global setup ===')

  TACKLELIB_ROOT = os.path.normcase(os.path.abspath(os.environ['TACKLELIB_ROOT'])).replace('\\', '/')

  # portable import to the global space
  sys.path.append(TACKLELIB_ROOT)
  import tacklelib as tkl

  tkl.tkl_init(tkl, init_stack_module = 'current')

  # cleanup
  #del tkl # must be instead of `tkl = None`, otherwise the variable would be still persist
  sys.path.pop()

  # update globals, based on: https://stackoverflow.com/questions/22768976/how-to-share-a-variable-across-modules-for-all-tests-in-py-test/32855229#32855229
  sys.path.append(SOURCE_DIR) # to load `globals.py` from tests
  import globals as gbl
  sys.path.pop()
  gbl.cache['tkl'] = tkl

  yield global_setup

  tkl.tkl_uninit()
  del tkl # must be instead of `tkl = None`, otherwise the variable would be still persist
  print('=== global teardown ===')
"""

#def pytest_ignore_collect(path, config):
#  pass
#
#def pytest_collect_directory(path, parent):
#  pass
#
#def pytest_collect_file(path, parent):
#  pass
#
#def pytest_collection_modifyitems(config, items):
#  for item in items:
#    print('-', item)
#    print('-', item.fspath)
#    print('-', item.location)
