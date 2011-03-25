require 'rubygems'
require 'net/http'
require 'open-uri'
require 'cgi'
require 'json'

def detect_language(request, translate_string)
    google_api_key = ''
    user_ip = URI.encode(request.env['REMOTE_ADDR'])
    translate_string = URI.encode(translate_string)
    url = "http://ajax.googleapis.com/ajax/services/language/detect?v=1.0&q=#{translate_string}&userip=#{user_ip}"
    if google_api_key != ''
        url += "&key=#{google_api_key}"
    end
    response = Net::HTTP.get_response(URI.parse(url))
    result = JSON.parse(response.body)
    result['responseData']['language']
end
