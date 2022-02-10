class PyCallGvlTest < Test::Unit::TestCase
  def test_exception
    math = PyCall.import_module("math")
    assert_raise_message(/factorial\(\) not defined for negative values/) do
      PyCall.without_gvl do
        math.factorial(-1)
      end
    end
  end
end
