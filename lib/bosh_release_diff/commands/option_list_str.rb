module BoshReleaseDiff::Commands
  class OptionListStr
    MSG_INDENT = 38

    def initialize(title, options)
      @title = title
      @options = options
    end

    def to_str
      options_str  = @options.map { |opt| "#{" " * MSG_INDENT}- #{opt}" }.join("\n")
      options_str += "\n" unless options_str.empty?
      "#{@title}\n#{options_str}\n"
    end
  end
end
