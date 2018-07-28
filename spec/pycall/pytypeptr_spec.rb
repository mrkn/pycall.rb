require 'spec_helper'

module PyCall
  ::RSpec.describe PyTypePtr do
    describe '#subclass?(other)' do
      subject { PyCall::List.__pyptr__ }

      context 'when the value of `other` is a PyTypePtr' do
        specify do
          expect(subject.subclass?(PyCall.builtins.object.__pyptr__)).to eq(true)
          expect(subject.subclass?(PyCall.builtins.dict.__pyptr__)).to eq(false)
        end
      end

      context 'when the value of `other` is a PyPtr' do
        specify do
          expect { subject.subclass?(Conversion.from_ruby(42)) }.to raise_error(TypeError)
        end
      end

      context 'when the value of `other` is a PyTypeObjectWrapper' do
        specify do
          expect { subject.subclass?(PyCall.builtins.object) }.to raise_error(TypeError)
          expect { subject.subclass?(PyCall.builtins.dict)   }.to raise_error(TypeError)
        end
      end

      context 'when the value of `other` is a Class' do
        specify do
          expect { subject.subclass?(Array) }.to raise_error(TypeError)
          expect { subject.subclass?(Hash)  }.to raise_error(TypeError)
        end
      end

      context 'when the value of `other` is an instance of other class' do
        specify do
          expect { subject.subclass?(12) }.to raise_error(TypeError)
        end
      end
    end

    describe '#<=>' do
      pending
    end

    describe '#<' do
      pending
    end

    describe '#>' do
      pending
    end

    describe '#<=' do
      pending
    end

    describe '#>=' do
      pending
    end
  end
end
