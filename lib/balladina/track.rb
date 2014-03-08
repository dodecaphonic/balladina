module Balladina
  class Track
    include Celluloid

    trap_exit :recorder_died

    def initialize(id, socket, options = {})
      @id     = id
      @socket = socket
      @chunks = []
      @creates_recorders = options.fetch(:creates_recorders) { Recorder}
    end

    attr_reader :chunks, :socket, :id, :creates_recorders
    private     :socket, :creates_recorders

    def start_recording
      @recorder = creates_recorders.new_link(Actor.current, socket)
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
