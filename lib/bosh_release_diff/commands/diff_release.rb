# encoding: UTF-8
require "bosh_release_diff/release"
require "bosh_release_diff/deployment_manifest"
require "bosh_release_diff/comparators"
require "bosh_release_diff/commands/no_double_nl_ui"

module BoshReleaseDiff::Commands
  class DiffRelease
    ALL_CHANGES_FILTER = [
      :job_added,
      :job_removed,
      :package_added,
      :package_removed,
      :property_added,
      :property_removed,
      :property_default_presence,
      :property_default_value,
    ].freeze

    attr_accessor :show_packages, :show_changes, :changes_filter

    def initialize(ui, logger)
      @ui = NoDoubleNlUi.new(ui)
      @logger = logger
      @changes_filter = []
    end

    def changes_filter=(value)
      raise ArgumentError, "value must be an Array" unless value.is_a?(Array)
      @changes_filter = value.include?(:all) ? ALL_CHANGES_FILTER : value
    end

    def run(release_tar_paths, deployment_manifest_paths, jobs_filter)
      @ui.nl

      @logger.debug("Reading releases")
      releases = release_tar_paths.map do |path|
        BoshReleaseDiff::Release::TarReader.new(path, @logger).read
      end

      if releases.empty?
        @ui.say("Must specify at least one release")
        return
      else
        @ui.say("Using releases: #{releases.map(&:detailed_name).join(", ")}")
        @ui.nl
      end

      @logger.debug("Reading deployment manifests")
      deployment_manifests = deployment_manifest_paths.map do |path|
        BoshReleaseDiff::DeploymentManifest::FileReader.new(path, @logger).read
      end

      if deployment_manifests.any?
        @ui.say("Using deployment manifests: #{
          deployment_manifests.map(&:detailed_name).join(", ")}")
        @ui.nl
      end

      @logger.debug("Starting to compare")
      release_comparator = \
        BoshReleaseDiff::Comparators::Release.from(
          releases, deployment_manifests, @logger)

      @ui.say("Jobs (aka job templates):")
      release_comparator.job_results.each do |job_result|
        if !jobs_filter.empty? && !jobs_filter.include?(job_result.name)
          @logger.debug("Job #{job_result.name} filtered out")
          next
        end

        show_job_result(job_result)
        show_property_results(job_result.property_results)
        show_package_results(job_result.package_results) if show_packages
        @ui.nl
      end

    ensure
      @logger.debug("Finished")
    end

    private

    TICK = "∟ "

    def show_job_result(job_result)
      @ui.say("- #{job_result.name}")
      return if show_changes && !job_result.any_changes?(changes_filter)

      job_result.changes.each do |change, d|
        @ui.say("  #{" "*2*d}#{TICK}" + change.description(show_packages))
      end
      @ui.nl
    end

    def show_property_results(property_results)
      status = if property_results.empty?
        "none"
      elsif show_changes && property_results.none? { |pr| pr.any_changes?(changes_filter) }
        "no changes"
      end

      @ui.say("  Properties: #{status}")
      last_i = property_results.size-1

      property_results.each.with_index do |property_result, i|
        if show_changes && !property_result.any_changes?(changes_filter)
          @logger.debug("Property #{property_result.name} has no changes")
          next
        end

        desc = property_result.description
        @ui.say("  - #{property_result.name.make_yellow}#{" (#{desc})" if desc}")

        property_result.changes.each do |change, d|
          @ui.say("    #{" "*2*d}#{TICK}" + change.description)
        end

        @ui.nl
      end

      @ui.nl if !status && show_packages
    end

    def show_package_results(package_results)
      status = if package_results.empty?
        "none"
      elsif show_changes && package_results.none? { |pr| pr.any_changes?(changes_filter) }
        "no changes"
      end

      @ui.say("  Packages: #{status}")

      package_results.each do |package_result|
        if show_changes && !package_result.any_changes?(changes_filter)
          @logger.debug("Package #{package_result.name} has no changes")
          next
        end

        @ui.say("  - #{package_result.name}")

        package_result.changes.each do |change, d|
          @ui.say("    #{" "*2*d}#{TICK}" + change.description)
        end
      end
    end
  end
end
