require "bosh_release_diff/comparators/perms"

module BoshReleaseDiff::Comparators
  # Compares multiple job packages
  class Package
    def initialize(packages, logger)
      @packages = packages
      @logger = logger
    end

    def name
      @packages.shared_value(&:name)
    end

    def changes
      Perms.new([[@packages, ReleasePackageChange]])
    end

    class ReleasePackageChange
      def initialize(current_pkg, index, prev_pkg, context)
        @current_pkg = current_pkg
        @index = index
        @prev_pkg = prev_pkg
        @context = context
      end

      def description
        str = "[#{@context.find_kind_of('Release').contextual_name}] "

        if @prev_pkg && @current_pkg
          str += "present"
        elsif @prev_pkg && !@current_pkg
          str += @index.zero? ? "not present" : "removed"
        elsif !@prev_pkg && @current_pkg
          str += @index.zero? ? "present" : "added"
        else # !@prev_pkg && !@current_pkg
          str += "not present"
        end

        str
      end
    end
  end
end
