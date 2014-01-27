require "bosh_release_diff/filters/abstract"
require "bosh_release_diff/filters/changes_and"
require "bosh_release_diff/filters/values_and"

module BoshReleaseDiff::Filters
  class Comparator
    def self.from_changes_and_values(changes, values)
      changes_filters  = [MatchAll.new] # default
      changes_filters << ChangesAnd.from_string_array(changes) if changes.any?
      changes_filters << ValuesAnd.from_string_array(values)   if values.any?
      new(And.new(changes_filters))
    end

    def initialize(filter)
      @filter = filter
    end

    def matches?(comparator)
      comparator.changes.any? { |ch| @filter.matches?(ch) }
    end
  end
end
