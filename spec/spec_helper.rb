require "celluloid/rspec"

require_relative "../lib/balladina"

Celluloid.logger = Logger.new(File.expand_path("../log/test.log", __dir__))

RSpec.configure do |config|
  config.around(actor_system: :global) do |ex|
    Celluloid.boot
    ex.run
    Celluloid.shutdown
  end
end
