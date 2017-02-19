module PyCall
  module Import
    def pyimport(mod_name, as: nil)
      case as
      when nil
        as = mod_name.to_str
      else
        as = as.to_str
      end

      check_valid_module_variable_name(mod_name, as)

      mod = PyCall.import_module(mod_name)
      define_singleton_method(as) { mod }
    end

    def pyfrom(mod_name, import: nil)
      raise ArgumentError, "missing identifiers to be imported" unless import

      mod = PyCall.import_module(mod_name)

      case import
      when Hash
        import.each do |attr, as|
          val = PyCall.getattr(mod, attr)
          define_singleton_method(as) { val }
        end
      when Array
        import.each do |attr|
          val = PyCall.getattr(mod, attr)
          define_singleton_method(attr) { val }
        end
      when Symbol, String
        val = PyCall.getattr(mod, import)
        define_singleton_method(import) { val }
      end
    end

    private

    def check_valid_module_variable_name(mod_name, var_name)
      if var_name.include?('.')
        raise ArgumentError, "#{var_name} is not a valid module variable name, use pyimport #{mod_name}, as: <name>"
      end
    end
  end
end
