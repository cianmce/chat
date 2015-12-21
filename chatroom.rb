require "pp"

class ChatRoom

  def initialize
    # ID of client that will join
    # @current_id = 0
    @clients = {}
    @rooms   = {}

  end

  def message_chat_room(room_ref, message)
    # Sends message to every client in room

    puts "Sending to RM '#{room_ref}': '#{message}'"

    clients = @rooms[room_ref][:clients]
    clients.each do |client, socket|
      text = "CHAT:#{room_ref}
CLIENT_NAME:#{client}
MESSAGE:#{message}\n\n"
      puts "Sending to CL: #{client} '#{text}'"
      begin
        socket.puts text
      rescue
        puts "Error senfing"
      end
    end
  end

  def get_client_id(client_name, client_socket)
    # Returns ID of client, ID is the client name
    # Adds if new client
    puts "Getting client_id for #{client_name}"
    unless @clients.include?(client_name)
      @clients[client_name] = client_socket
    end
    client_name.hash
  end

  def add_client_to_room(client_name, room_name, client_socket)
    puts "about to add client to room"
    room_ref = room_name.hash
    puts "adding client to room"
    client_id = get_client_id(client_name, client_socket)

    unless @rooms.include?(room_ref)
      @rooms[room_ref] = {
        :name => room_name,
        :clients => []
      }
    end

    @rooms[room_ref][:clients].push(client_name)
    return {:room_ref => room_ref, :join_id => client_id}
  end

  def info
    pp @clients
    pp @rooms
  end
end
