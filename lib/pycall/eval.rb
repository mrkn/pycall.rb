module PyCall
  module Eval
    Py_eval_input = 258

    def self.eval(str, filename: "pycall")
      globals_ptr = maindict_ptr
      locals_ptr = maindict_ptr
      defer_sigint do
        py_code_ptr = LibPython.Py_CompileString(str, filename, Py_eval_input)
        LibPython.PyEval_EvalCode(py_code_ptr, globals_ptr, locals_ptr)
      end
    end

    class << self
      private

      def maindict_ptr
        LibPython.PyModule_GetDict(PyCall.import_module("__main__"))
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
    return value.to_ruby unless value.null?
    raise PyError.fetch
  end

  def self.eval(str)
    Eval.eval(str).to_ruby
  end
end
