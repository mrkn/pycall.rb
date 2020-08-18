require 'spec_helper'

::RSpec.describe PyCall::PyModuleWrapper do
  let(:simple_module) do
    PyCall.import_module('pycall.simple_module')
  end

  specify do
    if RUBY_ENGINE != "truffleruby"
      #it's a clas for truffleruby
      expect(simple_module).to be_an_instance_of(Module)
    end
    expect(simple_module).to be_a(PyCall::PyModuleWrapper)
    expect(simple_module).to be_a(PyCall::PyObjectWrapper)
  end

  describe '#[]' do
    specify do
      expect(simple_module[:double]).to be_a(PyCall::PyObjectWrapper)
      expect(simple_module[:double].call(2)).to eq(4)
      expect(simple_module[:answer]).to eq(42)
    end
  end
end
