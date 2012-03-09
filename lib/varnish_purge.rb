require 'open-uri'

def purge(url)
    config = MySociety::Config.load_default()
    varnish_url = config['VARNISH_URL']
    url = "#{varnish_url}#{url}"
    result = open(url).read
    if result != "OK"
        raise
    end
end
