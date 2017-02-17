require 'spec_helper'

module PyCall
  describe Dict do
    subject { Dict.new('a' => 1, 'b' => 2, 'c' => 3) }

    specify do
      expect(subject['a']).to eq(1)
      expect(subject['b']).to eq(2)
      expect(subject['c']).to eq(3)
    end
  end
end
