require "bosh_release_diff/hash_flattener"
require "bosh_release_diff/deployment_manifest/property"

module BoshReleaseDiff::DeploymentManifest
  class Job
    def initialize(hash, global_properties)
      @hash = hash
      @global_properties = global_properties
    end

    def name
      @hash["name"]
    end

    def contextual_name
      name
    end

    def uses_job_template?(job_template_name)
      Array(@hash["template"]).include?(job_template_name) || 
        Array(@hash["templates"]).any? { |t| t["name"] == job_template_name }
    end

    def properties
      @properties ||= begin
        hf = BoshReleaseDiff::HashFlattener.new
        h = hf.flatten(@hash["properties"] || {}) || {}
        h.map { |k,v| Property.new(k, v) }
      end
    end

    # Include 'property_mappings' behavior?
    def all_properties
      @all_properties ||= (properties + @global_properties).uniq(&:name)
    end
  end
end
