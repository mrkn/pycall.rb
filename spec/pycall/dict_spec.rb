require 'spec_helper'

module PyCall
  describe Dict do
    subject { Dict.new('a' => 1, 'b' => 2, 'c' => 3) }

    specify do
      expect(subject['a']).to eq(1)
      expect(subject['b']).to eq(2)
      expect(subject['c']).to eq(3)
    end

    describe '#has_key?' do
      specify do
        expect(subject).to have_key('a')
        expect(subject).to have_key('b')
        expect(subject).to have_key('c')
        expect(subject).not_to have_key('d')
      end
    end
  end
end
