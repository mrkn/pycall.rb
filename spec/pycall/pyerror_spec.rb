require 'spec_helper'

module PyCall
  ::RSpec.describe PyError do
    subject(:pyerror) { PyError.new(type, value, traceback) }

    let(:type) { (PyCall.builtins.len rescue $!).type }
    let(:value) { (PyCall.builtins.len rescue $!).value }
    let(:traceback) { (PyCall.builtins.len rescue $!).traceback }

    describe '#to_s' do
      shared_examples 'does not contain traceback' do
        it 'does not contain traceback' do
          puts subject.to_s.lines.count
          expect(subject.to_s.lines.count).to eq(1)
        end
      end

      context 'when traceback is nil' do
        let(:traceback) { nil }
        include_examples 'does not contain traceback'
      end

      context 'when traceback is null' do
        let(:traceback) { PyCall::PyPtr.new(0) }
        include_examples 'does not contain traceback'
      end
    end
  end
end
