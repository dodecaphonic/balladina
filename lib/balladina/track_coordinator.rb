module Balladina
  class TrackCoordinator
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    finalizer :remove_track_from_board

    def initialize(control_socket, track, board, options = {})
      @track    = track
      @board    = board
      @listener = options.fetch(:creates_socket_listeners) {
        ControlSocketListener
      }.new_link(Actor.current, control_socket)
      @control_socket = control_socket

      subscribe "peers_ready",  :notify_peers
      subscribe "peers_online", :notify_peers
      subscribe "start_recording", :control_recording
      subscribe "stop_recording",  :control_recording
      subscribe "download_mixdown", :download_mixdown
    end

    attr_reader :track, :board, :control_socket
    private     :track, :board, :control_socket

    def on_message(message)
      case message["command"]
      when "start_recording", "stop_recording"
        board.async.public_send message["command"]
      when "broadcast_ready"
        board.async.notify_ready track
      when "promote_leader"
        board.async.promote_leader message["data"]
      when "mixdown"
        board.async.mixdown
      end
    end

    def notify_peers(msg, peer_ids)
      control_socket << { command: msg, data: peer_ids }.to_json
    end

    def control_recording(msg)
      control_socket << { command: msg }.to_json
      track.async.public_send msg
    end

    def download_mixdown(msg, public_path)
      info "==== DOWNLOAD MY MIX #{public_path}"
      control_socket << { command: msg, data: public_path }.to_json
    end

    private
    def remove_track_from_board
      board.async.remove_track track
    end
  end
end
