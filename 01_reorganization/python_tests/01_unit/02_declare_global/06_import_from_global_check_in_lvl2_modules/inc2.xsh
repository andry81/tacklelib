def test_inc2_global_data1():
  global test_inc1_data1
  assert(globals()['test_inc1_data1'] == [1, 2])
  assert(test_inc1_data1 == [1, 2])
  test_inc1_data1 += [3, 4]
