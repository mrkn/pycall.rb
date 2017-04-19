require 'spec_helper'

RSpec.describe PyCall, '.with' do
  before :all do
    PyCall.eval(<<PYTHON, input_type: :file)
class test_context(object):
  def __init__(self, value):
    self.enter_called = False
    self.exit_called = False
    self.value = value
    pass

  def __enter__(self):
    self.enter_called = True
    return self.value

  def __exit__(self):
    self.exit_called = True
    pass
PYTHON
  end

  after :all do
    PyCall.eval('del test_context', input_type: :file)
  end

  let(:test_context) { PyCall.eval('test_context').(42) }

  specify do
    expect {|b| PyCall.with(test_context, &b) }.to yield_with_args(42)
  end

  specify do
    PyCall.with(test_context) do
      expect(test_context.enter_called).to eq(true)
      expect(test_context.exit_called).to eq(false)
    end
    expect(test_context.enter_called).to eq(true)
    expect(test_context.exit_called).to eq(true)
  end
end
