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
      subject { PyObject.new(PyCall::Conversions.from_ruby(1)) }

      it 'returns python type' do
        expect(subject.type.inspect).to eq "pytype(int)"
      end
    end
  end
end
