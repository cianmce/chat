require "pp"

class ChatRoom

  def initialize
    # ID of client that will join
    # @current_id = 0
    @clients = []
    @rooms   = {}

  end

  def get_client_id(client_name)
    # Returns ID of client, ID is the client name
    # Adds if new client
    unless @clients.include?(client_name)
      @clients.push(client_name)
    end
    client_name.hash
  end

  def add_client_to_room(client_name, room_name)
    room_ref = room_name.hash
    client_id = get_client_id(client_name)

    unless @rooms.include?(room_ref)
      @rooms[room_ref] = {
        :name => room_name,
        :clients => []
      }
    end

    @rooms[room_ref][:clients].push(client_name)
    {:room_ref => room_ref, :join_id => client_id}
  end

  def info
    pp @clients
    pp @rooms
  end
end