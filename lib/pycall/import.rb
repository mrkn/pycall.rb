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
      raise PyError.fetch unless mod

      define_singleton_method(as) { mod }
    end

    # This function is implemented as a mimic of `import_from` function defined in `Python/ceval.c`.
    def pyfrom(mod_name, import: nil)
      raise ArgumentError, "missing identifiers to be imported" unless import

      mod_name = mod_name.to_str if mod_name.respond_to? :to_str
      mod_name = mod_name.to_s if mod_name.is_a? Symbol

      import = Array(import)
      fromlist = LibPython.PyTuple_New(import.length)
      import.each_with_index do |import_name, i|
        name = case import_name
               when assoc_array_matcher
                 import_name[0]
               when Symbol, String
                 import_name
               end
        LibPython.PyTuple_SetItem(fromlist, i, Conversions.from_ruby(name))
      end

      main_dict = PyCall::Eval.__send__ :main_dict
      globals = main_dict.__pyobj__ # FIXME: this should mimic to `import_name` function defined in `Python/ceval.c`.
      locals = main_dict.__pyobj__ # FIXME: this should mimic to `import_name` function defined in `Python/ceval.c`.
      level = 0 # TODO: support prefixed dots (#25)
      mod = LibPython.PyImport_ImportModuleLevel(mod_name, globals, locals, fromlist, level)
      raise PyError.fetch if mod.null?
      mod = mod.to_ruby

      import.each do |import_name|
        case import_name
        when assoc_array_matcher
          name, asname = *import_name
        when Symbol, String
          name, asname = import_name, import_name
        end

        if PyCall.hasattr?(mod, name)
          pyobj = PyCall.getattr(mod, name)
          define_name(asname, pyobj)
          next
        end

        if PyCall.hasattr?(mod, :__name__)
          pkgname = PyCall.getattr(mod, :__name__)
          fullname = "#{pkgname}.#{name}"
          module_dict = LibPython.PyImport_GetModuleDict()
          if PyCall.getattr(module_dict, fullname)
            pyobj = PyCall.getattr(module_dict, fullname)
            define_name(asname, pyobj)
            next
          end
        end

        raise ArgumentError, "cannot import name #{fullname}" unless pyobj
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

    def assoc_array_matcher
      @assoc_array_matcher ||= ->(ary) do
        ary.is_a?(Array) && ary.length == 2
      end
    end
  end
end
