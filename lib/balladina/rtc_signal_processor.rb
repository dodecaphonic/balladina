module Balladina
  class RTCSignalProcessor
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    def initialize(track_id, control_socket)
      @track_id       = track_id
      @control_socket = control_socket

      subscribe "new_rtc_signal", :new_rtc_signal
    end

    attr_reader :control_socket, :track_id

    def process(message)
      payload = { originating_track_id: track_id, data: message }
      publish "new_rtc_signal", payload
    end

    def new_rtc_signal(msg, signal)
      return if signal[:originating_track_id] == track_id
      control_socket << signal[:data].to_json
    end
  end
end
