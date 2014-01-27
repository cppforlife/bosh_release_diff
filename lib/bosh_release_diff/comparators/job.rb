require "bosh_release_diff/comparators/perms"
require "bosh_release_diff/comparators/property"
require "bosh_release_diff/comparators/package"

module BoshReleaseDiff::Comparators
  # Compares release jobs to dep manifest jobs
  class Job
    def initialize(rel_jobs, dep_man_jobs, logger)
      @rel_jobs = rel_jobs
      @dep_man_jobs = dep_man_jobs
      @logger = logger
    end

    def name
      @rel_jobs.shared_value(&:name)
    end

    def property_results
      names = @rel_jobs.extract(&:properties).map(&:name).uniq.sort
      @logger.debug("Property result names #{names}")

      names.map do |prop_name|
        # Release property might not be returned (nil) for a job template
        # because job template might not accept property with that name.
        rel_props = @rel_jobs.break_down { |j| j.properties.detect { |p| p.name == prop_name } }

        # Dep manifest property might not be returned (nil) for a job 
        # because job might not set property with that name in the manifest.
        dep_man_props = @dep_man_jobs.break_down { |j| j.all_properties.detect { |p| p.name == prop_name } }

        Property.new(rel_props, dep_man_props, @logger)
      end
    end

    def package_results
      names = @rel_jobs.extract(&:packages).map(&:name).uniq.sort
      @logger.debug("Package result names #{names}")

      names.map do |pkg_name|
        # Release package might not be returned (nil) for a job template
        # because job template might not depend on a package with that name.
        packages = @rel_jobs.break_down { |j| j.packages.detect { |p| p.name == pkg_name } }

        Package.new(packages, @logger)
      end
    end

    def changes
      Perms.new([[@rel_jobs, ReleaseJobChange]])
    end

    class ReleaseJobChange
      def initialize(job, index, prev_job, context)
        @job = job
        @prev_job = prev_job
        @index = index
        @context = context
      end

      def name
        @job.name if @job
      end

      def changes
        changes = []
        if @prev_job && !@job
          changes << :job_removed
        elsif !@prev_job && @job
          changes << :job_added unless @index.zero?
        end
        changes
      end

      def description(show_packages)
        str = "[#{@context.find_kind_of('Release').contextual_name}] "

        if @prev_job && @job
          str += "present"
        elsif @prev_job && !@job
          str += "removed"
        elsif !@prev_job && @job
          str += @index.zero? ? "present" : "added"
        else # !@prev_job && !@job
          str += "not present"
        end

        if @job
          str += "; #{@job.properties.size} prop(s)"
          str += ", #{@job.packages.size} package(s)" if show_packages
        end

        str
      end
    end
  end
end
