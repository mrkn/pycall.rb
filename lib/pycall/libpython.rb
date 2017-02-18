require 'ffi'

module PyCall
  class PyObject < FFI::Struct
    layout ob_refcnt: :int,
           ob_type:   :pointer
  end

  class PyTypeObject < FFI::Struct
    layout ob_base: PyObject,
           ob_size: :ssize_t,
           tp_name: :string
  end

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

    ffi_lib_flags :lazy, :global
    libpython = find_libpython ENV['PYTHON']

    # --- global variables ---

    attach_variable :_Py_NoneStruct, PyObject

    def self.Py_None
      _Py_NoneStruct
    end

    if libpython.find_variable('PyInt_Type')
      has_PyInt_Type = true
      attach_variable :PyInt_Type, PyTypeObject
    else
      has_PyInt_Type = false
      attach_variable :PyInt_Type, :PyLong_Type, PyTypeObject
    end

    attach_variable :PyLong_Type, PyTypeObject
    attach_variable :PyBool_Type, PyTypeObject
    attach_variable :PyFloat_Type, PyTypeObject
    attach_variable :PyComplex_Type, PyTypeObject
    attach_variable :PyUnicode_Type, PyTypeObject

    if libpython.find_symbol('PyString_FromStringAndSize')
      string_as_bytes = false
      attach_variable :PyString_Type, PyTypeObject
    else
      string_as_bytes = true
      attach_variable :PyString_Type, :PyBytes_Type, PyTypeObject
    end

    attach_variable :PyList_Type, PyTypeObject
    attach_variable :PyTuple_Type, PyTypeObject
    attach_variable :PyDict_Type, PyTypeObject
    attach_variable :PySet_Type, PyTypeObject

    # --- functions ---

    attach_function :Py_GetVersion, [], :string

    # Py_InitializeEx :: (int) -> void
    attach_function :Py_InitializeEx, [:int], :void

    # Py_IsInitialized :: () -> int
    attach_function :Py_IsInitialized, [], :int

    # Comparing two objects
    attach_function :PyObject_RichCompareBool, [PyObject.by_ref, PyObject.by_ref, :int], :int

    # Accessing Object's attributes
    attach_function :PyObject_GetAttrString, [PyObject.by_ref, :string], PyObject.by_ref
    attach_function :PyObject_SetAttrString, [PyObject.by_ref, :string, PyObject.by_ref], :int
    attach_function :PyObject_HasAttrString, [PyObject.by_ref, :string], :int

    # Accessing Object's items
    attach_function :PyObject_GetItem, [PyObject.by_ref, PyObject.by_ref], PyObject.by_ref
    attach_function :PyObject_SetItem, [PyObject.by_ref, PyObject.by_ref, PyObject.by_ref], :int
    attach_function :PyObject_DelItem, [PyObject.by_ref, PyObject.by_ref], :int

    # Calling a object as a function
    attach_function :PyObject_Call, [PyObject.by_ref, PyObject.by_ref, PyObject.by_ref], PyObject.by_ref

    # PyObject_IsInstane :: (PyPtr, PyPtr) -> int
    attach_function :PyObject_IsInstance, [PyObject.by_ref, PyTypeObject.by_ref], :int

    # PyBool_FromLong :: (long) -> PyPtr
    attach_function :PyBool_FromLong, [:long], PyObject.by_ref

    # PyInt_AsSsize_t :: (PyPtr) -> ssize_t
    if has_PyInt_Type
      attach_function :PyInt_AsSsize_t, [PyObject.by_ref], :ssize_t
    else
      attach_function :PyInt_AsSsize_t, :PyLong_AsSsize_t, [PyObject.by_ref], :ssize_t
    end

    # PyInt_FromSsize_t :: (ssize_t) -> PyPtr
    if has_PyInt_Type
      attach_function :PyInt_FromSsize_t, [:ssize_t], PyObject.by_ref
    else
      attach_function :PyInt_FromSsize_t, :PyLong_FromSsize_t, [:ssize_t], PyObject.by_ref
    end

    # PyFloat_FromDouble :: (double) -> PyPtr
    attach_function :PyFloat_FromDouble, [:double], PyObject.by_ref

    # PyFloat_AsDouble :: (PyPtr) -> double
    attach_function :PyFloat_AsDouble, [PyObject.by_ref], :double

    # PyComplex_RealAsDouble :: (PyPtr) -> double
    attach_function :PyComplex_RealAsDouble, [PyObject.by_ref], :double

    # PyComplex_ImagAsDouble :: (PyPtr) -> double
    attach_function :PyComplex_ImagAsDouble, [PyObject.by_ref], :double

    # String

    if string_as_bytes
      attach_function :PyString_FromStringAndSize, :PyBytes_FromStringAndSize, [:string, :ssize_t], PyObject.by_ref
    else
      attach_function :PyString_FromStringAndSize, [:string, :ssize_t], PyObject.by_ref
    end

    # PyString_AsStringAndSize :: (PyPtr, char**, int*) -> int
    if string_as_bytes
      attach_function :PyString_AsStringAndSize, :PyBytes_AsStringAndSize, [PyObject.by_ref, :pointer, :pointer], :int
    else
      attach_function :PyString_AsStringAndSize, [PyObject.by_ref, :pointer, :pointer], :int
    end

    # Unicode

    # PyUnicode_DecodeUTF8
    case
    when libpython.find_symbol('PyUnicode_DecodeUTF8')
      attach_function :PyUnicode_DecodeUTF8, [:string, :ssize_t, :string], PyObject.by_ref
    when libpython.find_symbol('PyUnicodeUCS4_DecodeUTF8')
      attach_function :PyUnicodeUCS4_DecodeUTF8, [:string, :ssize_t, :string], PyObject.by_ref
    when libpython.find_symbol('PyUnicodeUCS2_DecodeUTF8')
      attach_function :PyUnicodeUCS2_DecodeUTF8, [:string, :ssize_t, :string], PyObject.by_ref
    end

    # PyUnicode_AsUTF8String :: (PyPtr) -> PyPtr
    case
    when libpython.find_symbol('PyUnicode_AsUTF8String')
      attach_function :PyUnicode_AsUTF8String, [PyObject.by_ref], PyObject.by_ref
    when libpython.find_symbol('PyUnicodeUCS4_AsUTF8String')
      attach_function :PyUnicode_AsUTF8String, :PyUnicodeUCS4_AsUTF8String, [PyObject.by_ref], PyObject.by_ref
    when libpython.find_symbol('PyUnicodeUCS2_AsUTF8String')
      attach_function :PyUnicode_AsUTF8String, :PyUnicodeUCS2_AsUTF8String, [PyObject.by_ref], PyObject.by_ref
    end

    # Tuple

    attach_function :PyTuple_New, [:ssize_t], PyObject.by_ref
    attach_function :PyTuple_GetItem, [PyObject.by_ref, :ssize_t], PyObject.by_ref
    attach_function :PyTuple_SetItem, [PyObject.by_ref, :ssize_t, PyObject.by_ref], :int
    attach_function :PyTuple_Size, [PyObject.by_ref], :ssize_t

    # List

    attach_function :PyList_New, [:ssize_t], PyObject.by_ref
    attach_function :PyList_Size, [PyObject.by_ref], :ssize_t
    attach_function :PyList_GetItem, [PyObject.by_ref, :ssize_t], PyObject.by_ref
    attach_function :PyList_SetItem, [PyObject.by_ref, :ssize_t, PyObject.by_ref], :int
    attach_function :PyList_Append, [PyObject.by_ref, PyObject.by_ref], :int

    # PySequence_Size :: (PyPtr) -> ssize_t
    attach_function :PySequence_Size, [PyObject.by_ref], :ssize_t

    # PySequence_GetItem :: (PyPtr, ssize_t) -> PyPtr
    attach_function :PySequence_GetItem, [PyObject.by_ref, :ssize_t], PyObject.by_ref

    # Dict

    attach_function :PyDict_New, [], PyObject.by_ref

    # PyDict_GetItem :: (PyPtr, PyPtr) -> PyPtr
    attach_function :PyDict_GetItem, [PyObject.by_ref, PyObject.by_ref], PyObject.by_ref

    # PyDict_GetItemString :: (PyPtr, char const*) -> PyPtr
    attach_function :PyDict_GetItemString, [PyObject.by_ref, :string], PyObject.by_ref

    # PyDict_SetItem :: (PyPtr, PyPtr, PyPtr) -> int
    attach_function :PyDict_SetItem, [PyObject.by_ref, PyObject.by_ref, PyObject.by_ref], :int

    # PyDict_SetItemString :: (PyPtr, char const*, PyPtr) -> int
    attach_function :PyDict_SetItemString, [PyObject.by_ref, :string, PyObject.by_ref], :int

    # PyDict_DelItem :: (PyPtr, PyPtr) -> int
    attach_function :PyDict_DelItem, [PyObject.by_ref, PyObject.by_ref], :int

    # PyDict_DelItemString :: (PyPtr, char const*) -> int
    attach_function :PyDict_DelItem, [PyObject.by_ref, :string], :int

    # PyDict_Size :: (PyPtr) -> ssize_t
    attach_function :PyDict_Size, [PyObject.by_ref], :ssize_t

    # PyDict_Keys :: (PyPtr) -> PyPtr
    attach_function :PyDict_Keys, [PyObject.by_ref], PyObject.by_ref

    # PyDict_Values :: (PyPtr) -> PyPtr
    attach_function :PyDict_Values, [PyObject.by_ref], PyObject.by_ref

    # PyDict_Items :: (PyPtr) -> PyPtr
    attach_function :PyDict_Items, [PyObject.by_ref], PyObject.by_ref

    # PyDict_Contains :: (PyPtr, PyPtr) -> int
    attach_function :PyDict_Contains, [PyObject.by_ref, PyObject.by_ref], :int

    # PySet_Size :: (PyPtr) -> ssize_t
    attach_function :PySet_Size, [PyObject.by_ref], :ssize_t

    # PySet_Contains :: (PyPtr, PyPtr) -> int
    attach_function :PySet_Contains, [PyObject.by_ref, PyObject.by_ref], :int

    # PySet_Add :: (PyPtr, PyPtr) -> int
    attach_function :PySet_Add, [PyObject.by_ref, PyObject.by_ref], :int

    # PySet_Discard :: (PyPtr, PyPtr) -> int
    attach_function :PySet_Discard, [PyObject.by_ref, PyObject.by_ref], :int

    # PyModule_GetDict :: (PyPtr) -> PyPtr
    attach_function :PyModule_GetDict, [PyObject.by_ref], PyObject.by_ref

    # PyImport_ImportModule :: (char const*) -> PyPtr
    attach_function :PyImport_ImportModule, [:string], PyObject.by_ref

    # Py_CompileString :: (char const*, char const*, int) -> PyPtr
    attach_function :Py_CompileString, [:string, :string, :int], PyObject.by_ref

    # PyEval_EvalCode :: (PyPtr, PyPtr, PyPtr) -> PyPtr
    attach_function :PyEval_EvalCode, [PyObject.by_ref, PyObject.by_ref, PyObject.by_ref], PyObject.by_ref

    # PyErr_Print :: () -> Void
    attach_function :PyErr_Print, [], :void

    public_class_method
  end

  PYTHON_DESCRIPTION = LibPython.Py_GetVersion().freeze
  PYTHON_VERSION = PYTHON_DESCRIPTION.split(' ', 2)[0].freeze
end
