require 'spec_helper'

module PyCall
  ::RSpec.describe Tuple do
    subject { Tuple[1, 2, 3] }

    specify do
      expect(subject[0]).to eq(1)
      expect(subject[1]).to eq(2)
      expect(subject[2]).to eq(3)
    end

    describe '#length' do
      it 'returns its size' do
        expect(subject.length).to eq(3)
      end
    end
  end
end
