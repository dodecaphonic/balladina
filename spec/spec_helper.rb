require "rspec"
require "celluloid/rspec"
require "coveralls"

Coveralls.wear!

require_relative "../lib/balladina"

Celluloid.logger = Logger.new(File.expand_path("../log/test.log", __dir__))

RSpec.configure do |config|
  config.around(actor_system: :global) do |ex|
    Celluloid.boot
    ex.run
    Celluloid.shutdown
  end
end

class GossipFiend
  include Celluloid
  include Celluloid::Notifications

  def initialize
    @online = []
    @ready  = []

    subscribe "peers_online", :peers_online
    subscribe "peers_ready",  :peers_ready
  end

  attr_reader :online, :ready

  def peers_online(msg, content)
    @online = content
  end

  def peers_ready(msg, content)
    @ready = content
  end
end
