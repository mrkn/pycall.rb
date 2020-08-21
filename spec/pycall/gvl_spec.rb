require 'spec_helper'

RSpec.describe PyCall do
  context 'outside of PyCall.without_gvl' do
    specify 'PyCall does not releases GVL during Python C API invocation' do
      if RUBY_ENGINE == "truffleruby"
        skip("Truffleruby has no GVL")
      else
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

        expect(counter.value).to be < 5
      end
    end
  end

  context 'inside of .without_gvl' do
    specify 'PyCall releases GVL during Python C API invocation' do
      if RUBY_ENGINE == "truffleruby"
        skip("Truffleruby has no GVL")
      else
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

        PyCall.without_gvl do
          py_time.sleep(1)
        end

        mutex.synchronize do
          cancel = true
          cv.signal
        end

        expect(counter.value).to be >= 5
      end
    end

    specify 'PyCall acquires GVL during calling Ruby from Python' do
      if RUBY_ENGINE == "truffleruby"
        skip("Truffleruby has no GVL")
      else
        gvl_checker = PyCall::GvlChecker.allocate
        ruby_object_test = PyCall.import_module('pycall.ruby_object_test')
        PyCall.without_gvl do
          expect(ruby_object_test.call_callable(gvl_checker)).to eq(true)
        end
      end
    end
  end
end
