# python module for commands with extension modules usage: tacklelib, csv

import csv

tkl_source_module(SOURCE_DIR, 'cmdoplib.csv.xsh')

class GitReposListReaderDialect(csv.Dialect):
  delimiter = '|'
  quotechar = '"'
  doublequote = True
  skipinitialspace = True
  lineterminator = '\r\n'
  quoting = csv.QUOTE_MINIMAL

csv.register_dialect('git_repos_list', GitReposListReaderDialect)

class GitLsRemoteReaderDialect(csv.Dialect):
  delimiter = '\t'
  quotechar = '"'
  doublequote = True
  skipinitialspace = True
  lineterminator = '\r\n'
  quoting = csv.QUOTE_MINIMAL

csv.register_dialect('git_ls_remote', GitLsRemoteReaderDialect)

class GitShowRefReaderDialect(csv.Dialect):
  delimiter = ' '
  quotechar = '"'
  doublequote = True
  skipinitialspace = True
  lineterminator = '\r\n'
  quoting = csv.QUOTE_MINIMAL

csv.register_dialect('git_show_ref', GitShowRefReaderDialect)

class GitReposListReader(tkl.CsvListBaseFileReader):
  def __init__(self, file_path, fieldnames =
      ['scm_token', 'branch_type', 'remote_name', 'parent_remote_name', 'git_reporoot', 'svn_reporoot', 'local_branch', 'remote_branch', 'parent_git_path_prefix', 'svn_path_prefix', 'git_remote_add_cmdline', 'git_subtree_cmdline'],
      dialect = 'git_repos_list'):
    tkl.CsvListBaseFileReader.__init__(self, file_path, fieldnames, dialect)

class GitLsRemoteListReader(tkl.CsvListBaseStrReader):
  def __init__(self, str, fieldnames = ['hash', 'ref'], dialect = 'git_ls_remote'):
    tkl.CsvListBaseStrReader.__init__(self, str, fieldnames, dialect)

class GitShowRefListReader(tkl.CsvListBaseStrReader):
  def __init__(self, str, fieldnames = ['hash', 'ref'], dialect = 'git_show_ref'):
    tkl.CsvListBaseStrReader.__init__(self, str, fieldnames, dialect)

