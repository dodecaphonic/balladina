module Balladina
  class Recorder
    include Celluloid
    include Celluloid::Logger

    def initialize(track, socket, options = {})
      @track  = track
      @socket = socket
      writes_chunks = options.fetch(:writes_chunks) { ChunkWriter }
      chunks_path   = options.fetch(:chunks_path) {
        Configuration.instance.chunks_path
      }
      @writer = writes_chunks.supervise(track, File.join(chunks_path,String(track.id)))
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
