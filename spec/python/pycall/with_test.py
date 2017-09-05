class test_context(object):
  def __init__(self, value):
    self.enter_called = False
    self.exit_called = False
    self.exit_value = None
    self.value = value
    pass

  def __enter__(self):
    self.enter_called = True
    return self.value

  def __exit__(self, exc_type, exc_value, traceback):
    self.exit_called = (exc_type, exc_value, traceback)
    return self.exit_value

  def error(self, message):
    raise Exception(message)
