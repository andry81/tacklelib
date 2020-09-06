import os

def __init__():
  # init script search logic
  for i in ['..', '../..']:
    for j in ['__init__/__init__.xsh', '__init__.xsh']:
      import_file_path = os.path.abspath(os.path.join(SOURCE_DIR, i, j)).replace('\\', '/')
      if import_file_path.casefold() != SOURCE_FILE.casefold() and os.path.isfile(import_file_path):
        tkl_source_module(SOURCE_DIR + '/' + i, j)
        return

__init__()
