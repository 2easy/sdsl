require_relative 'connection'

class Service
  @@computable = ["sin", "add"]
  def compute str
    if /\A(\w*)\((.*)\)/ =~ str
      p $1,$2
      p @@computable.include?($1)
      if @@computable.include?($1)
        p $2.split(',')
        p self.send $1.to_sym, *($2.split(","))
        return self.send $1.to_sym, *($2.split(","))
      else
        return "Not computable"
      end
    end
  end

  def sin arg
    return Math::sin(arg.to_i)
  end
  def add arg1, arg2
    arg1+arg2
  end
end

c = Connection.new("192.168.0.3", 2014, Service.new)
c.recv
