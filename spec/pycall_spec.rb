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

  describe '.None' do
    subject { PyCall.None }
    it { is_expected.to be_py_none }
    it { is_expected.not_to be_nil }
    it { is_expected.to eq(PyCall.eval('None')) }
  end

  describe '.callable?' do
    it 'detects whether the given object is callable' do
      expect(PyCall.callable?(PyCall.eval('str'))).to eq(true)
      expect(PyCall.callable?(PyCall.eval('object()'))).to eq(false)
      expect(PyCall.callable?(PyCall::LibPython.PyDict_Type)).to eq(true)
      expect(PyCall.callable?(PyCall::Dict.new('a' => 1))).to eq(false)
      expect { PyCall.callable?(42) }.to raise_error(TypeError)
    end
  end

  describe '.dir' do
    it 'calls global dir function' do
      expect(PyCall.dir(PyCall.eval('object()'))).to include('__class__')
    end
  end
end
