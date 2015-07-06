# -*- encoding : utf-8 -*-
require 'strip_attributes/strip_attributes'
ActiveRecord::Base.extend(StripAttributes)
