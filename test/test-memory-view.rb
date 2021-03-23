require "memory-view-test-helper"
require "fiddle"

class MemoryViewTest < Test::Unit::TestCase
  def test_numpy
    numpy = PyCall.import_module("numpy")
    ary = numpy.array([[1, 2, 3], [4, 5, 6]], dtype: :float64)
    shape = ary.shape.to_a
    strides = ary.strides.to_a
    p [shape, strides]
    buf = Fiddle::MemoryView.new(ary)
    p buf
  end
end
