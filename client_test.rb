require_relative 'client'

remote = ClientConnection.new()
remote.register_function("add")
remote.register_function("sin")
remote.open("192.168.0.102", 2014)
remote.add "2", "4"
remote.sin "0"
