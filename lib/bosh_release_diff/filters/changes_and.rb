require "bosh_release_diff/filters/abstract"

module BoshReleaseDiff::Filters
  class ChangesAnd
    class UnknownItemError < StandardError; end

    def self.from_string_array(filter_strs)
      raise ArgumentError, "filter_strs must be an Array" unless filter_strs.is_a?(Array)
      filter_syms = filter_strs.map(&:to_sym)

      if filter_syms.include?(:all)
        return AnyChange.new
      end

      if unknown_item = filter_syms.detect { |f| !Change.all_changes.include?(f) }
        raise UnknownItemError, "filter_strs contains unknown item #{unknown_item.inspect}"
      end

      And.new(filter_syms.map { |f| Change.new(f) })
    end
  end

  class AnyChange
    def matches?(change)
      change.changes.any?
    end
  end

  class Change
    CHANGE_CLASS_TO_CHANGES = {
      "BoshReleaseDiff::Comparators::Job::ReleaseJobChange" => [
        :job_added,
        :job_removed,
      ],
      "BoshReleaseDiff::Comparators::Property::ReleasePropertyChange" => [
        :property_added,
        :property_removed,
        :property_default_added,
        :property_default_removed,
        :property_default_value,
      ],
      "BoshReleaseDiff::Comparators::Property::DeploymentManifestPropertyChange" => [
        :dep_man_property_added,
        :dep_man_property_removed,
        :dep_man_property_value,
      ],
      "BoshReleaseDiff::Comparators::Job::ReleasePackageChange" => [
        :package_added,
        :package_removed,
      ],
    }.freeze

    def self.all_changes
      @all_changes ||= CHANGE_CLASS_TO_CHANGES.map { |_,v| v }.flatten
    end

    def initialize(filter)
      raise ArgumentError, "filter must be a Symbol" unless filter.is_a?(Symbol)
      @filter = filter
    end

    def matches?(change)
      if changes = CHANGE_CLASS_TO_CHANGES[change.class.name]
        if changes.include?(@filter)
          return change.changes.include?(@filter)
        end
      end
      true
    end
  end
end
