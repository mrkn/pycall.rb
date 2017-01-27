module PyCall
  module Conversions
    def self.convert(py_obj_ptr)
      case
      when isnone?(py_obj_ptr)
        return nil

      when isinstance?(py_obj_ptr, LibPython.PyBool_Type)
        return convert_to_boolean(py_obj_ptr)

      when isinstance?(py_obj_ptr, LibPython.PyInt_Type)
        return convert_to_integer(py_obj_ptr)

      when isinstance?(py_obj_ptr, LibPython.PyLong_Type)
        # TODO: should make Bignum

      when isinstance?(py_obj_ptr, LibPython.PyFloat_Type)
        return convert_to_float(py_obj_ptr)

      when isinstance?(py_obj_ptr, LibPython.PyComplex_Type)
        return convert_to_complex(py_obj_ptr)

      when isinstance?(py_obj_ptr, LibPython.PyString_Type)
        return convert_to_string(py_obj_ptr)

      when isinstance?(py_obj_ptr, LibPython.PyUnicode_Type)
        py_str_ptr = LibPython.PyUnicode_AsUTF8String(py_obj_ptr)
        return convert_to_string(py_str_ptr)

      when isinstance?(py_obj_ptr, LibPython.PyList_Type)
        return convert_to_array(py_obj_ptr)

      when isinstance?(py_obj_ptr, LibPython.PyTuple_Type)
        return convert_to_tuple(py_obj_ptr)
      end
      py_obj_ptr
    end

    def self.convert_to_boolean(py_obj_ptr)
      0 != LibPython.PyInt_AsSsize_t(py_obj_ptr)
    end

    def self.convert_to_integer(py_obj_ptr)
      LibPython.PyInt_AsSsize_t(py_obj_ptr)
    end

    def self.convert_to_float(py_obj_ptr)
      LibPython.PyFloat_AsDouble(py_obj_ptr)
    end

    def self.convert_to_complex(py_obj_ptr)
      real = LibPython.PyComplex_RealAsDouble(py_obj_ptr)
      imag = LibPython.PyComplex_ImagAsDouble(py_obj_ptr)
      Complex(real, imag)
    end

    def self.convert_to_string(py_obj_ptr)
      FFI::MemoryPointer.new(:string) do |str_ptr|
        FFI::MemoryPointer.new(:int) do |len_ptr|
          res = LibPython.PyString_AsStringAndSize(py_obj_ptr, str_ptr, len_ptr)
          return nil if res == -1  # FIXME: error

          len = len_ptr.get(:int, 0)
          return str_ptr.get_pointer(0).read_string(len)
        end
      end
    end

    def self.convert_to_array(py_obj_ptr, force_list: true, array_class: Array)
      case
      when force_list || isinstance?(py_obj_ptr, LibPython.PyList_Type)
        len = LibPython.PySequence_Size(py_obj_ptr)
        array_class.new(len) do |i|
          convert(LibPython.PySequence_GetItem(py_obj_ptr, i))
        end
      end
    end

    def self.convert_to_tuple(py_obj_ptr)
      convert_to_array(py_obj_ptr, array_class: PyCall::Tuple)
    end

    class << self
      private

      def isnone?(py_obj_ptr)
        py_obj_ptr == LibPython.Py_None
      end

      def isinstance?(py_obj_ptr, py_type)
        Types.pyisinstance(py_obj_ptr, py_type)
      end
    end
  end
end
