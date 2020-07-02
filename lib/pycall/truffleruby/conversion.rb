module PyCall
  module Conversion
    # todo shiiiiet

    def self.get_type(pythonObj)
      return PyCall.builtins.type(pythonObject)
    end

    def self.register_python_type_mapping(python, ruby)
      python_type = self.get_type python
      @@mapping ||= Hash.new
      if @@mapping.has_key?(python_type)
        false
      else
        @@mapping[python_type] = ruby
        true
      end
    end

    def self.unregister_python_type_mapping(python, ruby)
      python_type = self.get_type python
      @@mapping ||= Hash.new
      if @@mapping.has_key?(python_type)
        @@mapping.delete python_type
        true
      else
        @@mapping[python_type] = ruby
        false
      end
    end

    def self.from_ruby(rubyObject)  # to python
      rubyObject.__pyptr__
    end

    def self.to_ruby(python)  # to ruby
      @@mapping[self.get_type python].new(python)
    end
  end
end