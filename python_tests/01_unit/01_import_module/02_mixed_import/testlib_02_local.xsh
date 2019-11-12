import os, inspect

THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

assert(SOURCE_DIR == THIS_TEST_ROOT)
assert(SOURCE_FILE == THIS_TEST_FILE)

tkl_source_module(SOURCE_DIR, 'testlib.test.py')

THIS_TEST_FILE = os.path.normcase(os.path.abspath(inspect.getsourcefile(lambda:0))).replace('\\','/')
THIS_TEST_ROOT = os.path.dirname(SOURCE_FILE)

assert(SOURCE_DIR == THIS_TEST_ROOT)
assert(SOURCE_FILE == THIS_TEST_FILE)

print(globals().keys())

testlib_test()
