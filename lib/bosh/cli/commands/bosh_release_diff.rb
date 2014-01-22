require "logger"
require "bosh_release_diff/commands/diff_release"

module Bosh::Cli::Command
  class BoshReleaseDiff < Base
    def initialize(*args)
      super
      @ui = Ui.new(self)
    end

    usage "diff release"
    desc  "diff multiple releases and optionally deployment manifests"
    option "--jobs JOBS",  "filter by job name; comma separated"
    option "--packages",   "show package information"
    option "--changes",    "show only changes"
    option "--debug",      "show debug log"
    def release_diff(*file_paths)
      logger = Logger.new(options[:debug] ? STDOUT : "/dev/null")
      command = ::BoshReleaseDiff::Commands::DiffRelease.new(@ui, logger)

      # Package information is not shown by default because
      # packages are an internal implementation of a release
      # which in theory should not be known about by release users.
      command.show_packages = !!options[:packages]
      
      command.show_changes = !!options[:changes]

      tar_paths   = file_paths.select { |p| p.end_with?(".tgz") }
      yml_paths   = file_paths.select { |p| p.end_with?(".yml") }
      jobs_filter = options[:jobs] ? options[:jobs].split(",") : []
      command.run(tar_paths, yml_paths, jobs_filter)

    # Unfortunetly BOSH cli swallows ArgumentError
    # thinking that they user specified wrong command line args.
    rescue ArgumentError => e
      logger.info("Caught ArgumentError #{e.inspect}\n#{e.backtrace}")
      raise
    end

    class Ui
      def initialize(bosh); @bosh = bosh;     end
      def say(*args);       @bosh.say(*args); end
      def nl(*args);        @bosh.nl(*args);  end
    end
  end
end