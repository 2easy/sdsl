#!/usr/bin/env ruby

require_relative 'master'
require_relative 'slave'

DEFAULT_RPORT = 2014
class Mastered < Exception; end

class Connection
  attr_accessor :local_ip

  require 'socket'

  def initialize service_obj, m_ip = nil, m_rPort = nil, local_rPort = DEFAULT_RPORT
    @local_ip, @local_rPort = local_ip, local_rPort
    @service_obj     = service_obj
    @server_list     = [[m_ip, m_rPort]]
    # bind service server
    @server = TCPServer.new(local_rPort.nil? ? DEFAULT_RPORT : local_rPort)
    @conn_handle_obj = Slave.new(@local_ip, @local_rPort, @server, @service_obj, @server_list)

    # if there is no master or you can't connect to it - become one
    # become_the_master if master_ip.nil? or !get_server_list
  end

  def master?; return @master; end

  def start_service_server
    while true
      begin
        # start service server
        Thread.abort_on_exception = true # when mastered exit and start new services
        service_threads = [
          Thread.new { @conn_handle_obj.start_service },
          Thread.new { @conn_handle_obj.monitor       }
        ]
        join_the_network! unless master?
        service_threads.each {|t| t.join}
      rescue Mastered => e
        become_the_master(e.message)
        service_threads.each {|t| Thread.kill(t)}
        next
      rescue Exception => e
        p e.message
        service_threads.each {|t| Thread.kill(t)}
        exit(1)
      end
    end
  end

  private
    def join_the_network!
      begin
        raise Mastered, "no master specified" if master_ip.nil?
        initSession = TCPSocket.new(master_ip, master_rPort)
        initSession.puts "ready at #{@local_rPort}\n"
        res = initSession.gets
        if  /request accepted, wait for tests/ =~ res
          puts "log: Request accepted, waiting for tests..."
        end
        initSession.close

        sleep(3) # wait for entry tests
        # TODO maybe that master server went down - ping it and try again (3 times then fail)
        @server_list.replace(@conn_handle_obj.get_server_list)
        unless @server_list.any? {|a| a.include?(@local_ip) }
          raise "error: Rejected by master - not on the server list"
        end
        @server_list = [[@local_ip, @local_rPort]]
        become_the_master
        return
      end
    end

    def become_the_master(msg)
      @master = true
      # if noone(or [nil, nil]) on the server list, ensure there is myself
      @server_list = [[@local_ip,@local_rPort]] if @server_list.size == 1
      @conn_handle_obj = Master.new(@local_ip, @local_rPort, @server, @service_obj, @server_list)
      puts "log: Became master server: #{msg}"
    end

    def master_ip; @server_list[0][0]; end
    def master_rPort; @server_list[0][1]; end

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
