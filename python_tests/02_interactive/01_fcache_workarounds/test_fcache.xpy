import os, sys, inspect

SOURCE_FILE = os.path.abspath(inspect.getsourcefile(lambda:0)).replace('\\','/')
SOURCE_DIR = os.path.dirname(SOURCE_FILE)
SOURCE_FILE_NAME = os.path.basename(SOURCE_FILE)

TACKLELIB_ROOT = os.environ['TACKLELIB_ROOT']
CMDOPLIB_ROOT = os.environ['CMDOPLIB_ROOT']

# portable import to the global space
sys.path.append(TACKLELIB_ROOT)
import tacklelib as tkl

tkl.tkl_init(tkl)

# cleanup
del tkl # must be instead of `tkl = None`, otherwise the variable would be still persist
sys.path.pop()

from fcache.cache import FileCache
import time
import sys

tkl_declare_global('TACKLELIB_ROOT', TACKLELIB_ROOT)
tkl_declare_global('CMDOPLIB_ROOT', CMDOPLIB_ROOT)

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.cache.py', 'tkl')


mycache = tkl.FileCache(os.path.splitext(SOURCE_FILE_NAME)[0], app_cache_dir = SOURCE_DIR)

count = 0
retry_count = 0
y = sys.argv[1]

while True:
  mycache['test'] = y
  mycache.sync()
  x = mycache['test']
  if x is None:
    print('FAILED', count, x)
  else:
    print('SUCCEED', count, x)
    retry_count = 0

  retry_count += 1
  if retry_count % 10 == 0:
    # give to scheduler a break
    print('sleep 1')
    time.sleep(.02)

  count += 1
