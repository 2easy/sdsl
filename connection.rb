SERVER_PORT = 2014

class Connection
  require 'socket'

  def initialize ip, s_port
    @master_ip = ip
    @age = Time.now.to_i

    # if there is no master or you can't connect to it - become one
    become_a_master if @master_ip.nil? or !get_server_list!

    @server = TCPServer.new(s_port.nil? ? SERVER_PORT : s_port)
  end

  def become_a_master
    @master = true
    @my_ip
    @master_ip = @my_ip
    @server_list = [@my_ip]
    p "become master"
  end
  def master?; return @master; end

  def get_server_list!
    begin
      initSession = TCPSocket.new(@master_ip, SERVER_PORT)
      initSession.puts "hello\n"
      @server_list = initSession.gets.split(" ")
      initSession.close
      puts "Aquaired server list: #{@server_list.to_s}"
      return true
    rescue
      puts "Couldn't connect to the master server"
      return false
    end
  end

  def recv
    while (session = @server.accept)
      Thread.start do
        puts "log: Connection from #{session.peeraddr[2]} at #{session.peeraddr[3]}"
        input = session.gets
        puts input

        case input
        when "hello\n" then session.puts @server_list.to_s
        when "ble\n" then session.puts "bleee\n"
        when "foo\n" then session.puts "foooo\n"
        else
          session.close
        end

      end
    end
  end

  def send ip
  end
end