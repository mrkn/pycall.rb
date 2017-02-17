module PyCall
  private_class_method def self.__initialize_pycall__
    initialized = (0 != PyCall::LibPython.Py_IsInitialized())
    return if initialized

    PyCall::LibPython.Py_InitializeEx(0)
  end

  __initialize_pycall__
end
