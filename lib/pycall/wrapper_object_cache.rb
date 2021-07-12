module PyCall
  class WrapperObjectCache

    begin
      ObjectSpace::WeakMap.new[42] = Object.new
    rescue
      WMAP_SUPPORT_INT_KEY = false
    else
      case RUBY_PLATFORM
      when /cygwin/, /mingw/, /mswin/
        WMAP_SUPPORT_INT_KEY = false
      else
        WMAP_SUPPORT_INT_KEY = true
      end
    end

    if WMAP_SUPPORT_INT_KEY
      def self.get_key(pyptr)
        pyptr.__address__
      end
    else
      class Key
        @address_key_map = {}

        def self.[](address)
          # An instance of Key created here is parmanently cached in @address_key_map.
          # This behavior is intentional.
          @address_key_map[address] ||= new(address)
        end

        def initialize(address)
          @address = address
        end

        attr_reader :address

        def ==(other)
          case other
          when Key
            self.address == other.address
          else
            super
          end
        end
      end

      def self.get_key(pyptr)
        Key[pyptr.__address__]
      end
    end

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

      key = self.class.get_key(pyptr)
      wrapper_object = @wrapper_object_table[key]
      unless wrapper_object
        wrapper_object = yield(pyptr)
        check_wrapper_object(wrapper_object)
        @wrapper_object_table[key] = wrapper_object
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
