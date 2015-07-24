# -*- encoding : utf-8 -*-
module XapianQueries

  # These methods take some filter criteria expressed in a hash and convert them
  # into a xapian query referencing the terms and values stored by InfoRequestEvent.
  # Note that the params are request params and may contain irrelevant keys

  def get_request_variety_from_params(params)
    query = ""
    sortby = "newest"
    varieties = []
    if params[:request_variety] && !(query =~ /variety:/)
      if params[:request_variety].include? "sent"
        varieties -= ['variety:sent', 'variety:followup_sent', 'variety:response', 'variety:comment']
        varieties << ['variety:sent', 'variety:followup_sent']
      end
      if params[:request_variety].include? "response"
        varieties << ['variety:response']
      end
      if params[:request_variety].include? "comment"
        varieties << ['variety:comment']
      end
    end
    if !varieties.empty?
      query = " (#{varieties.join(' OR ')})"
    end
    return query
  end

  def get_status_from_params(params)
    query = ""
    if params[:latest_status]
      statuses = []
      if params[:latest_status].class == String
        params[:latest_status] = [params[:latest_status]]
      end
      if params[:latest_status].include?("recent") ||  params[:latest_status].include?("all")
        query += " (variety:sent OR variety:followup_sent OR variety:response OR variety:comment)"
      end
      if params[:latest_status].include? "successful"
        statuses << ['latest_status:successful', 'latest_status:partially_successful']
      end
      if params[:latest_status].include? "unsuccessful"
        statuses << ['latest_status:rejected', 'latest_status:not_held']
      end
      if params[:latest_status].include? "awaiting"
        statuses << ['latest_status:waiting_response', 'latest_status:waiting_clarification', 'waiting_classification:true', 'latest_status:internal_review','latest_status:gone_postal', 'latest_status:error_message', 'latest_status:requires_admin']
      end
      if params[:latest_status].include? "internal_review"
        statuses << ['status:internal_review']
      end
      if params[:latest_status].include? "other"
        statuses << ['latest_status:gone_postal', 'latest_status:error_message', 'latest_status:requires_admin', 'latest_status:user_withdrawn']
      end
      if params[:latest_status].include? "gone_postal"
        statuses << ['latest_status:gone_postal']
      end
      if !statuses.empty?
        query = " (#{statuses.join(' OR ')})"
      end
    end
    return query
  end

  def get_date_range_from_params(params)
    query = ""
    if params.has_key?(:request_date_after) && !params.has_key?(:request_date_before)
      params[:request_date_before] = Time.now.strftime("%d/%m/%Y")
      query += " #{params[:request_date_after]}..#{params[:request_date_before]}"
    elsif !params.has_key?(:request_date_after) && params.has_key?(:request_date_before)
      params[:request_date_after] = "01/01/2001"
    end
    if params.has_key?(:request_date_after)
      query = " #{params[:request_date_after]}..#{params[:request_date_before]}"
    end
    return query
  end

  def make_query_from_params(params)
    query = params.fetch(:query) { '' }
    query += get_date_range_from_params(params)
    query += get_request_variety_from_params(params)
    query += get_status_from_params(params)
    query
  end
end
