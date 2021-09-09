class PyCallTest < Test::Unit::TestCase
  def test_VERSION
    assert_not_nil(PyCall::VERSION)
  end

  def test_setattr
    simple_class = PyCall.import_module("pycall.simple_class").SimpleClass
    pyobj = simple_class.new(42)
    before = pyobj.x
    PyCall.setattr(pyobj, :x, 1)
    assert_equal([42, 1],
                 [before, pyobj.x])
  end

  def test_delattr
    simple_class = PyCall.import_module("pycall.simple_class").SimpleClass
    pyobj = simple_class.new(42)
    PyCall.delattr(pyobj, :x)
    assert do
      not PyCall.hasattr?(pyobj, :x)
    end
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
