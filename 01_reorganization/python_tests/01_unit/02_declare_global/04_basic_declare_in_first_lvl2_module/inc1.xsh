test_inc1_data1 = [0, 0]

tkl_declare_global('test_inc1_data1', [1, 2]) # will overwrite the previous variable

test_inc1_data1 += [3, 4]

tkl_declare_global('test_inc1_data2', [1, 2])

test_inc1_data2 += [3, 4]

tkl_declare_global('test_inc1_data3', [1, 2])

def test_inc1_global_data3():
  global test_inc1_data3
  test_inc1_data3 += [3, 4]

  assert(globals()['test_inc1_data3'] == [1, 2, 3, 4])

def test_inc1_global_data4():
  tkl_declare_global('test_inc1_data4', [1, 2])

  global test_inc1_data4 # is required in a function
  test_inc1_data4 += [3, 4]

  assert(globals()['test_inc1_data4'] == [1, 2, 3, 4])

def test_inc1_global_data5():
  tkl_declare_global('test_inc1_data5', [0, 0])
  tkl_declare_global('test_inc1_data5', [1, 2]) # will overwrite the previous variable

  global test_inc1_data5 # is required in a function
  test_inc1_data5 += [3, 4]

  assert(globals()['test_inc1_data5'] == [1, 2, 3, 4])

def test_inc1_global_data6():
  global test_inc1_data6 # is required in a function
  test_inc1_data6 = [0, 0]

  tkl_declare_global('test_inc1_data6', [1, 2]) # will overwrite the previous variable

  test_inc1_data6 += [3, 4]

  assert(globals()['test_inc1_data6'] == [1, 2, 3, 4])
