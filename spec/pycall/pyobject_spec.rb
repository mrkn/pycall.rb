require 'spec_helper'

module PyCall
  ::RSpec.describe PyObject do
    describe '.null' do
      specify do
        expect(PyObject.null).to be_null
      end
    end

    describe '#call' do
      it 'calls a PyObject as a function' do
        expect(PyCall.str(42)).to eq('42')
        expect(PyCall.int(10 * Math::PI)).to eq(31)
      end
    end

    describe '#type' do
      subject { PyObject.new(PyCall::Conversions.from_ruby(1)) }

      it 'returns python type' do
        expect(subject.type.inspect).to eq "pytype(int)"
      end
    end

    describe '#hash' do
      before do
        PyCall.eval(<<PYTHON, input_type: :file)
class TestClass:
  def __init__(self):
    self.hash_called = False
    pass

  def __hash__(self):
    self.hash_called = True
    return 42
PYTHON
      end

      after do
        PyCall.eval('del TestClass', input_type: :file)
      end

      specify do
        test_obj = PyCall.eval('TestClass()')
        expect {
          test_obj.hash
        }.to change {
          test_obj.hash_called
        }.from(false).to(true)
      end
    end

    describe '#eql?' do
      before do
        PyCall.eval(<<PYTHON, input_type: :file)
class TestClass:
  def __init__(self):
    self.eq_called = False

  def __eq__(self, other):
    self.eq_called = True
    return False
PYTHON
      end

      after do
        PyCall.eval('del TestClass', input_type: :file)
      end

      specify do
        test_obj = PyCall.eval('TestClass()')
        hash = {}
        expect {
          expect(test_obj.eql?(test_obj)).to eq(false)
        }.to change {
          test_obj.eq_called
        }.from(false).to(true)
      end
    end

    describe 'for hash key' do
      before do
        PyCall.eval(<<PYTHON, input_type: :file)
class TestClass:
  def __init__(self, value):
    self.value = value
    pass

  def __hash__(self):
    return self.value % 2

  def __eq__(self, other):
    return (self.value % 2) == (other.value % 2)
PYTHON
      end

      after do
        PyCall.eval('del TestClass', input_type: :file)
      end

      specify do
        po1 = PyCall.eval('TestClass(42)')
        po2 = PyCall.eval('TestClass(43)')
        po3 = PyCall.eval('TestClass(44)')
        vo = Object.new
        hash = {}
        hash[po1] = vo
        expect(hash[po1]).to be_equal(vo)
        expect(hash[po2]).to be_equal(nil)
        expect(hash[po3]).to be_equal(vo)
      end
    end
  end
end
