DEFAULT_RPORT = 2014

class Connection
  attr_accessor :my_ip

  require 'socket'

  def initialize master_ip = nil, master_rPort = nil, service_obj = nil, my_rPort = DEFAULT_RPORT
    @master_ip = master_ip
    @master_rPort = master_rPort
    @my_ip = local_ip
    @my_rPort = my_rPort
    @service_obj = service_obj
    @server_list = []
    # if there is no master or you can't connect to it - become one
    become_a_master if @master_ip.nil? or !get_server_list!
    # bind service server
    @server = TCPServer.new(my_rPort.nil? ? DEFAULT_RPORT : my_rPort)
  end

  def start_service_server
    puts "log: Started service server at #{@my_ip}:#{@my_rPort}"
    unless @master
      unless report_service_readiness!
        puts "CRITICAL: not added to the network"
        raise "Critical error, can't service"
      end
    end

    puts "log: Service server at #{@my_ip}:#{@my_rPort} added to network!"
  end

  def become_a_master
    @master = true
    @master_ip = @my_ip
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

  def report_service_readiness!
    begin
      reportSession = TCPSocket.new(@master_ip, @master_rPort)
      reportSession.puts "ready at #{@my_rPort}\n"
      inp = reportSession.gets
      if  /request accepted, wait for tests/ =~ inp
        puts "log: request accepted, waiting for tests"
      end

      reportSession.close
      sleep(3)
      get_server_list!
      @server_list.any? {|a| a.include?(@my_ip) }
    rescue Exception => e
      puts e.message
      puts e.bactrace.inspect
    end
  end

  def recv
    while (session = @server.accept)
      Thread.start do
        peeraddr = session.peeraddr[2]
        puts "log: Connection from #{peeraddr} at #{session.peeraddr[1]}"
        input = session.gets
        puts input

        # here we define the behaviour of the server
        case input
        when "hello\n" then
          session.puts @server_list.join(" ")
        when /ready at (\d*)/ then
          if @master
            puts "log: Putting #{peeraddr}:#{$1} to test queue."
            session.puts "request accepted, wait for tests\n"
            test_credibility(peeraddr,$1)
          end
        else
          # delegate call to the main code
          puts @service_obj.compute(input)
          session.puts @service_obj.compute(input)
          session.close
        end
      end
    end
  end

  def monitor
    while sleep(5+rand())
      if @master
        ping_threads = []
        new_server_list = []
        p @server_list
        @server_list.each do |s|
          ping_threads.push(Thread.new do
            begin
              puts "log: Pinging #{s}..."
              pingSession = TCPSocket.new(*(s.split(":")))
              pingSession.close
              new_server_list.push(s)
            rescue Exception => e
              puts "log: #{s} is not responding - deleted from server list"
            end
          end)
        end
        ping_threads.each {|t| t.join}
        @server_list = new_server_list
      else
        reelect! unless get_server_list!
      end
    end
  end

  def reelect!
    if @server_list.size == 1
      become_a_master
      @server_list = []
    else
      @master_ip, @master_rPort = @server_list.shift.split(":")
      @master = true if @master_ip == @my_ip
    end
  end

  private
    def test_credibility addr_ip, port
      begin
      require_relative 'credibility_tests'
      credible = true
      for test in Ctests do
        p test, addr_ip, port.to_i
        testSession = TCPSocket.new(addr_ip, port.to_i)
        testSession.puts(test[:request_str])
        answer = testSession.gets
        p answer
        credible = false if answer.chomp! != test[:answer]
        testSession.close
      end

      if credible
        # TODO thread protection
        @server_list.push([addr_ip,port].join(":"))
      end
      rescue Exception => e
        puts e.message
        puts e.bactrace.inspect
      end
    end

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
