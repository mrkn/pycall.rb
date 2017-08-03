namespace :pycall do
  desc 'Show PYTHON_DESCRIPTION'
  task :PYTHON_DESCRIPTION do
    require 'pycall'
    puts PyCall::PYTHON_DESCRIPTION
  end
end
