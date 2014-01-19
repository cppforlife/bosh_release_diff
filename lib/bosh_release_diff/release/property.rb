module BoshReleaseDiff::Release
  class Property
    attr_reader :name, :description, :default_value

    def initialize(name, description, has_default_value, default_value)
      @name = name
      @description = description
      @has_default_value = has_default_value
      @default_value = default_value
    end

    def has_default_value?
      !!@has_default_value
    end
  end
end
