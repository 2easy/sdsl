require_relative 'connection'
require_relative 'service_obj'

c = Connection.new(Service.new)
c.start_service_server
