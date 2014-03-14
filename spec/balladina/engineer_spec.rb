require_relative "../spec_helper"
require "tempfile"

describe Balladina::Engineer, actor_system: :global do
  let(:creates_mixdowns) { double("Mixdown") }
  let(:board) { double("board", name: "my-crazy-board") }
  let(:temp_path) { File.join(Dir.tmpdir, "balladina-engineer") }

  before do
    @engineer = Balladina::Engineer.new(board, creates_mixdowns: creates_mixdowns,
                                        mixdowns_path: temp_path)
    FileUtils.mkdir_p temp_path
  end

  after do
    @engineer.terminate
    FileUtils.rm_rf temp_path
  end

  describe "coordinating mixdowns" do
    let(:track1) { { "track-1" => [:clip] } }
    let(:track2) { { "track-2" => [:clip] } }
    let(:future_tracks) { [double(value: track1), double(value: track2)] }

    before do
      @temp_path = Tempfile.new("a_mixdown")
      board.should_receive(:async).and_return board
      creates_mixdowns.should_receive(:create_for)
        .with("my-crazy-board", with_tracks: track1.merge(track2))
        .and_return @temp_path.path
    end

    after do
      @temp_path = nil
    end

    it "starts a Mixdown and notifies Board when it's finished" do
      filename = File.basename(@temp_path.path)
      board.should_receive(:mixdown_ready).with File.join(temp_path, filename)
      @engineer.mixdown future_tracks
    end
  end
end
