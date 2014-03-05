module AbbeyRoad
  class Board
    include Celluloid

    def initialize
      @tracks            = Hamster.set
      @track_secretaries = Hamster.hash
      @ready_ids         = Hamster.set
      @next_track_id     = 0
    end

    attr_reader :tracks, :track_secretaries
    private     :tracks, :track_secretaries

    def add_track(control_socket, data_socket, track_class = Track)
      track_id             = new_track_id
      supervised_track     = track_class.supervise(track_id,
                                                   data_socket)
      supervised_secretary = Secretary.supervise(control_socket,
                                                 supervised_track.actors.first,
                                                 Actor.current)

      @tracks            = (@tracks << supervised_track)
      @track_secretaries = @track_secretaries.put(track_id, supervised_secretary.actors.first)

      supervised_secretary.actors.first.async.listen

      supervised_track.actors.first
    end

    def broadcast_ready(track)
      @ready_ids = @ready_ids << track.id

      track_secretaries
        .select { |t_id, _| t_id != track.id }
        .each   { |_, s| s.async.broadcast_ready_peers(@ready_ids.to_a) }
    end

    def new_track_id
      @next_track_id += 1
    end
  end

  class Secretary
    include Celluloid

    def initialize(control_socket, track, board)
      @control_socket = control_socket
      @track          = track
      @board          = board
    end

    attr_reader :track, :control_socket, :board
    private     :track, :control_socket, :board

    def listen
      loop do
        begin
          message = JSON.parse(control_socket.read)
          case message["command"]
          when "start_recording", "stop_recording"
            track.public_send message["command"]
          when "broadcast_ready"
            board.broadcast_ready track
          end
        rescue JSON::ParserError
        end
      end
    end

    def broadcast_ready_peers(ready_peer_ids)
      control_socket << { command: "peers_ready", peers: ready_peer_ids }
    end
  end
end
