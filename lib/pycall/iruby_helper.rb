require 'pycall'
require 'iruby'

module PyCall
  module IRubyHelper
    private

    def check_pyobject_respond_to_format_method(obj, method_name)
      return false unless obj.kind_of? PyObject
      return false unless PyCall.hasattr?(obj, method_name)
      PyCall.getattr(obj, method_name).kind_of? PyCall::LibPython.PyMethod_Type
    end

    def register_pyobject_formatter(format_name, mime, priority_value=0)
      method_name = :"_repr_#{format_name}_"
      match do |obj|
        check_pyobject_respond_to_format_method(obj, method_name)
      end
      priority priority_value
      format mime do |obj|
        PyCall.getattr(obj, method_name).()
      end
    end
  end
end

::IRuby::Display::Registry.module_eval do
  extend PyCall::IRubyHelper

  register_pyobject_formatter :html, 'text/html'
  register_pyobject_formatter :markdown, 'text/markdown'
  register_pyobject_formatter :svg, 'image/svg+xml'
  register_pyobject_formatter :png, 'image/png'
  register_pyobject_formatter :jpeg, 'image/jpeg'
  register_pyobject_formatter :latex, 'text/latex'
  register_pyobject_formatter :json, 'application/json'
  register_pyobject_formatter :javascript, 'application/javascript'
  register_pyobject_formatter :pdf, 'application/pdf'
  register_pyobject_formatter :pretty, 'text/plain', -1000
end
