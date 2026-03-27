{
  actioncable = {
    dependencies = ["actionpack" "activesupport" "nio4r" "websocket-driver" "zeitwerk"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17z0flj504z9d5hmzmd8g2gmaiz1a3yndvkxmbz6qrkvjzr2pnxa";
      type = "gem";
    };
    version = "8.0.4";
  };
  actionmailbox = {
    dependencies = ["actionpack" "activejob" "activerecord" "activestorage" "activesupport" "mail"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03yqbiiz9z1nqy4n7rhjpavn20lx5rvjbq0sl0dkvdiga15662zd";
      type = "gem";
    };
    version = "8.0.4";
  };
  actionmailer = {
    dependencies = ["actionpack" "actionview" "activejob" "activesupport" "mail" "rails-dom-testing"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jyyfp786csg4hmsxfywi8131p1pk51jzi8i9d9zn2lzw7c714iv";
      type = "gem";
    };
    version = "8.0.4";
  };
  actionpack = {
    dependencies = ["actionview" "activesupport" "nokogiri" "rack" "rack-session" "rack-test" "rails-dom-testing" "rails-html-sanitizer" "useragent"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nyd4f58r11b0x5gsjlnyk2k9y2kd0zhv8szf82g9j1j5xccfr03";
      type = "gem";
    };
    version = "8.0.4";
  };
  actiontext = {
    dependencies = ["actionpack" "activerecord" "activestorage" "activesupport" "globalid" "nokogiri"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0h13x9y767i9nan09jyhiw32s1gmdmcb4mjld1jvhadcd019gcs0";
      type = "gem";
    };
    version = "8.0.4";
  };
  actionview = {
    dependencies = ["activesupport" "builder" "erubi" "rails-dom-testing" "rails-html-sanitizer"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0j0n38p02s73r9a8fg615z8m78n9agpf9d9b0v7i97m5wwgc9lsv";
      type = "gem";
    };
    version = "8.0.4";
  };
  active_model_otp = {
    dependencies = ["activemodel" "rotp"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0a5br51p0k3f61dq2v139bddpifwvrs8d4zxz5r8kk7n6lkifdfh";
      type = "gem";
    };
    version = "2.3.4";
  };
  activejob = {
    dependencies = ["activesupport" "globalid"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1knc9xwfnyqcxqzfsfix210ai2yhw9ps7j19aq5bk30n1rfsij6b";
      type = "gem";
    };
    version = "8.0.4";
  };
  activejob-uniqueness = {
    dependencies = ["activejob" "redlock"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "13w24pfshl86r70d0xgnqzya2f8r0y2x59m2c1a8kbhb7bq2i4nk";
      type = "gem";
    };
    version = "0.4.0";
  };
  activemodel = {
    dependencies = ["activesupport"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1z8dff84qgqinhwsj0i91r674vvg412kg72162zv216i7jn4yklg";
      type = "gem";
    };
    version = "8.0.4";
  };
  activerecord = {
    dependencies = ["activemodel" "activesupport" "timeout"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cmz9k27zy0746zpljg28ir4857df9r3nza4c1acmrcr2wbjr8xx";
      type = "gem";
    };
    version = "8.0.4";
  };
  activestorage = {
    dependencies = ["actionpack" "activejob" "activerecord" "activesupport" "marcel"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hx0chzrszc3kbjn8psagxaaas4ns5479kr0kxkc36685yb15ws7";
      type = "gem";
    };
    version = "8.0.4";
  };
  activesupport = {
    dependencies = ["base64" "benchmark" "bigdecimal" "concurrent-ruby" "connection_pool" "drb" "i18n" "logger" "minitest" "securerandom" "tzinfo" "uri"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0np97w7kc9dx7kx092nzhy3g6qxmqivcsfnzlzjzmd9kfxn3ljl9";
      type = "gem";
    };
    version = "8.0.4";
  };
  acts_as_versioned = {
    dependencies = ["activerecord"];
    groups = ["default"];
    platforms = [];
    source = {
      fetchSubmodules = false;
      rev = "13e928b8227349461205c2fa22d0bc3dbe2f1135";
      sha256 = "1ai7w47sdh9jrmzcw6646ccd4dszc5g33lipg4w4jff7r4hln89m";
      type = "git";
      url = "https://github.com/mysociety/acts_as_versioned.git";
    };
    version = "0.6.0";
  };
  addressable = {
    dependencies = ["public_suffix"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11ali533wx91fh93xlk88gjqq8w0p7kxw09nlh41hwc9wv5ly5fc";
      type = "gem";
    };
    version = "2.8.9";
  };
  alaveteli_features = {
    dependencies = ["flipper" "flipper-active_record" "mime-types" "rails"];
    groups = ["default"];
    platforms = [];
    source = {
      path = gems/alaveteli_features;
      type = "path";
    };
    version = "0.0.1";
  };
  annotaterb = {
    dependencies = ["activerecord" "activesupport"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11h2lz0fyj1hh37x1lwvxr0svaisnkjs2g81hap84nwdykjl1z36";
      type = "gem";
    };
    version = "4.22.0";
  };
  ast = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10yknjyn0728gjn6b5syynvrvrwm66bhssbxq8mkhshxghaiailm";
      type = "gem";
    };
    version = "2.4.3";
  };
  aws-eventstream = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fqqdqg15rgwgz3mn4pj91agd20csk9gbrhi103d20328dfghsqi";
      type = "gem";
    };
    version = "1.4.0";
  };
  aws-partitions = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gvnh2p22v5xkhq5dvbxxlxw3wr8plx5cbh9dlqgqimyz93qi0nr";
      type = "gem";
    };
    version = "1.1211.0";
  };
  aws-sdk-core = {
    dependencies = ["aws-eventstream" "aws-partitions" "aws-sigv4" "base64" "bigdecimal" "jmespath" "logger"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zg44q9bykznxdp4l130qkvmhx4n3hhalh3cgc781aafqalcnb54";
      type = "gem";
    };
    version = "3.241.4";
  };
  aws-sdk-kms = {
    dependencies = ["aws-sdk-core" "aws-sigv4"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1q015l5gm3f230jz9l6si9s3hlw7ra76q8biqvxlwxdmnk7w2qym";
      type = "gem";
    };
    version = "1.121.0";
  };
  aws-sdk-s3 = {
    dependencies = ["aws-sdk-core" "aws-sdk-kms" "aws-sigv4"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03g5k3jl0sgp60ppmxa267qflxlj174mrs8hnrnl10j5ak7nqndg";
      type = "gem";
    };
    version = "1.213.0";
  };
  aws-sigv4 = {
    dependencies = ["aws-eventstream"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "003ch8qzh3mppsxch83ns0jra8d222ahxs96p9cdrl0grfazywv9";
      type = "gem";
    };
    version = "1.12.1";
  };
  base64 = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yx9yn47a8lkfcjmigk79fykxvr80r4m1i35q82sxzynpbm7lcr7";
      type = "gem";
    };
    version = "0.3.0";
  };
  bcrypt = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1krd99p9828n07rcjjms56jaqv7v6s9pn7y6bppcfhhaflyn2r2r";
      type = "gem";
    };
    version = "3.1.21";
  };
  benchmark = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0v1337j39w1z7x9zs4q7ag0nfv4vs4xlsjx2la0wpv8s6hig2pa6";
      type = "gem";
    };
    version = "0.5.0";
  };
  bigdecimal = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "19y406nx17arzsbc515mjmr6k5p59afprspa1k423yd9cp8d61wb";
      type = "gem";
    };
    version = "4.0.1";
  };
  bindex = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0zmirr3m02p52bzq4xgksq4pn8j641rx5d4czk68pv9rqnfwq7kv";
      type = "gem";
    };
    version = "0.8.1";
  };
  bootstrap-sass = {
    dependencies = ["sass"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0r2qg3xn61yw4w9n45gxl5k886401dva1hnjjzfdxx7ynklqxcvh";
      type = "gem";
    };
    version = "2.3.2.2";
  };
  builder = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pw3r2lyagsxkm71bf44v5b74f7l9r7di22brbyji9fwz791hya9";
      type = "gem";
    };
    version = "3.3.0";
  };
  bullet = {
    dependencies = ["activesupport" "uniform_notifier"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zwq7g98c1mdigahb50c980a0fcc4ib1m9ivmgf3f8gc6qk7wjv0";
      type = "gem";
    };
    version = "8.1.0";
  };
  cancancan = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qkbqmj8hnljyl108mw7rl44c99xmrhpyaj5m54dzmaqpxf1sp4p";
      type = "gem";
    };
    version = "3.6.1";
  };
  capybara = {
    dependencies = ["addressable" "matrix" "mini_mime" "nokogiri" "rack" "rack-test" "regexp_parser" "xpath"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vxfah83j6zpw3v5hic0j70h519nvmix2hbszmjwm8cfawhagns2";
      type = "gem";
    };
    version = "3.40.0";
  };
  cgi = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1s8qdw1nfh3njd47q154njlfyc2llcgi4ik13vz39adqd7yclgz9";
      type = "gem";
    };
    version = "0.5.1";
  };
  charlock_holmes = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1c1dws56r7p8y363dhyikg7205z59a3bn4amnv2y488rrq8qm7ml";
      type = "gem";
    };
    version = "0.7.9";
  };
  childprocess = {
    dependencies = ["logger"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1v5nalaarxnfdm6rxb7q6fmc6nx097jd630ax6h9ch7xw95li3cs";
      type = "gem";
    };
    version = "5.1.0";
  };
  coderay = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jvxqxzply1lwp7ysn94zjhh57vc14mcshw1ygw14ib8lhc00lyw";
      type = "gem";
    };
    version = "1.1.3";
  };
  compare-xml = {
    dependencies = ["nokogiri"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "06aks0fjxwvs4l9bd8bl9q48kyadzn4cd5yrrrz1gwcyyv0aa6p2";
      type = "gem";
    };
    version = "0.66";
  };
  concurrent-ruby = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1aymcakhzl83k77g2f2krz07bg1cbafbcd2ghvwr4lky3rz86mkb";
      type = "gem";
    };
    version = "1.3.6";
  };
  connection_pool = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1b8nlxr5z843ii7hfk6igpr5acw3k2ih9yjrgkyz2gbmallgjkz5";
      type = "gem";
    };
    version = "2.5.5";
  };
  crack = {
    dependencies = ["bigdecimal" "rexml"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0zjcdl5i6lw508r01dym05ibhkc784cfn93m1d26c7fk1hwi0jpz";
      type = "gem";
    };
    version = "1.0.1";
  };
  crass = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pfl5c0pyqaparxaqxi6s4gfl21bdldwiawrc0aknyvflli60lfw";
      type = "gem";
    };
    version = "1.0.6";
  };
  csv = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gz7r2kazwwwyrwi95hbnhy54kwkfac5swh2gy5p5vw36fn38lbf";
      type = "gem";
    };
    version = "3.3.5";
  };
  dalli = {
    dependencies = ["logger"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "036slblmm814n4z3nwiya94n32qg79pbqmlgi4ly3ndh88saln5f";
      type = "gem";
    };
    version = "4.3.3";
  };
  dante = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1rkg1as47b305vgdmphlydn6xvm239il2czmpkxky9ad9gq7d5wk";
      type = "gem";
    };
    version = "0.2.0";
  };
  date = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1h0db8r2v5llxdbzkzyllkfniqw9gm092qn7cbaib73v9lw0c3bm";
      type = "gem";
    };
    version = "3.5.1";
  };
  declarative = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1yczgnqrbls7shrg63y88g7wand2yp9h6sf56c9bdcksn5nds8c0";
      type = "gem";
    };
    version = "0.0.20";
  };
  diff-lcs = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qlrj2qyysc9avzlr4zs1py3x684hqm61n4czrsk1pyllz5x5q4s";
      type = "gem";
    };
    version = "1.6.2";
  };
  digest-crc = {
    dependencies = ["rake"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01wcsyhaadss4zzvqh12kvbq3hmkl5y4fck7pr608hd24qxc5bb4";
      type = "gem";
    };
    version = "0.7.0";
  };
  docile = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1lxqxgq71rqwj1lpl9q1mbhhhhhhdkkj7my341f2889pwayk85sz";
      type = "gem";
    };
    version = "1.4.0";
  };
  drb = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wrkl7yiix268s2md1h6wh91311w95ikd8fy8m5gx589npyxc00b";
      type = "gem";
    };
    version = "2.2.3";
  };
  erb = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ar4nmvk1sk7drjigqyh9nnps3mxg625b8chfk42557p8i6jdrlz";
      type = "gem";
    };
    version = "6.0.2";
  };
  erubi = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1naaxsqkv5b3vklab5sbb9sdpszrjzlfsbqpy7ncbnw510xi10m0";
      type = "gem";
    };
    version = "1.13.1";
  };
  ethon = {
    dependencies = ["ffi"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17ix0mijpsy3y0c6ywrk5ibarmvqzjsirjyprpsy3hwax8fdm85v";
      type = "gem";
    };
    version = "0.16.0";
  };
  excel_analyzer = {
    dependencies = ["activestorage" "mahoro" "mail" "rubyXL" "rubyzip"];
    groups = ["default"];
    platforms = [];
    source = {
      path = gems/excel_analyzer;
      type = "path";
    };
    version = "0.0.1";
  };
  exception_notification = {
    dependencies = ["actionmailer" "activesupport"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1y98p9sxrwxs63c5ylxmsf1a0ggqm5hlmlagf7qm1v3h8s6qqsd9";
      type = "gem";
    };
    version = "5.0.1";
  };
  factory_bot = {
    dependencies = ["activesupport"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1gpgcr5dfrq7hs3wafxaqrkx84zm2rlfwbwamd6p1d71mrfjjnff";
      type = "gem";
    };
    version = "6.5.5";
  };
  factory_bot_rails = {
    dependencies = ["factory_bot" "railties"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0s3dpi8x754bwv4mlasdal8ffiahi4b4ajpccnkaipp4x98lik6k";
      type = "gem";
    };
    version = "6.5.1";
  };
  fancybox-rails = {
    dependencies = ["railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0nwx4i81zp7c5i3l34z1z7cvgg54239z611cik2nmiaxgcbirb0i";
      type = "gem";
    };
    version = "0.3.1";
  };
  faraday = {
    dependencies = ["faraday-net_http" "json" "logger"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "077n5ss3z3ds4vj54w201kd12smai853dp9c9n7ii7g3q7nwwg54";
      type = "gem";
    };
    version = "2.14.1";
  };
  faraday-follow_redirects = {
    dependencies = ["faraday"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1b8hgpci3wjm3rm41bzpasvsc5j253ljyg5rsajl62dkjk497pjw";
      type = "gem";
    };
    version = "0.5.0";
  };
  faraday-net_http = {
    dependencies = ["net-http"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0v4hfmc7d4lrqqj2wl366rm9551gd08zkv2ppwwnjlnkc217aizi";
      type = "gem";
    };
    version = "3.4.2";
  };
  faraday-typhoeus = {
    dependencies = ["faraday" "typhoeus"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1rwhd2f78vqj0wkkdah395apx6igp5xf82n5xgixs61q45y19ii4";
      type = "gem";
    };
    version = "1.1.0";
  };
  fast_gettext = {
    dependencies = ["prime" "racc"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1n7gcq1y893ijck42nm0wqxbqc36smmkd49fzcgc63avjkv35ig8";
      type = "gem";
    };
    version = "4.1.1";
  };
  ffi = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fgwn1grxf4zxmyqmb9i4z2hr111585n9jnk17y6y7hhs7dv1xi6";
      type = "gem";
    };
    version = "1.17.1";
  };
  fiddle = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vifygrkw22gcd4wzh8gc4pv6h1zpk6kll6mmprrf5174wvfxa3z";
      type = "gem";
    };
    version = "1.1.8";
  };
  fivemat = {
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pzlycasvwmg4bbx7plllpqnhd9zlmmff8l2w3yii86nrm2nvf9n";
      type = "gem";
    };
    version = "1.3.7";
  };
  flipper = {
    dependencies = ["concurrent-ruby"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1v8hn61xxpxcnxgnvd5iqbccqj3sfsb17a1iabjxi1884pq843ar";
      type = "gem";
    };
    version = "1.3.6";
  };
  flipper-active_record = {
    dependencies = ["activerecord" "flipper"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1giadfq4n3xqlz5g6mrpd5121kfjvqli9gbzsjmkfih2whj245qc";
      type = "gem";
    };
    version = "1.3.6";
  };
  forwardable = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0f78rjpnhm4lgp1qzadnr6kr02b6afh1lvy7w607k4qjk3641kgi";
      type = "gem";
    };
    version = "1.4.0";
  };
  friendly_id = {
    dependencies = ["activerecord"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hxhddr497v7cciwns9rw7fsi6qczp3c2r0i6a31blpvag6j3qi8";
      type = "gem";
    };
    version = "5.6.0";
  };
  gender_detector = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0mylqhjnirbh1jpxqb7map1m9k5ilfrrbdna9i7xhmn56cckdaaa";
      type = "gem";
    };
    version = "2.1.0";
  };
  gettext = {
    dependencies = ["erubi" "locale" "prime" "racc" "text"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0x1wpyy5mgn0523f4pyv7lpxs8b4s6pfvyi24nymd7vym9cjr85d";
      type = "gem";
    };
    version = "3.5.2";
  };
  gettext_i18n_rails = {
    dependencies = ["fast_gettext"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0a06pxblz50czlzgah28zzg6qq6cmnhkn3qaxjbdfylpyaasaak7";
      type = "gem";
    };
    version = "2.1.0";
  };
  globalid = {
    dependencies = ["activesupport"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "04gzhqvsm4z4l12r9dkac9a75ah45w186ydhl0i4andldsnkkih5";
      type = "gem";
    };
    version = "1.3.0";
  };
  globalize = {
    dependencies = ["activemodel" "activerecord" "activesupport" "request_store"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1rrdj37rlggbcj9jgbjxhdy1g34rrl2gn3r5nq4fx56ljsqqc8lk";
      type = "gem";
    };
    version = "7.1.1";
  };
  gnuplot = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cvb84lahhy6qxkkgg0pfk9b85qrb1by2p3jlpqgczl6am58vhnj";
      type = "gem";
    };
    version = "2.6.2";
  };
  google-apis-core = {
    dependencies = ["addressable" "faraday" "faraday-follow_redirects" "googleauth" "mini_mime" "representable" "retriable"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0a961x3jq0wskwgb8ym83viza05bcvsqiny8gg6dc0n9mnm7jids";
      type = "gem";
    };
    version = "1.0.2";
  };
  google-apis-iamcredentials_v1 = {
    dependencies = ["google-apis-core"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18s8kshls6amld400434xgmgssn2y9fpqnz9ahjxzkfnl480mxrz";
      type = "gem";
    };
    version = "0.26.0";
  };
  google-apis-storage_v1 = {
    dependencies = ["google-apis-core"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0rq4c6zk4p0y3s8984kajk2hiqk33f3wfhxhva62fwxf8wf1bwsj";
      type = "gem";
    };
    version = "0.58.0";
  };
  google-cloud-core = {
    dependencies = ["google-cloud-env" "google-cloud-errors"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kw10897ardky1chwwsb8milygzcdi8qlqlhcnqwmkw9y75yswp5";
      type = "gem";
    };
    version = "1.8.0";
  };
  google-cloud-env = {
    dependencies = ["base64" "faraday"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1rvqj6n6qhjmjy0lynpmga7ly48s7dk36i6nj4jqrrvvn8gc1ahg";
      type = "gem";
    };
    version = "2.3.1";
  };
  google-cloud-errors = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jvv9w8s4dqc4ncfa6c6qpdypz2wj8dmgpjd44jq2qhhij5y4sxm";
      type = "gem";
    };
    version = "1.5.0";
  };
  google-cloud-storage = {
    dependencies = ["addressable" "digest-crc" "google-apis-core" "google-apis-iamcredentials_v1" "google-apis-storage_v1" "google-cloud-core" "googleauth" "mini_mime"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zfzix33r060ch1ms2g7m7zzjhgrp43d67fy3sg1dbvmkixc1v8v";
      type = "gem";
    };
    version = "1.58.0";
  };
  google-logging-utils = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yyzlgy9hx104xhrbl51ana0dl3m5p5989j4lcjsizssxas64m37";
      type = "gem";
    };
    version = "0.2.0";
  };
  googleauth = {
    dependencies = ["faraday" "google-cloud-env" "google-logging-utils" "jwt" "multi_json" "os" "signet"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1wfmbg5cgn0rr84nv7b7w85xq8iqkdbjqcd4lkss1ipdwwp5qyqy";
      type = "gem";
    };
    version = "1.16.0";
  };
  hashdiff = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1lbw8lqzjv17vnwb9vy5ki4jiyihybcc5h2rmcrqiz1xa6y9s1ww";
      type = "gem";
    };
    version = "1.2.1";
  };
  holidays = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0n8qgflgkjih5gkylgdzzdg5isxic7yb779xlnyi8qiip6cn3dhp";
      type = "gem";
    };
    version = "8.8.0";
  };
  htmlentities = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hy5jvzd4wagk0k0yq7bjm6fa7ba7vjggzjfpri95jifkzvbvbxv";
      type = "gem";
    };
    version = "4.4.2";
  };
  i18n = {
    dependencies = ["concurrent-ruby"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1994i044vdmzzkyr76g8rpl1fq1532wf0sb21xg5r1ilj5iphmr8";
      type = "gem";
    };
    version = "1.14.8";
  };
  icalendar = {
    dependencies = ["base64" "ice_cube" "logger" "ostruct"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0r77iy9q5mvsplla88mgvxi27xjbll6svynikbr53mdfa32mdzzc";
      type = "gem";
    };
    version = "2.12.1";
  };
  ice_cube = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1gpwlpshsjlld53h1f999p0azd9jdlgmhbswa19wqjjbv9fv9pij";
      type = "gem";
    };
    version = "0.17.0";
  };
  image_processing = {
    dependencies = ["mini_magick" "ruby-vips"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ys28w0ayq3vl2sl4lpq6jnsy7gd4p9vzimyi449hqn2r5lw2k3m";
      type = "gem";
    };
    version = "1.14.0";
  };
  importmap-rails = {
    dependencies = ["actionpack" "activesupport" "railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0smixr7l97pky55k0kz9rxmmyk2032kp7xdqixaz2z699lmbw0bi";
      type = "gem";
    };
    version = "2.2.3";
  };
  io-console = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1k0lk3pwadm2myvpg893n8jshmrf2sigrd4ki15lymy7gixaxqyn";
      type = "gem";
    };
    version = "0.8.2";
  };
  irb = {
    dependencies = ["pp" "prism" "rdoc" "reline"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bishrxfn2anwlagw8rzly7i2yicjnr947f48nh638yqjgdlv30n";
      type = "gem";
    };
    version = "1.17.0";
  };
  iso_country_codes = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qyaaay09jfrlljnkfhs35340j8jbw4xl67z509c7r0bdj900i9c";
      type = "gem";
    };
    version = "0.7.8";
  };
  jmespath = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cdw9vw2qly7q7r41s7phnac264rbsdqgj4l0h4nqgbjb157g393";
      type = "gem";
    };
    version = "1.6.2";
  };
  jquery-rails = {
    dependencies = ["rails-dom-testing" "railties" "thor"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1h6rm2ricjhqlhnp22afbms5pi1zmkdm5ynssqgsxsndrnb397v1";
      type = "gem";
    };
    version = "4.6.1";
  };
  jquery-ui-rails = {
    dependencies = ["railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1mbwwbbwzp836l7mc21amnaqmf5wbrw5hzls48hscrcgh0vig812";
      type = "gem";
    };
    version = "6.0.1";
  };
  json = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11prr7nrxh1y4rfsqa51gy4ixx63r18cz9mdnmk0938va1ajf4gy";
      type = "gem";
    };
    version = "2.18.1";
  };
  json-schema = {
    dependencies = ["addressable" "bigdecimal"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00n73lr2gwlpf3safdmxxa44qchg36l3y298v835mzbdzcn0mxvb";
      type = "gem";
    };
    version = "6.1.0";
  };
  jwt = {
    dependencies = ["base64"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dfm4bhl4fzn076igh0bmh2v1vphcrxdv6ldc46hdd3bkbqr2sdg";
      type = "gem";
    };
    version = "3.1.2";
  };
  language_server-protocol = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1k0311vah76kg5m6zr7wmkwyk5p2f9d9hyckjpn3xgr83ajkj7px";
      type = "gem";
    };
    version = "3.17.0.5";
  };
  launchy = {
    dependencies = ["addressable" "childprocess" "logger"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17h522xhwi5m4n6n9m22kw8z0vy8100sz5f3wbfqj5cnrjslgf3j";
      type = "gem";
    };
    version = "3.1.1";
  };
  lint_roller = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11yc0d84hsnlvx8cpk4cbj6a4dz9pk0r1k29p0n1fz9acddq831c";
      type = "gem";
    };
    version = "1.1.0";
  };
  locale = {
    dependencies = ["fiddle"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1x1fnf4knvyzb9br6ja7b1nvy0860nax0i8rx4ljrnvbmbl06s0w";
      type = "gem";
    };
    version = "2.1.5";
  };
  logger = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00q2zznygpbls8asz5knjvvj2brr3ghmqxgr83xnrdj4rk3xwvhr";
      type = "gem";
    };
    version = "1.7.0";
  };
  loofah = {
    dependencies = ["crass" "nokogiri"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1rk0n13c9nmk8di2x5gqk5r04vf8bkp7ff6z0b44wsmc7fndfpnz";
      type = "gem";
    };
    version = "2.25.0";
  };
  mahoro = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xfqjfhjz87qwzda290shjjxc929jcd2b249dhry0scrl8savp3v";
      type = "gem";
    };
    version = "0.5";
  };
  mail = {
    dependencies = ["mini_mime" "net-imap" "net-pop" "net-smtp"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bf9pysw1jfgynv692hhaycfxa8ckay1gjw5hz3madrbrynryfzc";
      type = "gem";
    };
    version = "2.8.1";
  };
  marcel = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vhb1sbzlq42k2pzd9v0w5ws4kjx184y8h4d63296bn57jiwzkzx";
      type = "gem";
    };
    version = "1.1.0";
  };
  matrix = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0nscas3a4mmrp1rc07cdjlbbpb2rydkindmbj3v3z5y1viyspmd0";
      type = "gem";
    };
    version = "0.4.3";
  };
  maxmind-db = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0llhhk5np19hk66qsz5c14d14hz8pak1bwm7hwkfjzw4569wfr87";
      type = "gem";
    };
    version = "1.4.0";
  };
  mcp = {
    dependencies = ["json-schema"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1izi2hyyifn8m5b9s1yj8v1d4a453mrhga8yk06ssawmssapi5ps";
      type = "gem";
    };
    version = "0.7.1";
  };
  method_source = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1igmc3sq9ay90f8xjvfnswd1dybj1s3fi0dwd53inwsvqk4h24qq";
      type = "gem";
    };
    version = "1.1.0";
  };
  mime-types = {
    dependencies = ["logger" "mime-types-data"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0mjyxl7c0xzyqdqa8r45hqg7jcw2prp3hkp39mdf223g4hfgdsyw";
      type = "gem";
    };
    version = "3.7.0";
  };
  mime-types-data = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1n9vlqa5bkaj8wald4vhsm5yav4nd4azxi1aplwhimihrs5pnwqf";
      type = "gem";
    };
    version = "3.2025.0507";
  };
  mini_magick = {
    dependencies = ["benchmark" "logger"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0zlsc8dj0ak37snw3icag1jk56iq7j5mdayp3rmzinam5hm12mrc";
      type = "gem";
    };
    version = "5.1.2";
  };
  mini_mime = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vycif7pjzkr29mfk4dlqv3disc5dn0va04lkwajlpr1wkibg0c6";
      type = "gem";
    };
    version = "1.1.5";
  };
  mini_portile2 = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12f2830x7pq3kj0v8nz0zjvaw02sv01bqs1zwdrc04704kwcgmqc";
      type = "gem";
    };
    version = "2.8.9";
  };
  minitest = {
    dependencies = ["drb" "prism"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gdwmn2d4sznjdxyl3kz7hr95mvdgm38fk1vd0s63k3fdyamfvnv";
      type = "gem";
    };
    version = "6.0.2";
  };
  money = {
    dependencies = ["bigdecimal" "i18n"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0q1c5sr6xng25zm64fzzj3vj0kazmzalspswvb70s68xzp0jfp31";
      type = "gem";
    };
    version = "7.0.2";
  };
  multi_json = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1drisvysgvnjlz49a0qcbs294id6mvj3i8iik5rvym68ybwfzvvs";
      type = "gem";
    };
    version = "1.19.1";
  };
  net-http = {
    dependencies = ["uri"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15k96fj6qwbaiv6g52l538ass95ds1qwgynqdridz29yqrkhpfi5";
      type = "gem";
    };
    version = "0.9.1";
  };
  net-imap = {
    dependencies = ["date" "net-protocol"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0i24prs7yy1p1zdps2x1ksb7lmvbn2f0llxwdjdw3z2ksddx136b";
      type = "gem";
    };
    version = "0.5.12";
  };
  net-pop = {
    dependencies = ["net-protocol"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1wyz41jd4zpjn0v1xsf9j778qx1vfrl24yc20cpmph8k42c4x2w4";
      type = "gem";
    };
    version = "0.1.2";
  };
  net-protocol = {
    dependencies = ["timeout"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "051cc82dl41a66c9sxv4lx4slqk7sz1v4iy0hdk6gpjyjszf4hxd";
      type = "gem";
    };
    version = "0.1.3";
  };
  net-smtp = {
    dependencies = ["net-protocol"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dh7nzjp0fiaqq1jz90nv4nxhc2w359d7c199gmzq965cfps15pd";
      type = "gem";
    };
    version = "0.5.1";
  };
  nio4r = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18fwy5yqnvgixq3cn0h63lm8jaxsjjxkmj8rhiv8wpzv9271d43c";
      type = "gem";
    };
    version = "2.7.5";
  };
  nokogiri = {
    dependencies = ["mini_portile2" "racc"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1lss1nh526n3h1qsig2kjchi8vlsjwc8pdjpplm1f2yz6rzk52sr";
      type = "gem";
    };
    version = "1.19.1";
  };
  numo-narray = {
    groups = ["default"];
    platforms = [];
    source = {
      fetchSubmodules = false;
      rev = "95c05257349b954c027c2284834408736244662a";
      sha256 = "sha256-Er668v8pcenOI8lIlzSlVeC2VOaGMhaRa4RpBb/CSy0=";
      type = "git";
      url = "https://github.com/ruby-numo/numo-narray.git";
    };
    version = "0.9.2.1";
  };
  ollama-ai = {
    dependencies = ["faraday" "faraday-typhoeus" "typhoeus"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0s6kwja096c7prbfqa73h2wj6fb7jl24710kc0r0ghjpxkw2hxvl";
      type = "gem";
    };
    version = "1.3.0";
  };
  open4 = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cgls3f9dlrpil846q0w7h66vsc33jqn84nql4gcqkk221rh7px1";
      type = "gem";
    };
    version = "1.3.4";
  };
  os = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gwd20smyhxbm687vdikfh1gpi96h8qb1x28s2pdcysf6dm6v0ap";
      type = "gem";
    };
    version = "1.1.4";
  };
  ostruct = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "04nrir9wdpc4izqwqbysxyly8y7hsfr4fsv69rw91lfi9d5fv8lm";
      type = "gem";
    };
    version = "0.6.3";
  };
  parallel = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0c719bfgcszqvk9z47w2p8j2wkz5y35k48ywwas5yxbbh3hm3haa";
      type = "gem";
    };
    version = "1.27.0";
  };
  parser = {
    dependencies = ["ast" "racc"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0mwk9syajzdradzqzp3agf03d0cazqwbfd1439nxpkmxli5chq3g";
      type = "gem";
    };
    version = "3.3.10.2";
  };
  pg = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16caca7lcz5pwl82snarqrayjj9j7abmxqw92267blhk7rbd120k";
      type = "gem";
    };
    version = "1.6.3";
  };
  pp = {
    dependencies = ["prettyprint"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1xlxmg86k5kifci1xvlmgw56x88dmqf04zfzn7zcr4qb8ladal99";
      type = "gem";
    };
    version = "0.6.3";
  };
  prettyprint = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14zicq3plqi217w6xahv7b8f7aj5kpxv1j1w98344ix9h5ay3j9b";
      type = "gem";
    };
    version = "0.2.0";
  };
  prime = {
    dependencies = ["forwardable" "singleton"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pi2g9sd9ssyrpvbybh4skrgzqrv0rrd1q7ylgrsd519gjzmwxad";
      type = "gem";
    };
    version = "0.1.4";
  };
  prism = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11ggfikcs1lv17nhmhqyyp6z8nq5pkfcj6a904047hljkxm0qlvv";
      type = "gem";
    };
    version = "1.9.0";
  };
  pry = {
    dependencies = ["coderay" "method_source" "reline"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0kh5nv8v74k1ccy6gc7nd04aaf1cjkbk7g8pwy2izvcqaq36jv6p";
      type = "gem";
    };
    version = "0.16.0";
  };
  pstore = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "06icf1n6z7snygcq51zdm1zdz20cpkd4qw76s6b9wmv65h7lv403";
      type = "gem";
    };
    version = "0.2.1";
  };
  psych = {
    dependencies = ["date" "stringio"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0x0r3gc66abv8i4dw0x0370b5hrshjfp6kpp7wbp178cy775fypb";
      type = "gem";
    };
    version = "5.3.1";
  };
  public_suffix = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0mx84s7gn3xabb320hw8060v7amg6gmcyyhfzp0kawafiq60j54i";
      type = "gem";
    };
    version = "7.0.2";
  };
  puma = {
    dependencies = ["nio4r"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1a3jd9qakasizrf7dkq5mqv51fjf02r2chybai2nskjaa6mz93mz";
      type = "gem";
    };
    version = "7.2.0";
  };
  racc = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0byn0c9nkahsl93y9ln5bysq4j31q8xkf2ws42swighxd4lnjzsa";
      type = "gem";
    };
    version = "1.8.1";
  };
  rack = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hj5yq200wlq1clpdvh44pqwllbxll0k3gjajxnrcn95hxzhpky5";
      type = "gem";
    };
    version = "2.2.22";
  };
  rack-session = {
    dependencies = ["rack"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xhxhlsz6shh8nm44jsmd9276zcnyzii364vhcvf0k8b8bjia8d0";
      type = "gem";
    };
    version = "1.0.2";
  };
  rack-test = {
    dependencies = ["rack"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qy4ylhcfdn65a5mz2hly7g9vl0g13p5a0rmm6sc0sih5ilkcnh0";
      type = "gem";
    };
    version = "2.2.0";
  };
  rack-utf8_sanitizer = {
    dependencies = ["rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01vl78iy9mpk3742ajxy4zx2ry3vl8bib3hf7dc6a9w0kf9w004c";
      type = "gem";
    };
    version = "1.11.1";
  };
  rackup = {
    dependencies = ["rack" "webrick"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jf2ncj2nx56vh96hh2nh6h4r530nccxh87z7c2f37wq515611ms";
      type = "gem";
    };
    version = "1.0.1";
  };
  rails = {
    dependencies = ["actioncable" "actionmailbox" "actionmailer" "actionpack" "actiontext" "actionview" "activejob" "activemodel" "activerecord" "activestorage" "activesupport" "railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nv2g40b3hks0gqp7pbapj26cxz78z73dl1mq7azkhrd5nir8i1n";
      type = "gem";
    };
    version = "8.0.4";
  };
  rails-controller-testing = {
    dependencies = ["actionpack" "actionview" "activesupport"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "151f303jcvs8s149mhx2g5mn67487x0blrf9dzl76q1nb7dlh53l";
      type = "gem";
    };
    version = "1.0.5";
  };
  rails-dom-testing = {
    dependencies = ["activesupport" "minitest" "nokogiri"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "07awj8bp7jib54d0khqw391ryw8nphvqgw4bb12cl4drlx9pkk4a";
      type = "gem";
    };
    version = "2.3.0";
  };
  rails-html-sanitizer = {
    dependencies = ["loofah" "nokogiri"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "128y5g3fyi8fds41jasrr4va1jrs7hcamzklk1523k7rxb64bc98";
      type = "gem";
    };
    version = "1.7.0";
  };
  rails-i18n = {
    dependencies = ["i18n" "railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1wvcbdslb5gfvs9dw7kscd9da3xfyr3mdh1w4a28vwmy19ngvmaj";
      type = "gem";
    };
    version = "8.1.0";
  };
  railties = {
    dependencies = ["actionpack" "activesupport" "irb" "rackup" "rake" "thor" "tsort" "zeitwerk"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0iybsmr8yv8gg6a4cikmh0394sk707qr7h85vny4mazzvi9xh0w2";
      type = "gem";
    };
    version = "8.0.4";
  };
  rainbow = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0smwg4mii0fm38pyb5fddbmrdpifwv22zv3d3px2xx497am93503";
      type = "gem";
    };
    version = "3.1.1";
  };
  rake = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "175iisqb211n0qbfyqd8jz2g01q6xj038zjf4q0nm8k6kz88k7lc";
      type = "gem";
    };
    version = "13.3.1";
  };
  rake-compiler-dock = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hpq52ab86s70yv5hk56f0z14izhh59af95nlv73bsrksln1zdga";
      type = "gem";
    };
    version = "1.11.0";
  };
  rb_sys = {
    dependencies = ["rake-compiler-dock"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1rvshyirm32lzf2sggcrhvz5hi828s3rznmkchvzgshjgdapcd2i";
      type = "gem";
    };
    version = "0.9.124";
  };
  rdoc = {
    dependencies = ["erb" "psych" "tsort"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14iiyb4yi1chdzrynrk74xbhmikml3ixgdayjma3p700singfl46";
      type = "gem";
    };
    version = "7.2.0";
  };
  recaptcha = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nvsa14nd4sgx7m0n2xas8y6jiid5wcqr0ka1jgkm6cvpb7fj0z0";
      type = "gem";
    };
    version = "5.21.1";
  };
  redcarpet = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0iglapqs4av4za9yfaac0lna7s16fq2xn36wpk380m55d8792i6l";
      type = "gem";
    };
    version = "3.6.1";
  };
  redis = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fikjg6j12ka6hh36dxzhfkpqqmilzjfzcdf59iwkzsgd63f0ziq";
      type = "gem";
    };
    version = "4.8.1";
  };
  redis-client = {
    dependencies = ["connection_pool"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0k0qbbxxzinffqmsvgw5avqbpzpwip0p2qyh98c872xhl578i0qz";
      type = "gem";
    };
    version = "0.23.0";
  };
  redlock = {
    dependencies = ["redis-client"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1pixi711vv0f7g16dkr55x2mrq1kfxmpcmmknqsj84bqgiyjy9ny";
      type = "gem";
    };
    version = "2.0.6";
  };
  regexp_parser = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "192mzi0wgwl024pwpbfa6c2a2xlvbh3mjd75a0sakdvkl60z64ya";
      type = "gem";
    };
    version = "2.11.3";
  };
  reline = {
    dependencies = ["io-console"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0d8q5c4nh2g9pp758kizh8sfrvngynrjlm0i1zn3cnsnfd4v160i";
      type = "gem";
    };
    version = "0.6.3";
  };
  representable = {
    dependencies = ["declarative" "trailblazer-option" "uber"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kms3r6w6pnryysnaqqa9fsn0v73zx1ilds9d1c565n3xdzbyafc";
      type = "gem";
    };
    version = "3.2.0";
  };
  request_store = {
    dependencies = ["rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1jw89j9s5p5cq2k7ffj5p4av4j4fxwvwjs1a4i9g85d38r9mvdz1";
      type = "gem";
    };
    version = "1.7.0";
  };
  retriable = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1q48hqws2dy1vws9schc0kmina40gy7sn5qsndpsfqdslh65snha";
      type = "gem";
    };
    version = "3.1.2";
  };
  rexml = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hninnbvqd2pn40h863lbrn9p11gvdxp928izkag5ysx8b1s5q0r";
      type = "gem";
    };
    version = "3.4.4";
  };
  rice = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "sha256-xGzbJI2Ex3bmiYevZOCTjkQdm0dmC/JDu/fC4adrSII=";
      type = "gem";
    };
    version = "4.7.1";
  };
  rolify = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1dmmvqx8sh5f8s2y7lx59q2avskfjhmw1k7rlsnwqcs01kvznigy";
      type = "gem";
    };
    version = "6.0.1";
  };
  rotp = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0m48hv6wpmmm6cjr6q92q78h1i610riml19k5h1dil2yws3h1m3m";
      type = "gem";
    };
    version = "6.3.0";
  };
  rspec-activemodel-mocks = {
    dependencies = ["activemodel" "activesupport" "rspec-mocks"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0vnpb0zjjkd2py3h5gdhs9q3ly4n2a2sda03445a4w33f8di26xm";
      type = "gem";
    };
    version = "1.3.0";
  };
  rspec-core = {
    dependencies = ["rspec-support"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0bcbh9yv6cs6pv299zs4bvalr8yxa51kcdd1pjl60yv625j3r0m8";
      type = "gem";
    };
    version = "3.13.6";
  };
  rspec-expectations = {
    dependencies = ["diff-lcs" "rspec-support"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dl8npj0jfpy31bxi6syc7jymyd861q277sfr6jawq2hv6hx791k";
      type = "gem";
    };
    version = "3.13.5";
  };
  rspec-mocks = {
    dependencies = ["diff-lcs" "rspec-support"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "071bqrk2rblk3zq3jk1xxx0dr92y0szi5pxdm8waimxici706y89";
      type = "gem";
    };
    version = "3.13.7";
  };
  rspec-rails = {
    dependencies = ["actionpack" "activesupport" "railties" "rspec-core" "rspec-expectations" "rspec-mocks" "rspec-support"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hcxnxlcg6da7fy6s1y4k1r8cq36w994h0cai5yk2007l7kl195h";
      type = "gem";
    };
    version = "8.0.3";
  };
  rspec-support = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0z64h5rznm2zv21vjdjshz4v0h7bxvg02yc6g7yzxakj11byah06";
      type = "gem";
    };
    version = "3.13.7";
  };
  rubocop = {
    dependencies = ["json" "language_server-protocol" "lint_roller" "mcp" "parallel" "parser" "rainbow" "regexp_parser" "rubocop-ast" "ruby-progressbar" "unicode-display_width"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00cclinxd2xdwdcdc775g1vcxwbadcfrwbsdyra7v841nvz0fx1i";
      type = "gem";
    };
    version = "1.85.0";
  };
  rubocop-ast = {
    dependencies = ["parser" "prism"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zbikzd6237fvlzjfxdlhwi2vbmavg1cc81y6cyr581365nnghs9";
      type = "gem";
    };
    version = "1.49.0";
  };
  rubocop-performance = {
    dependencies = ["lint_roller" "rubocop" "rubocop-ast"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0d0qyyw1332afi9glwfjkb4bd62gzlibar6j55cghv8rzwvbj6fd";
      type = "gem";
    };
    version = "1.26.1";
  };
  rubocop-rails = {
    dependencies = ["activesupport" "lint_roller" "rack" "rubocop" "rubocop-ast"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1llsxc8wm2pq8glpv5mczd1h36fazbri3wwrh7dfqra80a4pklqh";
      type = "gem";
    };
    version = "2.34.3";
  };
  ruby-msg = {
    dependencies = ["ruby-ole" "vpim"];
    groups = ["default"];
    platforms = [];
    source = {
      fetchSubmodules = false;
      rev = "0c9ebb75a4dca40495b1caf8a37e6e628bb421f5";
      sha256 = "13wxrf8a0m0arrlz9y74i06qdw6db4myzv4cxscxzfcwgpj9nilw";
      type = "git";
      url = "https://github.com/mysociety/ruby-msg.git";
    };
    version = "1.5.2";
  };
  ruby-ole = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wnblgzz0fax0746yd4i8z16fpsjr6r6yv18l4sjnykr5bfi13ap";
      type = "gem";
    };
    version = "1.2.13.1";
  };
  ruby-progressbar = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cwvyb7j47m7wihpfaq7rc47zwwx9k4v7iqd9s1xch5nm53rrz40";
      type = "gem";
    };
    version = "1.13.0";
  };
  ruby-vips = {
    dependencies = ["ffi" "logger"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14nwdsd73c4ygjb7sfldnndlbzn5yyl02llnlzafmmjwh0d2pla1";
      type = "gem";
    };
    version = "2.2.3";
  };
  rubyXL = {
    dependencies = ["nokogiri" "rubyzip"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "071zgcwxyxip6j0s8hnvw9iy2k85liy0z1rph52an28hjmcdkrr0";
      type = "gem";
    };
    version = "3.4.35";
  };
  rubyzip = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0g2vx9bwl9lgn3w5zacl52ax57k4zqrsxg05ixf42986bww9kvf0";
      type = "gem";
    };
    version = "3.2.2";
  };
  safetensors = {
    dependencies = ["rb_sys"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "sha256-VpcBxDDIHkKfcrA3X4a1Cf52Og+SFoamr5zLpBvR8L0=";
      type = "gem";
    };
    version = "0.2.2";
  };
  sass = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0kfpcwh8dgw4lc81qglkvjl73689jy3g7196zkxm4fpskg1p5lkw";
      type = "gem";
    };
    version = "3.4.25";
  };
  sass-rails = {
    dependencies = ["railties" "sass" "sprockets" "sprockets-rails" "tilt"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "19bcs1ya3bkx36qaz21kgiz28s9h678m3rszcw7aany2lsis56y7";
      type = "gem";
    };
    version = "5.0.8";
  };
  secure_headers = {
    dependencies = ["cgi"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10qgnyhj4ggl7c7v110dprbhwlpihsr7dqlp7miwdf0jmwh3sfvi";
      type = "gem";
    };
    version = "7.2.0";
  };
  securerandom = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cd0iriqfsf1z91qg271sm88xjnfd92b832z49p1nd542ka96lfc";
      type = "gem";
    };
    version = "0.4.1";
  };
  sidekiq = {
    dependencies = ["connection_pool" "rack" "redis"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0zqr9is8y7mg5dfs1q8w5jl9spwvqkhbi9r6np8208n40hi3pydl";
      type = "gem";
    };
    version = "6.5.12";
  };
  sidekiq-limit_fetch = {
    dependencies = ["sidekiq"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "09wbzaa1sq2xxzm18f6xxj084m6g31bl9fx99kqw92fvs6sjy93x";
      type = "gem";
    };
    version = "4.4.1";
  };
  signet = {
    dependencies = ["addressable" "faraday" "jwt" "multi_json"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0nydm087m5c3j85gvzvz30w1qb9pl2lzpznw746jha29ybxyj5yn";
      type = "gem";
    };
    version = "0.21.0";
  };
  simplecov = {
    dependencies = ["docile" "simplecov-html" "simplecov_json_formatter"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "198kcbrjxhhzca19yrdcd6jjj9sb51aaic3b0sc3pwjghg3j49py";
      type = "gem";
    };
    version = "0.22.0";
  };
  simplecov-html = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yx01bxa8pbf9ip4hagqkp5m0mqfnwnw2xk8kjraiywz4lrss6jb";
      type = "gem";
    };
    version = "0.12.3";
  };
  simplecov-lcov = {
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ka6cdwywd6a6pqjwggm0439437xdq2r7514n3a5wn8a40ga6xvs";
      type = "gem";
    };
    version = "0.9.0";
  };
  simplecov_json_formatter = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0a5l0733hj7sk51j81ykfmlk2vd5vaijlq9d5fn165yyx3xii52j";
      type = "gem";
    };
    version = "0.1.4";
  };
  singleton = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0y2pc7lr979pab5n5lvk3jhsi99fhskl5f2s6004v8sabz51psl3";
      type = "gem";
    };
    version = "0.3.0";
  };
  sprockets = {
    dependencies = ["base64" "concurrent-ruby" "rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10ykzsa76cf8kvbfkszlvbyn4ckcx1mxjhfvwxzs7y28cljhzhkj";
      type = "gem";
    };
    version = "3.7.5";
  };
  sprockets-rails = {
    dependencies = ["actionpack" "activesupport" "sprockets"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1b9i14qb27zs56hlcc2hf139l0ghbqnjpmfi0054dxycaxvk5min";
      type = "gem";
    };
    version = "3.4.2";
  };
  stimulus-rails = {
    dependencies = ["railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01nbcxyi1mhikq8yjl0g9swy1cpzx146pli6w16gcfpkl7zpcmkn";
      type = "gem";
    };
    version = "1.3.4";
  };
  stringio = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1q92y9627yisykyscv0bdsrrgyaajc2qr56dwlzx7ysgigjv4z63";
      type = "gem";
    };
    version = "3.2.0";
  };
  strip_attributes = {
    dependencies = ["activemodel"];
    groups = ["default"];
    platforms = [];
    source = {
      fetchSubmodules = false;
      rev = "75f12bd5c68d4099142cb659a176748df0847488";
      sha256 = "0wzg07xmwadlr6msvfs02h4zlv2c3h14bf6q5p77afgy6ml690l7";
      type = "git";
      url = "https://github.com/mysociety/strip_attributes.git";
    };
    version = "1.14.1";
  };
  stripe = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cwf06d8i1x9pbbpzg78rs913zr46mv6bf4qa89l9jc4dp6253kl";
      type = "gem";
    };
    version = "13.5.1";
  };
  stripe-ruby-mock = {
    dependencies = ["dante" "drb" "multi_json" "stripe"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "05i389n9y62f2m34hhhnfgwx4mbggi3ay6lccz3jdw0gs456lmi0";
      type = "gem";
    };
    version = "5.0.0";
  };
  syslog_protocol = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1yb2cmbyj0zmb2yhkgnmghcngrkhcxs4g1svcmgfj90l2hs23nmc";
      type = "gem";
    };
    version = "0.9.2";
  };
  text = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1x6kkmsr49y3rnrin91rv8mpc3dhrf3ql08kbccw8yffq61brfrg";
      type = "gem";
    };
    version = "1.3.1";
  };
  thor = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wsy88vg2mazl039392hqrcwvs5nb9kq8jhhrrclir2px1gybag3";
      type = "gem";
    };
    version = "1.5.0";
  };
  tilt = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0rn8z8hda4h41a64l0zhkiwz2vxw9b1nb70gl37h1dg2k874yrlv";
      type = "gem";
    };
    version = "2.0.10";
  };
  timeout = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bz11pq7n1g51f50jqmgyf5b1v64p1pfqmy5l21y6vpr37b2lwkd";
      type = "gem";
    };
    version = "0.6.0";
  };
  tokenizers = {
    dependencies = ["rb_sys"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "sha256-y3a46GiTaV9s/mYYYcskaAdVvx+0Lcod3Tzf759leZQ=";
      type = "gem";
    };
    version = "0.6.3";
  };
  torch-rb = {
    dependencies = ["rb_sys" "rice"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "sha256-aqKbOVkCVcjqusRHUqvE4yMAbeRLqs+29XkkU/TAhE8=";
      type = "gem";
    };
    version = "0.22.2";
  };
  trailblazer-option = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18s48fndi2kfvrfzmq6rxvjfwad347548yby0341ixz1lhpg3r10";
      type = "gem";
    };
    version = "0.1.2";
  };
  transformers-rb = {
    dependencies = ["logger" "numo-narray" "rb_sys" "safetensors" "tokenizers" "torch-rb"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1fr8lv7jbk1dm7aka4wrv6rkd1gsprifbqz1h9sjqj2f3rscqlpa";
      type = "gem";
    };
    version = "0.1.7";
  };
  tsort = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17q8h020dw73wjmql50lqw5ddsngg67jfw8ncjv476l5ys9sfl4n";
      type = "gem";
    };
    version = "0.2.0";
  };
  turbo-rails = {
    dependencies = ["actionpack" "railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0priz7ww23h2j9j5zicc4np3rr357n01xw8zymn0bzxg79rr03gf";
      type = "gem";
    };
    version = "2.0.23";
  };
  typhoeus = {
    dependencies = ["ethon"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0z7gamf6s83wy0yqms3bi4srirn3fc0lc7n65lqanidxcj1xn5qw";
      type = "gem";
    };
    version = "1.4.1";
  };
  tzinfo = {
    dependencies = ["concurrent-ruby"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16w2g84dzaf3z13gxyzlzbf748kylk5bdgg3n1ipvkvvqy685bwd";
      type = "gem";
    };
    version = "2.0.6";
  };
  uber = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1p1mm7mngg40x05z52md3mbamkng0zpajbzqjjwmsyw0zw3v9vjv";
      type = "gem";
    };
    version = "0.1.0";
  };
  unicode = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1mx9lwzy021lpcqql5kn4yi20njhf5h7c7wxm2fx51p1r2zr9wj2";
      type = "gem";
    };
    version = "0.4.4.5";
  };
  unicode-display_width = {
    dependencies = ["unicode-emoji"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hiwhnqpq271xqari6mg996fgjps42sffm9cpk6ljn8sd2srdp8c";
      type = "gem";
    };
    version = "3.2.0";
  };
  unicode-emoji = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03zqn207zypycbz5m9mn7ym763wgpk7hcqbkpx02wrbm1wank7ji";
      type = "gem";
    };
    version = "4.2.0";
  };
  unidecoder = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wfnaynym2xvj9l60z30r3xndxhiw2qpnclijpadsm81fvxjwki2";
      type = "gem";
    };
    version = "1.1.2";
  };
  uniform_notifier = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17ffzyq6482yn27r7rz2k3zslf9jigbz383d90c68vznarapi1s7";
      type = "gem";
    };
    version = "1.18.0";
  };
  uri = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ijpbj7mdrq7rhpq2kb51yykhrs2s54wfs6sm9z3icgz4y6sb7rp";
      type = "gem";
    };
    version = "1.1.1";
  };
  useragent = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0i1q2xdjam4d7gwwc35lfnz0wyyzvnca0zslcfxm9fabml9n83kh";
      type = "gem";
    };
    version = "0.16.11";
  };
  vpim = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "09xrld8av4rqz717zx0k1yn74j4dvp7si2dyf64s88f4a26yrpyd";
      type = "gem";
    };
    version = "24.2.20";
  };
  web-console = {
    dependencies = ["actionview" "bindex" "railties"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "193ddancfznc34qp2bqz5mkv906v4aka6njv2lzhkhnz3hq72fz1";
      type = "gem";
    };
    version = "4.3.0";
  };
  webmock = {
    dependencies = ["addressable" "crack" "hashdiff"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1mqw7ca931zmqgad0fq4gw7z3gwb0pwx9cmd1b12ga4hgjsnysag";
      type = "gem";
    };
    version = "3.26.1";
  };
  webrick = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ca1hr2rxrfw7s613rp4r4bxb454i3ylzniv9b9gxpklqigs3d5y";
      type = "gem";
    };
    version = "1.9.2";
  };
  websocket-driver = {
    dependencies = ["base64" "websocket-extensions"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qj9dmkmgahmadgh88kydb7cv15w13l1fj3kk9zz28iwji5vl3gd";
      type = "gem";
    };
    version = "0.8.0";
  };
  websocket-extensions = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hc2g9qps8lmhibl5baa91b4qx8wqw872rgwagml78ydj8qacsqw";
      type = "gem";
    };
    version = "0.1.5";
  };
  will_paginate = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1fbmm0amshidnw0qx0nqjzfyy7if8xy6m5bm8lkksf8xprp24yqh";
      type = "gem";
    };
    version = "4.0.1";
  };
  wilson_score = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1sdxkxazimnvq5af00xjmikqc0d0pdyvl2fq4ji6zrakg32c2ck2";
      type = "gem";
    };
    version = "0.1.0";
  };
  xapian-full-alaveteli = {
    dependencies = ["mini_portile2" "rake"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14vm2yb0nj32cqybch6i0kc22zwc073scz3hn6ilahq77scwhdrx";
      type = "gem";
    };
    version = "1.4.22.2";
  };
  xml-simple = {
    dependencies = ["rexml"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pb9plyl71mdbjr4kllfy53qx6g68ryxblmnq9dilvy837jk24fj";
      type = "gem";
    };
    version = "1.1.9";
  };
  xpath = {
    dependencies = ["nokogiri"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0bh8lk9hvlpn7vmi6h4hkcwjzvs2y0cmkk3yjjdr8fxvj6fsgzbd";
      type = "gem";
    };
    version = "3.2.0";
  };
  zeitwerk = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1pbkiwwla5gldgb3saamn91058nl1sq1344l5k36xsh9ih995nnq";
      type = "gem";
    };
    version = "2.7.5";
  };
  zip_tricks = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "06gaba552jsxzx0gfmjypzm89jzhlg2iw3nfhrpyxkkvv4jljr7a";
      type = "gem";
    };
    version = "5.6.0";
  };
}
