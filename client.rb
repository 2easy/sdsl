DEFAULT_RPORT = 2014


class ClientConnection

  require 'socket'

  def initialize
    @port = nil
    @remote_ip = nil
    @server_list = []
  end

  def open ip, port=DEFAULT_RPORT
    @remote_ip = ip
    @port = port
    get_list
  end

  def register_function function_name
    define_singleton_method(function_name) do |*args|
      call_remote(function_name, args)
    end
  end


  private

  def call_remote function_name, args
    begin
      session = TCPSocket.new(@remote_ip, @port.to_i)
      request = "compute " + function_name + "("
      for a in args
        request = request + "," + a
      end
      request += ")"
      session.puts(request)
      answer = session.gets
      session.close
      get_list
      return answer
    rescue Exception => e
      puts "log: Couldn't perform request - #{e}"
      @server_list.shift
      if @server_list.length > 0
        puts "log: Trying again"
        @remote_ip = @server_list[0].split(":")[0]
        @port = @server_list[0].split(":")[1]
        # HERE SHOULD BE RETRY
      else
        puts "log: Ran out of potential new masters"
      end
    end
  end

  def get_list
    begin
      session = TCPSocket.new(@remote_ip, @port)
      session.puts "hello\n"
      response = session.gets
      session.close

      if response =~ /Can't handle this request, ask master at (.*)/
        puts "log: new server apparently at #{$1}"
        @server_list = [$1.dup]
        @remote_ip, @port = $1.split(":")
      else
        @server_list.replace(response.split(" "))
        @remote_ip, @port = @server_list[0].split(":")
      end
    rescue Exception => e
      puts "log: Couldn't aquire server list - #{e}"
      return nil
    end
  end
end
