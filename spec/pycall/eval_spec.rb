require 'spec_helper'

describe PyCall do
  def py_eval(src)
    PyCall.eval(src)
  end

  def self.describe_eval(src, &block)
    describe ".eval(#{src.inspect})" do
      subject { py_eval(src) }
      module_eval &block
    end
  end

  describe_eval('None') do
    it { is_expected.to equal(nil) }
  end

  describe_eval('True') do
    it { is_expected.to equal(true) }
  end

  describe_eval('False') do
    it { is_expected.to equal(false) }
  end

  describe_eval('1') do
    it { is_expected.to be_kind_of(Integer) }
    it { is_expected.to eq(1) }
  end

  describe_eval('1.0') do
    it { is_expected.to be_kind_of(Float) }
    it { is_expected.to eq(1.0) }
  end

  describe_eval('complex(1, 2)') do
    it { is_expected.to eq(1 + 2i) }
  end

  describe_eval('"python"') do
    it { is_expected.to eq("python") }
  end

  describe_eval('[1, 2, 3]') do
    it { is_expected.to eq([1, 2, 3]) }
  end

  describe_eval('(1, 2, 3)') do
    it { is_expected.to be_kind_of(PyCall::Tuple) }
    it { is_expected.to eq(PyCall::Tuple[1, 2, 3]) }
  end

  describe_eval('{ "a": 1, "b": 2 }') do
    it { is_expected.to eq({ 'a' => 1, 'b' => 2 }) }
  end

  describe_eval('{1, 2, 3}') do
    it { is_expected.to be_kind_of(Set) }
    it { is_expected.to eq(Set[1, 2, 3]) }
  end
end
