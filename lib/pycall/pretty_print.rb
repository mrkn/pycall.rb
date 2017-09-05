require 'pycall'
require 'pp'

PyCall.init
module PyCall
  class PyPtr < BasicObject
    include ::PP::ObjectMixin
  end
end
