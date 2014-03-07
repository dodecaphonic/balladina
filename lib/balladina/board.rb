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
      track   = track_class.new(track_id, data_socket)
      @tracks = (tracks << track)

      create_track_coordinator control_socket, track
      broadcast_online

      track
    end

    def remove_track(track)
      @tracks    = Hamster.set(*tracks.to_a.delete_if { |t|
                                 t.id == track.id
                              })
      @ready_ids = ready_ids.delete(track.id)

      broadcast_online
      broadcast_ready

      track.terminate
    end

    def notify_ready(track)
      @ready_ids = ready_ids << track.id
      broadcast_ready
    end

    def broadcast_ready
      publish "peers_ready", ready_ids.to_a
    end

    def broadcast_online
      publish "peers_online", tracks.map(&:id).to_a
    end

    private
    def create_track_coordinator(control_socket, track)
      TrackCoordinator.new(control_socket, track, Actor.current)
    end
  end
end
