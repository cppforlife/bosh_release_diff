require "bosh_release_diff/filters/abstract"
require "bosh_release_diff/filters/changes_and"
require "bosh_release_diff/filters/values_and"

module BoshReleaseDiff::Filters
  class Comparator
    def self.from_changes_and_values(changes, values)
      filters  = [MatchAll.new] # default
      filters << ValuesAnd.from_string_array(values)   if values.any?
      filters << ChangesAnd.from_string_array(changes) if changes.any?
      new(And.new(filters))
    end

    def initialize(filter)
      @filter = filter
    end

    def matches?(comparator)
      # Need to check for all of the changes down the line
      # since filter potentially is only satisfied by the leaf nodes
      comparator.all_changes.any? { |ch| @filter.matches?(ch) }
    end
  end
end
