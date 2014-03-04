require "spec_helper"

describe AbbeyRoad::Track, actor_system: :global do
  let(:socket) { double("socket") }

  before do
    @track = AbbeyRoad::Track.new(socket)
  end

  after do
    @track.terminate
  end

  describe "when recording" do
    describe "and starting" do
      it "changes state to 'recording'" do
        expect(@track).not_to be_recording
        @track.start_recording
        expect(@track).to be_recording
      end
    end

    describe "and stopping" do
      it "changes state when recording ends" do
        @track.start_recording
        expect(@track).to be_recording
        @track.stop_recording
        expect(@track).not_to be_recording
      end
    end

    describe "incoming data" do
      before do
        socket.should_receive(:read).and_return "chunk1"
        socket.should_receive(:read).and_return "chunk2"
        socket.should_receive(:read).and_raise IOError
      end

      it "retains the chunks as they come in" do
        @track.start_recording

        loop until @track.chunks.size == 2
        expect(@track.chunks).to eq(["chunk1", "chunk2"])
        sleep 0.2
        expect(@track).not_to be_recording
      end
    end
  end
end
