require 'pycall'
require 'iruby'

module PyCall
  module IRubyHelper
    private

    def check_pyobject_respond_to_format_method(obj, format)
      return false unless obj.kind_of? PyObject
      method_name = :"_repr_#{format}_"
      return false unless PyCall.hasattr?(obj, method_name)
      PyCall.getattr(obj, method_name).kind_of? PyCall::LibPython.PyMethod_Type
    end
  end
end

::IRuby::Display::Registry.module_eval do
  extend PyCall::IRubyHelper

  match do |obj|
    check_pyobject_respond_to_format_method(obj, :html)
  end
  format 'text/html' do |obj|
    obj._repr_html_.()
  end
end
