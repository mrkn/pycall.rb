require 'spec_helper'

module PyCall
  describe PyObject do
    describe '.null' do
      specify do
        expect(PyObject.null).to be_null
      end
    end

    describe '#call' do
      it 'calls a PyObject as a function' do
        expect(PyCall.str(42)).to eq('42')
        expect(PyCall.int(10 * Math::PI)).to eq(31)
      end
    end

    describe '#type' do
      it 'returns python type' do
        expect(PyCall::Conversions.from_ruby(1).type.inspect).to eq "<class 'int'>"
      end
    end
  end
end
