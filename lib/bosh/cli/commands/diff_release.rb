require "logger"
require "bosh_release_diff/commands/ui"
require "bosh_release_diff/commands/diff_release"
require "bosh_release_diff/commands/option_list_str"

module Bosh::Cli::Command
  class DiffRelease < Base
    C = ::BoshReleaseDiff::Commands

    def initialize(*args)
      super
      @ui = C::Ui.new(self)
    end

    usage "diff release"
    desc  "diff multiple releases and optionally deployment manifests"
    option "--changes CHANGES",   C::OptionListStr.new("show only changes", [:all] + C::DiffRelease::ALL_CHANGES_FILTER).to_str
    option "--jobs JOBS",         C::OptionListStr.new("show only jobs",    []).to_str
    option "--packages",          "show package information"
    option "--debug",             "show debug log"
    def release_diff(*file_paths)
      logger = Logger.new(options[:debug] ? STDOUT : "/dev/null")
      command = C::DiffRelease.new(@ui, logger)

      # Package information is not shown by default because
      # packages are an internal implementation of a release
      # which in theory should not be known about by release users.
      command.show_packages = !!options[:packages]

      if (changes = options[:changes].to_s.split(",")).any?
        command.show_changes = true
        command.changes_filter = changes.map(&:to_sym)
      end

      tar_paths   = file_paths.select { |p| p.end_with?(".tgz") }
      yml_paths   = file_paths.select { |p| p.end_with?(".yml") }
      jobs_filter = options[:jobs].to_s.split(",")
      command.run(tar_paths, yml_paths, jobs_filter)

    # Unfortunetly BOSH cli swallows ArgumentError
    # thinking that they user specified wrong command line args.
    rescue ArgumentError => e
      logger.info("Caught ArgumentError #{e.inspect}\n#{e.backtrace}")
      raise
    end
  end
end
