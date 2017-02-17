module PyCall
  module Conversions
    def self.from_ruby(obj)
      case obj
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
      else
        LibPython.Py_None
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

  class PyObject
    def to_ruby
      return nil if self.null? || self.py_none?

      case self
      when LibPython.PyBool_Type
        return Conversions.convert_to_boolean(self)

      when LibPython.PyInt_Type
        return Conversions.convert_to_integer(self)

      when LibPython.PyLong_Type
        # TODO: should make Bignum

      when LibPython.PyFloat_Type
        return Conversions.convert_to_float(self)

      when LibPython.PyComplex_Type
        return Conversions.convert_to_complex(self)

      when LibPython.PyString_Type
        return Conversions.convert_to_string(self)

      when LibPython.PyUnicode_Type
        py_str_ptr = LibPython.PyUnicode_AsUTF8String(self)
        return Conversions.convert_to_string(py_str_ptr).force_encoding(Encoding::UTF_8)

      when LibPython.PyList_Type
        return Conversions.convert_to_array(self)

      when LibPython.PyTuple_Type
        return Conversions.convert_to_tuple(self)

      when LibPython.PyDict_Type
        return PyCall::Dict.new(self)

      when LibPython.PySet_Type
        return PyCall::Set.new(self)
      end

      self
    end
  end
end
