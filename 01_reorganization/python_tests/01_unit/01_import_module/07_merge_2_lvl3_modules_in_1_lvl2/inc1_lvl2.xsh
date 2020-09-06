tkl_import_module(SOURCE_DIR, 'inc1_lvl3.xsh', 'common_module')

assert(hasattr(common_module, 'test1'))
assert('test1' in vars(common_module))

assert(hasattr(common_module, 'Test1'))
assert('Test1' in vars(common_module))

assert(hasattr(common_module.Test1, 'test1'))
assert(hasattr(vars(common_module)['Test1'], 'test1'))

assert(common_module.Test1.test1 == [1, 2])
assert(vars(common_module)['Test1'].test1 == [1, 2])

common_module.test1()

# must be merge into already existed module

tkl_import_module(SOURCE_DIR, 'inc2_lvl3.xsh', 'common_module')

assert(hasattr(common_module, 'test1'))
assert(hasattr(common_module, 'test2'))
assert('test1' in vars(common_module))
assert('test2' in vars(common_module))

assert(hasattr(common_module, 'Test1'))
assert(hasattr(common_module, 'Test2'))
assert('Test1' in vars(common_module))
assert('Test2' in vars(common_module))

assert(hasattr(common_module.Test1, 'test1'))
assert(hasattr(common_module.Test2, 'test2'))
assert(hasattr(vars(common_module)['Test1'], 'test1'))
assert(hasattr(vars(common_module)['Test2'], 'test2'))

assert(common_module.Test1.test1 == [1, 2])
assert(common_module.Test2.test2 == [3, 4])
assert(vars(common_module)['Test1'].test1 == [1, 2])
assert(vars(common_module)['Test2'].test2 == [3, 4])

common_module.test1()
common_module.test2()
