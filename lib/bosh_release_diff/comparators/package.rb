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

    def any_changes?(filter)
      changes.any? { |chs| chs.changes.any? { |cf| filter.include?(cf) } }
    end

    def changes
      Perms.new([[@packages, ReleasePackageChange]])
    end

    class ReleasePackageChange
      def initialize(pkg, index, prev_pkg, context)
        @pkg = pkg
        @prev_pkg = prev_pkg
        @index = index
        @context = context
      end

      def changes
        changes = []
        if @prev_pkg && !@pkg
          changes << :package_removed
        elsif !@prev_pkg && @pkg
          changes << :package_added unless @index.zero? # added
        end
        changes
      end

      def description
        str = "[#{@context.find_kind_of('Release').contextual_name}] "

        if @prev_pkg && @pkg
          str += "present"
        elsif @prev_pkg && !@pkg
          str += "removed"
        elsif !@prev_pkg && @pkg
          str += @index.zero? ? "present" : "added"
        else # !@prev_pkg && !@pkg
          str += "not present"
        end

        str
      end
    end
  end
end
