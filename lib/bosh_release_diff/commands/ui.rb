module BoshReleaseDiff::Commands
  class Ui
    def initialize(bosh); @bosh = bosh;     end
    def say(*args);       @bosh.say(*args); end
    def nl(*args);        @bosh.nl(*args);  end
  end
end
