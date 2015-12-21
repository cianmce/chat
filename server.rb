require 'socket'
require 'thread'
require 'open-uri'
require_relative 'chatroom'


class Server
  MAX_READ_CHUNK = 2048
  def initialize(logger, student_id)
    @logger     = logger
    @student_id = student_id
    @local_ip = local_ip
    @remote_ip = open('http://whatismyip.akamai.com').read
    @chat_room = ChatRoom.new
    info "remote_ip: #{@remote_ip}"
    info 'initialized'
  end

  def run(port_number, max_threads, host='0.0.0.0')
    @running = true
    @port = port_number
    work_q = Queue.new
    @socket = TCPServer.new(host, port_number)

    info "listening on http://#{local_ip}:#{port_number}"    

    # Starts server
    threads = (0...max_threads).map do |i|
      Thread.current['id'] = i
      info "starting thread: #{i}"
      Thread.new do
        begin   
          while @running
            if work_q.length > 0
              client = work_q.pop
              handle_request(client, i)
            else
              sleep(0.05)
            end
          end
        rescue ThreadError
          puts 'oopps ThreadError...'
          puts ThreadError
        end
      end
    end;
    info 'all threads started'
    while @running
      begin
        puts "\t\t\tWaiting"
        work_q.push(@socket.accept)
        puts "\t\t\tGot one!"
      rescue IOError
        # Socket closed by kill function
        puts 'Closed'
      end
    end

    # Wait for threads to join
    threads.map(&:join)
    puts 'Byeee :)'
  end

  def info(msg)
    puts msg
    @logger.info msg
  end

  def handle_request(client, tid)
    # data = client.gets # Read 1st line from socket

    while true
      sleep(0.05)

      info "Reading[#{tid}]..."
      line = client.gets
      # data = client.readpartial(MAX_READ_CHUNK) # Read data
      info "Read"
      info "          ----------received: #{line}----------"

      # port, ip = client.unpack_sockaddr_in(socket.getpeername)
      # info "port: #{port} IP: #{ip}"

      # begin
      #   info "Client: (#{client.peeraddr[2]}) #{client.peeraddr[3]}"
      # rescue Exception => e
      #   info "Error getting client address"
      #   info e
      # end

      unless line.empty?
        begin     
          
          if line.start_with?("JOIN_CHATROOM")
            join_room(line, client)
          elsif line.start_with?("LEAVE_CHATROOM")
            leave_room(line, client)
          elsif line.start_with?("HELO")
            text = helo(line, client)
            client.puts text
          elsif line == "KILL_SERVICE\n"
            text = kill(line, client)
            info "returning: '#{text}'"
            client.puts text
            client.close
          else
            text = unknown_message(line, client)
            info "returning: '#{text}'"
            client.puts text
            client.close
          end

        rescue Exception => e
          info "\n\n\t\tERROR in handle_request:"
          info e
        end 
      end

      if not @running
        info "Exiting"
        exit
      end
    end
  end

  # Handle different requests
  # Chat room requests

  def leave_room(data, client)
    info "Leaving room: #{data}"

    data += client.gets # JOIN_ID
    data += client.gets # CLIENT_NAME

    info "got data: #{data}"

    # Get room_ref and join_id as int
    room_ref    = data.scan(/LEAVE_CHATROOM:(..\d+)/).first[0].to_i
    join_id     = data.scan(/JOIN_ID:(..\d+)/).first[0].to_i
    # client_name as string, strip whitespace
    client_name = data.scan(/CLIENT_NAME:(..\w+)/).first[0].strip!

    info "room_ref: #{room_ref}, join_id: #{join_id}, client_name: #{client_name}"

    @chat_room.remove_client_from_room(client_name, room_ref)
    
    text = "LEFT_CHATROOM:#{room_ref}\nJOIN_ID:#{join_id}"
    client.puts text

    message = "#{client_name} has left the chatroom."
    @chat_room.message_chat_room(room_ref, message)
  end

  def join_room(data, client)
    # JOIN_CHATROOM:room1
    # CLIENT_IP:0
    # PORT:0
    # CLIENT_NAME:client1
    data += client.gets # CLIENT_IP
    data += client.gets # PORT
    data += client.gets # CLIENT_NAME

    # Get room and client name
    room_name   = data.scan(/JOIN_CHATROOM:(\w+)/).first[0]
    client_name = data.scan(/CLIENT_NAME:(\w+)/).first[0]
    info "Room: #{room_name} Client: #{client_name}"

    join_ret = @chat_room.add_client_to_room(client_name, room_name, client)

    text = "JOINED_CHATROOM:#{room_name}\nSERVER_IP:#{@remote_ip}\nPORT:#{@port}\nROOM_REF:#{join_ret[:room_ref]}\nJOIN_ID:#{join_ret[:join_id]}\n"

    client.puts text
    # Send message to chat room
    info "Sending join message to chatroom"
    text = "client1 has joined this chatroom."
    info "Sending: #{text}"
    @chat_room.message_chat_room(join_ret[:room_ref], text)
    info "done join_room()"
    return
  end

  # Old requests
  def helo(data, client)
    text = "#{data}IP:#{@remote_ip}\nPort:#{@port}\nStudentID:#{@student_id}\n"
    return text
  end
  def unknown_message(data, client)
    text = "Unknown message[#{data.length}]: '#{data}'"
    info text
    return text
  end
  def kill(data, client)
    info "Killing"
    @running = false
    @socket.close
    text = "Server closing\n"
    sleep(0.5)
    return text
  end

  def local_ip
    orig = Socket.do_not_reverse_lookup  
    Socket.do_not_reverse_lookup = true # turn off reverse DNS resolution temporarily
    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1 # googles ip
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
end
