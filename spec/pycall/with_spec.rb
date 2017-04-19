require 'spec_helper'

RSpec.describe PyCall, '.with' do
  before :all do
    PyCall.eval(<<PYTHON, input_type: :file)
class test_context(object):
  def __init__(self, value):
    self.enter_called = False
    self.exit_called = False
    self.exit_value = None
    self.value = value
    pass

  def __enter__(self):
    self.enter_called = True
    return self.value

  def __exit__(self, exc_type, exc_value, traceback):
    self.exit_called = (exc_type, exc_value, traceback)
    return self.exit_value

  def error(self, message):
    raise Exception(message)
PYTHON
end

  after :all do
    PyCall.eval('del test_context', input_type: :file)
  end

  let(:test_context) { PyCall.eval('test_context(42)') }

  specify do
    expect {|b| PyCall.with(test_context, &b) }.to yield_with_args(42)
  end

  context 'in a normal case' do
    specify do
      PyCall.with(test_context) do
        expect(test_context.enter_called).to eq(true)
        expect(test_context.exit_called).to eq(false)
      end
      expect(test_context.enter_called).to eq(true)
      expect(test_context.exit_called).to be_a(PyCall::Tuple)
      expect(test_context.exit_called[0]).to be_nil
      expect(test_context.exit_called[1]).to be_nil
      expect(test_context.exit_called[2]).to be_nil
    end
  end

  context 'in an exception occurred in Python' do
    context 'when __exit__ returns True' do
      specify do
        expect {
          PyCall.with(test_context) do
            test_context.exit_value = true
            test_context.error.('error in Python')
          end
        }.not_to raise_error
        expect(test_context.exit_called[0]).not_to be_nil
        expect(test_context.exit_called[1]).not_to be_nil
        expect(PyCall.str(test_context.exit_called[1])).to eq('error in Python')
        expect(test_context.exit_called[2]).not_to be_nil
      end
    end

    context 'when __exit__ returns not True' do
      specify do
        expect {
          PyCall.with(test_context) do
            test_context.error.('error in Python')
          end
        }.to raise_error(PyCall::PyError, /error in Python/)
        expect(test_context.exit_called[0]).not_to be_nil
        expect(test_context.exit_called[1]).not_to be_nil
        expect(PyCall.str(test_context.exit_called[1])).to eq('error in Python')
        expect(test_context.exit_called[2]).not_to be_nil
      end
    end
  end

  xcontext 'in an exception occurred in Ruby' do
    context 'when __exit__ returns True' do
      specify do
        expect {
          PyCall.with(test_context) do
            test_context.exit_value = true
            raise "error in Ruby"
          end
        }.not_to raise_error
        expect(test_context.exit_called[0]).not_to be_nil
        expect(test_context.exit_called[1]).not_to be_nil
        expect(test_context.exit_called[1].message).to eq('error in Ruby')
        expect(test_context.exit_called[2]).not_to be_nil
      end
    end

    context 'when __exit__ returns not True' do
      specify do
        expect {
          PyCall.with(test_context) do
            raise "error in Ruby"
          end
        }.to raise_error(RuntimeError, /error in Ruby/)
        expect(test_context.exit_called[0]).not_to be_nil
        expect(test_context.exit_called[1]).not_to be_nil
        expect(test_context.exit_called[1].message).to eq('error in Ruby')
        expect(test_context.exit_called[2]).not_to be_nil
      end
    end
  end
end
