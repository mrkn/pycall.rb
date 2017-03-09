require 'spec_helper'

module PyCall
  module RSpec
  end

  describe PyObjectWrapper do
    describe '.wrap_class' do
      before do
        class PyCall::RSpec::ClassForTest
          include PyCall::PyObjectWrapper
        end
      end

      after do
        PyCall::RSpec.send :remove_const, :ClassForTest
      end

      context 'called with fractions.Fraction class' do
        it 'makes the class as a Fraction object wrapper' do
          fraction_class = PyCall.import_module('fractions').Fraction

          # before wrapping the class
          expect(fraction_class.(1, 2)).to be_kind_of(PyObject)

          expect {
            PyCall::RSpec::ClassForTest.send :wrap_class, fraction_class
          }.not_to raise_error

          # after wrapping the class
          expect(fraction_class.(1, 2)).to be_kind_of(PyCall::RSpec::ClassForTest)
        end
      end
    end

    describe '#rich_compare' do
      let(:fraction_class) { PyCall.import_module('fractions').Fraction }
      subject { fraction_class.(1, 2) }

      context 'when comparing with an Integer' do
        specify do
          expect { subject.rich_compare(42, :<) }.not_to raise_error
        end
      end

      context 'when comparing with an PyObject' do
        specify do
          expect { subject.rich_compare(fraction_class.(2, 3), :<) }.not_to raise_error
        end
      end
    end
  end
end
