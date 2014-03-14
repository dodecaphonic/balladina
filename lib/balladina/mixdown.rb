module Balladina
  class Mixdown
    def initialize(name, options = {})
      @name        = name
      @target_path = options.fetch(:target_path) { Configuration.mixdowns_path }
    end

    attr_reader :name, :target_path

    def perform_on(tracks_clips)
      create_temp_mixdown_path

      tracks_clips.map { |track_name, clips|
        join_clips track_name, clips
      }.each { |track_path|
        compress_track track_path
      }

      zip_tracks
    ensure
      FileUtils.rm_rf temp_mixdown_path
    end

    def join_clips(track_name, clips)
      track_path = File.join(temp_mixdown_path, "#{track_name}.wav")
      clip_paths = clips.join(" ")

      `sox #{clip_paths} #{track_path}`

      track_path
    end

    def compress_track(track_path)
      mp3_path = track_path.sub(/\.wav$/, ".mp3")
      `lame -V2 --quiet #{track_path} #{mp3_path}`
      mp3_path
    ensure
      File.delete track_path
    end

    def zip_tracks
      `cd #{temp_mixdown_path}/../; zip -r #{mixdown_zipfile_path} #{name}`
      mixdown_zipfile_path
    end

    def create_temp_mixdown_path
      FileUtils.mkdir_p temp_mixdown_path
    end

    def temp_mixdown_path
      File.join Dir.tmpdir, "balladina-mixdowns", name
    end

    def mixdown_zipfile_path
      File.join target_path, "#{name}.zip"
    end
  end
end
