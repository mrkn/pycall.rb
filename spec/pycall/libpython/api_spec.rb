require 'spec_helper'

module PyCall
  module LibPython
    ::RSpec.describe API do
      describe '.builtins_module_ptr' do
        subject { API.builtins_module_ptr }
        it { is_expected.to be_a(PyPtr) }

        it 'returns the different instance but the same address' do
          other = API.builtins_module_ptr
          expect(subject).not_to equal(other)
          expect(subject.__address__).to eq(other.__address__)
        end
      end
    end
  end
end
