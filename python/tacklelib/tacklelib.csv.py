# pure python module for commands w/o extension modules usage

import csv, io

class CsvListBaseReader:
  @staticmethod
  def _decomment(csv_file):
    for row in csv_file:
        raw = row.split('#')[0].strip()
        if raw:
          yield raw

class CsvListBaseFileReader(CsvListBaseReader):
  def __init__(self, file_path, fieldnames, dialect):
    self.file = open(file_path, newline='')
    # decomment based on: https://stackoverflow.com/questions/14158868/python-skip-comment-lines-marked-with-in-csv-dictreader/50592259#50592259
    self.dict_reader = csv.DictReader(CsvListBaseReader._decomment(self.file), fieldnames = fieldnames, dialect = dialect)
    self.fieldnames = fieldnames
    self.dialect = dialect
    self.is_next_called = False

  def __copy__(self):
    return type(self)(self.file_path, self.fieldnames, self.dialect)

  def __enter__(self):
    return self

  def __exit__(self, exc_type, exc_value, trackback):
    self.close()

  def __iter__(self):
    return self

  def __next__(self):
    self.is_next_called = True
    return self.dict_reader.__next__()

  def close(self):
    if self.dict_reader:
      self.dict_reader = None
    if self.file:
      self.file.close()
      self.file = None

  def reset(self):
    # We can not use `file.tell` directly in the `reset` method  because of this: `OSError: telling position disabled by next() call`
    # Instead do override the `__next__` and `__iter__` methods to detect the started iteration.
    #
    if self.is_next_called or self.file.tell():
      self.file.seek(0)
      self.dict_reader = csv.DictReader(CsvListBaseReader._decomment(self.file), fieldnames = self.fieldnames, dialect = self.dialect)

class CsvListBaseStrReader(CsvListBaseReader):
  def __init__(self, str, fieldnames, dialect):
    self.str = str
    # decomment based on: https://stackoverflow.com/questions/14158868/python-skip-comment-lines-marked-with-in-csv-dictreader/50592259#50592259
    self.dict_reader = csv.DictReader(CsvListBaseReader._decomment(io.StringIO(self.str)), fieldnames = fieldnames, dialect = dialect)
    self.fieldnames = fieldnames
    self.dialect = dialect

  def __enter__(self):
    return self

  def __exit__(self, exc_type, exc_value, trackback):
    self.close()

  def __iter__(self):
    return self.dict_reader

  def close(self):
    if self.dict_reader:
      self.dict_reader = None
    self.str = None

  def reset(self):
    self.dict_reader = csv.DictReader(CsvListBaseFileReader._decomment(io.StringIO(self.str)), fieldnames = self.fieldnames, dialect = self.dialect)
