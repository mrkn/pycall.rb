require 'spec_helper'

RSpec.describe PyCall do
  describe '.eval' do
    context 'without globals' do
      context 'without locals' do
        it 'evaluates immediate values correctly' do
          expect(PyCall.eval('None')).to eq(nil)
          expect(PyCall.eval('True')).to eq(true)
          expect(PyCall.eval('False')).to eq(false)
          expect(PyCall.eval('1')).to eq(1)
          expect(PyCall.eval('1.1')).to eq(1.1)
          expect(PyCall.eval('"a"')).to eq("a")
          expect(PyCall.eval('"あ"').force_encoding('UTF-8')).to eq("あ") # TODO: force_encoding
        end
        it 'handles complex numbers correctly' do
          expect(PyCall.eval('1 + 2j')).to eq(1 + 2i)
        end
        it 'evaluates complex object wrappers correctly' do
          expect(PyCall.eval('[1, 2, 3]')).to eq(PyCall::List.new([1, 2, 3])) # TODO: PyCall::List[1, 2, 3]
          expect(PyCall.eval('(1, 2, 3)')).to eq(PyCall::Tuple.new(1, 2, 3))
          expect(PyCall.eval('{"a": 1, "b": 2}')).to eq(PyCall::Dict.new(a: 1, b: 2))
          expect(PyCall.eval('{1, 2, 3}')).to eq(PyCall.builtins.set.new([1, 2, 3]))
        end

        it 'raises an exception occurred in Python side' do
          expect { PyCall.eval('raise Exception("abcdef")') }.to raise_error(PyCall::PyError, /abcdef/)
        end
      end

      context 'with locals of a Hash' do
        pending
      end

      xcontext 'with locals of a binding' do
      end
    end

    xcontext 'with globals' do
      context 'without locals' do
      end

      context 'with locals of a Hash' do
      end

      context 'with locals of a binding' do
      end
    end
  end

  describe '.exec' do
    context 'without globals' do
      context 'without locals' do
        specify do
          expect(PyCall.exec(<<-PYTHON)).to eq(nil)
class Hoge:
  pass
          PYTHON
          expect(PyCall.import_module(:__main__).Hoge).to be_a(Class)
        end

        it 'raises an exception occurred in Python side' do
          expect { PyCall.exec('raise Exception("abcdef")') }.to raise_error(PyCall::PyError, /abcdef/)
        end
      end

      context 'with locals of a Hash' do
        pending
      end

      xcontext 'with locals of a binding' do
      end
    end

    xcontext 'with globals' do
      context 'without locals' do
      end

      context 'with locals of a Hash' do
      end

      context 'with locals of a binding' do
      end
    end
  end
end
