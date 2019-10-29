# pure python module for commands w/o extension modules usage

import os, sys

# error print
def print_err(*args, **kwargs):
  print(*args, file = sys.stderr, **kwargs)

# based on: https://stackoverflow.com/questions/2929899/cross-platform-dev-null-in-python/2930038#2930038
class devnull():
  def __init__(self, *args):
    self.closed = False
    self.mode = "wb"
    self.name = "<null>"
    self.encoding = None
    self.errors = None
    self.newlines = None
    self.softspace = 0
    self.file = None

  def flush(self):
    if self.file:
      self.flush()

  def next(self):
    raise IOError("Invalid operation")

  def read(size = 0):
    raise IOError("Invalid operation")

  def readline(self):
    raise IOError("Invalid operation")

  def readlines(self):
    raise IOError("Invalid operation")

  def xreadlines(self):
    raise IOError("Invalid operation")

  def seek(self):
    raise IOError("Invalid operation")

  def tell(self):
    return 0

  def truncate(self, *args):
    pass

  def write(self, *args):
    pass

  def writelines(self, *args):
    pass

  def __enter__(self):
    return self

  def __exit__(self, exc_type, exc_value, trackback):
    self.close()

  def __del__(self):
    self.close()

  def close(self):
    if self.file:
      self.file.close()
      self.file = None
    self.closed == True

  def fileno(self):
    # nothing can do, needs to open the real file here
    if not self.file:
      self.file = open(os.devnull, 'wb')
    return self.file.fileno()

class OnExit:
  def __init__(self, on_exit_pred = None):
    self.on_exit_pred = on_exit_pred
  def __enter__(self):
    return self
  def __exit__(self, type, value, tb):
    if self.on_exit_pred:
      self.on_exit_pred()
