require_relative "../spec_helper"
require "digest/md5"

describe Balladina::Mixdown do
  let(:clip_paths) {
    Dir[File.expand_path("../fixtures/clips/*.wav", __dir__)]
  }
  let(:mixdown) {
    File.expand_path("../fixtures/clips/mixdowns/my-crazy-mixdown.zip", __dir__)
  }

  let(:clips) { Hamster.set(clip_paths) }
  let(:tmp_mixdowns) { Dir.tmpdir + "/balladina-mixdowns" }

  subject { Balladina::Mixdown.new("my-crazy-mixdown", target_path: tmp_mixdowns) }

  before do
    FileUtils.mkdir_p tmp_mixdowns
  end

  after do
    FileUtils.rm_rf tmp_mixdowns
  end

  it "joins a set of Tracks into a zipfile" do
    zipped_path = subject.perform_on("track-1" => clips, "track-2" => clips)
    expect(File.size(zipped_path)).to eq(File.size(mixdown))
  end

  def digest(path)
    Digest::MD5.file path
  end
end
