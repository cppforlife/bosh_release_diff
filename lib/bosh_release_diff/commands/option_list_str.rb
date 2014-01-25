module BoshReleaseDiff::Commands
  class OptionListStr
    def initialize(title, options)
      @title = title
      @options = options
    end

    def to_str
      @title + "; comma separated\n" + @options.map { |opt| "#{" " * 38}- #{opt}" }.join("\n") + "\n\n"
    end
  end
end
