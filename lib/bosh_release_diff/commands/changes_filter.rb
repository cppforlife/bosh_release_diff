module BoshReleaseDiff::Commands
  class ChangesFilter
    class UnknownItemError < StandardError; end

    META = [:all].freeze

    JOB = [
      :job_added,
      :job_removed,
    ].freeze

    PROPERTY = [
      :property_added,
      :property_removed,
      :property_default_presence,
      :property_default_value,
    ].freeze

    PACKAGE = [
      :package_added,
      :package_removed,
    ].freeze

    ALL = (META + JOB + PROPERTY + PACKAGE).freeze

    def initialize(filter)
      raise ArgumentError, "filter must be an Array" unless filter.is_a?(Array)
      @filter = filter.map(&:to_sym)
      @filter = ALL if @filter.include?(:all)

      if unknown_item = @filter.detect { |f| !ALL.include?(f) }
        raise UnknownItemError, "filter contains unknown item #{unknown_item.inspect}"
      end
    end

    def any_changes?(comparator)
      comparator.changes.any? { |chs| chs.changes.any? { |cf| @filter.include?(cf) } }
    end

    def package_related?
      @filter.any? { |f| PACKAGE.include?(f) }
    end
  end
end
