require 'pycall'
require 'iruby'

module PyCall
  module IRubyHelper
    private

    def check_pyobject_respond_to__repr_html_(obj)
      return false unless obj.kind_of? PyObject
      return false unless PyCall.hasattr?(obj, :_repr_html_)
      obj._repr_html_.kind_of? PyCall::LibPython.PyMethod_Type
    end
  end
end

::IRuby::Display::Registry.module_eval do
  extend PyCall::IRubyHelper

  match do |obj|
    check_pyobject_respond_to__repr_html_(obj)
  end

  format 'text/html' do |obj|
    obj._repr_html_.()
  end
end
