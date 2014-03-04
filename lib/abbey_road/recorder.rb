module AbbeyRoad
  class Recorder
    include Celluloid

    def initialize(track, socket)
      @track  = track
      @socket = socket
    end

    attr_reader :socket, :track

    def record
      loop do
        chunk = socket.read
        track.async.on_data chunk
      end
    end
  end
end
