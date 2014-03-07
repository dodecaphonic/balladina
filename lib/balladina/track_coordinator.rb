module Balladina
  class TrackCoordinator
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    finalizer :remove_track_from_board

    def initialize(control_socket, track, board)
      @track          = track
      @board          = board
      @listener       = ControlSocketListener.new_link(Actor.current, control_socket)
      @control_socket = control_socket

      subscribe "peers_ready", :notify_peers
      subscribe "peers_online", :notify_peers
    end

    attr_reader :track, :board, :control_socket
    private     :track, :board, :control_socket

    def on_message(message)
      case message["command"]
      when "start_recording", "stop_recording"
        track.async.public_send message["command"]
      when "broadcast_ready"
        board.async.notify_ready track
      end
    end

    def notify_peers(msg, peer_ids)
      control_socket << { command: msg, data: peer_ids }.to_json
    end

    def remove_track_from_board
      board.async.remove_track track
    end
  end
end
