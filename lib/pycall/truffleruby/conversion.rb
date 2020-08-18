module PyCall
  module Conversion

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
          raise ArgumentError.new("#to_ruby and #to_python have to be callable")
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
      @@type ||= Polyglot.eval("python", "type")
      @@type.call(pythonObj)
    end

    def self.register_nice_python_type_mapping(python_object, ruby_class, to_ruby, to_python)
      python_type = self.get_type(python_object)
      @@mapping_python ||= Hash.new
      @@mapping_ruby ||= Hash.new
      hash = Polyglot.eval("python", "hash").call(python_type)
      if @@mapping_python.has_key?(hash)
        false
      else
        converter = Converter.new(to_ruby, to_python, ruby_class, python_type)
        @@mapping_python[hash] = converter
        @@mapping_ruby[ruby_class] = converter
        true
      end
    end

    def self.register_python_type_mapping(python_object, ruby_class)
      self.register_nice_python_type_mapping(python_object, ruby_class,
                                             ->(x, ruby) { a = ruby.allocate; a.__pyptr__ = x; return a },
                                             ->(x, python) { return x.__pyptr__ })
    end



    def self.unregister_python_type_mapping(python_class)
      @@mapping_python ||= Hash.new
      hash = Polyglot.eval("python", "hash").call(python_class)
      if @@mapping_python.has_key?(hash)
        converter = @@mapping_python[hash]
        @@mapping_python.delete hash
        @@mapping_ruby.delete converter.ruby
        true
      else
        false
      end
    end

    def self.from_ruby(ruby_object) # to python
      @@mapping_python ||= Hash.new
      @@mapping_ruby ||= Hash.new
      if @@mapping_ruby.has_key?(ruby_object.class)
        PyObjectWrapper.wrap(@@mapping_ruby[ruby_object.class].convert_to_python(ruby_object))
      else
        PyObjectWrapper.wrap(nil)
      end
    end

    # todo store conversion-lambdas as well as ruby_object class
    def self.to_ruby(python_object) # to ruby_object
      python_type = self.get_type(python_object)
      @@mapping_python ||= Hash.new
      @@mapping_ruby ||= Hash.new
      hash = Polyglot.eval("python", "hash").call(python_type)
      if @@mapping_python.has_key?(hash)
        @@mapping_python[hash].convert_to_ruby(python_object)
      else
        nil
      end
    end
  end


  Conversion.register_nice_python_type_mapping(Polyglot.eval("python", "None"), NilClass,
                                                     ->(x, python) {return nil},
                                                     ->(x, ruby) {return LibPython::API::ForeignNone})
  Conversion.register_nice_python_type_mapping(Polyglot.eval("python", "1+1j"), Complex,
                                               ->(x, ruby) { return PyCall.from_py_complex(x) },
                                               ->(x, python) { return PyCall.to_py_complex(x) })
  Conversion.register_nice_python_type_mapping(Polyglot.eval("python", "str()"), String,
                                               ->(x, ruby){return ruby.new(x)},
                                               ->(x, python){return Polyglot.eval("python", "lambda x: str(x)").call(x)})

end