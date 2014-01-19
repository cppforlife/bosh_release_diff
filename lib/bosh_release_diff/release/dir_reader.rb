require "yaml"
require "bosh_release_diff/error"
require "bosh_release_diff/release/release"
require "bosh_release_diff/release/job_tar_reader"

module BoshReleaseDiff::Release
  class DirReader
    def initialize(dir_path, logger)
      @dir_path = dir_path
      @logger = logger
    end

    def read
      release_mf_path = File.join(@dir_path, "release.MF")
      @logger.debug("Reading release manifest from #{release_mf_path}")

      begin
        hash = YAML.load_file(release_mf_path)
      rescue Exception => e
        raise BoshReleaseDiff::Error, e.inspect
      end

      @logger.debug("Building release from #{hash.inspect}")
      release = Release.new(*hash.values_at(
        "name", 
        "version", 
        "commit_hash", 
        "uncommitted_changes",
      ))

      job_names = hash["jobs"].map { |h| h["name"] }
      job_names.each do |job_name|
        job_dir_path = File.join(@dir_path, "jobs", "#{job_name}.tgz")
        release.jobs << JobTarReader.new(job_dir_path, @logger).read
      end

      release
    end
  end
end
