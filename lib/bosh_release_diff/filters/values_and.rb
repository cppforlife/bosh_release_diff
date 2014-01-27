require "bosh_release_diff/filters/abstract"

module BoshReleaseDiff::Filters
  class ValuesAnd
    # e.g. from_array(["property_has_default_value=123", "property_default_value!=nil"])
    def self.from_string_array(filter_strs)
      raise ArgumentError, "filter_strs must be an Array" unless filter_strs.is_a?(Array)
      factory = ValueOpFactory.new
      And.new(filter_strs.map { |f| factory.from_string(f) })
    end
  end

  class ValueOp
    class UnknownSubjectError < StandardError; end

    MATCH_OP = "=~".freeze

    # Instead of checking `respond_to?(subject)` against a comparator
    # only expose controlled number of subjects.
    CHANGE_CLASS_TO_SUBJECTS = {
      "BoshReleaseDiff::Comparators::Job::ReleaseJobChange" => {
        "job_name" => "name",
      },
      "BoshReleaseDiff::Comparators::Property::ReleasePropertyChange" => {
        "property_name"              => "name",
        "property_has_default_value" => "has_default_value?",
        "property_has_default_value" => "has_default_value?",
        "property_default_value"     => "default_value",
      },
      "BoshReleaseDiff::Comparators::Property::DeploymentManifestPropertyChange" => {
        "dep_man_property_name"  => "name",
        "dep_man_property_value" => "value",
      },
      "BoshReleaseDiff::Comparators::Job::ReleasePackageChange" => {
        "package_name" => "name",
      },
    }.freeze

    def self.all_subjects
      @all_subjects ||= CHANGE_CLASS_TO_SUBJECTS.map { |_,v| v.keys }.flatten
    end

    # e.g. new("property_has_default_value", "==", true)
    #      new("dep_man_property_value",     "!=", true)
    def initialize(subject, operator, expected_value)
      unless self.class.all_subjects.include?(subject)
        raise UnknownSubjectError, "subject is an unknown item"
      end

      @subject = subject
      @operator = operator
      @expected_value = expected_value

      if @operator == MATCH_OP
        @expected_value = Regexp.new(@expected_value)
      end
    end

    def matches?(change)
      if subjects = CHANGE_CLASS_TO_SUBJECTS[change.class.name]
        if method = subjects[@subject]
          actual_value = change.public_send(method)
          return !!actual_value.send(@operator, @expected_value)
        end
      end
      true
    end
  end

  class ValueOpFactory
    OPERATORS_TO_FILTER_REG = {
      ValueOp::MATCH_OP => /\A(.+)=~(.+)\z/,
      "!=" => /\A(.+)!=(.+)\z/,
      "==" => /\A(.+)==?(.+)\z/,
    }.freeze

    def from_string(filter)
      raise ArgumentError, "filter must be a String" unless filter.is_a?(String)
      subject, operator, value = nil, nil, nil

      OPERATORS_TO_FILTER_REG.each do |op, vs|
        if filter =~ vs
          subject, operator, value = $1, op, $2
          break
        end
      end

      unless subject && operator && value
        raise ArgumentError, "filter must use known operators: " +
          OPERATORS_TO_FILTER_REG.keys.inspect
      end

      ValueOp.new(subject, operator, cast_str_value_to_ruby_value(value))
    end

    private

    def cast_str_value_to_ruby_value(value)
      case value
        when "true"    then true
        when "false"   then false
        when "nil"     then nil
        when /\A\d+\z/ then value.to_i
        else value
      end
    end
  end
end
