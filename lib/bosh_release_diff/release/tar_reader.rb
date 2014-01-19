require "bosh_release_diff/error"
require "bosh_release_diff/release/dir_reader"

module BoshReleaseDiff::Release
  class TarReader
    def initialize(tarball_path, logger)
      @tarball_path = File.expand_path(tarball_path, Dir.pwd)
      @logger = logger
    end

    def read
      Dir.mktmpdir do |unpack_dir|
        @logger.debug("Unpacking release tar #{@tarball_path} into #{unpack_dir.inspect}")

        system("tar", "-C", unpack_dir, "-xzf", @tarball_path) ||
          raise(BoshReleaseDiff::Error, "failed to unpack tarball")

        DirReader.new(unpack_dir, @logger).read
      end
    end
  end
end
