require "spec_helper"

module PyCall
  ::RSpec.describe LibPython do
    describe '.Py_GetVersion' do
      it "is available" do
        expect(LibPython.Py_GetVersion()).to be_a(String)
      end
    end
  end
end
