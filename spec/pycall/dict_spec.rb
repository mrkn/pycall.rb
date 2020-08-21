require 'spec_helper'

module PyCall
  ::RSpec.describe Dict do
    let(:time_module) { PyCall.import_module('time') }
    let(:key) { 'a' }

    subject(:dict) { Dict.new(key => 1, 'b' => 2, 'c' => 3) }

    describe '.new' do
      let(:key) { time_module.localtime() }

      it 'accepts python object as a key' do
        expect{ Dict.new(key => 1) }.not_to raise_error
      end
    end

    describe '#[]' do
      it 'returns a value corresponding to a given key' do
        expect(subject['a']).to eq(1)
        expect(subject['b']).to eq(2)
        expect(subject['c']).to eq(3)
        expect { subject['nothing'] }.not_to raise_error
      end

      it 'increments the returned python object' do
        if RUBY_ENGINE == "truffleruby"
          skip("Refcount not available in Truffleruby")
        end
        pyobj = PyCall.builtins.object.()
        subject['o'] = pyobj
        expect { subject['o'] }.to change { pyobj.__pyptr__.__ob_refcnt__ }.from(2).to(3)
        expect(subject['o'].__pyptr__).to eq(pyobj.__pyptr__)
      end

      context 'when key is a python object' do
        let(:key) { time_module.localtime() }

        it 'returns a value corresponding to a given key' do
          expect(subject[key]).to eq(1)
        end
      end
    end

    describe '#[]=' do
      it 'stores a given value for a given key' do
        subject['a'] *= 10
        expect(subject['a']).to eq(10)

        subject['b'] *= 10
        expect(subject['b']).to eq(20)

        subject['c'] *= 10
        expect(subject['c']).to eq(30)
      end

      context 'when key is a python object' do
        let(:key) { time_module.localtime() }

        it 'stores a given value for a given key' do
          subject[key] *= 10
          expect(subject[key]).to eq(10)
        end
      end
    end

    describe '#delete' do
      it 'deletes a value for a given key'do
        expect(subject.delete('a')).to eq(1)
        expect(subject['b']).to eq(2)
        expect(subject['c']).to eq(3)
        expect(subject['a']).to eq(nil)
      end

      context 'when key is a python object' do
        let(:key) { time_module.localtime() }

        it 'deletes a value for a given key'do
          expect(subject.delete(key)).to eq(1)
          expect(subject['b']).to eq(2)
          expect(subject['c']).to eq(3)
          expect(subject[key]).to eq(nil)
        end
      end
    end

    describe '#has_key?' do
      specify do
        expect(subject).to have_key('a')
        expect(subject).to have_key('b')
        expect(subject).to have_key('c')
        expect(subject).not_to have_key('d')
      end

      context 'when key is a python object' do
        let(:key) { time_module.localtime() }

        specify do
          expect(subject).to have_key(key)
          non_key = time_module.localtime(time_module.time() + 1)
          expect(subject).not_to have_key(non_key)
        end
      end
    end

    describe '#length' do
      subject { dict.length }
      it { is_expected.to eq(3) }
    end
  end
end
