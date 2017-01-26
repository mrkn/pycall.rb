module PyCall
  module Types
    def self.pyisinstance(pyobj, pytype)
      check_pyobject(pyobj)
      pyobj_ptr = pyobj # TODO: fix after introducing PyObject class
      LibPython.PyObject_IsInstance(pyobj_ptr, pytype.to_ptr) == 1
    end

    class << self
      private def check_pyobject(pyobj)
        # TODO: Check whether pyobj is PyObject
      end
    end
  end
end
