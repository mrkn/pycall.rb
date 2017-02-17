require "spec_helper"

describe PyCall do
  it "has a version number" do
    expect(PyCall::VERSION).not_to be nil
  end

  describe 'PYTHON_VERSION' do
    it "has a Python's version number" do
      expect(PyCall::PYTHON_VERSION).to be_kind_of(String)
    end
  end
end
