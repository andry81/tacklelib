# pure python module for commands w/o extension modules usage

import os, sys, re

# error print
def print_err(*args, **kwargs):
  print(*args, file = sys.stderr, **kwargs)

def extract_urls(str):
  urls = re.findall('http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+', str.lower())
  urls_arr = []
  for url in urls:
    lastChar = url[-1] # get the last character
    # if the last character is not (^ - not) an alphabet, or a number,
    # or a '/' (some websites may have that. you can add your own ones), then enter IF condition
    if (bool(re.match(r'[^a-zA-Z0-9/]', lastChar))): 
      urls_arr.append(url[:-1]) # stripping last character, no matter what
    else:
      urls_arr.append(url) # else, simply append to new list
  return urls_arr

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
