require_relative "../spec_helper"

describe Balladina::Board, actor_system: :global do
  let(:control_socket) { OpenStruct.new(read: "", commands: []) }
  let(:data_socket) { double("data_socket") }

  before do
    @board = Balladina::Board.new
  end

  after do
    @board.terminate
  end

  describe "adding a track" do
    it do
      track = @board.add_track("test-track", control_socket, data_socket, StubTrack)
      expect(track.id).to eq("test-track")
    end
  end

  describe "mediating" do
    let(:control_socket1) { OpenStruct.new(read: "", commands: []) }

    it "informs other Peers that a particular Peer is ready" do
      class << control_socket1
        def <<(command)
          self.commands << command
        end
      end

      @board.add_track("track-1", control_socket, data_socket, StubTrack)
      @board.add_track("track-2", control_socket1, data_socket, StubTrack)

      control_socket.read = %q|{ "command": "broadcast_ready" }|
      sleep 0.05
      expect(control_socket1.commands).not_to be_empty
    end
  end

  describe "controlling tracks" do
    before do
      control_socket.read = %q|{ "command": "start_recording"}|
    end

    it "starts recording" do
      track = @board.add_track("track_1", control_socket, data_socket, StubTrack)
      sleep 0.2
      expect(track).to be_recording
    end

    it "stops recording" do
      track = @board.add_track("track_2", control_socket, data_socket, StubTrack)
      expect(track).to be_recording

      control_socket.read = %q|{ "command": "stop_recording" }|
      sleep 0.2
      expect(track).not_to be_recording
    end
  end

  class StubTrack
    include Celluloid

    def initialize(id, socket)
      @id = id
    end

    attr_reader :id

    def start_recording
      @recording = true
    end

    def recording?
      @recording
    end

    def stop_recording
      @recording = nil
    end
  end
end
