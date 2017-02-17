module PyCall
  private_class_method def self.__initialize_pycall__
    initialized = (0 != PyCall::LibPython.Py_IsInitialized())
    return if initialized

    PyCall::LibPython.Py_InitializeEx(0)

    @builtin = LibPython.PyImport_ImportModule(PYTHON_VERSION < '3.0.0' ? '__builtin__' : 'builtins')
  end

  class << self
    attr_reader :builtin
  end

  __initialize_pycall__
end
