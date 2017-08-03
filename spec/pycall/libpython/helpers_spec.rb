require 'spec_helper'

module PyCall
  module LibPython
    ::RSpec.describe Helpers do
      describe '.import_module' do
        it 'is a wrapper method of PyImport_ImportModule'
      end

      describe '.getattr' do
        it 'is a wrapper method of PyObject_GetAttrString' do
          builtins_ptr = LibPython::API.builtins_module_ptr

          expect(Helpers.getattr(builtins_ptr, :object)).to be_a(PyCall::PyTypeObjectWrapper)

          expect { Helpers.getattr(builtins_ptr, :non_existing_name) }.to raise_error(PyCall::PyError)

          default_value = Object.new
          expect(Helpers.getattr(builtins_ptr, :non_existing_name, default_value)).to eq(default_value)
        end
      end
 
      describe '.hasattr?' do
        it 'is a wrapper method of PyObject_HasAttrString' do
          builtins_ptr = LibPython::API.builtins_module_ptr
          expect(Helpers.hasattr?(builtins_ptr, :object)).to eq(true)
          expect(Helpers.hasattr?(builtins_ptr, :non_existing_name)).to eq(false)
        end
      end

      describe '.define_wrapper_method' do
        it 'defines a wrapper method of a instance method of a Python object'
      end
    end
  end
end
