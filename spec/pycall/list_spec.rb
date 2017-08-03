require 'spec_helper'

module PyCall
  ::RSpec.describe List do
    subject(:list) { PyCall::List.new([1, 2, 3]) }

    describe '#length' do
      subject { list.length }
      it { is_expected.to eq(3) }
    end

    describe '#each' do
      context 'without a block' do
        it 'returns an Enumerator' do
          expect(subject.each).to be_a(Enumerator)
        end
      end

      context 'with a block' do
        it 'enumerates each item' do
          expect { |b|
            subject.each(&b)
          }.to yield_successive_args(1, 2, 3)
        end
      end
    end

    describe '#<<' do
      it 'appends the given object' do
        expect { list << 4 }.to change { list.length }.from(3).to(4)
        expect(list[-1]).to eq(4)
      end
    end

    describe '#push' do
      it 'appends all the given objects' do
        expect { list.push(4, 5, 6) }.to change { list.length }.from(3).to(6)
        expect(list[PyCall::Slice.new(-3, nil)].to_a).to eq([4, 5, 6])
      end
    end

    describe '#sort' do
      subject(:ary) { [5, 3, 9, 2, 10, 8, 1, 6, 4, 7] }
      subject(:list) { PyCall::List.new(ary) }

      it 'returns a new sorted PyCall::List' do
        expect(list.sort).not_to equal(list)
        expect(list.sort.to_a).to eq(ary.sort)
      end

      it 'does not change the list' do
        list.sort
        expect(list.to_a).to eq(ary)
      end
    end

    describe '#sort!' do
      subject(:ary) { [5, 3, 9, 2, 10, 8, 1, 6, 4, 7] }
      subject(:list) { PyCall::List.new(ary) }

      it 'sorts the list in place' do
        expect(list.sort!).to equal(list)
        expect(list.to_a).not_to eq(ary)
        expect(list.to_a).to eq(ary.sort)
      end
    end
  end
end
