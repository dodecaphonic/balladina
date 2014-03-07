module Balladina
  class Track
    include Celluloid

    trap_exit :recorder_died

    def initialize(socket)
      @socket = socket
      @chunks = []
    end

    attr_reader :chunks, :socket
    private     :socket

    def start_recording
      @recorder = Recorder.new_link(Actor.current, socket)
      @recorder.async.record
    end

    def stop_recording
      @recorder.terminate if @recorder
      @recorder = nil
    end

    def recording?; !!@recorder; end

    def on_data(chunk)
      @chunks << chunk
    end

    def recorder_died(actor, reason)
      @recorder = nil
    end
  end
end
