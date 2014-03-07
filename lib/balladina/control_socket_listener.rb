module Balladina
  class ControlSocketListener
    include Celluloid

    def initialize(secretary, control_socket)
      @secretary      = secretary
      @control_socket = control_socket
      async.listen
    end

    attr_reader :secretary, :control_socket
    private     :secretary, :control_socket

    def listen
      loop do
        secretary.async.on_message next_message
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
