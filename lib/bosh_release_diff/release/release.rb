require "bosh_release_diff/error"

module BoshReleaseDiff::Release
  class Release
    attr_reader :name, :version, :commit_hash, :uncommitted_changes, :jobs

    def initialize(name, version, commit_hash, uncommitted_changes)
      @name = name
      @version = version
      @commit_hash = commit_hash
      @uncommitted_changes = uncommitted_changes
      @jobs = []
    end

    def detailed_name
      "#{name}/#{version} (#{commit_hash || "?"}#{"*" if uncommitted_changes})"
    end

    def contextual_name
      "#{name}/#{version}"
    end
  end
end
