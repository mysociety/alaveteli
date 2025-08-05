# -*- encoding : utf-8 -*-
namespace :embargoes do

  desc "Delete any embargoes that have expired"
  task :expire_publishable => :environment do
    AlaveteliPro::Embargo.expire_publishable
  end

end
