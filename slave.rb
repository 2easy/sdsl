class Slave
  def initialize local_ip, local_rPort, server_binding, service_obj, server_list
    @local_ip = local_ip
    @local_rPort = local_rPort
    @server = server_binding
    @service_obj = service_obj
    @server_list = server_list
  end

  def get_server_list
    begin
      p master_ip, master_rPort
      initSession = TCPSocket.new(master_ip, master_rPort)
      initSession.puts "hello\n"
      @server_list.replace(initSession.gets.split(" "))
      initSession.close

      puts "log: Aquaired server list: #{@server_list.to_s}"
      return @server_list
    rescue Exception => e
      puts "log: Couldn't aquire server list - #{e}"
      return nil
    end
  end

  def start_service
    while (session = @server.accept)
      Thread.start do
        peeraddr = session.peeraddr[2]
        input = session.gets
        puts "log: #{peeraddr}:#{session.peeraddr[1]} requesting: #{input}"

        if input =~ /compute (.*)/
          puts @service_obj.compute($1)
          session.puts @service_obj.compute($1)
        else
          p @server_list
          session.puts "Can't handle this request, ask master at #{master_ip}:#{master_rPort}"
        end
        # finalize request
        session.close
      end
    end
  end

  def master_ip; @server_list[0].split(":")[0]; end
  def master_rPort; @server_list[0].split(":")[1]; end

  def monitor
    while sleep(5+rand())
      reelect! unless get_server_list
    end
  end
  def reelect!
    @server_list.shift # delete old master
    raise Mastered if master_ip == @local_ip
  end
end
