require "yaml"
require "bosh_release_diff/error"
require "bosh_release_diff/release/job"
require "bosh_release_diff/release/package"
require "bosh_release_diff/release/property"

module BoshReleaseDiff::Release
  class JobDirReader
    def initialize(dir_path, logger)
      @dir_path = dir_path
      @logger = logger
    end

    def read
      job_mf_path = File.join(@dir_path, "job.MF")
      @logger.debug("Reading job manifest from #{job_mf_path}")

      begin
        hash = YAML.load_file(job_mf_path)
      rescue Exception => e
        raise BoshReleaseDiff::Error, e.inspect
      end

      @logger.debug("Building job from #{hash.inspect}")
      job = Job.new(hash["name"])

      Array(hash["packages"]).each do |name|
        job.packages << Package.new(name)
      end

      Array(hash["properties"]).each do |name, hash|
        # e.g. saml_login spec in cf-release had a "name: 'blah'"
        unless hash.is_a?(Hash)
          @logger.info("Invalid property #{name.inspect}")
          next
        end

        job.properties << Property.new(
          name, 
          hash["description"], 
          hash.has_key?("default"), 
          hash["default"],
        )
      end

      job
    end
  end
end
