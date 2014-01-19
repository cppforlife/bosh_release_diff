require "bosh_release_diff/error"

module BoshReleaseDiff::Release
  class Job
    attr_reader :name, :properties, :packages

    def initialize(name)
      @name = name
      @properties = []
      @packages = []
    end
  end
end
