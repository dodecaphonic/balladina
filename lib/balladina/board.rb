module Balladina
  class Board
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    def initialize
      @tracks    = Hamster.set
      @ready_ids = Hamster.set
    end

    attr_reader :tracks, :ready_ids
    private     :tracks, :ready_ids

    def add_track(track_id, control_socket, data_socket, track_class = Track)
      supervised_track = track_class.supervise(track_id, data_socket)
      @tracks          = (tracks << supervised_track)

      create_secretary control_socket, supervised_track.actors.first
      broadcast_online

      supervised_track.actors.first
    end

    def notify_ready(track)
      @ready_ids = ready_ids << track.id
      broadcast_ready
    end

    def broadcast_ready
      publish "peers_ready", ready_ids.to_a
    end

    def broadcast_online
      publish "peers_online", tracks.map { |t| t.actors.first.id }.to_a
    end

    private
    def create_secretary(control_socket, track)
      Secretary.supervise control_socket, track, Actor.current
    end
  end
end
