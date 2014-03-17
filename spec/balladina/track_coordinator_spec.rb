require_relative "../spec_helper"

describe Balladina::TrackCoordinator, actor_system: :global do
  let(:socket) { double("socket") }
  let(:track) { double("track") }
  let(:board) { double("board") }

  before do
    @coordinator = Balladina::TrackCoordinator.new(socket, track, board, creates_socket_listeners: StubListener)
  end

  after do
    @coordinator.terminate
  end

  describe "processing messages from the control socket" do
    before do
      board.should_receive(:async).at_least(1).times.and_return board
    end

    it "tells the board to start recording" do
      board.should_receive(:start_recording)
      @coordinator.on_message "command" => "start_recording"
    end

    it "tells the board to stop recording" do
      board.should_receive(:stop_recording)
      @coordinator.on_message "command" => "stop_recording"
    end

    it "tells the board to promote another track to leader" do
      board.should_receive(:promote_leader).with "track-1"
      @coordinator.on_message "command" => "promote_leader", "data" => "track-1"
    end
  end

  describe "processing messages from the pub/sub channels" do
    it "notifies peers of who's ready or online" do
      socket.should_receive(:<<).twice
      @coordinator.notify_peers "peers_ready", ["track-1"]
      @coordinator.notify_peers "peers_online", ["track-1"]
    end

    it "controls its track's recording" do
      socket.should_receive(:<<).twice
      track.should_receive(:async).twice.and_return track
      track.should_receive(:start_recording)
      track.should_receive(:stop_recording)

      @coordinator.control_recording "start_recording"
      @coordinator.control_recording "stop_recording"
    end
  end

  describe "removing its Track from the board if it is terminated" do
    before do
      socket.should_receive(:<<).and_raise "hell"
      board.should_receive(:async).and_return board
      board.should_receive(:remove_track).with track
    end

    xit do
      pending "figure out how to write this and get what I mean"
      @coordinator.control_recording "start_recording"
    end
  end

  class StubListener
    include Celluloid
    def initialize(*); end
  end
end
