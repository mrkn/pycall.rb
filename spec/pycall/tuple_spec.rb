require 'spec_helper'

module PyCall
  ::RSpec.describe Tuple do
    subject { Tuple.new(1, 2, 3) }

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

    describe '#to_a' do
      it 'returns an array that contains all the items in the subject' do
        expect(subject.to_a).to eq([1, 2, 3])
      end
    end

    describe '#to_ary' do
      it 'is used for multiple assignment' do
        (a1, a2, a3), (b1, b2, b3) = Tuple.new(subject, subject)
        expect([a1, a2, a3]).to eq([1, 2, 3])
        expect([b1, b2, b3]).to eq([1, 2, 3])
      end
    end

    describe '#inspect' do
      pending
    end
  end

  ::RSpec.describe '.tuple' do
    specify do
      expect(PyCall.tuple()).to be_a(Tuple)
      expect(PyCall.tuple(Tuple.new(1, 2, 3))).to eq(Tuple.new(1, 2, 3))
      expect(PyCall.tuple([1, 2, 3])).to eq(Tuple.new(1, 2, 3))
    end
  end
end
