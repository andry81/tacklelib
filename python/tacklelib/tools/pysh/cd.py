# The `cd(newdir)` function for python command line.
# Based on:
#   https://stackoverflow.com/questions/431684/equivalent-of-shell-cd-command-to-change-the-working-directory/24176022#24176022

from contextlib import contextmanager
import os

@contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)
