require 'spec_helper'

describe PyCall, '.eval' do
  def py_eval(src)
    PyCall.eval(src)
  end

  def expect_python(src)
    expect(py_eval(src))
  end

  specify { expect_python('None').to equal(nil) }

  specify { expect_python('True').to equal(true) }
  specify { expect_python('False').to equal(false) }

  specify { expect_python('1').to be_kind_of(Integer) }
  specify { expect_python('1').to eq(1) }
  specify { expect_python('1.0').to be_kind_of(Float) }
  specify { expect_python('1.0').to eq(1.0) }

  specify { expect_python('"python"').to eq("python") }

  specify { expect_python('[1, 2, 3]').to eq([1, 2, 3]) }

  specify { expect_python('{ "a": 1, "b": 2 }').to eq({ 'a' => 1, 'b' => 2 }) }

  specify { expect_python('{1, 2, 3}').to eq(Set[1, 2, 3]) }
end
