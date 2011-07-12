# def foo
#   f = Proc.new { return "return from foo from inside proc" }
#   f.call # control leaves foo here
#   return "return from foo"
# end
#
# def bar
#   f = lambda { return "return from lambda" }
#   f.call # control does not leave bar here
#   return "return from bar"
# end
#
# puts foo # prints "return from foo from inside proc"
# puts bar # prints "return from bar"


class RouteSet
  def call
    recognize &Proc.new { return 'return from recognize block' }
    p "KEKSE"
    # recognize do
    #   return 'return from recognize block'
    # end
  end

  def recognize
    yield
    p "KEKSE"
  end
end


puts RouteSet.new.call
