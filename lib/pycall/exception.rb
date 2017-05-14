require 'pycall'

module PyCall
  @exceptions = {
    Exception => LibPython.PyExc_RuntimeError,
    TypeError => LibPython.PyExc_TypeError,
  }.freeze

  def self.raise_python_exception(exception)
    pyexc = @exceptions[exception.class] || @exceptions[Exception]
    LibPython.PyErr_SetString(pyexc, "Ruby exception: #{exception.class}: #{exception.message}")
  end
end
