def test_inc1_global_data1():
  tkl_declare_global('test_inc1_data1', [1, 2])

  global test_inc1_data1
  assert(globals()['test_inc1_data1'] == [1, 2])
  assert(test_inc1_data1 == [1, 2])
