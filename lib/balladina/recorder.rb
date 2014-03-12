module Balladina
  class Recorder
    include Celluloid
    include Celluloid::Logger

    def initialize(track, socket, options = {})
      @track  = track
      @socket = socket
      writes_chunks = options.fetch(:writes_chunks) { ChunkWriter }
      @writer = writes_chunks.supervise(track,
                                        Dir.tmpdir + "/balladina/#{track.id}")
    end

    attr_reader :socket, :track, :writer
    private     :socket, :track, :writer

    def record
      loop do
        chunk       = socket.read
        received_at = Time.now.to_i

        writer.actors.first.async.on_chunk received_at, chunk
      end
    end
  end
end
