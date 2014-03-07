require_relative "../spec_helper"

describe AbbeyRoad::Recorder, actor_system: :global do
  let(:socket) { double("socket") }
  let(:track)  { double("track") }

  before do
    @recorder = AbbeyRoad::Recorder.new(track, socket)
  end

  after do
    @recorder.terminate if @recorder.alive?
  end

  describe "when receiving data" do
    before do
      track.should_receive(:async).exactly(2).times.and_return track
      socket.should_receive(:read).and_return "chunk1"
      socket.should_receive(:read).and_return "chunk2"
      socket.should_receive(:read).and_raise  IOError
    end

    it "send Track the new chunk" do
      track.should_receive(:on_data).with("chunk1")
      track.should_receive(:on_data).with("chunk2")

      expect { @recorder.record }.to raise_error(IOError)
    end
  end
end
