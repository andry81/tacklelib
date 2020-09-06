# pure python module for commands w/o extension modules usage

import os, tempfile

# based on: https://stackoverflow.com/questions/2929899/cross-platform-dev-null-in-python/2930038#2930038
#
class devnull:
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

  def read(self, size = -1):
    raise IOError("Invalid operation")

  def readline(self):
    raise IOError("Invalid operation")

  def readlines(self, *args):
    raise IOError("Invalid operation")

  def xreadlines(self, *args):
    raise IOError("Invalid operation")

  def seek(self, *args):
    raise IOError("Invalid operation")

  def tell(self):
    return 0

  def truncate(self, *args):
    pass

  def write(self, *args):
    pass

  def writelines(self, *args):
    pass

  def readable(self):
    return True

  def writable(self):
    return True

  def seekable(self):
    return False

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
    self.closed = True

  def fileno(self):
    # nothing can do, needs to open the real file here
    if not self.file:
      self.file = open(os.devnull, 'wb')
    return self.file.fileno()

class TmpFileIO:
  def __init__(self, mode = 'r', buffering = -1, encoding = None, errors = None, newline = None, closefd = True, opener = None):
    self.fd, self.path = tempfile.mkstemp()
    self.file = None
    try:
      self.file = os.fdopen(self.fd, mode = mode, buffering = buffering, encoding = encoding,
        errors = errors, newline = newline, closefd = closefd, opener = opener)
    except OSError:
      self.close()
      raise

  def flush(self):
    if self.file:
      self.file.flush()

  def next(self):
    return self.file.next(self)

  def read(self, size = -1):
    return self.file.read(size)

  def readline(self):
    return self.file.readline()

  def readlines(self, *args):
    return self.file.readlines(*args)

  def xreadlines(self, *args):
    return self.file.xreadlines(*args)

  def seek(self, *args):
    return self.file.seek(*args)

  def tell(self):
    return self.file.tell()

  def truncate(self, *args):
    return self.file.truncate(*args)

  def write(self, *args):
    return self.file.write(*args)

  def writelines(self, *args):
    return self.file.writelines(*args)

  def readable(self):
    return self.file.readable()

  def writable(self):
    return self.file.writable()

  def seekable(self):
    return self.file.seekable()

  def __enter__(self):
    return self

  def __exit__(self, exc_type, exc_value, trackback):
    self.close()

  def __del__(self):
    self.close()

  def __iter__(self):
    return self.file

  def close(self):
    if self.file:
      self.file.close()
      self.file = None
    self.fd = None
    if not self.path is None:
      os.unlink(self.path)
      self.path = None

  def fileno(self):
    return self.file.fileno()
