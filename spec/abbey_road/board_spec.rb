require_relative "../spec_helper"

describe AbbeyRoad::Board, actor_system: :global do
  let(:control_socket) { OpenStruct.new(read: "") }
  let(:data_socket) { double("data_socket") }

  before do
    @board = AbbeyRoad::Board.new
  end

  after do
    @board.terminate
  end

  describe "adding a track" do
    it do
      track = @board.add_track(control_socket, data_socket, StubTrack)
      expect(track.id).to be(1)
    end
  end

  describe "mediating" do
    let(:control_socket1) { OpenStruct.new(read: "", write: []) }

    it "informs other Peers that a particular Peer is ready" do
      class << control_socket1
        def <<(command)
          p "=== GOT COMMAND #{command}"
          (self.commands ||= []) << command
        end
      end

      @board.add_track(control_socket, data_socket, StubTrack)
      @board.add_track(control_socket1, data_socket, StubTrack)

      control_socket.read = %q|{ "command": "broadcast_ready" }|
      expect(control_socket1.commands).not_to be_empty
    end
  end

  describe "controlling tracks" do
    before do
      control_socket.read = %q|{ "command": "start_recording"}|
    end

    it "starts recording" do
      track = @board.add_track(control_socket, data_socket, StubTrack)
      expect(track).to be_recording
    end

    it "stops recording" do
      track = @board.add_track(control_socket, data_socket, StubTrack)
      expect(track).to be_recording

      control_socket.read = %q|{ "command": "stop_recording" }|
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
