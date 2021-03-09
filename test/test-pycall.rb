class PyCallTest < Test::Unit::TestCase
  def test_VERSION
    assert_not_nil(PyCall::VERSION)
  end
end
