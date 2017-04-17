module PyCall
  module Eval
    Py_file_input = 257
    Py_eval_input = 258

    def self.input_type(sym)
      return Py_file_input if sym == :file
      return Py_eval_input if sym == :eval
      raise ArgumentError, "Unknown input_type for compile Python code"
    end

    def self.eval(str, filename: "pycall", input_type: :eval)
      input_type = self.input_type(input_type)
      globals_ptr = main_dict.__pyobj__
      locals_ptr = main_dict.__pyobj__
      defer_sigint do
        py_code_ptr = LibPython.Py_CompileString(str, filename, input_type)
        raise PyError.fetch if py_code_ptr.null?
        LibPython.PyEval_EvalCode(py_code_ptr, globals_ptr, locals_ptr)
      end
    end

    class << self
      private

      def main_dict
        @main_dict ||= PyCall.import_module("__main__") do |main_module|
          PyCall.incref(LibPython.PyModule_GetDict(main_module.__pyobj__)).to_ruby
        end
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
    value = value.to_ruby
    return value unless block_given?
    begin
      yield value
    ensure
      PyCall.decref(value.__pyobj__)
    end
  end

  def self.eval(str, conversion: true, filename: "pycall", input_type: :eval)
    result = Eval.eval(str, filename: filename, input_type: input_type)
    conversion ? result.to_ruby : result
  end
end
