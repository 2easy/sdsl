class Service
  @@computable = ["sin", "add"]
  def compute str
    if /\A(\w*)\((.*)\)/ =~ str
      p $1,$2
      p @@computable.include?($1)
      if @@computable.include?($1)
        return self.send $1.to_sym, *($2.split(","))
      else
        return "Not computable"
      end
    end
  end

  def sin arg
    return Math::sin(arg.to_i).to_s
  end
  def add arg1, arg2
    return (arg1+arg2).to_s
  end
end