module PyCall
  module Conversions
    def self.convert(py_obj_ptr)
      case
      when Types.pyisinstance(py_obj_ptr, LibPython.PyBool_Type)
        return convert_to_boolean(py_obj_ptr)
      when Types.pyisinstance(py_obj_ptr, LibPython.PyInt_Type)
        return convert_to_integer(py_obj_ptr)
      when Types.pyisinstance(py_obj_ptr, LibPython.PyLong_Type)
        # TODO: should make Bignum
      when Types.pyisinstance(py_obj_ptr, LibPython.PyFloat_Type)
        return convert_to_float(py_obj_ptr)
      when Types.pyisinstance(py_obj_ptr, LibPython.PyString_Type)
        return convert_to_string(py_obj_ptr)
      when Types.pyisinstance(py_obj_ptr, LibPython.PyUnicode_Type)
        py_str_ptr = LibPython.PyUnicode_AsUTF8String(py_obj_ptr)
        return convert_to_string(py_str_ptr)
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
  end
end
