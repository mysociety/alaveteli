{
  bcp47_spec = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "043qld01c163yc7fxlar3046dac2833rlcg44jbbs9n1jvgjxmiz";
      type = "gem";
    };
    version = "0.2.1";
  };
  caxlsx = {
    dependencies = [ "htmlentities" "marcel" "nokogiri" "rubyzip" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "09q9743z94qv3y2fbiyby3mffaapjv1qna03xiykqyszpi91cr24";
      type = "gem";
    };
    version = "3.4.1";
  };
  ebnf = {
    dependencies =
      [ "base64" "htmlentities" "rdf" "scanf" "sxp" "unicode-types" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "0gpnphpp7qcdjh9vrj8bfrb3k54lq7pk7p23w92wr1d8r8ba6ip7";
      type = "gem";
    };
    version = "2.6.0";
  };
  link_header = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1yamrdq4rywmnpdhbygnkkl9fdy249fg5r851nrkkxr97gj5rihm";
      type = "gem";
    };
    version = "0.0.8";
  };
  net-http-persistent = {
    dependencies = [ "connection_pool" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "0pfxhhn1lqnxx8dj3ig3lgnhkxq5jsb0brg7w2wnrpwf8c23mfra";
      type = "gem";
    };
    version = "4.0.6";
  };
  rdf = {
    dependencies =
      [ "bcp47_spec" "bigdecimal" "link_header" "logger" "ostruct" "readline" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1har1346p7jwrs89d5w1gv98jk2nh3cwkdyvkzm2nkjv3s1a0zx7";
      type = "gem";
    };
    version = "3.3.4";
  };
  rdf-aggregate-repo = {
    dependencies = [ "rdf" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1p7gm5arszrjqvmzsr170bb1j7ri52qamscm7h8wggnvyjmwr4sn";
      type = "gem";
    };
    version = "3.3.0";
  };
  rdf-xsd = {
    dependencies = [ "rdf" "rexml" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "0wj7ljxnlsyf8ni7dz0bhi04ki74hcpg6bk2kdyj6i03n8kivdgs";
      type = "gem";
    };
    version = "3.3.0";
  };
  readline = {
    dependencies = [ "reline" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "0shxkj3kbwl43rpg490k826ibdcwpxiymhvjnsc85fg2ggqywf31";
      type = "gem";
    };
    version = "0.0.4";
  };
  rodf = {
    dependencies = [ "builder" "rubyzip" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "14993s6x5fr1053wmb7s5ij16sr90ig853fapzvp6d03ay6b840c";
      type = "gem";
    };
    version = "1.2.0";
  };
  scanf = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "000vxsci3zq8m1wl7mmppj7sarznrqlm6v2x2hdfmbxcwpvvfgak";
      type = "gem";
    };
    version = "1.0.0";
  };
  sparql = {
    dependencies = [
      "builder"
      "ebnf"
      "logger"
      "rdf"
      "rdf-aggregate-repo"
      "rdf-xsd"
      "readline"
      "sparql-client"
      "sxp"
    ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1p34xnrzjjyr5zlm9x9nym75kxma24n039achcyd1mhzh1i3mmr0";
      type = "gem";
    };
    version = "3.3.2";
  };
  sparql-client = {
    dependencies = [ "net-http-persistent" "rdf" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "0knnrajm5zw7prykh9az7s1zmzxwm7w8s05pnsm2pp28mppmw8ki";
      type = "gem";
    };
    version = "3.3.0";
  };
  spreadsheet_architect = {
    dependencies = [ "caxlsx" "rodf" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1sf4p3qqrwvl4l6dq2z67cfbwf6jhnzvmqj95kd0yzf2jdacddri";
      type = "gem";
    };
    version = "5.0.1";
  };
  sxp = {
    dependencies = [ "matrix" "rdf" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "08a7ha191gdc1n1pwaqgsx133wy1p1g4fchkhr5gx0jannx1p5vr";
      type = "gem";
    };
    version = "2.0.0";
  };
  unicode-types = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1mif6v3wlfpb69scikpv7i4zq9rhj19px23iym6j8m3wnnh7d2wi";
      type = "gem";
    };
    version = "1.10.0";
  };
}
