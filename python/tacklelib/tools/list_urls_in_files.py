import os, sys, inspect, io, argparse

SOURCE_FILE = os.path.abspath(inspect.getsourcefile(lambda:0)).replace('\\','/')
SOURCE_DIR = os.path.dirname(SOURCE_FILE)
SOURCE_FILE_NAME = os.path.split(SOURCE_FILE)[1]

# portable import to the global space
sys.path.append(SOURCE_DIR + '/..')
import tacklelib as tkl

tkl.tkl_init(tkl)

# cleanup
del tkl # must be instead of `tkl = None`, otherwise the variable would be still persist
sys.path.pop()

tkl_import_module(SOURCE_DIR + '/..', 'tacklelib.url.py', 'tkl')

CHECKED_URLS = []

# sort_by:
#   `line`  -  sort by lines in a file
#   `url`   -  sort by url in a file
#
def parse_dir(dir_path, sort_by = 'line'):
  for dirpath, dirs, files in os.walk(dir_path):
    for dir in dirs:
      # ignore directories beginning by '.'
      if str(dir)[0:1] == '.':
        continue
      parse_dir(os.path.join(dirpath, dir), sort_by = sort_by)
    dirs.clear() # not recursively

    for file_name in files:
      file_path = os.path.join(dirpath, file_name).replace('\\','/')
      with open(file_path, 'rb') as file: # CAUTION: binary mode is required to correctly decode string into `utf-8` below
        file_content = file.read()

        is_file_path_printed = False

        # item: (<url>, <line_number>)
        unique_file_urls = []

        # CAUTION:
        #   Do decode with explicitly stated encoding to avoid the error:
        #   `UnicodeDecodeError: 'charmap' codec can't decode byte ... in position ...: character maps to <undefined>`
        #   (see details: https://stackoverflow.com/questions/27453879/unicode-decode-error-how-to-skip-invalid-characters/27454001#27454001 )
        #
        file_content_decoded = file_content.decode('utf-8', errors='ignore')

        # To iterate over lines instead chars.
        # (see details: https://stackoverflow.com/questions/3054604/iterate-over-the-lines-of-a-string/3054898#3054898 )
        file_strings = io.StringIO(file_content_decoded)

        line_number = 1
        for line in file_strings:
          urls = tkl.extract_urls(line)
          for url in urls:
            if not is_file_path_printed:
              print('{0}:'.format(file_path))
              is_file_path_printed = True

            if not url in CHECKED_URLS:
              # check url here...
              CHECKED_URLS.append(url)

            if not url in unique_file_urls:
              unique_file_urls.append((url, line_number))

          line_number += 1

        if sort_by == 'line':
          unique_file_urls.sort(key=lambda tup: tup[1])
        elif sort_by == 'url':
          unique_file_urls.sort(key=lambda tup: tup[0])
        else:
          # sort by lines by default
          unique_file_urls.sort(key=lambda tup: tup[1])

        for url, line_number in unique_file_urls:
          print('  * {0} -> {1}'.format(line_number, url))

if __name__ == '__main__':
  # parse arguments
  arg_parser = argparse.ArgumentParser()
  arg_parser.add_argument('dir_path', type = str)
  arg_parser.add_argument('--sort_by', type = str)
  args = arg_parser.parse_args(sys.argv[1:])

  DIR_PATH = args.dir_path.replace('\\', '/')

  if not os.path.isdir(DIR_PATH):
    tkl.print_err("{0}: error: argv[1] directory does not exist: `{1}`.".format(SOURCE_FILE_NAME, DIR_PATH))
    sys.exit(1)

  parse_dir(DIR_PATH, sort_by = args.sort_by)

  sys.exit(0)
