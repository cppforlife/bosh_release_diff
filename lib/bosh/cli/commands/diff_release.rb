require "logger"
require "bosh_release_diff/commands/ui"
require "bosh_release_diff/commands/diff_release"
require "bosh_release_diff/commands/option_list_str"
require "bosh_release_diff/filters/comparator"
require "bosh_release_diff/filters/changes_and"
require "bosh_release_diff/filters/values_and"

module Bosh::Cli::Command
  class DiffRelease < Base
    Cmd = ::BoshReleaseDiff::Commands
    Flt = ::BoshReleaseDiff::Filters

    def initialize(*args)
      super
      @ui = Cmd::Ui.new(self)
    end

    usage "diff release"

    desc "diff multiple releases and optionally deployment manifests"

    option(
      "--changes CHANGES",
      Cmd::OptionListStr.new(
        "filter by changes; matches all specified; " +
        "e.g. job_added,property_added",
        Flt::Change.all_changes,
      ).to_str,
    )

    option(
      "--values VALUES",
      Cmd::OptionListStr.new(
        "filter by values; matches all specified; " +
        "e.g. job_name=dea_next,property_name!=nats.user",
        Flt::ValueOp.all_subjects,
      ).to_str,
    )

    option "--packages", "show package information"

    option "--debug", "show debug log"

    def release_diff(*file_paths)
      logger  = Logger.new(options[:debug] ? STDOUT : "/dev/null")
      command = Cmd::DiffRelease.new(@ui, logger)

      changes = option_as_array(:changes)
      values  = option_as_array(:values)
      command.comparator_filter = \
        Flt::Comparator.from_changes_and_values(changes, values)

      # Package information is not shown by default because
      # packages are an internal implementation of a release
      # which in theory should not be known about by release users.
      command.show_packages = !!options[:packages]

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
