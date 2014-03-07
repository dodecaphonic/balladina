module Balladina
  class Endpoint < Reel::Server
    include Celluloid::Logger

    PendingClient = Struct.new(:socket_type, :socket)

    def initialize(host = "0.0.0.0", port = 7331)
      super host, port, &method(:on_connection)
      @pending_clients = Hamster.hash
      @board           = Board.supervise
    end

    attr_reader :board, :pending_clients

    def on_connection(connection)
      connection.each_request do |request|
        if request.websocket?
          connection.detach
          await_track_creation_on(request.websocket)
        end
      end
    end

    def await_track_creation_on(socket)
      loop do
        raw_data    = socket.read
        message     = JSON.parse(raw_data)
        client_id   = message["clientId"]
        socket_type = message["command"].sub("promote_to_", "").to_sym

        if (pending = pending_clients[client_id])
          create_track socket_type, socket, pending
          @pending_clients = pending_clients.delete(client_id)
        else
          pending = PendingClient.new(socket_type, socket)
          @pending_clients = pending_clients.put(client_id, pending)
        end

        break
      end
    end

    def create_track(current_socket_type, current_socket, pending)
      control_socket, data_socket = if current_socket_type == :control
                                      [current_socket, pending.socket]
                                    else
                                      [pending.socket, current_socket]
                                    end

      info "Adding client to board with control and data sockets"

      board.actors.first.async.add_track control_socket, data_socket
    end
  end
end
