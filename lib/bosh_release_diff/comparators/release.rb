require "bosh_release_diff/comparators/variations"
require "bosh_release_diff/comparators/job"

module BoshReleaseDiff::Comparators
  # Compares releases to dep manifests
  class Release
    def self.from(releases, manifests, logger)
      new(
        Variations.from(releases), 
        Variations.from(manifests), 
        logger,
      )
    end

    def initialize(releases, manifests, logger)
      @releases = releases
      @manifests = manifests
      @logger = logger
    end

    def job_results
      names = @releases.extract(&:jobs).map(&:name).uniq.sort
      @logger.debug("Job result names #{names}")

      names.map do |job_name|
        # Release job might not be returned (nil) for a release 
        # because job template with that name might not exist.
        rel_jobs = @releases.break_down { |r| r.jobs.detect { |j| j.name == job_name } }

        dep_man_jobs = @manifests.break_down_flat { |m| m.jobs_using_job_template(job_name) }

        Job.new(rel_jobs, dep_man_jobs, @logger)
      end
    end
  end
end
