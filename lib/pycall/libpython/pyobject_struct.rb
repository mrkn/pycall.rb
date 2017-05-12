require 'ffi'

module PyCall
  module LibPython
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
  end
end
