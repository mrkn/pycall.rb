require 'spec_helper'

module PyCall
  ::RSpec.describe List do
    subject(:list) { PyCall::List.new([1, 2, 3]) }

    describe '#length' do
      subject { list.length }
      it { is_expected.to eq(3) }
    end
  end
end
