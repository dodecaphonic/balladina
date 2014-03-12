require_relative "../spec_helper"

describe Balladina::Recorder, actor_system: :global do
  let(:socket) { double("socket") }
  let(:track)  { double("track", id: 1) }

  before do
    @recorder = Balladina::Recorder.new(track, socket,
                                        writes_chunks: MockWriter)
  end

  after do
    @recorder.terminate if @recorder.alive?
  end

  describe "when receiving data" do
    before do
      socket.should_receive(:read).and_return "chunk1"
      socket.should_receive(:read).and_return "chunk2"
      socket.should_receive(:read).and_raise  IOError
    end

    it "send Track the new chunk" do
      track.should_receive(:chunked).at_least(1).times
      expect { @recorder.record }.to raise_error(IOError)
    end
  end

  class MockWriter
    include Celluloid

    def initialize(track, tmpdir)
      @track  = track
    end

    attr_reader :chunks, :track

    def on_chunk(time, chunk)
      track.chunked
    end
  end
end
