class PyCallTest < Test::Unit::TestCase
  def test_VERSION
    assert_not_nil(PyCall::VERSION)
  end

  def test_iterable
    simple_iterable = PyCall.import_module("pycall.simple_iterable")
    int_gen = simple_iterable.IntGenerator.new(10, 25)
    iterable = PyCall.iterable(int_gen)
    assert_equal({
                   enumerable_p: true,
                   each_to_a: (10 .. 24).to_a,
                 },
                 {
                   enumerable_p: iterable.is_a?(Enumerable),
                   each_to_a: iterable.each.to_a
                 })
  end
end
