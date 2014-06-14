require_relative 'connection'
require_relative 'service_obj'


c = Connection.new(Service.new, "192.168.0.102", 2014)
c.start_service_server
