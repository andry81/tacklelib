# not a true global, does nothing without initilization
global test_data1
global test_data2

def test_global_data1():
  assert('test_data1' not in globals())

  test_data1 = [3, 4] # does local change, not a global

  assert('test_data1' not in globals())

def test_global_data2():
  assert('test_data2' not in globals())

  test_data2 = [3, 4] # does local change, not a global

  assert('test_data2' not in globals())

def test_global_data3():
  global test_data3 # still is global in a module

  assert('test_data3' not in globals())

  test_data3 = [3, 4] # won't be visible outside the module

  assert(globals()['test_data3'] == [3, 4])

def test_global_data4():
  global test_data4 # still is global in a module

  assert('test_data4' not in globals())

  test_data4 = [3, 4] # won't be visible outside the module

  assert(globals()['test_data4'] == [3, 4])
