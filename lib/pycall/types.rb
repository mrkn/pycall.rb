module PyCall
  module Types
    def self.pyisinstance(pyobj, pytype)
      check_pyobject(pyobj)
      pytype = PyObject.new(pytype.to_ptr) if pytype.kind_of?(PyTypeObject)
      LibPython.PyObject_IsInstance(pyobj, pytype) == 1
    end

    class << self
      private def check_pyobject(pyobj)
        # TODO: Check whether pyobj is PyObject
      end
    end
  end
end
