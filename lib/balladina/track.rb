module Balladina
  class Track
    include Celluloid
    include Celluloid::Logger

    trap_exit :recorder_died

    def initialize(id, socket, options = {})
      @id     = id
      @socket = socket
      @chunks = Hamster.vector
      @creates_recorders = options.fetch(:creates_recorders) { Recorder }
      @leader = options.fetch(:leader, false)
      @recorder = creates_recorders.new_link(Actor.current, socket)
      @is_recording = false

      @recorder.async.record
    end

    attr_reader :chunks, :socket, :id, :creates_recorders
    private     :socket, :creates_recorders

    def start_recording
      info "Track \##{id}: starting to record"
      @is_recording = true
    end

    def stop_recording
      info "Track \##{id}: stopping recording"
      @is_recording = false
    end

    def leader?; @leader; end

    def recording?; @is_recording; end

    def on_chunk(chunk_path)
      if recording?
        @chunks = @chunks << chunk_path
      end
    end

    def prepare_mixdown
      { id => chunks }
    end

    def recorder_died(actor, reason)
      @recorder     = nil
      @is_recording = false
    end
  end
end
