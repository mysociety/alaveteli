# This is a sample VCL configuration file for varnish running in front
# of Alaveteli.  See the vcl(7) man page for details on VCL syntax and
# semantics.

# 
# Default backend definition.  Set this to point to your content
# server.  In this case, apache + Passenger running on port 80
# 

backend default {
    .host = "127.0.0.1";
    .port = "80";
    .connect_timeout = 600s;
    .first_byte_timeout = 600s;
    .between_bytes_timeout = 600s;
}

sub vcl_recv {

   # Handle IPv6
   if (req.http.Host ~ "^ipv6.*") {
        set req.http.host = regsub(req.http.host, "^ipv6\.(.*)","www\.\1");
   }


    # Sanitise X-Forwarded-For...
    remove req.http.X-Forwarded-For;
    set req.http.X-Forwarded-For = client.ip;
 
    # Remove Google Analytics, has_js, and last-seen cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(__[a-z]+|has_js|last_body_id|last_request_id|seen_foi2)=[^;]*", "");

    # Normalize the Accept-Encoding header
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|jpeg|png|gif|gz|tgz|bz2|tbz|mp3|ogg|swf|flv|pdf|ico)$") {
            # No point in compressing these
            remove req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            # unknown algorithm
            remove req.http.Accept-Encoding;
        }
    }
 
    # Ignore empty cookies
    if (req.http.Cookie ~ "^\s*$") {
        remove req.http.Cookie;
    }
    
    if (req.request != "GET" &&
       req.request != "HEAD" && 
       req.request != "POST" &&
       req.request != "PUT" &&
       req.request != "DELETE" ) {
        # We don't allow any other methods.
        error 405 "Method Not Allowed";
    }

    if (req.request != "GET" && req.request != "HEAD") {
        /* We only deal with GET and HEAD by default, the rest get passed direct to backend */
        return (pass);
    }
   
    # Ignore Cookies on images...
    if (req.url ~ "\.(png|gif|jpg|jpeg|swf|css|js|rdf|ico|txt)(\?.*|)$") {
        remove req.http.Cookie;
        return (lookup);
    }

    if (req.http.Authorization || req.http.Cookie) {
        return (pass);
    }
 
    # Let's have a little grace
    set req.grace = 30s;
    return (lookup);
}


sub vcl_fetch {

    if (req.url ~ "\.(png|gif|jpg|jpeg|swf|css|js|rdf|ico|txt)(\?.*|)$") {
    # Ignore backend headers..
        remove beresp.http.set-Cookie;
        set beresp.ttl = 3600s;
        return (deliver);
    }

     if (beresp.status == 404 || beresp.status == 301 || beresp.status == 500) {
        set beresp.ttl = 1m;
        return (deliver);
    }
}
