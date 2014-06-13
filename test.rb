require_relative 'connection'
require_relative 'service_obj'

c = Connection.new("127.0.0.1", nil, Service.new)
t1 = Thread.new { c.recv }
t2 = Thread.new { c.monitor }

t1.join
t2.join
