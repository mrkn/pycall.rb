module PyCall
  private_class_method def self.__initialize_pycall__
    initialized = (0 != PyCall::LibPython.Py_IsInitialized())
    return if initialized

    PyCall::LibPython.Py_InitializeEx(0)

    FFI::MemoryPointer.new(:pointer, 1) do |argv|
      argv.write_pointer(FFI::MemoryPointer.from_string(""))
      PyCall::LibPython.PySys_SetArgvEx(0, argv, 0)
    end

    @builtin = LibPython.PyImport_ImportModule(PYTHON_VERSION < '3.0.0' ? '__builtin__' : 'builtins').to_ruby

    begin
      import_module('stackless')
      @has_stackless_extension = true
    rescue PyError
      @has_stackless_extension = false
    end

    __initialize_ruby_wrapper__
  end

  class << self
    attr_reader :builtin
    attr_reader :has_stackless_extension
  end

  __initialize_pycall__
end
