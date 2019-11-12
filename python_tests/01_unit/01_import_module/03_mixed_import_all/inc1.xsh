import os, inspect

THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

assert(SOURCE_DIR == THIS_TEST_ROOT)
assert(SOURCE_FILE == THIS_TEST_FILE)

tkl_import_module(SOURCE_DIR, 'inc2.xsh', 'aaa')

THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

assert(SOURCE_DIR == THIS_TEST_ROOT)
assert(SOURCE_FILE == THIS_TEST_FILE)

def inc1():
  print("inc1")

aaa.inc2()
aaa.inc3()
aaa.bbb.inc4()
print("-")
