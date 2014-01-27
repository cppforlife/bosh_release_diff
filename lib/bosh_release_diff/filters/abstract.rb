module BoshReleaseDiff::Filters
  class MatchAll
    def matches?(_); true; end
  end

  class MatchNone
    def matches?(_); false; end
  end

  class And
    def initialize(filters)
      raise ArgumentError, "filters must be an Array" unless filters.is_a?(Array)
      @filters = filters
    end

    def matches?(something)
      @filters.all? { |f| f.matches?(something) }
    end
  end

  class Or
    def initialize(filters)
      raise ArgumentError, "filters must be an Array" unless filters.is_a?(Array)
      @filters = filters
    end

    def matches?(something)
      @filters.any? { |f| f.matches?(something) }
    end
  end
end
