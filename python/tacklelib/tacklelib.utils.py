# pure python module for commands w/o extension modules usage

import sys, platform, io

# error print
def print_err(*args, **kwargs):
  print(*args, file = sys.stderr, **kwargs)

class OnExit:
  def __init__(self, on_exit_pred = None):
    self.on_exit_pred = on_exit_pred
  def __enter__(self):
    return self
  def __exit__(self, type, value, tb):
    if self.on_exit_pred:
      self.on_exit_pred()

# based on: https://stackoverflow.com/questions/6797984/how-do-i-lowercase-a-string-in-python/31599276#31599276
#
def compare_file_paths(p1, p2, op = '=='):
  p1_ = p1.replace('\\', '/')
  p2_ = p2.replace('\\', '/')
  if platform.system() == 'Windows':
    p1_ = p1_.casefold()
    p2_ = p2_.casefold()

  return eval('"' + p1_ + '" ' + op + ' "' + p2_ + '"')

def print_max(str, max_lines = 9):
  if max_lines >= 0:
    num_new_lines = str.count('\n')
    if num_new_lines > max_lines:
      line_index = 0

      # To iterate over lines instead chars.
      # (see details: https://stackoverflow.com/questions/3054604/iterate-over-the-lines-of-a-string/3054898#3054898 )

      half_lines = int(max_lines / 2)
      for line in io.StringIO(str):
        if line_index < half_lines or line_index >= num_new_lines - half_lines: # excluding the last line return
          print(line.rstrip())
        elif line_index == half_lines:
          print('...')
        line_index += 1
    elif len(str) > 0:
      print(str)
  elif len(str) > 0:
    print(str)
