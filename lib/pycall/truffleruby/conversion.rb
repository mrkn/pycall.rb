module PyCall
  module Conversion

    @mapping_python = Hash.new
    @mapping_ruby = Hash.new

    class Converter
      attr_reader :ruby
      attr_reader :python

      def initialize(to_ruby, to_python, ruby_class, python_type)
        if to_ruby.is_a?(Proc) && to_python.is_a?(Proc)
          @to_ruby = to_ruby
          @to_python = to_python
          @ruby = ruby_class
          @python = python_type
        else
          raise ArgumentError, "#to_ruby and #to_python have to be callable"
        end
      end

      def convert_to_ruby(python_object)
        @to_ruby.call(python_object, @ruby)
      end

      def convert_to_python(ruby_object)
        @to_python.call(ruby_object, @python)
      end
    end

    def self.get_type(pythonObj)
      Polyglot.eval('python', 'type').call(pythonObj)
    end

    def self.register_nice_python_type_mapping(python_object, ruby_class, to_ruby, to_python)
      if ruby_class.is_a?(Class)
        if ruby_class <= @object_wrapper
          python_type = self.get_type(python_object)
          hash = Polyglot.eval('python', 'hash').call(python_type)
          if @mapping_python.has_key?(hash)
            false
          else
            converter = Converter.new(to_ruby, to_python, ruby_class, python_type)
            @mapping_python[hash] = converter
            @mapping_ruby[ruby_class] = converter
            true
          end
        else
          raise TypeError, 'ruby class must be a class'
        end
      else
        raise TypeError, 'ruby class must be extended by PyCall::PyTypeObjectWrapper'
      end
    end

    def self.register_python_type_mapping(python_object, ruby_class)

      self.register_nice_python_type_mapping(python_object, ruby_class,
                                             ->(x, ruby) { a = ruby.allocate; a.__pyptr__ = x; return a },
                                             ->(x, python) { return x.__pyptr__ })
    end

    def self.use_wrappers(wrapper_class)
      @object_wrapper ||= wrapper_class
    end

    def self.set_dict_wrapper(dict_wrapper)
      if dict_wrapper <= @object_wrapper
        @dict_wrapper ||= dict_wrapper
      end
    end

    def self.set_tuple_wrapper(tuple_wrapper)
      if tuple_wrapper <= @object_wrapper
        @tuple_wrapper ||= tuple_wrapper
      end
    end

    def self.set_list_wrapper(list_wrapper)
      if list_wrapper <= @object_wrapper
        @list_wrapper ||= list_wrapper
      end
    end

    def self.set_set_wrapper(set_wrapper)
      if set_wrapper <= @object_wrapper
        @set_wrapper ||= set_wrapper
      end
    end

    def self.set_slice_wrapper(slice_wrapper)
      if slice_wrapper <= @object_wrapper
        @slice_wrapper ||= slice_wrapper
      end
    end

    def self.set_ruby_wrapper(ruby_wrapper)
      @ruby_wrapper ||= ruby_wrapper
    end



    def self.unregister_python_type_mapping(python_class)
      @mapping_python ||= Hash.new
      hash = Polyglot.eval('python', 'hash').call(python_class)
      if @mapping_python.has_key?(hash)
        converter = @mapping_python[hash]
        @mapping_python.delete hash
        @mapping_ruby.delete converter.ruby
        true
      else
        false
      end
    end

    def self.from_ruby(ruby_object) # to python
      if !!ruby_object == ruby_object  # if ruby_object.is_a?(Boolean)
        @object_wrapper.new(ruby_object)
      elsif ruby_object.is_a?(Hash)
        @dict_wrapper.new(ruby_object).__pyptr__
      elsif ruby_object.is_a?(Proc)
        @ruby_wrapper.new(ruby_object)
      elsif ruby_object.is_a?(Numeric)
        @object_wrapper.new(ruby_object)
      else
        if @mapping_ruby.has_key?(ruby_object.class)
          @object_wrapper.wrap(@mapping_ruby[ruby_object.class].convert_to_python(ruby_object))
        else
          @object_wrapper.wrap(ruby_object)
        end
      end
    end

    # todo store conversion-lambdas as well as ruby_object class
    def self.to_ruby(python_object) # to ruby_object
      if Polyglot.eval('python', 'lambda x: type(x) is str').call(python_object)
        python_object.to_s
      else
        python_type = self.get_type(python_object)
        hash = Polyglot.eval('python', 'hash').call(python_type)
        if @mapping_python.has_key?(hash)
          @mapping_python[hash].convert_to_ruby(python_object)
        else
          nil
        end
      end
    end
  end
end