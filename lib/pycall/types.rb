module PyCall
  module Types
    def self.pyisinstance(pyobj, pytype)
      pyobj = LibPython::PyObjectStruct.new(pyobj) if pyobj.kind_of? FFI::Pointer
      pyobj = pyobj.__pyobj__ unless pyobj.kind_of? LibPython::PyObjectStruct

      pytype = LibPython::PyObjectStruct.new(pytype) if pytype.kind_of? FFI::Pointer
      pytype = ptype.__pyobj__ unless pytype.kind_of? LibPython::PyObjectStruct

      LibPython.PyObject_IsInstance(pyobj, pytype) == 1
    end

    class << self
      private def check_pyobject(pyobj)
        # TODO: Check whether pyobj is PyObject
      end
    end
  end
end
