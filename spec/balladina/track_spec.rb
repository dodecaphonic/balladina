require "spec_helper"

describe Balladina::Track, actor_system: :global do
  let(:socket) { double("socket") }
  let(:creates_recorders) { double("Recorder") }

  class MockRecorder
    include Celluloid

    def record
      @recording = true
    end

    def recording?
      @recording
    end
  end

  class MockRecorderWithDeathBuiltin
    include Celluloid

    def initialize(*args); end

    def record
      sleep 0.1
      raise "hell"
    end
  end

  before do
    @track = Balladina::Track.new("test-track", socket,
                                  creates_recorders: creates_recorders)
  end

  after do
    @track.terminate
  end

  describe "when recording" do
    describe "and starting" do
      before do
        @recorder = MockRecorder.new
        creates_recorders.should_receive(:new_link).with(@track, socket)
          .and_return @recorder
      end

      after do
        @recorder.terminate
      end

      it "changes state to 'recording'" do
        expect(@track).not_to be_recording
        @track.start_recording
        expect(@track).to be_recording
        expect(@recorder).to be_recording
      end
    end

    describe "and stopping deliberately" do
      before do
        @recorder = MockRecorder.new
        creates_recorders.should_receive(:new_link).with(@track, socket)
          .and_return @recorder
      end

      it "changes state" do
        @track.start_recording
        expect(@track).to be_recording
        expect(@recorder).to be_recording
        @track.stop_recording
        expect(@track).not_to be_recording
      end
    end

    describe "and stopping because Recorder died" do
      let(:creates_recorders) { MockRecorderWithDeathBuiltin }

      it "changes its state" do
        @track.start_recording
        expect(@track).to be_recording
        sleep 0.2
        expect(@track).not_to be_recording
      end
    end
  end
end
