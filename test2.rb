require_relative 'connection'
require_relative 'service_obj'


c = Connection.new("192.168.0.3", 2014, Service.new)

Thread.new do
  c.recv
end.join

c.start_service_server
