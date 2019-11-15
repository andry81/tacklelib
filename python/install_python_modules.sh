#!/bin/bash

PYTHON_EXE_PATH=python3

function Call()
{
  echo ">$@"
  echo
  "$@"
}

Call "$PYTHON_EXE_PATH" -m pip install pip --upgrade || exit
Call "$PYTHON_EXE_PATH" -m pip install setuptools --upgrade || exit
Call "$PYTHON_EXE_PATH" -m pip install win_unicode_console --upgrade
Call "$PYTHON_EXE_PATH" -m pip install prompt-toolkit --upgrade
Call "$PYTHON_EXE_PATH" -m pip install xonsh --upgrade
Call "$PYTHON_EXE_PATH" -m pip install plumbum --upgrade
Call "$PYTHON_EXE_PATH" -m pip install pyyaml --upgrade
Call "$PYTHON_EXE_PATH" -m pip install conditional --upgrade
Call "$PYTHON_EXE_PATH" -m pip install fcache --upgrade
Call "$PYTHON_EXE_PATH" -m pip install pytest --upgrade
