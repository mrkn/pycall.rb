module PyCall
  module Eval
    Py_eval_input = 258

    def self.eval(str, filename: "pycall")
      globals_ptr = maindict_ptr
      locals_ptr = maindict_ptr
      defer_sigint do
        py_code_ptr = LibPython.Py_CompileString(str, filename, Py_eval_input)
        raise PyError.fetch if py_code_ptr.null?
        LibPython.PyEval_EvalCode(py_code_ptr, globals_ptr, locals_ptr)
      end
    end

    class << self
      private

      def main_module
        @main_module ||= PyCall.import_module("__main__")
      end

      def maindict_ptr
        @maindict_ptr ||= LibPython.PyModule_GetDict(main_module)
      end

      def defer_sigint
        # TODO: should be implemented
        yield
      end
    end
  end

  def self.import_module(name)
    name = name.to_s if name.kind_of? Symbol
    raise TypeError, "name must be a String" unless name.kind_of? String
    value = LibPython.PyImport_ImportModule(name)
    raise PyError.fetch if value.null?
    value.to_ruby
  end

  def self.eval(str, conversion: true)
    result = Eval.eval(str)
    conversion ? result.to_ruby : result
  end
end
