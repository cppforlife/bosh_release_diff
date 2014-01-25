module BoshReleaseDiff::Commands
  class JobsFilter
    def initialize(filter)
      raise ArgumentError, "filter must be an Array" unless filter.is_a?(Array)
      @filter = filter
    end

    def matches?(job_comparator)
      @filter.include?(job_comparator.name)
    end
  end
end
