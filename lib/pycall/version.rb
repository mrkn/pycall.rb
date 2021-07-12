module PyCall
  VERSION = "1.4.1"

  module Version
    numbers, TAG = VERSION.split("-")
    MAJOR, MINOR, MICRO = numbers.split(".").map(&:to_i)
    STRING = VERSION
  end
end
