require 'pycall' unless defined?(::PyCall)
require 'iruby'

module PyCall
  module IRubyHelper
    private

    def check_python_object_respond_to_format_method(obj, method_name)
      return false unless obj.kind_of? PyObjectWrapper
      return false unless obj.respond_to? method_name
      true
    end

    def register_python_object_formatter(format_name, mime, priority_value=0)
      method_name = :"_repr_#{format_name}_"
      match do |obj|
        check_python_object_respond_to_format_method(obj, method_name)
      end
      priority priority_value
      format mime, &method_name
    end
  end
end

::IRuby::Display::Registry.module_eval do
  extend PyCall::IRubyHelper

  register_python_object_formatter :html, 'text/html', 1
  register_python_object_formatter :markdown, 'text/markdown', 1
  register_python_object_formatter :svg, 'image/svg+xml', 1
  register_python_object_formatter :png, 'image/png', 1
  register_python_object_formatter :jpeg, 'image/jpeg', 1
  register_python_object_formatter :latex, 'text/latex', 1
  register_python_object_formatter :json, 'application/json', 1
  register_python_object_formatter :javascript, 'application/javascript', 1
  register_python_object_formatter :pdf, 'application/pdf', 1
  register_python_object_formatter :pretty, 'text/plain', -1000
end
