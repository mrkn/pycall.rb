require 'pycall'
require 'iruby'

module PyCall
  module IRubyHelper
    ::IRuby::Display::Registry.module_eval do
      match do |obj|
        obj.kind_of?(PyCall::PyObject) &&
          PyCall.hasattr?(obj, :_repr_html_) &&
          obj._repr_html_.kind_of?(PyCall::PyObject) &&
          obj._repr_html_.kind_of?(PyCall::LibPython.PyMethod_Type)
      end
      format 'text/html' do |obj|
        obj._repr_html_.()
      end
    end
  end
end
