module BoshReleaseDiff
  class HashFlattener
    def flatten(hash, prefix=nil)
      result = {}
      prefix = "#{prefix}." if prefix
      hash.each do |k,v|
        if v.is_a?(Hash)
          result.merge!(flatten(v, "#{prefix}#{k}"))
        else
          result["#{prefix}#{k}"] = v
        end
      end
      result
    end
  end
end
