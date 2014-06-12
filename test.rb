require_relative 'connection'
require_relative 'service_obj'

c = Connection.new("127.0.0.1", nil, Service.new)
c.recv
