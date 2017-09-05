module PyCall
  class WrapperObjectCache
    def initialize(*restricted_pytypes)
      unless restricted_pytypes.empty?
        restricted_pytypes.each do |pytype|
          next if pytype.kind_of? PyTypePtr
          raise TypeError, "unexpected type of object in the arguments (#{pytype.class} for PyCall::PyTypePtr)"
        end
      end
      @restricted_pytypes = restricted_pytypes
      @wrapper_object_table = {}
      @wrapped_pyptr_table = {}
      @weakref_table = {}
    end

    def lookup(pyptr)
      # TODO: check pytypeptr type
      unless pyptr.kind_of? PyPtr
        raise TypeError, "unexpected argument type #{pyptr.class} (expected PyCall::PyPtr)"
      end

      unless @restricted_pytypes.empty?
        unless @restricted_pytypes.any? {|pytype| pyptr.kind_of? pytype }
          raise TypeError, "unexpected argument Python type #{pyptr.__ob_type__.__name__} (expected either of them in [#{@restricted_pytypes.map(&:__tp_name__).join(', ')}])"
        end
      end

      wrapper_object_id = @wrapper_object_table[pyptr.__address__]
      if wrapper_object_id
        wrapper_object = ObjectSpace._id2ref(wrapper_object_id) rescue nil
        return wrapper_object if wrapper_object
      end

      wrapper_object = yield(pyptr)
      check_wrapper_object(wrapper_object)
      register_wrapper_object(pyptr, wrapper_object)

      wrapper_object
    end

    def check_wrapper_object(wrapper_object)
      unless wrapper_object.kind_of?(PyObjectWrapper)
        raise TypeError, "unexpected wrapper object (expected an object extended by PyObjectWrapper)"
      end
    end

    def register_wrapper_object(pyptr, wrapper_object)
      @wrapper_object_table[pyptr.__address__] = wrapper_object.__id__
      @wrapped_pyptr_table[wrapper_object.__id__] = pyptr.__address__
      ObjectSpace.define_finalizer(wrapper_object, &method(:unregister_wrapper_object))
      # TODO: weakref
      self
    end

    def unregister_wrapper_object(wrapper_object_id)
      pyptr_addr = @wrapped_pyptr_table.delete(wrapper_object_id)
      @wrapper_object_table.delete(pyptr_addr) if pyptr_addr
      self
    end
  end
end
