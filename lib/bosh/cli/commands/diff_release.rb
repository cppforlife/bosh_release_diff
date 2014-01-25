require "logger"
require "bosh_release_diff/commands/ui"
require "bosh_release_diff/commands/diff_release"
require "bosh_release_diff/commands/option_list_str"
require "bosh_release_diff/commands/changes_filter"
require "bosh_release_diff/commands/jobs_filter"

module Bosh::Cli::Command
  class DiffRelease < Base
    C = ::BoshReleaseDiff::Commands

    def initialize(*args)
      super
      @ui = C::Ui.new(self)
    end

    usage "diff release"
    desc  "diff multiple releases and optionally deployment manifests"
    option "--changes CHANGES",   C::OptionListStr.new("show only changes", C::ChangesFilter::ALL).to_str
    option "--jobs JOBS",         C::OptionListStr.new("show only jobs",    []).to_str
    option "--packages",          "show package information"
    option "--debug",             "show debug log"
    def release_diff(*file_paths)
      logger = Logger.new(options[:debug] ? STDOUT : "/dev/null")
      command = C::DiffRelease.new(@ui, logger)

      changes = option_as_array(:changes)
      command.changes_filter = C::ChangesFilter.new(changes) if changes.any?

      jobs = option_as_array(:jobs)
      command.jobs_filter = C::JobsFilter.new(jobs) if jobs.any?

      # Package information is not shown by default because
      # packages are an internal implementation of a release
      # which in theory should not be known about by release users.
      command.show_packages = !!options[:packages]

      # Showing changes related to packages will not be visible
      # unless command is configured to show packages list.
      if command.changes_filter && command.changes_filter.package_related?
        command.show_packages = true
      end

      tar_paths = file_paths.select { |p| p.end_with?(".tgz") }
      yml_paths = file_paths.select { |p| p.end_with?(".yml") }
      command.run(tar_paths, yml_paths)

    # Unfortunetly BOSH cli swallows ArgumentError
    # thinking that they user specified wrong command line args.
    rescue ArgumentError => e
      logger.info("Caught ArgumentError #{e.inspect}\n#{e.backtrace}")
      raise
    end

    private

    def option_as_array(name)
      options[name].to_s.split(",")
    end
  end
end
