module PyCall
  module Conversion
    # todo shiiiiet

    class Converter
      def initialize(to_ruby, to_python, ruby, python)
        if to_ruby.is_a?(Proc) && to_python.is_a?(Proc)
          @to_ruby = to_ruby
          @to_python = to_python
          @ruby = ruby
          @python = python
        else
          raise ArgumentError.new("#to_ruby and #to_python have to be callable")
        end
      end

      def convert_to_ruby(python)
        @to_ruby.call(python, @python)
      end

      def convert_to_python(ruby_object)
        @to_python.call(ruby_object, @ruby)
      end

    end

    def self.get_type(pythonObj)
      @@type ||= Polyglot.eval("python", "type")
      @@type.call(pythonObj)
    end

    def self.register_nice_python_type_mapping(python_object, ruby_class, to_ruby, to_python)
      python_type = self.get_type python_object
      @@mapping ||= Hash.new
      @@python_hash ||= Polyglot.eval("python", "hash")
      hash = @@python_hash.call(python_type)
      if @@mapping.has_key?(hash)
        false
      else
        @@mapping[hash] = Converter.new(to_ruby, to_python, ruby_class, python_type)
        true
      end
    end

    def self.register_python_type_mapping(python, ruby)
      self.register_nice_python_type_mapping(python, ruby,
                                             ->(x, ruby) { return ruby.new(x) },
                                             ->(x, python) { return x.__pyptr__ })
    end

    def self.unregister_python_type_mapping(python, ruby)
      python_type = self.get_type python
      @@mapping ||= Hash.new
      @@python_hash ||= Polyglot.eval("python", "hash")
      hash = @@python_hash.call(python_type)
      if @@mapping.has_key?(hash)
        @@mapping.delete hash
        true
      else
        @@mapping[hash] = ruby
        false
      end
    end

    def self.from_ruby(rubyObject) # to python
      rubyObject.__pyptr__
    end

    # todo store conversion-lambdas as well as ruby_object class
    def self.to_ruby(python) # to ruby_object
      @@mapping ||= Hash.new
      @@lambda ||= Polyglot.eval("python", "lambda x : hash(type(x))")
      hash = @@lambda.call(python)
      if @@mapping.has_key?(hash)
        @@mapping[hash].convert_to_ruby(python)
      else
        nil
      end
    end
  end


  Conversion.register_nice_python_type_mapping(Polyglot.eval("python", "None"), NilClass.class,
                                                     ->(x, python) {return nil},
                                                     ->(x, ruby) {return PyCall::LibPython::API::None.__pyptr__})
  Conversion.register_nice_python_type_mapping(Polyglot.eval("python", "1+1j"), Complex.class,
                                                     ->(x, python) { return PyCall.from_py_complex(x) },
                                                     ->(x, ruby) { return PyCall.to_py_complex(x) })
end