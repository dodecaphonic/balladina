module Balladina
  class Track
    include Celluloid
    include Celluloid::Logger

    trap_exit :recorder_died

    def initialize(id, socket, options = {})
      @id     = id
      @socket = socket
      @chunks = []
      @creates_recorders = options.fetch(:creates_recorders) { Recorder }
      @leader = options.fetch(:leader, false)
    end

    attr_reader :chunks, :socket, :id, :creates_recorders
    private     :socket, :creates_recorders

    def start_recording
      @recorder = creates_recorders.new_link(Actor.current, socket)
      info "Track: starting to record"
      @recorder.async.record
    end

    def stop_recording
      @recorder.terminate if @recorder
      info "Track: stopping recording"
      @recorder = nil
    end

    def leader?; @leader; end

    def recording?; !!@recorder; end

    def on_chunk(chunk_path)
      chunks << chunk_path
      info "NEW CHUNK. CHUNKS ARE: #{chunks.inspect}"
    end

    def recorder_died(actor, reason)
      @recorder = nil
    end
  end
end
