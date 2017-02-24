require 'pycall'

module PyCall
  module Import
    def self.main_object
      @main_object
    end
  end
end

main_object = self
PyCall::Import.class_eval { @main_object = main_object }

module PyCall
  module Import
    def pyimport(mod_name, as: nil)
      case as
      when nil
        as = mod_name
      end

      check_valid_module_variable_name(mod_name, as)

      mod = PyCall.import_module(mod_name)
      define_singleton_method(as) { mod }
    end

    def pyfrom(mod_name, import: nil)
      raise ArgumentError, "missing identifiers to be imported" unless import

      mod = PyCall.import_module(mod_name)
      raise PyError.fetch unless mod

      case import
      when Hash
        import.each do |attr, as|
          val = PyCall.getattr(mod, attr)
          define_name(as, val)
        end
      when Array
        import.each do |attr|
          val = PyCall.getattr(mod, attr)
          define_name(attr, val)
        end
      when Symbol, String
        val = PyCall.getattr(mod, import)
        define_name(import, val)
      end
    end

    private

    def define_name(name, pyobj)
      if constant_name?(name)
        context = self
        context = (self == PyCall::Import.main_object) ? Object : self
        context.module_eval { const_set(name, pyobj) }
      else
        define_singleton_method(name) { pyobj }
      end
    end

    def constant_name?(name)
      name =~ /\A[A-Z]/
    end

    def check_valid_module_variable_name(mod_name, var_name)
      var_name = var_name.to_s if var_name.kind_of? Symbol
      if var_name.include?('.')
        raise ArgumentError, "#{var_name} is not a valid module variable name, use pyimport #{mod_name}, as: <name>"
      end
    end
  end
end
