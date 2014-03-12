module Balladina
  class ChunkWriter
    include Celluloid

    def initialize(track, target_dir)
      @track      = track
      @target_dir = target_dir

      create_target_dir
    end

    attr_reader :track, :target_dir
    private     :track, :target_dir

    def on_chunk(received_at, data)
      chunk_path = write_chunk(received_at, data)
      track.async.on_chunk chunk_path
    end

    private
    def create_target_dir
      FileUtils.mkdir_p target_dir
    end

    def write_chunk(received_at, data)
      chunk_path = target_dir + "/#{received_at}.wav"
      open(chunk_path, "w") { |f| f << data }
      chunk_path
    end
  end
end
