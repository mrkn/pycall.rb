require 'spec_helper'
require 'tmpdir'

module PyCall
  module LibPython
    ::RSpec.describe Finder do
      describe '.investigate_python_config' do
        subject { Finder.investigate_python_config('python') }

        it { is_expected.to be_a(Hash) }
      end
    end
  end
end
