module PyCall
  Slice = builtins.slice
  class Slice
    def self.all
      new(nil)
    end
  end
end
