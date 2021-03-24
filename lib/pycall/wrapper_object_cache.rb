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
      @wrapper_object_table = ObjectSpace::WeakMap.new
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

      wrapper_object = @wrapper_object_table[pyptr.__address__]
      unless wrapper_object
        wrapper_object = yield(pyptr)
        check_wrapper_object(wrapper_object)
        @wrapper_object_table[pyptr.__address__] = wrapper_object
      end

      wrapper_object
    end

    def check_wrapper_object(wrapper_object)
      unless wrapper_object.kind_of?(PyObjectWrapper)
        raise TypeError, "unexpected wrapper object (expected an object extended by PyObjectWrapper)"
      end
    end
  end
end
