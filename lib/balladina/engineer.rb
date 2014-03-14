module Balladina
  class Engineer
    include Celluloid
    include Celluloid::Notifications
    include Celluloid::Logger

    def initialize(board, options = {})
      @board            = board
      @creates_mixdowns = options.fetch(:creates_mixdowns) { Mixdown }
      @mixdowns_path    = options.fetch(:mixdowns_path) {
        Configuration.instance.public_mixdowns_path
      }
    end

    attr_reader :creates_mixdowns, :board, :mixdowns_path
    private     :creates_mixdowns, :board, :mixdowns_path

    def mixdown(future_tracks)
      tracks_clips = future_tracks.inject({}) { |tcm, t| tcm.merge t.value }
      mixdown_path = creates_mixdowns.create_for(board.name,
                                                 with_tracks: tracks_clips)

      board.async.mixdown_ready copy_to_public_path(mixdown_path)
    end

    def copy_to_public_path(mixdown_path)
      public_path  = File.join(mixdowns_path, File.basename(mixdown_path))
      FileUtils.cp mixdown_path, public_path

      public_path
    end
  end
end
