# The `cd(newdir)` function for python command line.
# Based on:
#   https://stackoverflow.com/questions/431684/equivalent-of-shell-cd-command-to-change-the-working-directory/24176022#24176022

from contextlib import contextmanager
import os
import shutil
import tempfile

@contextmanager
def cd(newdir, cleanup_from_prevdir=lambda: True, cleanup_from_newdir=lambda: True):
    prevdir = os.getcwd()
    # Windows: will be unlocked from delete in `cleanup_from_prevdir()`
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        cleanup_from_newdir()
        os.chdir(prevdir)
        cleanup_from_prevdir()

@contextmanager
def cd_tempdir():
    dirpath = tempfile.mkdtemp()
    def cleanup_from_prevdir():
        shutil.rmtree(dirpath)
    with cd(dirpath, cleanup_from_prevdir):
        yield dirpath
