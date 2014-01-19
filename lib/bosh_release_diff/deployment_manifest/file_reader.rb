require "bosh_release_diff/error"
require "bosh_release_diff/deployment_manifest/deployment_manifest"

module BoshReleaseDiff::DeploymentManifest
  class FileReader
    def initialize(file_path, logger)
      @file_path = File.expand_path(file_path, Dir.pwd)
      @logger = logger
    end

    def read
      begin
        hash = YAML.load_file(@file_path)
      rescue Exception => e
        raise BoshReleaseDiff::Error, e.inspect
      end

      @logger.debug("Building deployment manifest from #{hash.inspect}")
      DeploymentManifest.new(hash, File.basename(@file_path))
    end
  end
end
