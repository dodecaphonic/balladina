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

  def listen_to(channel_name)
    instance_variable_set "@#{channel_name}", []
    self.class.send :define_method, channel_name.to_sym do |value|
      instance_variable_get("@#{channel_name}") << value
    end

    subscribe channel_name, channel_name.to_sym
  end

  def [](channel_name)
    instance_variable_get "@#{channel_name}"
  end

  def peers_online(msg, content)
    @online = content
  end

  def peers_ready(msg, content)
    @ready = content
  end
end
