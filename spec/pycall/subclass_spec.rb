require 'spec_helper'

::RSpec.describe 'A subclass of the wrapper class of a Python class' do
  let(:subclass_test) do
    PyCall.import_module('pycall.subclass_test')
  end

  let(:superclass_wrapper) do
    subclass_test.SuperClass
  end

  let(:subclass) do
    Class.new(superclass_wrapper)
  end

  it 'calls __init__ of superclass' do
    a = subclass.new(1, 2, 3)
    expect(a.init_args.to_a).to eq([1, 2, 3])
  end

  it 'calls initialize' do
    subclass.class_eval do
      def initialize(*args, &b)
        super()
        b.call
      end
    end
    expect {|b| a = subclass.new(&b) }.to yield_control
  end

  it 'calls __init__ of superclass via super' do
    subclass.class_eval do
      def initialize
        super(10, 20, 30)
      end
    end
    a = subclass.new
    expect(a.init_args.to_a).to eq([10, 20, 30])
  end

  it 'calls an instance methods of the superclass' do
    a = subclass.new
    expect(a.dbl(21)).to eq(42)
    expect(subclass_test.call_dbl(a, 30)).to eq(60)
  end
end
