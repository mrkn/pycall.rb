require 'pycall'

module PyCall
  module Import
    class << self
      attr_reader :main_object
    end
  end
end

PyCall::Import.instance_variable_set(:@main_object, self)

module PyCall
  module Import
    def pyimport(mod_name, as: nil)
      as = mod_name unless as
      check_valid_module_variable_name(mod_name, as)
      mod = PyCall.import_module(mod_name)
      define_singleton_method(as) { mod }
    end

    # This function is implemented as a mimic of `import_from` function defined in `Python/ceval.c`.
    def pyfrom(mod_name, import: nil)
      raise ArgumentError, "missing identifier(s) to be imported" unless import

      mod_name = mod_name.to_str if mod_name.respond_to? :to_str
      mod_name = mod_name.to_s if mod_name.is_a? Symbol

      import = Array(import)
      fromlist = import.map.with_index do |import_name, i|
        case import_name
        when assoc_array_matcher
          import_name[0]
        when Symbol, String
          import_name
        else
          raise ArgumentError, "wrong type of import name #{import_name.class} (expected String or Symbol)"
        end
      end
      from_list = PyCall.tuple(from_list)

      main_dict_ptr = PyCall.import_module('__main__').__dict__.__pyptr__
      globals = main_dict_ptr # FIXME: this should mimic to `import_name` function defined in `Python/ceval.c`.
      locals = main_dict_ptr # FIXME: this should mimic to `import_name` function defined in `Python/ceval.c`.
      level = 0 # TODO: support prefixed dots (#25)
      mod = LibPython::Helpers.import_module(mod_name, globals, locals, fromlist, level)

      import.each do |import_name|
        case import_name
        when assoc_array_matcher
          name, asname = *import_name
        when Symbol, String
          name, asname = import_name, import_name
        end

        if PyCall::LibPython::Helpers.hasattr?(mod.__pyptr__, name)
          pyobj = PyCall::LibPython::Helpers.getattr(mod.__pyptr__, name)
          define_name(asname, pyobj)
          next
        end

        if mod.respond_to? :__name__
          pkgname = mod.__name__
          fullname = "#{pkgname}.#{name}"
          sys_modules = PyCall.import_module('sys').modules
          if sys_modules.has_key?(fullname)
            pyobj = module_dict[fullname]
            define_name(asname, pyobj)
            next
          end
        end

        raise ArgumentError, "cannot import name #{fullname}" unless pyobj
      end
    end

    private

    def define_name(name, pyobj)
      if callable?(pyobj) && !type_object?(pyobj)
        define_singleton_method(name) do |*args|
          LibPython::Helpers.call_object(pyobj.__pyptr__, *args)
        end
      else
        if constant_name?(name)
          context = self
          context = (self == PyCall::Import.main_object) ? Object : self
          context.module_eval { const_set(name, pyobj) }
        else
          define_singleton_method(name) { pyobj }
        end
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

    def callable?(pyobj)
      LibPython::Helpers.callable?(pyobj.__pyptr__)
    end

    def type_object?(pyobj)
      pyobj.__pyptr__.kind_of? PyTypePtr
    end
  end
end
