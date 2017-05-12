require 'ffi'

module PyCall
  module LibPython
    # Python 2.7
    Py_TPFLAGS_HAVE_GETCHARBUFFER  = 0x00000001<<0
    Py_TPFLAGS_HAVE_SEQUENCE_IN    = 0x00000001<<1
    Py_TPFLAGS_GC                  = 0 # was sometimes (0x00000001<<2) in Python <= 2.1
    Py_TPFLAGS_HAVE_INPLACEOPS     = 0x00000001<<3
    Py_TPFLAGS_CHECKTYPES          = 0x00000001<<4
    Py_TPFLAGS_HAVE_RICHCOMPARE    = 0x00000001<<5
    Py_TPFLAGS_HAVE_WEAKREFS       = 0x00000001<<6
    Py_TPFLAGS_HAVE_ITER           = 0x00000001<<7
    Py_TPFLAGS_HAVE_CLASS          = 0x00000001<<8
    Py_TPFLAGS_HAVE_INDEX          = 0x00000001<<17
    Py_TPFLAGS_HAVE_NEWBUFFER      = 0x00000001<<21
    Py_TPFLAGS_STRING_SUBCLASS     = 0x00000001<<27

    # Python 3.0+ has only these:
    Py_TPFLAGS_HEAPTYPE = 0x00000001<<9
    Py_TPFLAGS_BASETYPE = 0x00000001<<10
    Py_TPFLAGS_READY    = 0x00000001<<12
    Py_TPFLAGS_READYING = 0x00000001<<13
    Py_TPFLAGS_HAVE_GC  = 0x00000001<<14
    Py_TPFLAGS_HAVE_VERSION_TAG  = 0x00000001<<18
    Py_TPFLAGS_VALID_VERSION_TAG = 0x00000001<<19
    Py_TPFLAGS_IS_ABSTRACT    = 0x00000001<<20
    Py_TPFLAGS_INT_SUBCLASS   = 0x00000001<<23
    Py_TPFLAGS_LONG_SUBCLASS  = 0x00000001<<24
    Py_TPFLAGS_LIST_SUBCLASS  = 0x00000001<<25
    Py_TPFLAGS_TUPLE_SUBCLASS = 0x00000001<<26
    Py_TPFLAGS_BYTES_SUBCLASS = 0x00000001<<27
    Py_TPFLAGS_UNICODE_SUBCLASS  = 0x00000001<<28
    Py_TPFLAGS_DICT_SUBCLASS     = 0x00000001<<29
    Py_TPFLAGS_BASE_EXC_SUBCLASS = 0x00000001<<30
    Py_TPFLAGS_TYPE_SUBCLASS     = 0x00000001<<31

    # only use this if we have the stackless extension
    Py_TPFLAGS_HAVE_STACKLESS_EXTENSION_ = 0x00000003<<15

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

      def self.new(*args)
        case args.length
        when 0, 1
          super
        else
          name, basic_size = *args
          t = super()
          t[:tp_basicsize] = basic_size
          stackless_extension_flag = PyCall.has_stackless_extension ? Py_TPFLAGS_HAVE_STACKLESS_EXTENSION_ : 0
          t[:tp_flags] = if PYTHON_VERSION >= '3'
                           stackless_extension_flag | Py_TPFLAGS_HAVE_VERSION_TAG
                         else
                           Py_TPFLAGS_HAVE_GETCHARBUFFER |
                             Py_TPFLAGS_HAVE_SEQUENCE_IN |
                             Py_TPFLAGS_HAVE_INPLACEOPS |
                             Py_TPFLAGS_HAVE_RICHCOMPARE |
                             Py_TPFLAGS_HAVE_WEAKREFS |
                             Py_TPFLAGS_HAVE_ITER |
                             Py_TPFLAGS_HAVE_CLASS |
                             stackless_extension_flag |
                             Py_TPFLAGS_HAVE_INDEX
                         end
          t.tp_name = name
          yield t if block_given?
          t[:tp_new] = LibPython.find_symbol(:PyType_GenericNew) if t[:tp_new] == FFI::Pointer::NULL
        end
      end

      def tp_name=(str)
        @saved_name = FFI::MemoryPointer.from_string(str)
        self.pointer.put_pointer(offset_of(:tp_name), @saved_name)
      end
    end
  end
end
