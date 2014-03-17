require "spec_helper"

describe Balladina::Track, actor_system: :global do
  let(:socket) { double("socket") }

  before do
    @track = Balladina::Track.new("test-track", socket,
                                  creates_recorders: creates_recorders)
  end

  after do
    @track.terminate
  end

  describe "when recording" do
    let(:creates_recorders) { MockRecorder }

    describe "and starting" do
      it "changes state to 'recording'" do
        expect(@track).not_to be_recording
        @track.start_recording
        expect(@track).to be_recording
      end
    end

    describe "and stopping deliberately" do
      it "changes state" do
        @track.start_recording
        expect(@track).to be_recording
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

  class MockRecorder
    include Celluloid

    def initialize(*args); end

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
end
