module BoshReleaseDiff::Release
  class Package
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end
end
