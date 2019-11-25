def test_inc1_global_data1():
  # dependent on a declaration order in case of a direct usage (not through the `globals()['...']`), so must always be to avoid a dependence
  global test_inc1_data1

  assert(test_inc1_data1 == [1, 2])

  test_inc1_data1 += [3, 4]

def test_inc1_global_data2():
  # another form of usage, declaration is not required here, but a global variable won't be visible from the function

  try:
    assert(test_inc1_data2 == None)
  except:
    pass

def test_inc1_global_data3():
  # corrected form of the `test_inc1_global_data2`
  global test_inc1_data3

  try:
    assert(test_inc1_data3 == [1, 2])
    test_inc1_data3 += [3, 4]
  except:
    pass

def test_inc1_global_data4():
  # no need a global declaration at all, because of a dynamic access through the dictionary

  current_globals = globals()

  assert(current_globals['test_inc1_data4'] == [1, 2])

  current_globals['test_inc1_data4'] += [3, 4]
