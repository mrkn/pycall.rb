module PyCall
  class Tuple < Array
    def to_s
      "PyCall::Tuple#{super}"
    end

    alias inspect to_s
  end
end
