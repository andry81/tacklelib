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
Call "$PYTHON_EXE_PATH" -m pip install win_unicode_console --upgrade || exit
Call "$PYTHON_EXE_PATH" -m pip install prompt-toolkit --upgrade || exit
Call "$PYTHON_EXE_PATH" -m pip install xonsh --upgrade || exit
Call "$PYTHON_EXE_PATH" -m pip install plumbum --upgrade || exit
Call "$PYTHON_EXE_PATH" -m pip install pyyaml --upgrade || exit
Call "$PYTHON_EXE_PATH" -m pip install conditional --upgrade || exit
Call "$PYTHON_EXE_PATH" -m pip install pytest --upgrade || exit
