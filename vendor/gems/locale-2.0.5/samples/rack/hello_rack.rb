require 'rubygems'
require 'rack'
require 'locale'
 
Locale.init(:driver => :cgi)

class HelloRackApp
  def call(env)
    req = Rack::Request.new(env)
    Locale.set_request(req["lang"], req.cookies["lang"],
                       env["HTTP_ACCEPT_LANGUAGE"], env["HTTP_ACCEPT_CHARSET"])
    str = "Language tag candidates of your request order by the priority:\n\n"
    str += Locale.candidates(:type => :rfc).map{|v| v.inspect + "\n"}.join
    [200, {"Content-Type" => "text/plain", "Content-Length" => str.length.to_s}, [str]]
  end
end

