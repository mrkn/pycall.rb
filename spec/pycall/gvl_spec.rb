require 'spec_helper'

::RSpec.describe PyCall do
  it 'releases GVL during Python C API invocation' do
    py_time = PyCall.import_module('time')

    mutex = Mutex.new
    cv = ConditionVariable.new
    cancel = false
    counter = Thread.start do
      count = 0
      mutex.synchronize do
        until cancel
          count += 1
          cv.wait(mutex, 0.1)
        end
      end
      count
    end

    py_time.sleep(1)

    mutex.synchronize do
      cancel = true
      cv.signal
    end

    expect(counter.value).to be >= 5
  end

  it 'acquires GVL during calling Ruby from Python' do
    gvl_checker = PyCall::GvlChecker.allocate
    ruby_object_test = PyCall.import_module('pycall.ruby_object_test')
    expect(ruby_object_test.call_callable(gvl_checker)).to eq(true)
  end
end
