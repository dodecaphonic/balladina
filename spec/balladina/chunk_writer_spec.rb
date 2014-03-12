require_relative "../spec_helper"

describe Balladina::ChunkWriter, actor_system: :global do
  let(:target_dir) { Dir.tmpdir + "/balladina_tests" }

  before do
    @track        = StubTrack.new
    @chunk_writer = Balladina::ChunkWriter.new(@track, target_dir)
  end

  after do
    @chunk_writer.terminate
    @track.terminate

    FileUtils.rm_rf target_dir
  end

  describe "writing chunks" do
    it "writes to disk and notifies the Track" do
      received_at = Time.now.to_i
      @chunk_writer.on_chunk received_at, "IMPORTANT AUDIO"
      expect(File.exist?(target_dir + "/#{received_at}.wav")).to be_true
      expect(@track.chunks).to have(1).item
    end
  end

  class StubTrack
    include Celluloid

    def initialize
      @chunks = []
    end

    attr_reader :chunks

    def on_chunk(chunk_path)
      chunks << chunk_path
    end
   end
end
