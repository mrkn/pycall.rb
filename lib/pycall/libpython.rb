require 'ffi'

module PyCall
  module LibPython
    extend FFI::Library

    class PyObjectStruct < FFI::Struct
      layout ob_refcnt: :ssize_t,
             ob_type:   PyObjectStruct.by_ref

      def self.null
        new(FFI::Pointer::NULL)
      end

      def py_none?
        PyCall.none?(self)
      end

      def kind_of?(klass)
        klass = klass.__pyobj__ if klass.kind_of? PyObjectWrapper
        return super unless klass.kind_of? PyObjectStruct
        PyCall::Types.pyisinstance(self, klass)
      end
    end

    class PyMethodDef < FFI::Struct
      layout ml_name:  :string,
             ml_meth:  :pointer,
             ml_flags: :int,
             ml_doc:   :string   # may be NULL
    end

    class PyGetSetDef < FFI::Struct
      layout name:    :string,
             get:     :pointer,
             set:     :pointer,  # may be NULL for read-only members
             doc:     :string,
             closure: :pointer
    end

    class PyTypeObjectStruct < FFI::Struct
      layout ob_refcnt: :ssize_t,
             ob_type:   PyObjectStruct.by_ref,
             ob_size:   :ssize_t,

             tp_name: :string, # For printing, in format "<module>.<name>"

             # For allocation
             tp_basicsize: :ssize_t,
             tp_itemsize: :ssize_t,

             # Methods to implement standard operations

             tp_dealloc: :pointer,
             tp_print: :pointer,
             tp_getattr: :pointer,
             tp_setattr: :pointer,
             tp_as_async: :pointer, # formerly known as tp_compare (Python 2) or tp_reserved (Python 3)
             tp_repr: :pointer,

             # Method suites for standard classes

             tp_as_number: :pointer,
             tp_as_sequence: :pointer,
             tp_as_mapping: :pointer,

             # More standard operations (here for binary compatibility)

             tp_hash: :pointer,
             tp_call: :pointer,
             tp_str: :pointer,
             tp_getattro: :pointer,
             tp_setattro: :pointer,

             # Functions to access object as input/output buffer
             tp_as_buffer: :pointer,

             # Flags to define presence of optional/expanded features
             tp_flags: :ulong,

             tp_doc: :string, # Documentation string

             # Assigned meaning in release 2.0
             # call function for all accessible objects
             tp_traverse: :pointer,

             # delete references to contained objects
             tp_clear: :pointer,

             # Assigned meaning in release 2.1
             # rich comparisons
             tp_richcompare: :pointer,

             # weak reference enabler
             tp_weaklistoffset: :ssize_t,

             # Iterators
             tp_iter: :pointer,
             tp_iternext: :pointer,

             # Attribute descriptor and subclassing stuff
             tp_methods: PyMethodDef.by_ref,
             tp_members: PyMethodDef.by_ref,
             tp_getset: PyGetSetDef.by_ref,
             tp_base: :pointer,
             tp_dict: PyObjectStruct.by_ref,
             tp_descr_get: :pointer,
             tp_descr_set: :pointer,
             tp_dictoffset: :ssize_t,
             tp_init: :pointer,
             tp_alloc: :pointer,
             tp_new: :pointer,
             tp_free: :pointer, # Low-level free-memory routine
             tp_is_gc: :pointer, # For PyObject_IS_GC
             tp_bases: PyObjectStruct.by_ref,
             tp_mro: PyObjectStruct.by_ref, # method resolution order
             tp_cache: PyObjectStruct.by_ref,
             tp_subclasses: PyObjectStruct.by_ref,
             tp_weaklist: PyObjectStruct.by_ref,
             tp_del: :pointer,

             # Type attribute cache version tag. Added in version 2.6
             tp_version_tag: :uint,

             tp_finalize: :pointer,

             # The following members are only used for COUNT_ALLOCS builds of Python
             tp_allocs: :ssize_t,
             tp_frees: :ssize_t,
             tp_maxalloc: :ssize_t,
             tp_prev: :pointer,
             tp_next: :pointer
    end

    private_class_method

    def self.find_libpython(python = nil)
      debug = (ENV['DEBUG_FIND_LIBPYTHON'] == '1')
      dir_sep = File::ALT_SEPARATOR || File::SEPARATOR
      python ||= 'python'
      python_config = investigate_python_config(python)

      v = python_config[:VERSION]
      libprefix = FFI::Platform::LIBPREFIX
      libs = []
      %i(INSTSONAME LDLIBRARY).each do |key|
        lib = python_config[key]
        libs << lib << File.basename(lib) if lib
      end
      if (lib = python_config[:LIBRARY])
        libs << File.basename(lib, File.extname(lib))
      end
      libs << "#{libprefix}python#{v}" << "#{libprefix}python"
      libs.uniq!

      $stderr.puts "DEBUG(find_libpython) libs: #{libs.inspect}" if debug

      executable = python_config[:executable]
      libpaths = [ python_config[:LIBDIR] ]
      if FFI::Platform.windows?
        libpaths << File.dirname(executable)
      else
        libpaths << File.expand_path('../../lib', executable)
      end
      libpaths << python_config[:PYTHONFRAMEWORKPREFIX] if FFI::Platform.mac?
      exec_prefix = python_config[:exec_prefix]
      libpaths << exec_prefix << [exec_prefix, 'lib'].join(dir_sep)
      libpaths.compact!

      $stderr.puts "DEBUG(find_libpython) libpaths: #{libpaths.inspect}" if debug

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

      # Try LIBPYTHON environment variable first.
      if ENV['LIBPYTHON']
        if File.file?(ENV['LIBPYTHON'])
          begin
            libs = ffi_lib(ENV['LIBPYTHON'])
            return libs.first
          rescue LoadError
          end
        end
        $stderr.puts '[WARN] Ignore the wrong libpython location specified in LIBPYTHON environment variable.'
      end

      # Find libpython (we hope):
      libsuffix = FFI::Platform::LIBSUFFIX
      multiarch = python_config[:MULTIARCH] || python_config[:multiarch]
      libs.each do |lib|
        libpaths.each do |libpath|
          # NOTE: File.join doesn't use File::ALT_SEPARATOR
          libpath_libs = [ [libpath, lib].join(dir_sep) ]
          libpath_libs << [libpath, multiarch, lib].join(dir_sep) if multiarch
          libpath_libs.each do |libpath_lib|
            [
              libpath_lib,
              "#{libpath_lib}.#{libsuffix}"
            ].each do |fullname|
              unless File.file?(fullname)
                $stderr.puts "DEBUG(find_libpython) Unable to find #{fullname}" if debug
                next
              end
              begin
                dynlibs = ffi_lib(fullname)
                $stderr.puts "DEBUG(find_libpython) ffi_lib(#{fullname.inspect}) = #{dynlibs.inspect}" if debug
                return dynlibs.first
              rescue LoadError
                # skip load error
              end
            end
          end
        end
      end

      # Find libpython in the system path
      libs.each do |lib|
        begin
          dynlibs = ffi_lib(lib)
          $stderr.puts "DEBUG(find_libpython) ffi_lib(#{lib.inspect}) = #{dynlibs.inspect}" if debug
          return dynlibs.first
        rescue LoadError
          # skip load error
        end
      end
    end

    def self.investigate_python_config(python)
      python_env = { 'PYTHONIOENCODING' => 'UTF-8' }
      IO.popen(python_env, [python, python_investigator_py], 'r') do |io|
        {}.tap do |config|
          io.each_line do |line|
            key, value = line.chomp.split(': ', 2)
            config[key.to_sym] = value if value != 'None'
          end
        end
      end
    end

    def self.python_investigator_py
      File.expand_path('../python/investigator.py', __FILE__)
    end

    ffi_lib_flags :lazy, :global
    libpython = find_libpython ENV['PYTHON']

    attach_function :Py_GetVersion, [], :string
    PYTHON_DESCRIPTION = LibPython.Py_GetVersion().freeze
    PYTHON_VERSION = PYTHON_DESCRIPTION.split(' ', 2)[0].freeze

    # --- types ---

    if PYTHON_VERSION < '3.2'
      typedef :long, :Py_hash_t
    else
      typedef :ssize_t, :Py_hash_t
    end

    # --- global variables ---

    attach_variable :_Py_NoneStruct, PyObjectStruct

    def self.Py_None
      _Py_NoneStruct
    end

    attach_variable :PyType_Type, PyObjectStruct

    if libpython.find_variable('PyInt_Type')
      has_PyInt_Type = true
      attach_variable :PyInt_Type, PyObjectStruct
    else
      has_PyInt_Type = false
      attach_variable :PyInt_Type, :PyLong_Type, PyObjectStruct
    end

    attach_variable :PyLong_Type, PyObjectStruct
    attach_variable :PyBool_Type, PyObjectStruct
    attach_variable :PyFloat_Type, PyObjectStruct
    attach_variable :PyComplex_Type, PyObjectStruct
    attach_variable :PyUnicode_Type, PyObjectStruct

    if libpython.find_symbol('PyString_FromStringAndSize')
      string_as_bytes = false
      attach_variable :PyString_Type, PyObjectStruct
    else
      string_as_bytes = true
      attach_variable :PyString_Type, :PyBytes_Type, PyObjectStruct
    end

    attach_variable :PyList_Type, PyObjectStruct
    attach_variable :PyTuple_Type, PyObjectStruct
    attach_variable :PyDict_Type, PyObjectStruct
    attach_variable :PySet_Type, PyObjectStruct

    attach_variable :PyFunction_Type, PyObjectStruct
    attach_variable :PyMethod_Type, PyObjectStruct

    # --- functions ---

    attach_function :Py_InitializeEx, [:int], :void
    attach_function :Py_IsInitialized, [], :int
    attach_function :PySys_SetArgvEx, [:int, :pointer, :int], :void

    # Reference count

    attach_function :Py_IncRef, [PyObjectStruct.by_ref], :void
    attach_function :Py_DecRef, [PyObjectStruct.by_ref], :void

    # Object

    attach_function :PyObject_RichCompare, [PyObjectStruct.by_ref, PyObjectStruct.by_ref, :int], PyObjectStruct.by_ref
    attach_function :PyObject_GetAttrString, [PyObjectStruct.by_ref, :string], PyObjectStruct.by_ref
    attach_function :PyObject_SetAttrString, [PyObjectStruct.by_ref, :string, PyObjectStruct.by_ref], :int
    attach_function :PyObject_HasAttrString, [PyObjectStruct.by_ref, :string], :int
    attach_function :PyObject_GetItem, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyObject_SetItem, [PyObjectStruct.by_ref, PyObjectStruct.by_ref, PyObjectStruct.by_ref], :int
    attach_function :PyObject_Call, [PyObjectStruct.by_ref, PyObjectStruct.by_ref, PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyObject_IsInstance, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], :int
    attach_function :PyObject_Dir, [PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyObject_Hash, [PyObjectStruct.by_ref], :Py_hash_t
    attach_function :PyObject_Repr, [PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyObject_Str, [PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyObject_Type, [PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyCallable_Check, [PyObjectStruct.by_ref], :int

    # Bool

    attach_function :PyBool_FromLong, [:long], PyObjectStruct.by_ref

    # Integer

    if has_PyInt_Type
      attach_function :PyInt_AsSsize_t, [PyObjectStruct.by_ref], :ssize_t
    else
      attach_function :PyInt_AsSsize_t, :PyLong_AsSsize_t, [PyObjectStruct.by_ref], :ssize_t
    end

    if has_PyInt_Type
      attach_function :PyInt_FromSsize_t, [:ssize_t], PyObjectStruct.by_ref
    else
      attach_function :PyInt_FromSsize_t, :PyLong_FromSsize_t, [:ssize_t], PyObjectStruct.by_ref
    end

    # Float

    attach_function :PyFloat_FromDouble, [:double], PyObjectStruct.by_ref
    attach_function :PyFloat_AsDouble, [PyObjectStruct.by_ref], :double

    # Complex

    attach_function :PyComplex_RealAsDouble, [PyObjectStruct.by_ref], :double
    attach_function :PyComplex_ImagAsDouble, [PyObjectStruct.by_ref], :double

    # String

    if string_as_bytes
      attach_function :PyString_FromStringAndSize, :PyBytes_FromStringAndSize, [:string, :ssize_t], PyObjectStruct.by_ref
    else
      attach_function :PyString_FromStringAndSize, [:string, :ssize_t], PyObjectStruct.by_ref
    end

    # PyString_AsStringAndSize :: (PyPtr, char**, int*) -> int
    if string_as_bytes
      attach_function :PyString_AsStringAndSize, :PyBytes_AsStringAndSize, [PyObjectStruct.by_ref, :pointer, :pointer], :int
    else
      attach_function :PyString_AsStringAndSize, [PyObjectStruct.by_ref, :pointer, :pointer], :int
    end

    # Unicode

    # PyUnicode_DecodeUTF8
    case
    when libpython.find_symbol('PyUnicode_DecodeUTF8')
      attach_function :PyUnicode_DecodeUTF8, [:string, :ssize_t, :string], PyObjectStruct.by_ref
    when libpython.find_symbol('PyUnicodeUCS4_DecodeUTF8')
      attach_function :PyUnicode_DecodeUTF8, :PyUnicodeUCS4_DecodeUTF8, [:string, :ssize_t, :string], PyObjectStruct.by_ref
    when libpython.find_symbol('PyUnicodeUCS2_DecodeUTF8')
      attach_function :PyUnicode_DecodeUTF8, :PyUnicodeUCS2_DecodeUTF8, [:string, :ssize_t, :string], PyObjectStruct.by_ref
    end

    # PyUnicode_AsUTF8String
    case
    when libpython.find_symbol('PyUnicode_AsUTF8String')
      attach_function :PyUnicode_AsUTF8String, [PyObjectStruct.by_ref], PyObjectStruct.by_ref
    when libpython.find_symbol('PyUnicodeUCS4_AsUTF8String')
      attach_function :PyUnicode_AsUTF8String, :PyUnicodeUCS4_AsUTF8String, [PyObjectStruct.by_ref], PyObjectStruct.by_ref
    when libpython.find_symbol('PyUnicodeUCS2_AsUTF8String')
      attach_function :PyUnicode_AsUTF8String, :PyUnicodeUCS2_AsUTF8String, [PyObjectStruct.by_ref], PyObjectStruct.by_ref
    end

    # Tuple

    attach_function :PyTuple_New, [:ssize_t], PyObjectStruct.by_ref
    attach_function :PyTuple_GetItem, [PyObjectStruct.by_ref, :ssize_t], PyObjectStruct.by_ref
    attach_function :PyTuple_SetItem, [PyObjectStruct.by_ref, :ssize_t, PyObjectStruct.by_ref], :int
    attach_function :PyTuple_Size, [PyObjectStruct.by_ref], :ssize_t

    # Slice

    attach_function :PySlice_New, [PyObjectStruct.by_ref, PyObjectStruct.by_ref, PyObjectStruct.by_ref], PyObjectStruct.by_ref

    # List

    attach_function :PyList_New, [:ssize_t], PyObjectStruct.by_ref
    attach_function :PyList_Size, [PyObjectStruct.by_ref], :ssize_t
    attach_function :PyList_Append, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], :int

    # Sequence

    attach_function :PySequence_Size, [PyObjectStruct.by_ref], :ssize_t
    attach_function :PySequence_GetItem, [PyObjectStruct.by_ref, :ssize_t], PyObjectStruct.by_ref
    attach_function :PySequence_Contains, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], :int

    # Dict

    attach_function :PyDict_New, [], PyObjectStruct.by_ref
    attach_function :PyDict_GetItem, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyDict_GetItemString, [PyObjectStruct.by_ref, :string], PyObjectStruct.by_ref
    attach_function :PyDict_SetItem, [PyObjectStruct.by_ref, PyObjectStruct.by_ref, PyObjectStruct.by_ref], :int
    attach_function :PyDict_SetItemString, [PyObjectStruct.by_ref, :string, PyObjectStruct.by_ref], :int
    attach_function :PyDict_DelItem, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], :int
    attach_function :PyDict_DelItemString, [PyObjectStruct.by_ref, :string], :int
    attach_function :PyDict_Size, [PyObjectStruct.by_ref], :ssize_t
    attach_function :PyDict_Keys, [PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyDict_Values, [PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyDict_Items, [PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyDict_Contains, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], :int

    # Set

    attach_function :PySet_Size, [PyObjectStruct.by_ref], :ssize_t
    attach_function :PySet_Contains, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], :int

    # Module

    attach_function :PyModule_GetDict, [PyObjectStruct.by_ref], PyObjectStruct.by_ref

    # Import

    attach_function :PyImport_ImportModule, [:string], PyObjectStruct.by_ref

    # Operators

    attach_function :PyNumber_Add, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyNumber_Subtract, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyNumber_Multiply, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyNumber_TrueDivide, [PyObjectStruct.by_ref, PyObjectStruct.by_ref], PyObjectStruct.by_ref
    attach_function :PyNumber_Power, [PyObjectStruct.by_ref, PyObjectStruct.by_ref, PyObjectStruct.by_ref], PyObjectStruct.by_ref

    # Compiler

    attach_function :Py_CompileString, [:string, :string, :int], PyObjectStruct.by_ref
    attach_function :PyEval_EvalCode, [PyObjectStruct.by_ref, PyObjectStruct.by_ref, PyObjectStruct.by_ref], PyObjectStruct.by_ref

    # Error

    attach_function :PyErr_Clear, [], :void
    attach_function :PyErr_Print, [], :void
    attach_function :PyErr_Occurred, [], PyObjectStruct.by_ref
    attach_function :PyErr_Fetch, [:pointer, :pointer, :pointer], :void
    attach_function :PyErr_NormalizeException, [:pointer, :pointer, :pointer], :void

    public_class_method
  end

  PYTHON_DESCRIPTION = LibPython::PYTHON_DESCRIPTION
  PYTHON_VERSION = LibPython::PYTHON_VERSION

  def self.unicode_literals?
    @unicode_literals ||= (PYTHON_VERSION >= '3.0')
  end
end
