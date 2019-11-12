# python module for commands with extension modules usage: tacklelib, fcache

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.io.py', 'tkl')
tkl_import_module(TACKLELIB_ROOT, 'tacklelib.utils.py', 'tkl')

from fcache.cache import FileCache as FileCache_
import time
import logging
import platform

class FileCache(FileCache_):
  def __init__(self, appname, flag = 'c', mode = 438, keyencoding = 'utf-8', serialize = True, app_cache_dir = None, no_logger_warnings = True):
    if no_logger_warnings:
      logger = logging.getLogger('fcache.cache')
      logger.setLevel(logging.ERROR)
    FileCache_.__init__(self, appname, flag = flag, mode = mode, keyencoding = keyencoding,
      serialize = serialize, app_cache_dir = app_cache_dir)

  def __enter__(self):
    return self

  def __exit__(self, type, value, tb):
    FileCache_.close(self)

  # CAUTION:
  #   Must be used instead to workaround sync errors on Windows in a multiprocess request
  #
  def sync(self):
    if platform.system() == 'Windows':
      prev_stderr = sys.stderr
      devnull = tkl.devnull()
      with tkl.OnExit(lambda: [None for sys.stderr in [prev_stderr]]):
        retry_count = 0
        while True:
          sys.stderr = devnull
          try:
            return FileCache_.sync(self)
          except OSError as e:
            # OSError: [WinError 6800] The function attempted to use a name that is reserved for use by another transaction: ...
            if isinstance(e, EOFError) or e.args[0] == 6800:
              sys.stderr = prev_stderr
              # retry, has meaning on Windows
              retry_count += 1
              if retry_count % 10 == 0:
                # give to scheduler a break
                time.sleep(0.02)
              continue
    else:
      return FileCache_.sync(self)

  # CAUTION:
  #   Must be used instead to workaround sync errors on Windows in a multiprocess request
  #
  def __getitem__(self, key):
    if platform.system() == 'Windows':
      prev_stderr = sys.stderr
      devnull = tkl.devnull()
      with tkl.OnExit(lambda: [None for sys.stderr in [prev_stderr]]):
        retry_count = 0
        while True:
          sys.stderr = devnull
          try:
            return FileCache_.__getitem__(self, key)
          except (OSError, EOFError) as e:
            # OSError: [WinError 6800] The function attempted to use a name that is reserved for use by another transaction: ...
            # EOFError: Ran out of input (pickle.loads(...))
            if isinstance(e, EOFError) or e.args[0] == 6800:
              sys.stderr = prev_stderr
              # retry, has meaning on Windows
              retry_count += 1
              if retry_count % 10 == 0:
                # give to scheduler a break
                time.sleep(0.02)
              continue
    else:
      return FileCache_.__getitem__(self, key)

  # CAUTION:
  #   Must be used instead to workaround sync errors on Windows in a multiprocess request
  #
  def __setitem__(self, key, value):
    if platform.system() == 'Windows':
      prev_stderr = sys.stderr
      devnull = tkl.devnull()
      with tkl.OnExit(lambda: [None for sys.stderr in [prev_stderr]]):
        retry_count = 0
        while True:
          sys.stderr = devnull
          try:
            return FileCache_.__setitem__(self, key, value)
          except (OSError, EOFError) as e:
            # OSError: [WinError 6800] The function attempted to use a name that is reserved for use by another transaction: ...
            # EOFError: Ran out of input (pickle.loads(...))
            if isinstance(e, EOFError) or e.args[0] == 6800:
              sys.stderr = prev_stderr
              # retry, has meaning on Windows
              retry_count += 1
              if retry_count % 10 == 0:
                # give to scheduler a break
                time.sleep(0.02)
              continue
    else:
      return FileCache_.__setitem__(self, key, value)
