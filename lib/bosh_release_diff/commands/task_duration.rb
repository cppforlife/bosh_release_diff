module BoshReleaseDiff::Commands
  class TaskDuration
    def start
      @started_at = Time.now
    end

    def end
      @ended_at = Time.now
    end

    def duration_secs
      @ended_at.to_i - @started_at.to_i
    end
  end
end
