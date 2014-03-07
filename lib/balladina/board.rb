module Balladina
  class Board
    include Celluloid
    include Celluloid::Logger

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
      supervised_track     = track_class.supervise(track_id, data_socket)
      @tracks              = (@tracks << supervised_track)
      supervised_secretary = create_secretary(control_socket,
                                              supervised_track.actors.first)
      supervised_track.actors.first
    end

    def broadcast_ready(track)
      @ready_ids = @ready_ids << track.id

      track_secretaries
        .select { |t_id, _| t_id != track.id }
        .each   { |_, s| s.async.broadcast_ready_peers(@ready_ids.to_a) }
    end

    private
    def create_secretary(control_socket, track)
      supervised_secretary = Secretary.supervise(control_socket,
                                                 track,
                                                 Actor.current)
      @track_secretaries   = @track_secretaries.put(track.id,
                                                    supervised_secretary.actors.first)

      supervised_secretary
    end

    def new_track_id
      @next_track_id += 1
    end
  end
end
