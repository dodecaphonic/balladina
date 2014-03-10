module Balladina
  class ControlSocketListener
    include Celluloid

    def initialize(track_id, secretary, control_socket)
      @track_id             = track_id
      @secretary            = secretary
      @control_socket       = control_socket
      @rtc_signal_processor = RTCSignalProcessor.new_link(track_id,
                                                          control_socket)

      async.listen
    end

    attr_reader :secretary, :control_socket, :rtc_signal_processor
    private     :secretary, :control_socket, :rtc_signal_processor

    def listen
      loop do
        message = next_message

        if message["command"]
          secretary.async.on_message message
        else
          rtc_signal_processor.async.process message
        end
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
