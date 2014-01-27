# encoding: UTF-8
require "bosh_release_diff/release/tar_reader"
require "bosh_release_diff/deployment_manifest/file_reader"
require "bosh_release_diff/comparators/release"
require "bosh_release_diff/commands/no_double_nl_ui"

module BoshReleaseDiff::Commands
  class DiffRelease
    attr_accessor :comparator_filter, :show_packages

    def initialize(ui, logger)
      @ui = NoDoubleNlUi.new(ui)
      @logger = logger
    end

    def run(release_tar_paths, deployment_manifest_paths)
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
        if !comparator_filter.matches?(job_result)
          @logger.debug("Job #{job_result.name} does not match")
          next
        end

        show_job_result(job_result)
      end

    ensure
      @logger.debug("Finished")
    end

    private

    def show_job_result(job_result)
      @ui.say("- #{job_result.name}")

      job_result.changes.each do |change, d|
        @ui.say("  #{" "*2*d}#{ComparatorPresenter::TICK}" + change.description(show_packages))
      end

      @ui.nl

      presenter = ComparatorPresenter.new(@ui, comparator_filter, @logger)

      presenter.present(job_result.property_results, {
        title: "Properties",
        title_highlight: true,
        has_description: true,
      })

      presenter.present(job_result.package_results, {
        title: "Packages",
        title_highlight: false,
        has_description: false,
      }) if show_packages

      @ui.nl
    end

    class ComparatorPresenter
      TICK = "∟ "

      def initialize(ui, comparator_filter, logger)
        @ui = ui
        @comparator_filter = comparator_filter
        @logger = logger
      end

      def present(comparator, opts)
        if comparator.empty?
          @ui.say("  #{opts.fetch(:title)}: none")
          return
        end

        has_changes = false

        comparator.each do |result|
          if !@comparator_filter.matches?(result)
            @logger.debug("#{opts.fetch(:title)} #{result.name} does not match")
            next
          elsif !has_changes
            has_changes = true
            @ui.say("  #{opts.fetch(:title)}:")
          end

          name = result.name
          name = name.make_yellow   if opts.fetch(:title_highlight)
          desc = result.description if opts.fetch(:has_description)
          @ui.say("  - #{name}#{" (#{desc})" if desc}")

          result.changes.each do |change, d|
            @ui.say("    #{" "*2*d}#{TICK}" + change.description)
          end

          @ui.nl
        end

        if !has_changes
          @ui.say("  #{opts.fetch(:title)}: filtered out")
        end

        @ui.nl
      end
    end
  end
end
