require_relative "../spec_helper"

describe Balladina::Board, actor_system: :global do
  let(:control_socket) { double("control_socket") }
  let(:data_socket) { double("data_socket") }
  let(:creates_tracks) { double("Track") }
  let(:creates_coordinators) { double("TrackCoordinator") }

  before do
    @board = Balladina::Board.new(creates_tracks: creates_tracks,
                                  creates_coordinators: creates_coordinators)
    @gf    = GossipFiend.new

    prepare_track "test-track"
  end

  after do
    @board.terminate
    @gf.terminate
  end

  describe "adding a track" do
    it do
      @board.add_track("test-track", control_socket, data_socket)
      expect(@gf.online).to eq(["test-track"])
      expect(@gf.ready).to be_empty
    end
  end

  describe "removing a track" do
    before do
      prepare_track "test-track1", with_termination: true
    end

    it do
      track0 = @board.add_track("test-track", control_socket, data_socket)
      track1 = @board.add_track("test-track1", control_socket, data_socket)
      @board.notify_ready(track1)
      expect(@gf.online).to have(2).items
      expect(@gf.ready).to have(1).item

      @board.remove_track(track1)
      expect(@gf.online).to have(1).items
      expect(@gf.ready).to be_empty
    end
  end

  describe "mediating" do
    it "informs other Peers that a particular Peer is ready" do
      track = @board.add_track("test-track", control_socket, data_socket)
      @board.notify_ready track
      expect(@gf.ready).to eq(["test-track"])
    end
  end

  def prepare_track(track_id, with_termination: false)
    track = double(track_id, id: track_id)

    creates_tracks.should_receive(:new)
      .with(track_id, data_socket).and_return track
    creates_coordinators.should_receive(:new)
      .with(control_socket, track, @board)

    if with_termination
      track.should_receive(:terminate)
    end

    track
  end
end
