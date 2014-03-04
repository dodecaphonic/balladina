require "celluloid/rspec"

require_relative "../lib/abbey_road"

RSpec.configure do |config|
  config.around(actor_system: :global) do |ex|
    Celluloid.boot
    ex.run
    Celluloid.shutdown
  end
end
