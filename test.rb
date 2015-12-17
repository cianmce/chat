require 'socket'
require 'thread'

require 'open3'

require 'test/unit'

PORT = 2001
DOS_NUM = 30
STUDENT_ID = 'a04dcb0fee025f2b48663ba413d0b8d481db11b65b254d41e3611b834c17d6d5'

class TCPServertest < Test::Unit::TestCase
  def setup

    @local_ip = local_ip_look_up

    cmd = "./start.sh #{PORT}"
    Open3.popen3(cmd)
    # Make sure server is started
    sleep(1.5)
  end

  def teardown
    # Try and kill
    begin
      res = tcp_send "KILL_SERVICE\n"
    rescue Errno::ECONNREFUSED
      # Already killed
    end
  end

  def test_dos   
    threads = (0...DOS_NUM).map do |i|
      Thread.new do
        begin
          data_array = [
            {
              :send => "HELO getting dos'd [#{i}]\n",
              :expect => "HELO getting dos'd [#{i}]\nIP:[#{@local_ip}]\nPort:[#{PORT}]\nStudentID:[#{STUDENT_ID}]\n"
            }
          ] 
          send_test_array(data_array, false)
        rescue ThreadError
          puts 'oopps ThreadError...'
          puts ThreadError
        end
        # puts "Done ##{i}"
      end
    end;
    # puts "Sent #{DOS_NUM} requests"
    # Wait for threads to join
    threads.map(&:join)
  end

  def test_kill
    data_array = [
      {
        :send => "KILL_SERVICE\n",
        :expect => "Server closing\n"
      }
    ]
    send_test_array data_array
  end

  def test_unknown
    data_array = [
      {
        :send => "test blahhhh\n",
        :expect => "Unknown message[13]: 'test blahhhh\n'\n"
      }
    ]
    send_test_array data_array
  end

  def test_helo
    data_array = [
      {
        :send => "HELO cian\n",
        :expect => "HELO cian\nIP:[#{@local_ip}]\nPort:[#{PORT}]\nStudentID:[#{STUDENT_ID}]\n"
      },
      {
        :send => "HELO some more text\n",
        :expect => "HELO some more text\nIP:[#{@local_ip}]\nPort:[#{PORT}]\nStudentID:[#{STUDENT_ID}]\n"
      }
    ]
    send_test_array data_array
  end

  def send_test_array(data_array, get_response=true)
    data_array.map do |data|
      response = tcp_send(data[:send], get_response)
      if get_response
        assert_equal(response, data[:expect]) 
      end
    end
  end

  def tcp_send(data, get_response=true, host='localhost', port=PORT)
    begin
      s = TCPSocket.open(host, port)
      s.print(data)
      if get_response
        response = s.read
      else
        response = nil
      end
      s.close
    rescue
      response = 'noo :('
    end
    return response
  end

  def local_ip_look_up
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
