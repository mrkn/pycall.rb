class PyCallOperatorsTest < Test::Unit::TestCase
  def setup
    @simple_class = PyCall.import_module("pycall.simple_class").SimpleClass
  end

  def test_unary_positive
    x = @simple_class.new("x")
    assert_equal "+x", +x
  end

  def test_unary_negative
    x = @simple_class.new("x")
    assert_equal "-x", -x
  end

  def test_unary_invert
    x = @simple_class.new("x")
    assert_equal "~x", ~x
  end
end
