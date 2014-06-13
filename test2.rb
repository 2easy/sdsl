require_relative 'connection'
require_relative 'service_obj'


c = Connection.new("192.168.0.102", 2014, Service.new)

t1 = Thread.new do
  c.recv
end
t2 = Thread.new do
  c.monitor!
end

c.start_service_server

t1.join
t2.join
