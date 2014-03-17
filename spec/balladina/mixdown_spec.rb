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
    expect(contents_of(zipped_path)).to eq(contents_of(mixdown, :mixdown))
  end

  def contents_of(zipfile, type = :reference)
    dest = destination_of(zipfile, type)
    FileUtils.mkdir_p dest
    `unzip #{zipfile} -d #{dest}`
    Dir["dest/**/*"]
  ensure
    FileUtils.rm_rf destination_of(zipfile, type)
  end

  def destination_of(zipfile, type)
    File.join(tmp_mixdowns, "unzipping-#{type}")
  end
end
