module Balladina
  class Secretary
    include Celluloid
    include Celluloid::Logger

    def initialize(control_socket, track, board)
      @track          = track
      @board          = board
      @listener       = ControlSocketListener.new_link(Actor.current, control_socket)
      @control_socket = control_socket
    end

    attr_reader :track, :board, :control_socket
    private     :track, :board, :control_socket

    def on_message(message)
      info "==== RECEIVED #{message["command"]}"

      case message["command"]
      when "start_recording", "stop_recording"
        track.public_send message["command"]
      when "broadcast_ready"
        board.async.broadcast_ready track
      end
    end

    def broadcast_ready_peers(ready_peer_ids)
      info "Sending PEERS_READY to control_socket"
      control_socket << { command: "peers_ready", peers: ready_peer_ids }.to_json
    end
  end
end
