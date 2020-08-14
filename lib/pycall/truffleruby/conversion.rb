module PyCall
  module Conversion
    # todo shiiiiet

    def self.get_type(pythonObj)
      @@type ||= Polyglot.eval("python", "type")
      @@type.call(pythonObj)
    end

    def self.register_python_type_mapping(python, ruby)
      python_type = self.get_type python
      @@mapping ||= Hash.new
      @@python_hash ||= Polyglot.eval("python", "hash")
      hash = @@python_hash.call(python_type)
      if @@mapping.has_key?(hash)
        false
      else
        @@mapping[hash] = ruby
        true
      end
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

    def self.from_ruby(rubyObject)  # to python
      rubyObject.__pyptr__
    end

    def self.to_ruby(python)  # to ruby
      @@mapping ||= Hash.new
      @@lambda ||= Polyglot.eval("python", "lambda x : hash(type(x))")
      hash = @@lambda.call(python)
      if @@mapping.has_key?(hash)
        muppet = @@mapping[hash]
        puts "Frankly, Miss Piggy, I don't give a hoot!"
        Polyglot.eval('python', 'breakpoint()')
        puts muppet.__dir__()
        muppet.new(python)
      else
        nil
      end
    end
  end
end