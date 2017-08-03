require 'spec_helper'

::RSpec.describe PyCall, '.with' do
  let(:test_context_class) do
    PyCall.import_module('pycall.with_test').test_context
  end

  let(:test_context) do
    test_context_class.new(42)
  end

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
            test_context.error('error in Python')
          end
        }.not_to raise_error
        expect(test_context.exit_called[0]).not_to be_nil
        expect(test_context.exit_called[1]).not_to be_nil
        expect(test_context.exit_called[1].to_s).to eq('error in Python')
        expect(test_context.exit_called[2]).not_to be_nil
      end
    end

    context 'when __exit__ returns not True' do
      specify do
        expect {
          PyCall.with(test_context) do
            test_context.error('error in Python')
          end
        }.to raise_error(PyCall::PyError, /error in Python/)
        expect(test_context.exit_called[0]).not_to be_nil
        expect(test_context.exit_called[1]).not_to be_nil
        expect(test_context.exit_called[1].to_s).to eq('error in Python')
        expect(test_context.exit_called[2]).not_to be_nil
      end
    end
  end

  context 'in an exception occurred in Ruby' do
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
        expect(test_context.exit_called[0]).to eq(RuntimeError)
        expect(test_context.exit_called[1]).to be_a(RuntimeError)
        expect(test_context.exit_called[1].message).to eq('error in Ruby')
        expect(test_context.exit_called[2]).to be_a(PyCall::List)
        expect(test_context.exit_called[2]).to be_all {|x| x.is_a?(Thread::Backtrace::Location) }
      end
    end
  end
end
