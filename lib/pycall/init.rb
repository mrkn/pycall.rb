initialized = (0 != PyCall::LibPython.Py_IsInitialized())

unless initialized
  PyCall::LibPython.Py_InitializeEx(0)
end
