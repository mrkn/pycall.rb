module PyCall
  module Conversions
    def self.convert(py_obj)
      case
      when isnone?(py_obj)
        return nil

      when isinstance?(py_obj, LibPython.PyBool_Type)
        return convert_to_boolean(py_obj)

      when isinstance?(py_obj, LibPython.PyInt_Type)
        return convert_to_integer(py_obj)

      when isinstance?(py_obj, LibPython.PyLong_Type)
        # TODO: should make Bignum

      when isinstance?(py_obj, LibPython.PyFloat_Type)
        return convert_to_float(py_obj)

      when isinstance?(py_obj, LibPython.PyComplex_Type)
        return convert_to_complex(py_obj)

      when isinstance?(py_obj, LibPython.PyString_Type)
        return convert_to_string(py_obj)

      when isinstance?(py_obj, LibPython.PyUnicode_Type)
        py_str_ptr = LibPython.PyUnicode_AsUTF8String(py_obj)
        return convert_to_string(py_str_ptr)

      when isinstance?(py_obj, LibPython.PyList_Type)
        return convert_to_array(py_obj)

      when isinstance?(py_obj, LibPython.PyTuple_Type)
        return convert_to_tuple(py_obj)

      when isinstance?(py_obj, LibPython.PyDict_Type)
        return PyCall::Dict.new(py_obj)

      when isinstance?(py_obj, LibPython.PySet_Type)
        return PyCall::Set.new(py_obj)
      end

      py_obj
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
      when force_list || isinstance?(py_obj, LibPython.PyList_Type)
        len = LibPython.PySequence_Size(py_obj)
        array_class.new(len) do |i|
          convert(LibPython.PySequence_GetItem(py_obj, i))
        end
      end
    end

    def self.convert_to_tuple(py_obj)
      convert_to_array(py_obj, array_class: PyCall::Tuple)
    end

    class << self
      private

      def isnone?(py_obj)
        py_obj.to_ptr == LibPython.Py_None.to_ptr
      end

      def isinstance?(py_obj, py_type)
        Types.pyisinstance(py_obj, py_type)
      end
    end
  end
end
