require "bosh_release_diff/filters/abstract"
require "bosh_release_diff/comparators/job"
require "bosh_release_diff/comparators/property"
require "bosh_release_diff/comparators/package"

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

    r  = BoshReleaseDiff::Release
    dm = BoshReleaseDiff::DeploymentManifest

    CHANGE_CLASS_TO_SUBJECTS = {
      r::Job => {
        "job_name" => "name",
      },
      r::Property => {
        "property_name"              => "name",
        "property_has_default_value" => "has_default_value?",
        "property_default_value"     => "default_value",
      },
      dm::Property => {
        "dep_man_property_name"  => "name",
        "dep_man_property_value" => "value",
      },
      r::Package => {
        "package_name" => "name",
      },
    }.freeze

    def self.all_subjects
      @all_subjects ||= CHANGE_CLASS_TO_SUBJECTS.map { |_,v| v.keys }.flatten
    end

    def self.class_for_subject(subject)
      CHANGE_CLASS_TO_SUBJECTS.map { |k, v| return k if v.keys.include?(subject) }
      raise UnknownSubjectError, "subject is an unknown item #{subject.inspect}"
    end

    # e.g. new("property_has_default_value", "==", true)
    #      new("dep_man_property_value",     "!=", true)
    def initialize(subject, operator, expected_value)
      unless self.class.all_subjects.include?(subject)
        raise UnknownSubjectError, "subject is an unknown item #{subject.inspect}"
      end

      @subject = subject
      @operator = operator
      @expected_value = expected_value

      if @operator == MATCH_OP
        @expected_value = Regexp.new(@expected_value)
      end

      # Resolve class name once
      @klass = self.class.class_for_subject(@subject)
      @klass_name = @klass.name.split("::").last

      # Actual Ruby method to call on an instance of resolved class
      @method = CHANGE_CLASS_TO_SUBJECTS[@klass][@subject]
    end

    def matches?(change)
      # Some changes do not have enough context
      # to determine the actual value
      return false unless value_source = change.context.find_kind_of(@klass_name)

      actual_value = value_source.public_send(@method)

      !!actual_value.public_send(@operator, @expected_value)
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
