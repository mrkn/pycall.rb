require 'spec_helper'

module PyCall
  RSpec.describe PyError do
    subject(:pyerror) { PyError.new(type, value, traceback) }

    let(:type) { (PyCall.eval('len()'); PyError.fetch).type }
    let(:value) { (PyCall.eval('len()'); PyError.fetch).value }
    let(:traceback) { (PyCall.eval('len()'); PyError.fetch).traceback }

    describe '#to_s' do
      shared_examples 'does not contain traceback' do
        it 'does not contain traceback' do
          expect(subject.to_s.lines.count).to eq(1)
        end
      end

      context 'when traceback is nil' do
        let(:traceback) { nil }
        include_examples 'does not contain traceback'
      end

      context 'when traceback is null' do
        let(:traceback) { FFI::Pointer::NULL }
        include_examples 'does not contain traceback'
      end
    end
  end
end
