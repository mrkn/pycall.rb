require "pycall"
require "pathname"
require "test-unit"

test_dir = Pathname.new(__dir__)
python_dir = test_dir + "python"

PyCall.sys.path.append(python_dir.to_s)
