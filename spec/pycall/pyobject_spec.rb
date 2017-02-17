require 'spec_helper'

module PyCall
  describe PyObject do
    describe '#call' do
      let(:str) { PyCall.eval('str') }
      let(:int) { PyCall.eval('int') }

      it 'calls a PyObject as a function' do
        expect(str.(42)).to eq('42')
        expect(int.(10 * Math::PI)).to eq(31)
      end
    end
  end
end
