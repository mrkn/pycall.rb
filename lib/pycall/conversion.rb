module PyCall
  module Conversions
    @python_type_map = []

    class TypePair < Struct.new(:pytype, :rbtype)
      def to_a
        [pytype, rbtype]
      end
    end

    def self.each_type_pair
      i, n = 1, @python_type_map.length
      while i <= n
        yield @python_type_map[n - i]
        i += 1
      end
      self
    end

    def self.python_type_mapping(pytype, rbtype)
      each_type_pair do |type_pair|
        next unless pytype == type_pair.pytype
        type_pair.rbtype = rbtype
        return
      end
      @python_type_map << TypePair.new(pytype, rbtype)
    end

    # Convert a PyCall::PyObjectStruct object to a Ruby object
    #
    # @param [PyCall::PyObjectStruct] pyptr  a PyObjectStruct object.
    #
    # @return a Ruby object converted from `pyptr`.
    def self.to_ruby(pyptr)
      return nil if pyptr.null? || PyCall.none?(pyptr)

      case
      when PyCall::Types.pyisinstance(pyptr, LibPython.PyType_Type)
        return TypeObject.new(pyptr)

      when PyCall::Types.pyisinstance(pyptr, LibPython.PyBool_Type)
        return Conversions.convert_to_boolean(pyptr)

      when PyCall::Types.pyisinstance(pyptr, LibPython.PyInt_Type)
        return Conversions.convert_to_integer(pyptr)

      when PyCall::Types.pyisinstance(pyptr, LibPython.PyLong_Type)
        # TODO: should make Bignum

      when PyCall::Types.pyisinstance(pyptr, LibPython.PyFloat_Type)
        return Conversions.convert_to_float(pyptr)

      when PyCall::Types.pyisinstance(pyptr, LibPython.PyComplex_Type)
        return Conversions.convert_to_complex(pyptr)

      when PyCall::Types.pyisinstance(pyptr, LibPython.PyString_Type)
        return Conversions.convert_to_string(pyptr)

      when PyCall::Types.pyisinstance(pyptr, LibPython.PyUnicode_Type)
        py_str_ptr = LibPython.PyUnicode_AsUTF8String(pyptr)
        return Conversions.convert_to_string(py_str_ptr).force_encoding(Encoding::UTF_8)

      when PyCall::Types.pyisinstance(pyptr, LibPython.PyList_Type)
        return PyCall::List.new(pyptr)

      when PyCall::Types.pyisinstance(pyptr, LibPython.PyTuple_Type)
        return Conversions.convert_to_tuple(pyptr)

      when PyCall::Types.pyisinstance(pyptr, LibPython.PyDict_Type)
        return PyCall::Dict.new(pyptr)

      when PyCall::Types.pyisinstance(pyptr, LibPython.PySet_Type)
        return PyCall::Set.new(pyptr)
      end

      pyobj = PyObject.new(pyptr)
      each_type_pair do |tp|
        pytype, rbtype = tp.to_a
        next unless pyobj.kind_of?(pytype)
        case
        when rbtype.kind_of?(Proc)
          return rbtype.(pyobj)
        when rbtype.respond_to?(:from_python)
          return rbtype.from_python(pyobj)
        else
          return rbtype.new(pyobj)
        end
      end
      pyobj
    end

    def self.from_ruby(obj)
      case obj
      when LibPython::PyObjectStruct
        obj
      when PyObjectWrapper
        obj.__pyobj__
      when TrueClass, FalseClass
        LibPython.PyBool_FromLong(obj ? 1 : 0)
      when Integer
        LibPython.PyInt_FromSsize_t(obj)
      when Float
        LibPython.PyFloat_FromDouble(obj)
      when String
        case obj.encoding
        when Encoding::US_ASCII, Encoding::BINARY
          LibPython.PyString_FromStringAndSize(obj, obj.bytesize)
        else
          obj = obj.encode(Encoding::UTF_8)
          LibPython.PyUnicode_DecodeUTF8(obj, obj.bytesize, nil)
        end
      when Symbol
        from_ruby(obj.to_s)
      when Array
        PyCall::List.new(obj).__pyobj__
      when Hash
        PyCall::Dict.new(obj).__pyobj__
      else
        PyCall.None
      end
    end

    def self.convert_to_boolean(py_obj)
      0 != LibPython.PyInt_AsSsize_t(py_obj)
    end

    def self.convert_to_integer(py_obj)
      LibPython.PyInt_AsSsize_t(py_obj)
    end

    def self.convert_to_float(py_obj)
      LibPython.PyFloat_AsDouble(py_obj)
    end

    def self.convert_to_complex(py_obj)
      real = LibPython.PyComplex_RealAsDouble(py_obj)
      imag = LibPython.PyComplex_ImagAsDouble(py_obj)
      Complex(real, imag)
    end

    def self.convert_to_string(py_obj)
      FFI::MemoryPointer.new(:string) do |str_ptr|
        FFI::MemoryPointer.new(:int) do |len_ptr|
          res = LibPython.PyString_AsStringAndSize(py_obj, str_ptr, len_ptr)
          return nil if res == -1  # FIXME: error

          len = len_ptr.get(:int, 0)
          return str_ptr.get_pointer(0).read_string(len)
        end
      end
    end

    def self.convert_to_array(py_obj, force_list: true, array_class: Array)
      case
      when force_list || py_obj.kind_of?(LibPython.PyList_Type)
        len = LibPython.PySequence_Size(py_obj)
        array_class.new(len) do |i|
          LibPython.PySequence_GetItem(py_obj, i).to_ruby
        end
      end
    end

    def self.convert_to_tuple(py_obj)
      PyCall::Tuple.new(py_obj)
    end
  end

  class LibPython::PyObjectStruct
    def to_ruby
      Conversions.to_ruby(self)
    end
  end
end
