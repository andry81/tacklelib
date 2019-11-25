def foo():
  pass

class B():
  def b(self):
    foo() # initially is in the `globals()` of the module `inc2.py` and should stay in it as is
