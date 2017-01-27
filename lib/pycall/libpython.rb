require 'ffi'

module PyCall
  module LibPython
    extend FFI::Library

    private_class_method

    def self.find_libpython(python = nil)
      python ||= 'python'
      python_config = investigate_python_config(python)

      v = python_config[:VERSION]
      libprefix = FFI::Platform::LIBPREFIX
      libs = [ "#{libprefix}python#{v}", "#{libprefix}python" ]
      lib = python_config[:LIBRARY]
      libs.unshift(File.basename(lib, File.extname(lib))) if lib
      lib = python_config[:LDLIBRARY]
      libs.unshift(lib, File.basename(lib)) if lib
      libs.uniq!

      executable = python_config[:executable]
      libpaths = [ python_config[:LIBDIR] ]
      if FFI::Platform.windows?
        libpaths << dirname(executable)
      else
        libpaths << File.expand_path('../../lib', executable)
      end
      libpaths << python_config[:PYTHONFRAMEWORKPREFIX] if FFI::Platform.mac?

      exec_prefix = python_config[:exec_prefix]
      libpaths << exec_prefix << File.join(exec_prefix, 'lib')

      unless ENV['PYTHONHOME']
        # PYTHONHOME tells python where to look for both pure python and binary modules.
        # When it is set, it replaces both `prefix` and `exec_prefix`
        # and we thus need to set it to both in case they differ.
        # This is also what the documentation recommends.
        # However, they are documented to always be the same on Windows,
        # where it causes problems if we try to include both.
        if FFI::Platform.windows?
          ENV['PYTHONHOME'] = exec_prefix
        else
          ENV['PYTHONHOME'] = [python_config[:prefix], exec_prefix].join(':')
        end

        # Unfortunately, setting PYTHONHOME screws up Canopy's Python distribution?
        unless system(python, '-c', 'import site', out: File::NULL, err: File::NULL)
          ENV['PYTHONHOME'] = nil
        end
      end

      # Find libpython (we hope):
      libsuffix = FFI::Platform::LIBSUFFIX
      libs.each do |lib|
        libpaths.each do |libpath|
          libpath_lib = File.join(libpath, lib)
          if File.file?("#{libpath_lib}.#{libsuffix}")
            libs = ffi_lib("#{libpath_lib}.#{libsuffix}")
            return libs.first
          end
        end
      end
    end

    def self.investigate_python_config(python)
      python_env = { 'PYTHONIOENCODING' => 'UTF-8' }
      IO.popen(python_env, [python, python_investigator_py], 'r') do |io|
        {}.tap do |config|
          io.each_line do |line|
            key, value = line.chomp.split(': ', 2)
            config[key.to_sym] = value
          end
        end
      end
    end

    def self.python_investigator_py
      File.expand_path('../python/investigator.py', __FILE__)
    end

    class PyObject_struct < FFI::Struct
      layout ob_refcnt: :int,
             ob_type:   :pointer
    end

    ffi_lib_flags :lazy, :global
    libpython = find_libpython ENV['PYTHON']

    # --- global variables ---

    attach_variable :_Py_NoneStruct, PyObject_struct

    def self.Py_None
      _Py_NoneStruct.to_ptr
    end

    if libpython.find_variable('PyInt_Type')
      has_PyInt_Type = true
      attach_variable :PyInt_Type, PyObject_struct
    else
      has_PyInt_Type = false
      attach_variable :PyInt_Type, :PyLong_Type, PyObject_struct
    end

    attach_variable :PyLong_Type, PyObject_struct
    attach_variable :PyBool_Type, PyObject_struct
    attach_variable :PyFloat_Type, PyObject_struct
    attach_variable :PyComplex_Type, PyObject_struct
    attach_variable :PyUnicode_Type, PyObject_struct

    if libpython.find_symbol('PyString_FromStringAndSize')
      string_as_bytes = false
      attach_variable :PyString_Type, PyObject_struct
    else
      string_as_bytes = true
      attach_variable :PyString_Type, :PyBytes_Type, PyObject_struct
    end

    attach_variable :PyList_Type, PyObject_struct
    attach_variable :PyTuple_Type, PyObject_struct

    # --- functions ---

    attach_function :Py_GetVersion, [], :string

    # Py_InitializeEx :: (int) -> void
    attach_function :Py_InitializeEx, [:int], :void

    # Py_IsInitialized :: () -> int
    attach_function :Py_IsInitialized, [], :int

    # PyObject_IsInstane :: (PyPtr, PyPtr) -> int
    attach_function :PyObject_IsInstance, [:pointer, :pointer], :int

    # PyInt_AsSsize_t :: (PyPtr) -> ssize_t
    if has_PyInt_Type
      attach_function :PyInt_AsSsize_t, [:pointer], :ssize_t
    else
      attach_function :PyInt_AsSsize_t, :PyLong_AsSsize_t, [:pointer], :ssize_t
    end

    # PyFloat_AsDouble :: (PyPtr) - double
    attach_function :PyFloat_AsDouble, [:pointer], :double

    # PyComplex_RealAsDouble :: (PyPtr) -> double
    attach_function :PyComplex_RealAsDouble, [:pointer], :double

    # PyComplex_ImagAsDouble :: (PyPtr) -> double
    attach_function :PyComplex_ImagAsDouble, [:pointer], :double

    # PyString_AsStringAndSize :: (PyPtr, char**, int*) -> int
    if string_as_bytes
      attach_function :PyString_AsStringAndSize, :PyBytes_AsStringAndSize, [:pointer, :pointer, :pointer], :int
    else
      attach_function :PyString_AsStringAndSize, [:pointer, :pointer, :pointer], :int
    end

    # PyUnicode_AsUTF8String :: (PyPtr) -> PyPtr
    case
    when libpython.find_symbol('PyUnicode_AsUTF8String')
      attach_function :PyUnicode_AsUTF8String, [:pointer], :pointer
    when libpython.find_symbol('PyUnicodeUCS4_AsUTF8String')
      attach_function :PyUnicode_AsUTF8String, :PyUnicodeUCS4_AsUTF8String, [:pointer], :pointer
    when libpython.find_symbol('PyUnicodeUCS2_AsUTF8String')
      attach_function :PyUnicode_AsUTF8String, :PyUnicodeUCS2_AsUTF8String, [:pointer], :pointer
    end

    # PySequence_Size :: (PyPtr) -> ssize_t
    attach_function :PySequence_Size, [:pointer], :ssize_t

    # PySequence_GetItem :: (PyPtr, ssize_t) -> PyPtr
    attach_function :PySequence_GetItem, [:pointer, :ssize_t], :pointer

    # PyModule_GetDict :: (PyPtr) -> PyPtr
    attach_function :PyModule_GetDict, [:pointer], :pointer

    # PyImport_ImportModule :: (char const*) -> PyPtr
    attach_function :PyImport_ImportModule, [:string], :pointer

    # Py_CompileString :: (char const*, char const*, int) -> PyPtr
    attach_function :Py_CompileString, [:string, :string, :int], :pointer

    # PyEval_EvalCode :: (PyPtr, PyPtr, PyPtr) -> PyPtr
    attach_function :PyEval_EvalCode, [:pointer, :pointer, :pointer], :pointer

    # PyErr_Print :: () -> Void
    attach_function :PyErr_Print, [], :void

    public_class_method
  end
end
