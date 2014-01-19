# encoding: UTF-8
require "bosh_release_diff/release"
require "bosh_release_diff/deployment_manifest"
require "bosh_release_diff/comparators"

module BoshReleaseDiff::Commands
  class DiffRelease
    attr_accessor :show_packages

    def initialize(ui, logger)
      @ui = ui
      @logger = logger
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
          @logger.debug("Skipping job #{job_result.name}")
          next
        end

        @ui.say("- #{job_result.name}")
        show_job_changes(job_result.changes)
        show_property_results(job_result.property_results)
        show_package_results(job_result.package_results) if show_packages
        @ui.nl
      end

    ensure
      @logger.debug("Finished")
    end

    private

    TICK = "∟ "

    def show_job_changes(changes)
      changes.each do |change, d|
        @ui.say("  #{" "*2*d}#{TICK}" + change.description(show_packages))
      end
      @ui.nl
    end

    def show_property_results(property_results)
      @ui.say("  Properties: #{"none" if property_results.empty?}")
      last_i = property_results.size-1

      property_results.each.with_index do |property_result, i|
        desc = property_result.description
        @ui.say("  - #{property_result.name.make_yellow}#{" (#{desc})" if desc}")

        property_result.changes.each do |change, d|
          @ui.say("    #{" "*2*d}#{TICK}" + change.description)
        end

        @ui.nl unless last_i == i
      end

      @ui.nl if property_results.any? && show_packages
    end

    def show_package_results(package_results)
      @ui.say("  Packages: #{"none" if package_results.empty?}")

      package_results.each do |package_result|
        @ui.say("  - #{package_result.name}")

        package_result.changes.each do |change, d|
          @ui.say("    #{" "*2*d}#{TICK}" + change.description)
        end
      end
    end
  end
end
