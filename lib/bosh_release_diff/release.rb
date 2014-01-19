module BoshReleaseDiff
  module Release
    require "bosh_release_diff/release/release"
    require "bosh_release_diff/release/job"
    require "bosh_release_diff/release/property"

    require "bosh_release_diff/release/tar_reader"
    require "bosh_release_diff/release/dir_reader"
    require "bosh_release_diff/release/job_dir_reader"
  end
end
