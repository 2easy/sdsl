DEFAULT_RPORT = 2014

class Connection
  attr_accessor :my_ip

  require 'socket'

  def initialize master_ip = nil, master_rPort = nil, my_rPort = DEFAULT_RPORT
    @master_ip = master_ip
    @master_rPort = master_rPort
    @my_ip = local_ip
    @my_rPort = my_rPort
    @age = Time.now.to_i
    # if there is no master or you can't connect to it - become one
    become_a_master if @master_ip.nil? or !get_server_list!
    # start service server
    @server = TCPServer.new(my_rPort.nil? ? DEFAULT_RPORT : my_rPort)
    puts "log: Started service server at #{@my_ip}:#{@my_rPort}"
  end

  def become_a_master
    @master = true
    @master_ip = @my_ip
    @server_list = [@my_ip]
    puts "log: Became master server!"
  end
  def master?; return @master; end

  def get_server_list!
    begin
      initSession = TCPSocket.new(@master_ip, @master_rPort)
      initSession.puts "hello\n"
      @server_list = initSession.gets.split(" ")
      initSession.close
      puts "log: Aquaired server list: #{@server_list.to_s}"
      return true
    rescue
      puts "log: Couldn't connect to the master server!"
      return false
    end
  end

  def recv
    while (session = @server.accept)
      Thread.start do
        puts "log: Connection from #{session.peeraddr[2]} at #{session.peeraddr[3]}"
        input = session.gets
        puts input

        # here we define the behaviour of the server
        case input
        when "hello\n" then
          session.puts @server_list.join(" ")
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

  private
    def local_ip
      orig = Socket.do_not_reverse_lookup
      Socket.do_not_reverse_lookup = true # turn off reverse DNS resolution temporarily
      UDPSocket.open do |s|
        s.connect '64.233.187.99', 1 #google
        s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end
end
