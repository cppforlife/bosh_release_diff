module BoshReleaseDiff::Commands
  class NoDoubleNlUi
    def initialize(ui)
      @ui = ui
      @nl_last = false
    end

    def say(*args)
      @nl_last = false
      @ui.say(*args)
    end

    def nl(*args)
      unless @nl_last
        @nl_last = true
        @ui.nl(*args)
      end
    end
  end
end
