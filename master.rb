class Master
  def initialize local_ip, local_rPort, server_binding, service_obj, server_list
    @local_ip = local_ip
    @local_rPort = local_rPort
    @server = server_binding
    @service_obj = service_obj
    @server_list = server_list
  end

  def start_service_server
    puts "log: Started service server at #{@my_ip}:#{@my_rPort}"
  end

  def test_credibility addr_ip, port
    begin
      require_relative 'credibility_tests'
      credible = true
      for test in Ctests do
        p test, addr_ip, port.to_i
        testSession = TCPSocket.new(addr_ip, port.to_i)
        testSession.puts("compute #{test[:request_str]}")
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
      puts e.backtrace.inspect
    end
  end

  def start_service
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
          puts "log: Putting #{peeraddr}:#{$1} to test queue."
          session.puts "request accepted, wait for tests\n"
          test_credibility(peeraddr,$1)
        else
          # TODO if master delegate to slave
          session.close
        end
      end
    end
  end

  def monitor
    while sleep(5+rand())
      ping_threads = []
      new_server_list = []
      slaves_to_ping = @server_list[1..-1] # do not ping yourself
      slaves_to_ping.each do |s|
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
      new_server_list.unshift(@server_list[0])
      @server_list.replace(new_server_list)
      p @server_list
    end
  end
end
