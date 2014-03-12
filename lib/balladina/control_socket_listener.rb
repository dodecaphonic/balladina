module Balladina
  class ControlSocketListener
    include Celluloid

    def initialize(coordinator, control_socket)
      @coordinator    = coordinator
      @control_socket = control_socket

      async.listen
    end

    attr_reader :coordinator, :control_socket
    private     :coordinator, :control_socket

    def listen
      loop do
        coordinator.async.on_message next_message
      end
    ensure
      terminate
    end

    def next_message
      JSON.parse control_socket.read
    rescue JSON::ParserError
      error "Control Socket (Track \##{track.id}): message was not understood"
      {}
    end
  end
end
