{
  actioncable = {
    dependencies = ["actionpack" "activesupport" "nio4r" "websocket-driver" "zeitwerk"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18496axh89kakw5f82mmmac3w9rwb0b0wq4j6la806p9cbgy5k3v";
      type = "gem";
    };
    version = "8.0.2";
  };
  actionmailbox = {
    dependencies = ["actionpack" "activejob" "activerecord" "activestorage" "activesupport" "mail"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nyfwa1kj0cm1scqsbv723ypv69bzaxh886hliyjbrhk752v73rx";
      type = "gem";
    };
    version = "8.0.2";
  };
  actionmailer = {
    dependencies = ["actionpack" "actionview" "activejob" "activesupport" "mail" "rails-dom-testing"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1l3pnba14p0p7zsh366c31maxap030c97597vjimdv3nhnrnijdh";
      type = "gem";
    };
    version = "8.0.2";
  };
  actionpack = {
    dependencies = ["actionview" "activesupport" "nokogiri" "rack" "rack-session" "rack-test" "rails-dom-testing" "rails-html-sanitizer" "useragent"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0y2b5ydiqy32jbd9g5bl6v4aw6d7pjn5f3w2rxf2j59q9w307rwk";
      type = "gem";
    };
    version = "8.0.2";
  };
  actiontext = {
    dependencies = ["actionpack" "activerecord" "activestorage" "activesupport" "globalid" "nokogiri"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1grs41yr3nzw7zbnz0vkv8f4qd448a632saxkm3vnbzf68hb63d4";
      type = "gem";
    };
    version = "8.0.2";
  };
  actionview = {
    dependencies = ["activesupport" "builder" "erubi" "rails-dom-testing" "rails-html-sanitizer"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1fyfyxf2a798lxq6sfpnj94kmnpfp17xlhvjy428zhfzbi0f2f70";
      type = "gem";
    };
    version = "8.0.2";
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
      sha256 = "1jjk31di5kvcflc90wmgdd50jzhljhafi166h6hg67kbwd2qn8mh";
      type = "gem";
    };
    version = "8.0.2";
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
      sha256 = "0v35y2jzqlfy1wnrzlzj2cxylhnz09vykaa1l2dnkq7sl5zzpq8a";
      type = "gem";
    };
    version = "8.0.2";
  };
  activerecord = {
    dependencies = ["activemodel" "activesupport" "timeout"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "02nrya34qviawdkssyahb3mg08kqdc461b320a6ikr245jwp0d3r";
      type = "gem";
    };
    version = "8.0.2";
  };
  activestorage = {
    dependencies = ["actionpack" "activejob" "activerecord" "activesupport" "marcel"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xr9cy6h8il61qq6w3rkvl56visms45ljm8f43r3ibh61wg24ggq";
      type = "gem";
    };
    version = "8.0.2";
  };
  activesupport = {
    dependencies = ["base64" "benchmark" "bigdecimal" "concurrent-ruby" "connection_pool" "drb" "i18n" "logger" "minitest" "securerandom" "tzinfo" "uri"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pm40y64wfc50a9sj87kxvil2102rmpdcbv82zf0r40vlgdwsrc5";
      type = "gem";
    };
    version = "8.0.2";
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
      sha256 = "0cl2qpvwiffym62z991ynks7imsm87qmgxf0yfsmlwzkgi9qcaa6";
      type = "gem";
    };
    version = "2.8.7";
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
      sha256 = "0g6ahzpdbybryzlfrbb18pybr4230hw1n6g475hh61mk4nlqgl1y";
      type = "gem";
    };
    version = "4.16.0";
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
      sha256 = "1m6rvr639n9hrhm5f6zk19xd8bc07avspmk66x89dnnjdjbl910j";
      type = "gem";
    };
    version = "1.1133.0";
  };
  aws-sdk-core = {
    dependencies = ["aws-eventstream" "aws-partitions" "aws-sigv4" "base64" "jmespath" "logger"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17n7vw9djnw74x7cgwsxfi0k033l351mf56i7y3lg4yawg2iy1wr";
      type = "gem";
    };
    version = "3.227.0";
  };
  aws-sdk-kms = {
    dependencies = ["aws-sdk-core" "aws-sigv4"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "07gyiwb7kbmg1amky4bg7nj8fwjpz9rqa40piz44k4s555mf3a0w";
      type = "gem";
    };
    version = "1.107.0";
  };
  aws-sdk-s3 = {
    dependencies = ["aws-sdk-core" "aws-sdk-kms" "aws-sigv4"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0sq0kv5zkys0g7l0h6wrwb0lyl86nbp03arfv9ldzx3sxhr5xks4";
      type = "gem";
    };
    version = "1.194.0";
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
  bcp47_spec = {
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "043qld01c163yc7fxlar3046dac2833rlcg44jbbs9n1jvgjxmiz";
      type = "gem";
    };
    version = "0.2.1";
  };
  bcrypt = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16a0g2q40biv93i1hch3gw8rbmhp77qnnifj1k0a6m7dng3zh444";
      type = "gem";
    };
    version = "3.1.20";
  };
  benchmark = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kicilpma5l0lwayqjb5577bm0hbjndj2gh150xz09xsgc1l1vyl";
      type = "gem";
    };
    version = "0.4.1";
  };
  bigdecimal = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1p2szbr4jdvmwaaj2kxlbv1rp0m6ycbgfyp0kjkkkswmniv5y21r";
      type = "gem";
    };
    version = "3.2.2";
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
      sha256 = "0hn5nysivwlzwgwgh3m97kzjgfy8g7nl82b2pahdj0xqnrg91fdl";
      type = "gem";
    };
    version = "8.0.8";
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
  capistrano = {
    dependencies = ["highline" "net-scp" "net-sftp" "net-ssh" "net-ssh-gateway"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0x4vcxqrnv3lwmqhnwcqpddidy4h6860xiinj9sq7zgipli540c0";
      type = "gem";
    };
    version = "2.15.11";
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
  caxlsx = {
    dependencies = ["htmlentities" "marcel" "nokogiri" "rubyzip"];
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "09q9743z94qv3y2fbiyby3mffaapjv1qna03xiykqyszpi91cr24";
      type = "gem";
    };
    version = "3.4.1";
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
  concurrent-ruby = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ipbrgvf0pp6zxdk5ascp6i29aybz2bx9wdrlchjmpx6mhvkwfw1";
      type = "gem";
    };
    version = "1.3.5";
  };
  connection_pool = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0nrhsk7b3sjqbyl1cah6ibf1kvi3v93a7wf4637d355hp614mmyg";
      type = "gem";
    };
    version = "2.5.3";
  };
  crack = {
    dependencies = ["bigdecimal" "rexml"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jaa7is4fw1cxigm8vlyhg05bw4nqy4f91zjqxk7pp4c8bdyyfn8";
      type = "gem";
    };
    version = "1.0.0";
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
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "19daxf5n5gr3pr57k4wqg701c3zwsk2h4jjialkaw7yrhi85jqrf";
      type = "gem";
    };
    version = "3.2.8";
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
      sha256 = "0kz6mc4b9m49iaans6cbx031j9y7ldghpi5fzsdh0n3ixwa8w9mz";
      type = "gem";
    };
    version = "3.4.1";
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
      sha256 = "07pj4z3h8wk4fgdn6s62vw1lwvhj0ac0x10vfbdkr9xzk7krn5cn";
      type = "gem";
    };
    version = "1.4.1";
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
  ebnf = {
    dependencies = ["base64" "htmlentities" "rdf" "scanf" "sxp" "unicode-types"];
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gpnphpp7qcdjh9vrj8bfrb3k54lq7pk7p23w92wr1d8r8ba6ip7";
      type = "gem";
    };
    version = "2.6.0";
  };
  erb = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03vcq8g8rxdq8njp9j9k9fxwjw19q4m08c7lxjs0yc6l8f0ja3yk";
      type = "gem";
    };
    version = "5.0.2";
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
      sha256 = "0p2rblgb4jwsjda5dp5p1lrb3qqwklr1rwkqnqmyr0fgmyy1xjfg";
      type = "gem";
    };
    version = "5.0.0";
  };
  execjs = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03a590q16nhqvfms0lh42mp6a1i41w41qpdnf39zjbq5y3l8pjvb";
      type = "gem";
    };
    version = "2.10.0";
  };
  factory_bot = {
    dependencies = ["activesupport"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "04z6zkfxasddw2bq1whyzzj45hxzhw2lcsdhzrqlvhd7h1yzn1s7";
      type = "gem";
    };
    version = "6.5.4";
  };
  factory_bot_rails = {
    dependencies = ["factory_bot" "railties"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18n06y5ww7d08w296b6fpzx05yywp5r8p88j0k37r994aiin2ysa";
      type = "gem";
    };
    version = "6.5.0";
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
      sha256 = "1dq1mk28vwn3hqrbd2nrm5mdq4bvvyg79z55blw5nnfs99x1wmz9";
      type = "gem";
    };
    version = "2.13.3";
  };
  faraday-net_http = {
    dependencies = ["net-http"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fxbckg468dabkkznv48ss8zv14d9cd8mh1rr3m98aw7wzx5fmq9";
      type = "gem";
    };
    version = "3.4.1";
  };
  fast_gettext = {
    dependencies = ["prime" "racc"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qr73k69pk5sjgkysrfar0sghrx0shz7kkfjcab200fnfqk62swf";
      type = "gem";
    };
    version = "4.1.0";
  };
  ffi = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "19kdyjg3kv7x0ad4xsd4swy5izsbb1vl1rpb6qqcqisr5s23awi9";
      type = "gem";
    };
    version = "1.17.2";
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
      sha256 = "05wmzqh23dsk4nw7asfwrjpk9s8lv42jf5mwf47j9kgsf2gw3ax4";
      type = "gem";
    };
    version = "1.3.5";
  };
  flipper-active_record = {
    dependencies = ["activerecord" "flipper"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18fm67g0y6fpjy2wbvzmbwqbifd6bdclcipwwrkbskym4ri7v1kp";
      type = "gem";
    };
    version = "1.3.5";
  };
  forwardable = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1b5g1i3xdvmxxpq4qp0z4v78ivqnazz26w110fh4cvzsdayz8zgi";
      type = "gem";
    };
    version = "1.3.3";
  };
  friendly_id = {
    dependencies = ["activerecord"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01v2q0cyqn8za374ygfxzpa5qf4j8yk7ilz6zrv3457wkfwg4670";
      type = "gem";
    };
    version = "5.5.1";
  };
  gender_detector = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "19m7z8l8vgr0aghlxa1gbb3zblj38092nk0lsiv9w1wr8c4brvd0";
      type = "gem";
    };
    version = "2.0.0";
  };
  gettext = {
    dependencies = ["erubi" "locale" "prime" "racc" "text"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0aji3873pxn6gc5qkvnv5y9025mqk0p6h22yrpyz2b3yx9qpzv03";
      type = "gem";
    };
    version = "3.5.1";
  };
  gettext_i18n_rails = {
    dependencies = ["fast_gettext"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1rlfmhhampvkzir32yqriry6rc6w66l36kb95lmfav4bjafp796l";
      type = "gem";
    };
    version = "1.13.0";
  };
  globalid = {
    dependencies = ["activesupport"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1sbw6b66r7cwdx3jhs46s4lr991969hvigkjpbdl7y3i31qpdgvh";
      type = "gem";
    };
    version = "1.2.1";
  };
  globalize = {
    dependencies = ["activemodel" "activerecord" "activesupport" "request_store"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1c6h9c50f8p536q67j8nzypwr5g85cs3970rfsslhcgbrn72zx3z";
      type = "gem";
    };
    version = "7.0.0";
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
    dependencies = ["addressable" "googleauth" "httpclient" "mini_mime" "mutex_m" "representable" "retriable"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vjls3xdzphphay0z3wmv2lw4zxbiv3vbmcy2d4b9spfdy0mgc4n";
      type = "gem";
    };
    version = "0.18.0";
  };
  google-apis-iamcredentials_v1 = {
    dependencies = ["google-apis-core"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1133kisa29q36db74lb28id3n65zfqpjw99may4jgddpiz3xlx2p";
      type = "gem";
    };
    version = "0.24.0";
  };
  google-apis-storage_v1 = {
    dependencies = ["google-apis-core"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0q1mdkzgy1gd3amm65qaqgy178h5nn3lr7mgzsixlfahlxairzmf";
      type = "gem";
    };
    version = "0.54.0";
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
      sha256 = "0jv9p5398rcdcflqp88zhjv3a2df662636m4p1ahjxf98hi5vc4x";
      type = "gem";
    };
    version = "1.56.0";
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
      sha256 = "0jai8xv2rmhz8nb6vxg4whq6aldmkbyjsn3hvk9w740qg48xxrv2";
      type = "gem";
    };
    version = "1.14.0";
  };
  hashdiff = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1da0w5v7ppxrgvh58bafjklzv73nknyq73if6d9rkz2v24zg3169";
      type = "gem";
    };
    version = "1.2.0";
  };
  highline = {
    dependencies = ["reline"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jmvyhjp2v3iq47la7w6psrxbprnbnmzz0hxxski3vzn356x7jv7";
      type = "gem";
    };
    version = "3.1.2";
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
      sha256 = "1nkklqsn8ir8wizzlakncfv42i32wc0w9hxp00hvdlgjr7376nhj";
      type = "gem";
    };
    version = "4.3.4";
  };
  httpclient = {
    dependencies = ["mutex_m"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1j4qwj1nv66v3n9s4xqf64x2galvjm630bwa5xngicllwic5jr2b";
      type = "gem";
    };
    version = "2.9.0";
  };
  i18n = {
    dependencies = ["concurrent-ruby"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03sx3ahz1v5kbqjwxj48msw3maplpp2iyzs22l4jrzrqh4zmgfnf";
      type = "gem";
    };
    version = "1.14.7";
  };
  icalendar = {
    dependencies = ["base64" "ice_cube" "logger" "ostruct"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0x4m9fznb9dikq1rhx5prnk4si3zp4j4ljl535qnvfbg1ncwaq42";
      type = "gem";
    };
    version = "2.11.2";
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
      sha256 = "0hg7m97pgssa6w0q6myvsp2i3wrx0c6i0j7lg5sm86k5c1ywc44z";
      type = "gem";
    };
    version = "2.1.0";
  };
  io-console = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1jszj95hazqqpnrjjzr326nn1j32xmsc9xvd97mbcrrgdc54858y";
      type = "gem";
    };
    version = "0.8.1";
  };
  irb = {
    dependencies = ["pp" "rdoc" "reline"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1fpxa2m83rb7xlzs57daqwnzqjmz6j35xr7zb15s73975sak4br2";
      type = "gem";
    };
    version = "1.15.2";
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
      sha256 = "1qm74n8g68a417ngb6kkw98x9ikjahdsmf1nv120nd3lfbs6nkiw";
      type = "gem";
    };
    version = "4.6.0";
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
      sha256 = "1x5b8ipv6g0z44wgc45039k04smsyf95h2m5m67mqq35sa5a955s";
      type = "gem";
    };
    version = "2.12.2";
  };
  jwt = {
    dependencies = ["base64"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1x64l31nkqjwfv51s2vsm0yqq4cwzrlnji12wvaq761myx3fxq9i";
      type = "gem";
    };
    version = "2.10.2";
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
  libv8-node = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kbijkxrqzgf94qdzh1xdxcypr6wnqmra0bhmwz7bif45739l3ig";
      type = "gem";
    };
    version = "24.1.0.0";
  };
  link_header = {
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1yamrdq4rywmnpdhbygnkkl9fdy249fg5r851nrkkxr97gj5rihm";
      type = "gem";
    };
    version = "0.0.8";
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
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "107pm4ccmla23z963kyjldgngfigvchnv85wr6m69viyxxrrjbsj";
      type = "gem";
    };
    version = "2.1.4";
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
      sha256 = "0dx316q03x6rpdbl610rdaj2vfd5s8fanixk21j4gv3h5f230nk5";
      type = "gem";
    };
    version = "2.24.1";
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
      sha256 = "190n2mk8m1l708kr88fh6mip9sdsh339d2s6sgrik3sbnvz4jmhd";
      type = "gem";
    };
    version = "1.0.4";
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
      sha256 = "02qlgz8lk1b6131hhb40a6qj78gb6kdpiz2s10d1m71knr3qy1ca";
      type = "gem";
    };
    version = "1.3.2";
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
      sha256 = "1x42yk0fi6bjm8g2ld9f0752v3p53sc4a7c1v5k8ls65xibzvlgr";
      type = "gem";
    };
    version = "3.2025.0722";
  };
  mini_magick = {
    dependencies = ["logger"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "194vlx50sj527zl9824m6kvwarcjb854vw63nh2f5szrj2f304vg";
      type = "gem";
    };
    version = "5.3.0";
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
  mini_racer = {
    dependencies = ["libv8-node"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hdv2sn2p74hpixvk7065irhiycilgi2ccc4xmf192yv713njlli";
      type = "gem";
    };
    version = "0.19.0";
  };
  minitest = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0mn7q9yzrwinvfvkyjiz548a4rmcwbmz2fn9nyzh4j1snin6q6rr";
      type = "gem";
    };
    version = "5.25.5";
  };
  money = {
    dependencies = ["i18n"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1wyswxfpvhxm3vmgwa7r52kfzl154zarzva1j9qq69rgwjhnz4zc";
      type = "gem";
    };
    version = "6.19.0";
  };
  multi_json = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "06sabsvnw0x1aqdcswc6bqrqz6705548bfd8z22jxgxfjrn1yn3n";
      type = "gem";
    };
    version = "1.17.0";
  };
  mutex_m = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0l875dw0lk7b2ywa54l0wjcggs94vb7gs8khfw9li75n2sn09jyg";
      type = "gem";
    };
    version = "0.3.0";
  };
  net-http = {
    dependencies = ["uri"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ysrwaabhf0sn24jrp0nnp51cdv0jf688mh5i6fsz63q2c6b48cn";
      type = "gem";
    };
    version = "0.6.0";
  };
  net-http-persistent = {
    dependencies = ["connection_pool"];
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pfxhhn1lqnxx8dj3ig3lgnhkxq5jsb0brg7w2wnrpwf8c23mfra";
      type = "gem";
    };
    version = "4.0.6";
  };
  net-imap = {
    dependencies = ["date" "net-protocol"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1z1kpshd0r09jv0091bcr4gfx3i1psbqdzy7zyag5n8v3qr0anfr";
      type = "gem";
    };
    version = "0.5.9";
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
  net-scp = {
    dependencies = ["net-ssh"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0p8s7l4pr6hkn0l6rxflsc11alwi1kfg5ysgvsq61lz5l690p6x9";
      type = "gem";
    };
    version = "4.1.0";
  };
  net-sftp = {
    dependencies = ["net-ssh"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0r33aa2d61hv1psm0l0mm6ik3ycsnq8symv7h84kpyf2b7493fv5";
      type = "gem";
    };
    version = "4.0.0";
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
  net-ssh = {
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1w1ypxa3n6mskkwb00b489314km19l61p5h3bar6zr8cng27c80p";
      type = "gem";
    };
    version = "7.3.0";
  };
  net-ssh-gateway = {
    dependencies = ["net-ssh"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1l3v761y32aw0n8lm0c0m42lr4ay8cq6q4sc5yc68b9fwlfvb70x";
      type = "gem";
    };
    version = "2.0.0";
  };
  nio4r = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1a9www524fl1ykspznz54i0phfqya4x45hqaz67in9dvw1lfwpfr";
      type = "gem";
    };
    version = "2.7.4";
  };
  nokogiri = {
    dependencies = ["mini_portile2" "racc"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0czsh9d738kj0bmpkjnczq9j924hg103gc00i0wfyg0fzn9psnmc";
      type = "gem";
    };
    version = "1.18.9";
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
      sha256 = "0i9w8msil4snx5w11ix9b0wf52vjc3r49khy3ddgl1xk890kcxi4";
      type = "gem";
    };
    version = "3.3.8.0";
  };
  pg = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1p2gqqrm895fzr9vi8d118zhql67bm8ydjvgqbq1crdnfggzn7kn";
      type = "gem";
    };
    version = "1.5.9";
  };
  pp = {
    dependencies = ["prettyprint"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zxnfxjni0r9l2x42fyq0sqpnaf5nakjbap8irgik4kg1h9c6zll";
      type = "gem";
    };
    version = "0.6.2";
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
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gkhpdjib9zi9i27vd9djrxiwjia03cijmd6q8yj2q1ix403w3nw";
      type = "gem";
    };
    version = "1.4.0";
  };
  pry = {
    dependencies = ["coderay" "method_source"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ssv704qg75mwlyagdfr9xxbzn1ziyqgzm0x474jkynk8234pm8j";
      type = "gem";
    };
    version = "0.15.2";
  };
  pstore = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1a3lrq8k62n8bazhxgdmjykni9wv0mcjks5vi1g274i3wblcgrfn";
      type = "gem";
    };
    version = "0.2.0";
  };
  psych = {
    dependencies = ["date" "stringio"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0vii1xc7x81hicdbp7dlllhmbw5w3jy20shj696n0vfbbnm2hhw1";
      type = "gem";
    };
    version = "5.2.6";
  };
  public_suffix = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1543ap9w3ydhx39ljcd675cdz9cr948x9mp00ab8qvq6118wv9xz";
      type = "gem";
    };
    version = "6.0.2";
  };
  puma = {
    dependencies = ["nio4r"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11xd3207k5rl6bz0qxhcb3zcr941rhx7ig2f19gxxmdk7s3hcp7j";
      type = "gem";
    };
    version = "6.6.0";
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
      sha256 = "1pcr8sn02lwzv3z6vx5n41b6ybcnw9g9h05s3lkv4vqdm0f2mq2z";
      type = "gem";
    };
    version = "2.2.17";
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
      sha256 = "0g6765f95k3q3380vzl0c1pcbr52l8d7xapchpr76ydbl68ick6m";
      type = "gem";
    };
    version = "1.10.1";
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
      sha256 = "1ik4y7c545pb9lf70prv0n4drblwjlaxb22fhq18wf607slabypx";
      type = "gem";
    };
    version = "8.0.2";
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
      sha256 = "0q55i6mpad20m2x1lg5pkqfpbmmapk0sjsrvr1sqgnj2hb5f5z1m";
      type = "gem";
    };
    version = "1.6.2";
  };
  rails-i18n = {
    dependencies = ["i18n" "railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03dy8nmq2gxvkg8zqq6c0wwz98mdwp3i9krn0slcknhb8nak2c0m";
      type = "gem";
    };
    version = "8.0.1";
  };
  railties = {
    dependencies = ["actionpack" "activesupport" "irb" "rackup" "rake" "thor" "zeitwerk"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1yaw5sw9vxvvkkc335laxv2k34rs2nxx9hdsy604k9wvqi03yz0d";
      type = "gem";
    };
    version = "8.0.2";
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
      sha256 = "14s4jdcs1a4saam9qmzbsa2bsh85rj9zfxny5z315x3gg0nhkxcn";
      type = "gem";
    };
    version = "13.3.0";
  };
  rb-fsevent = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zmf31rnpm8553lqwibvv3kkx0v7majm1f341xbxc0bk5sbhp423";
      type = "gem";
    };
    version = "0.11.2";
  };
  rb-inotify = {
    dependencies = ["ffi"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0vmy8xgahixcz6hzwy4zdcyn2y6d6ri8dqv5xccgzc1r292019x0";
      type = "gem";
    };
    version = "0.11.1";
  };
  rdf = {
    dependencies = ["bcp47_spec" "bigdecimal" "link_header" "logger" "ostruct" "readline"];
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1har1346p7jwrs89d5w1gv98jk2nh3cwkdyvkzm2nkjv3s1a0zx7";
      type = "gem";
    };
    version = "3.3.4";
  };
  rdf-aggregate-repo = {
    dependencies = ["rdf"];
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1p7gm5arszrjqvmzsr170bb1j7ri52qamscm7h8wggnvyjmwr4sn";
      type = "gem";
    };
    version = "3.3.0";
  };
  rdf-xsd = {
    dependencies = ["rdf" "rexml"];
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wj7ljxnlsyf8ni7dz0bhi04ki74hcpg6bk2kdyj6i03n8kivdgs";
      type = "gem";
    };
    version = "3.3.0";
  };
  rdoc = {
    dependencies = ["erb" "psych"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "09lj8d16wx5byj0nbcb9wc6v9farsvgn98n91kknm18g2ggl9pcz";
      type = "gem";
    };
    version = "6.14.2";
  };
  readline = {
    dependencies = ["reline"];
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0shxkj3kbwl43rpg490k826ibdcwpxiymhvjnsc85fg2ggqywf31";
      type = "gem";
    };
    version = "0.0.4";
  };
  recaptcha = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0f9aicqz0rsirjb30d4nci767a0hdyw5mjfj05ls13bqbcd0575n";
      type = "gem";
    };
    version = "5.19.0";
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
      sha256 = "1gb838wvrmsv2zf6g6injf1dvgxhh5km28n3xrrrqk0rjn7hy4s0";
      type = "gem";
    };
    version = "0.25.1";
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
      sha256 = "0qccah61pjvzyyg6mrp27w27dlv6vxlbznzipxjcswl7x3fhsvyb";
      type = "gem";
    };
    version = "2.10.0";
  };
  reline = {
    dependencies = ["io-console"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ii8l0q5zkang3lxqlsamzfz5ja7jc8ln905isfdawl802k2db8x";
      type = "gem";
    };
    version = "0.6.2";
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
      sha256 = "1jmbf6lf7pcyacpb939xjjpn1f84c3nw83dy3p1lwjx0l2ljfif7";
      type = "gem";
    };
    version = "3.4.1";
  };
  rodf = {
    dependencies = ["builder" "rubyzip"];
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14993s6x5fr1053wmb7s5ij16sr90ig853fapzvp6d03ay6b840c";
      type = "gem";
    };
    version = "1.2.0";
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
      sha256 = "1fx28knrndm5xijhnv0pa06ra6jx2iswkgyhpl9b8hlbnsmsihd2";
      type = "gem";
    };
    version = "1.2.1";
  };
  rspec-core = {
    dependencies = ["rspec-support"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18sgga9zjrd5579m9rpb78l7yn9a0bjzwz51z5kiq4y6jwl6hgxb";
      type = "gem";
    };
    version = "3.13.5";
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
      sha256 = "10gajm8iscl7gb8q926hyna83bw3fx2zb4sqdzjrznjs51pqlcz4";
      type = "gem";
    };
    version = "3.13.5";
  };
  rspec-rails = {
    dependencies = ["actionpack" "activesupport" "railties" "rspec-core" "rspec-expectations" "rspec-mocks" "rspec-support"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01b5d37i3igh11v5y801gxzb1df2v0il0mfdqi4cdmxn1aqh0dqc";
      type = "gem";
    };
    version = "8.0.1";
  };
  rspec-support = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1xx3f4mgr84jz07fifd3r68hm6giqy91hqyzawmi0s59yqa1hjqq";
      type = "gem";
    };
    version = "3.13.4";
  };
  rubocop = {
    dependencies = ["json" "language_server-protocol" "lint_roller" "parallel" "parser" "rainbow" "regexp_parser" "rubocop-ast" "ruby-progressbar" "unicode-display_width"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1h48rhmp178ppzc4ybfj42a2savs4bxgy3bvw95i4ypgfm2hndhz";
      type = "gem";
    };
    version = "1.77.0";
  };
  rubocop-ast = {
    dependencies = ["parser" "prism"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ar3y8w36am483ynyzg0x8iwhn8h34y8f4agny4lyqcqbfnzd9qd";
      type = "gem";
    };
    version = "1.46.0";
  };
  rubocop-performance = {
    dependencies = ["lint_roller" "rubocop" "rubocop-ast"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1h9flnqk2f3llwf8g0mk0fvzzznfj7hsil3qg88m803pi9b06zbg";
      type = "gem";
    };
    version = "1.25.0";
  };
  rubocop-rails = {
    dependencies = ["activesupport" "lint_roller" "rack" "rubocop" "rubocop-ast"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1404nfa0gw3p0xzmv4b9zg9v1da0nwc4m7796pl73zi2hwy65k4z";
      type = "gem";
    };
    version = "2.32.0";
  };
  ruby-msg = {
    dependencies = ["ruby-ole" "vpim"];
    groups = ["default"];
    platforms = [];
    source = {
      fetchSubmodules = false;
      rev = "fae72e547299ab1f8b23239a79f5a1d353426b40";
      sha256 = "1r834sf44240hp6nyjmlhsszgmab1hsksihagqzwsi1mksinbnhc";
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
      sha256 = "0j8wxbkl261nwg7jr6kdz0zlyim4zcnnb72ynky97grqid6d61d3";
      type = "gem";
    };
    version = "2.2.4";
  };
  rubyXL = {
    dependencies = ["nokogiri" "rubyzip"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0bkd50mpsrkz6agqvvbi8d0l1cic6jrkdsrjjzfkz5jzrzd349yw";
      type = "gem";
    };
    version = "3.4.33";
  };
  rubyzip = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "05an0wz87vkmqwcwyh5rjiaavydfn5f4q1lixcsqkphzvj7chxw5";
      type = "gem";
    };
    version = "2.4.1";
  };
  sass = {
    dependencies = ["sass-listen"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0p95lhs0jza5l7hqci1isflxakz83xkj97lkvxl919is0lwhv2w0";
      type = "gem";
    };
    version = "3.7.4";
  };
  sass-listen = {
    dependencies = ["rb-fsevent" "rb-inotify"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xw3q46cmahkgyldid5hwyiwacp590zj2vmswlll68ryvmvcp7df";
      type = "gem";
    };
    version = "4.0.0";
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
  scanf = {
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "000vxsci3zq8m1wl7mmppj7sarznrqlm6v2x2hdfmbxcwpvvfgak";
      type = "gem";
    };
    version = "1.0.0";
  };
  secure_headers = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1712ywg4vw5w457zklq8diagyffpiwbsy50ylk3lg64c6x4djgyh";
      type = "gem";
    };
    version = "7.0.0";
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
      sha256 = "18s7xiclzajp9w9cmq8k28iy5ig1zpx1zv1mrm416cb2c0m0wrmw";
      type = "gem";
    };
    version = "0.20.0";
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
      sha256 = "0ikjfwydgs08nm3xzc4cn4b6z6rmcrj2imp84xcnimy2wxa8w2xx";
      type = "gem";
    };
    version = "0.13.2";
  };
  simplecov-lcov = {
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0r3pmjjdjvprk8bzmcvarhf57sp5xzgj1c6007qaqhs7b4fhvxvb";
      type = "gem";
    };
    version = "0.7.0";
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
  sparql = {
    dependencies = ["builder" "ebnf" "logger" "rdf" "rdf-aggregate-repo" "rdf-xsd" "readline" "sparql-client" "sxp"];
    groups = ["theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1p34xnrzjjyr5zlm9x9nym75kxma24n039achcyd1mhzh1i3mmr0";
      type = "gem";
    };
    version = "3.3.2";
  };
  sparql-client = {
    dependencies = ["net-http-persistent" "rdf"];
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0knnrajm5zw7prykh9az7s1zmzxwm7w8s05pnsm2pp28mppmw8ki";
      type = "gem";
    };
    version = "3.3.0";
  };
  spreadsheet_architect = {
    dependencies = ["caxlsx" "rodf"];
    groups = ["theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0rljmja7pi0dyq53mbh9ni6gcix31flsjqd9krb2f0w4yyrvm3s4";
      type = "gem";
    };
    version = "5.0.0";
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
      sha256 = "17hiqkdpcjyyhlm997mgdcr45v35j5802m5a979i5jgqx5n8xs59";
      type = "gem";
    };
    version = "3.5.2";
  };
  statistics2 = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1iym14av4a35ybac0ghbnc6knvg4skkhrqmzb8sjvgy5kmqazbax";
      type = "gem";
    };
    version = "0.54";
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
      sha256 = "1yh78pg6lm28c3k0pfd2ipskii1fsraq46m6zjs5yc9a4k5vfy2v";
      type = "gem";
    };
    version = "3.1.7";
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
      sha256 = "1gzff69hciwlpy80rq838h56h8a4bq3423rhagl3v4lcm7wnwlid";
      type = "gem";
    };
    version = "11.7.0";
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
  sxp = {
    dependencies = ["matrix" "rdf"];
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08a7ha191gdc1n1pwaqgsx133wy1p1g4fchkhr5gx0jannx1p5vr";
      type = "gem";
    };
    version = "2.0.0";
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
      sha256 = "0gcarlmpfbmqnjvwfz44gdjhcmm634di7plcx2zdgwdhrhifhqw7";
      type = "gem";
    };
    version = "1.4.0";
  };
  tilt = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0w27v04d7rnxjr3f65w1m7xyvr6ch6szjj2v5wv1wz6z5ax9pa9m";
      type = "gem";
    };
    version = "2.6.1";
  };
  timeout = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03p31w5ghqfsbz5mcjzvwgkw3h9lbvbknqvrdliy8pxmn9wz02cm";
      type = "gem";
    };
    version = "0.4.3";
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
  turbo-rails = {
    dependencies = ["actionpack" "railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "13d31vm4i39cg7nkgn10h8zi89qh77jngafdkrab6xf5y1h1nknj";
      type = "gem";
    };
    version = "2.0.16";
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
  uglifier = {
    dependencies = ["execjs"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1apmqsad2y1avffh79f4lfysfppz94fvpyi7lkkj3z8bn60jpm3m";
      type = "gem";
    };
    version = "4.2.1";
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
      sha256 = "1has87asspm6m9wgqas8ghhhwyf2i1yqrqgrkv47xw7jq3qjmbwc";
      type = "gem";
    };
    version = "3.1.4";
  };
  unicode-emoji = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ajk6rngypm3chvl6r0vwv36q1931fjqaqhjjya81rakygvlwb1c";
      type = "gem";
    };
    version = "4.0.4";
  };
  unicode-types = {
    groups = ["default" "theme"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ybns4spibnw11am52h7bx7bnl9sp7mpw7j7hndsh3r6fc921lc1";
      type = "gem";
    };
    version = "1.11.0";
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
      sha256 = "19vcdlfcxrlp4vkzx0jn4zwf5jg125ca89s0mnqcqs6i5bnqfiyv";
      type = "gem";
    };
    version = "1.17.0";
  };
  uri = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "04bhfvc25b07jaiaf62yrach7khhr5jlr5bx6nygg8pf11329wp9";
      type = "gem";
    };
    version = "1.0.3";
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
    dependencies = ["actionview" "activemodel" "bindex" "railties"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "087y4byl2s3fg0nfhix4s0r25cv1wk7d2j8n5324waza21xg7g77";
      type = "gem";
    };
    version = "4.2.1";
  };
  webmock = {
    dependencies = ["addressable" "crack" "hashdiff"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08v374yrqqhjj3xjzmvwnv3yz21r22kn071yr0i67gmwaf9mv7db";
      type = "gem";
    };
    version = "3.25.1";
  };
  webrick = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12d9n8hll67j737ym2zw4v23cn4vxyfkb6vyv1rzpwv6y6a3qbdl";
      type = "gem";
    };
    version = "1.9.1";
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
      sha256 = "119ypabas886gd0n9kiid3q41w76gz60s8qmiak6pljpkd56ps5j";
      type = "gem";
    };
    version = "2.7.3";
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
