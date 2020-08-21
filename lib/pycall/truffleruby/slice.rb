module PyCall
  class Slice < PyObjectWrapper

    def initialize(*args)
      if args.length == 1 && args[0].is_a?(Integer)#handle special test case from PyCall
        args = [nil, args[0]]
      end
      unwrapped = PyObjectWrapper.unwrap(args)
      super Polyglot.eval('python', 'slice').call(*unwrapped)
    end

    def self.all
      super Polyglot.eval('python', 'slice').call(LibPython::API::ForeignNone)
    end

    def self.from_ruby_range(obj)
      if (obj.is_a? Range) || (obj.is_a? Enumerator::ArithmeticSequence)
        range_begin = obj.begin
        range_step = (obj.is_a? Enumerator::ArithmeticSequence) ? obj.step : nil
        range_end = obj.end

        if (range_step.nil?) || (range_step > 0)
          if range_end == -1 && !obj.exclude_end? #include last item if end = -1
            range_end = nil
          elsif !range_end.nil? && !obj.exclude_end?
            range_end +=1
          end
        else
          if range_end == 0 && !obj.exclude_end? #include last item if end = -1
            range_end = nil
          elsif !range_end.nil? && !obj.exclude_end?
            range_end -=1
          end
        end

        return PyCall::Slice.new(range_begin, range_end, range_step)
      elsif obj.is_a? Enumerator
        #hacky way to support (nil..nil).step(-1) Enumerators
        iter = obj.instance_variable_get(:@iter)
        if iter == :step
          args = obj.instance_variable_get(:@args)
          if (args.is_a? Array) && (args.length == 1) && (args.first.is_a? Integer)
            return PyCall::Slice.new(nil, nil, args[0])
          end
        end
        return nil
      end

      return nil
    end
  end

  Conversion.register_python_type_mapping(Slice.new(nil).__pyptr__, Slice)
end
