test_inc2_data1 = [0, 0]

tkl_declare_global('test_inc2_data1', [3, 4]) # will overwrite the previous variable

test_inc2_data1 += [5, 6]

tkl_declare_global('test_inc2_data2', [3, 4])

test_inc2_data2 += [5, 6]

tkl_declare_global('test_inc2_data3', [3, 4])

def test_inc2_global_data3():
  global test_inc2_data3
  test_inc2_data3 += [5, 6]

  assert(globals()['test_inc2_data3'] == [3, 4, 5, 6])

def test_inc2_global_data4():
  tkl_declare_global('test_inc2_data4', [3, 4])

  global test_inc2_data4 # is required in a function
  test_inc2_data4 += [5, 6]

  assert(globals()['test_inc2_data4'] == [3, 4, 5, 6])

def test_inc2_global_data5():
  tkl_declare_global('test_inc2_data5', [0, 0])
  tkl_declare_global('test_inc2_data5', [3, 4]) # will overwrite the previous variable

  global test_inc2_data5 # is required in a function
  test_inc2_data5 += [5, 6]

  assert(globals()['test_inc2_data5'] == [3, 4, 5, 6])

def test_inc2_global_data6():
  global test_inc2_data6 # is required in a function
  test_inc2_data6 = [0, 0]

  tkl_declare_global('test_inc2_data6', [3, 4]) # will overwrite the previous variable

  test_inc2_data6 += [5, 6]

  assert(globals()['test_inc2_data6'] == [3, 4, 5, 6])
