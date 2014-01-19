require "bosh_release_diff/hash_flattener"
require "bosh_release_diff/deployment_manifest/job"
require "bosh_release_diff/deployment_manifest/property"

module BoshReleaseDiff::DeploymentManifest
  class DeploymentManifest
    def initialize(hash, source)
      @hash = hash
      @source = source
    end

    def detailed_name
      "#{@hash["name"]} (#{@source})"
    end

    def contextual_name
      @source
    end

    def jobs_using_job_template(job_template_name)
      jobs.select { |j| j.uses_job_template?(job_template_name) }
    end

    def jobs
      @jobs ||= Array(@hash["jobs"]).map do |hash|
        Job.new(hash, properties)
      end
    end

    def properties
      @properties ||= begin
        hf = BoshReleaseDiff::HashFlattener.new
        h = hf.flatten(@hash["properties"] || {}) || {}
        h.map { |k,v| Property.new(k, v) }
      end
    end
  end
end
